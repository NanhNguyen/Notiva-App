import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/enums/hand_status.dart';
import '../../domain/enums/piece_status.dart';
import '../../domain/models/piece.dart';
import '../../domain/models/piece_with_sections.dart';
import '../../domain/models/section.dart';
import '../database/app_database.dart' as db;
import '../helpers/clock.dart';
import '../helpers/id_generator.dart';

/// Repository interface for musical pieces.
abstract interface class PieceRepository {
  Future<Piece> create({
    required String title,
    String? composer,
    PieceStatus status = PieceStatus.learning,
    String? userId,
  });

  Future<Piece> update(Piece piece);

  Future<void> softDelete(String id);

  Future<Piece?> getById(String id);

  Stream<Piece?> watchById(String id);

  Future<List<Piece>> getAll();

  Stream<List<Piece>> watchAll();

  Stream<List<PieceWithSections>> watchAllWithSections();

  Stream<int> watchSessionCountForPiece(String pieceId);
}

/// Drift-backed implementation of [PieceRepository].
class DriftPieceRepository implements PieceRepository {
  DriftPieceRepository({
    required db.AppDatabase db,
    required IdGenerator idGenerator,
    required AppClock clock,
  })  : _db = db,
        _idGenerator = idGenerator,
        _clock = clock;

  final db.AppDatabase _db;
  final IdGenerator _idGenerator;
  final AppClock _clock;

  @override
  Future<Piece> create({
    required String title,
    String? composer,
    PieceStatus status = PieceStatus.learning,
    String? userId,
  }) async {
    final now = _clock.nowUtc();
    final id = _idGenerator.nextId();
    final companion = db.PiecesCompanion.insert(
      id: id,
      userId: Value(userId),
      title: title,
      composer: Value(composer),
      status: status.name,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.pieces).insert(companion);

    return Piece(
      id: id,
      userId: userId,
      title: title,
      composer: composer,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<Piece> update(Piece piece) async {
    final now = _clock.nowUtc();
    final updated = piece.copyWith(updatedAt: now);

    await (_db.update(_db.pieces)
          ..where((t) => t.id.equals(piece.id) & t.deletedAt.isNull()))
        .write(
      db.PiecesCompanion(
        userId: Value(updated.userId),
        title: Value(updated.title),
        composer: Value(updated.composer),
        status: Value(updated.status.name),
        updatedAt: Value(now),
      ),
    );

    return updated;
  }

  @override
  Future<void> softDelete(String id) async {
    final now = _clock.nowUtc();
    await _db.transaction(() async {
      // Soft-delete the piece.
      await (_db.update(_db.pieces)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .write(
        db.PiecesCompanion(
          updatedAt: Value(now),
          deletedAt: Value(now),
        ),
      );

      // Find active sections belonging to this piece so dependent rows are also soft-deleted.
      final sectionRows = await (_db.select(_db.sections)
            ..where((t) => t.pieceId.equals(id) & t.deletedAt.isNull()))
          .get();
      final sectionIds = sectionRows.map((s) => s.id).toList();

      if (sectionIds.isNotEmpty) {
        await (_db.update(_db.sections)
              ..where((t) => t.pieceId.equals(id) & t.deletedAt.isNull()))
            .write(
          db.SectionsCompanion(
            updatedAt: Value(now),
            deletedAt: Value(now),
          ),
        );

        await (_db.update(_db.planItems)
              ..where(
                (t) => t.sectionId.isIn(sectionIds) & t.deletedAt.isNull(),
              ))
            .write(
          db.PlanItemsCompanion(
            updatedAt: Value(now),
            deletedAt: Value(now),
          ),
        );

        await (_db.update(_db.entries)
              ..where(
                (t) => t.sectionId.isIn(sectionIds) & t.deletedAt.isNull(),
              ))
            .write(
          db.EntriesCompanion(
            updatedAt: Value(now),
            deletedAt: Value(now),
          ),
        );
      }
    });
  }

  @override
  Future<Piece?> getById(String id) async {
    final row = await (_db.select(_db.pieces)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Stream<Piece?> watchById(String id) {
    return (_db.select(_db.pieces)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _mapRow(row));
  }

  @override
  Stream<int> watchSessionCountForPiece(String pieceId) {
    final query = _db.select(_db.entries).join([
      innerJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.entries.sectionId) &
            _db.sections.pieceId.equals(pieceId) &
            _db.sections.deletedAt.isNull(),
      ),
    ])
      ..where(_db.entries.deletedAt.isNull());

    return query.watch().map((rows) {
      final sessionIds = <String>{};
      for (final row in rows) {
        sessionIds.add(row.readTable(_db.entries).sessionId);
      }
      return sessionIds.length;
    });
  }

  @override
  Future<List<Piece>> getAll() async {
    final rows = await (_db.select(_db.pieces)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows.map(_mapRow).toList();
  }

  @override
  Stream<List<Piece>> watchAll() {
    return (_db.select(_db.pieces)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Stream<List<PieceWithSections>> watchAllWithSections() {
    final query = _db.select(_db.pieces).join([
      leftOuterJoin(
        _db.sections,
        _db.sections.pieceId.equalsExp(_db.pieces.id) &
            _db.sections.deletedAt.isNull(),
      ),
    ])
      ..where(_db.pieces.deletedAt.isNull())
      ..orderBy([
        OrderingTerm.desc(_db.pieces.updatedAt),
        OrderingTerm.asc(_db.sections.orderIndex),
      ]);

    return query.watch().map((rows) {
      final grouped = <String, _PieceGroup>{};
      for (final row in rows) {
        final pieceRow = row.readTable(_db.pieces);
        final sectionRow = row.readTableOrNull(_db.sections);
        final group = grouped.putIfAbsent(
          pieceRow.id,
          () => _PieceGroup(_mapRow(pieceRow)),
        );
        if (sectionRow != null) {
          group.sections.add(_mapSectionRow(sectionRow));
        }
      }
      return grouped.values
          .map((g) => PieceWithSections(piece: g.piece, sections: g.sections))
          .toList();
    });
  }

  Section _mapSectionRow(db.Section row) {
    return Section(
      id: row.id,
      userId: row.userId,
      pieceId: row.pieceId,
      name: row.name,
      orderIndex: row.orderIndex,
      pageRef: row.pageRef,
      measureStart: row.measureStart,
      measureEnd: row.measureEnd,
      difficultyTags: _decodeStringList(row.difficultyTags),
      note: row.note,
      links: _decodeStringList(row.links),
      rhStatus: HandStatus.fromValue(row.rhStatus),
      lhStatus: HandStatus.fromValue(row.lhStatus),
      htStatus: HandStatus.fromValue(row.htStatus),
      nextAction: row.nextAction,
      lastPracticedAt: row.lastPracticedAt?.toUtc(),
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
      deletedAt: row.deletedAt?.toUtc(),
    );
  }

  List<String> _decodeStringList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } catch (_) {}
    return const [];
  }

  Piece _mapRow(db.Piece row) {
    return Piece(
      id: row.id,
      userId: row.userId,
      title: row.title,
      composer: row.composer,
      status: PieceStatus.values.firstWhere(
        (e) => e.name == row.status,
        orElse: () => PieceStatus.learning,
      ),
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
      deletedAt: row.deletedAt?.toUtc(),
    );
  }
}

class _PieceGroup {
  _PieceGroup(this.piece);

  final Piece piece;
  final List<Section> sections = [];
}

