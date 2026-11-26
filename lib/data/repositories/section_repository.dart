import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/enums/hand_status.dart';
import '../../domain/models/section.dart';
import '../database/app_database.dart' as db;
import '../helpers/clock.dart';
import '../helpers/id_generator.dart';

/// Repository interface for practice sections.
abstract interface class SectionRepository {
  Future<Section> create({
    required String pieceId,
    required String name,
    int? orderIndex,
    String? pageRef,
    int? measureStart,
    int? measureEnd,
    List<String> difficultyTags = const [],
    String? note,
    List<String> links = const [],
    HandStatus rhStatus = HandStatus.notStarted,
    HandStatus lhStatus = HandStatus.notStarted,
    HandStatus htStatus = HandStatus.notStarted,
    String? nextAction,
    DateTime? lastPracticedAt,
    String? userId,
  });

  Future<Section> update(Section section);

  Future<Section> updateHandStatus(
    String sectionId, {
    HandStatus? rh,
    HandStatus? lh,
    HandStatus? ht,
  });

  Future<void> softDelete(String id);

  Future<Section?> getById(String id);

  Future<List<Section>> getByPieceId(String pieceId);

  Stream<List<Section>> watchByPieceId(String pieceId);

  Stream<Section?> watchById(String id);
}

/// Drift-backed implementation of [SectionRepository].
class DriftSectionRepository implements SectionRepository {
  DriftSectionRepository({
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
  Future<Section> create({
    required String pieceId,
    required String name,
    int? orderIndex,
    String? pageRef,
    int? measureStart,
    int? measureEnd,
    List<String> difficultyTags = const [],
    String? note,
    List<String> links = const [],
    HandStatus rhStatus = HandStatus.notStarted,
    HandStatus lhStatus = HandStatus.notStarted,
    HandStatus htStatus = HandStatus.notStarted,
    String? nextAction,
    DateTime? lastPracticedAt,
    String? userId,
  }) async {
    final now = _clock.nowUtc();
    final id = _idGenerator.nextId();
    final resolvedOrderIndex =
        orderIndex ?? await _nextOrderIndex(pieceId);

    await _db.into(_db.sections).insert(
          db.SectionsCompanion.insert(
            id: id,
            userId: Value(userId),
            pieceId: pieceId,
            name: name,
            orderIndex: resolvedOrderIndex,
            pageRef: Value(pageRef),
            measureStart: Value(measureStart),
            measureEnd: Value(measureEnd),
            difficultyTags: Value(jsonEncode(difficultyTags)),
            note: Value(note),
            links: Value(jsonEncode(links)),
            rhStatus: Value(rhStatus.value),
            lhStatus: Value(lhStatus.value),
            htStatus: Value(htStatus.value),
            nextAction: Value(nextAction),
            lastPracticedAt: Value(lastPracticedAt?.toUtc()),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return Section(
      id: id,
      userId: userId,
      pieceId: pieceId,
      name: name,
      orderIndex: resolvedOrderIndex,
      pageRef: pageRef,
      measureStart: measureStart,
      measureEnd: measureEnd,
      difficultyTags: difficultyTags,
      note: note,
      links: links,
      rhStatus: rhStatus,
      lhStatus: lhStatus,
      htStatus: htStatus,
      nextAction: nextAction,
      lastPracticedAt: lastPracticedAt?.toUtc(),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<int> _nextOrderIndex(String pieceId) async {
    final existing = await (_db.select(_db.sections)
          ..where((t) => t.pieceId.equals(pieceId) & t.deletedAt.isNull()))
        .get();
    if (existing.isEmpty) return 0;
    var maxIndex = existing.first.orderIndex;
    for (final row in existing) {
      if (row.orderIndex > maxIndex) maxIndex = row.orderIndex;
    }
    return maxIndex + 1;
  }

  @override
  Future<Section> update(Section section) async {
    final now = _clock.nowUtc();
    final updated = section.copyWith(updatedAt: now);

    await (_db.update(_db.sections)
          ..where((t) => t.id.equals(section.id) & t.deletedAt.isNull()))
        .write(
      db.SectionsCompanion(
        name: Value(updated.name),
        orderIndex: Value(updated.orderIndex),
        pageRef: Value(updated.pageRef),
        measureStart: Value(updated.measureStart),
        measureEnd: Value(updated.measureEnd),
        difficultyTags: Value(jsonEncode(updated.difficultyTags)),
        note: Value(updated.note),
        links: Value(jsonEncode(updated.links)),
        rhStatus: Value(updated.rhStatus.value),
        lhStatus: Value(updated.lhStatus.value),
        htStatus: Value(updated.htStatus.value),
        nextAction: Value(updated.nextAction),
        lastPracticedAt: Value(updated.lastPracticedAt?.toUtc()),
        updatedAt: Value(now),
      ),
    );

    return updated;
  }

  @override
  Future<Section> updateHandStatus(
    String sectionId, {
    HandStatus? rh,
    HandStatus? lh,
    HandStatus? ht,
  }) async {
    final existing = await getById(sectionId);
    if (existing == null) {
      throw StateError('Section $sectionId not found');
    }
    return update(
      existing.copyWith(
        rhStatus: rh ?? existing.rhStatus,
        lhStatus: lh ?? existing.lhStatus,
        htStatus: ht ?? existing.htStatus,
      ),
    );
  }

  @override
  Future<void> softDelete(String id) async {
    final now = _clock.nowUtc();
    await _db.transaction(() async {
      await (_db.update(_db.sections)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .write(
        db.SectionsCompanion(
          updatedAt: Value(now),
          deletedAt: Value(now),
        ),
      );
      await (_db.update(_db.planItems)
            ..where((t) => t.sectionId.equals(id) & t.deletedAt.isNull()))
          .write(
        db.PlanItemsCompanion(
          updatedAt: Value(now),
          deletedAt: Value(now),
        ),
      );
      await (_db.update(_db.entries)
            ..where((t) => t.sectionId.equals(id) & t.deletedAt.isNull()))
          .write(
        db.EntriesCompanion(
          updatedAt: Value(now),
          deletedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<Section?> getById(String id) async {
    final row = await (_db.select(_db.sections)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<List<Section>> getByPieceId(String pieceId) async {
    final rows = await (_db.select(_db.sections)
          ..where((t) => t.pieceId.equals(pieceId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
    return rows.map(_mapRow).toList();
  }

  @override
  Stream<List<Section>> watchByPieceId(String pieceId) {
    return (_db.select(_db.sections)
          ..where((t) => t.pieceId.equals(pieceId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Stream<Section?> watchById(String id) {
    return (_db.select(_db.sections)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _mapRow(row));
  }

  Section _mapRow(db.Section row) {
    return Section(
      id: row.id,
      userId: row.userId,
      pieceId: row.pieceId,
      name: row.name,
      orderIndex: row.orderIndex,
      pageRef: row.pageRef,
      measureStart: row.measureStart,
      measureEnd: row.measureEnd,
      difficultyTags: _decodeList(row.difficultyTags),
      note: row.note,
      links: _decodeList(row.links),
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

  List<String> _decodeList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } catch (_) {}
    return const [];
  }
}
