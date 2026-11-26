import 'package:drift/drift.dart';

import '../../domain/enums/piece_status.dart';
import '../../domain/models/piece.dart';
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

  Future<List<Piece>> getAll();

  Stream<List<Piece>> watchAll();
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

