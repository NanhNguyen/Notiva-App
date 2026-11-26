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
    required int orderIndex,
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

  Future<List<Section>> getByPieceId(String pieceId);
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
    required int orderIndex,
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
    await _db.into(_db.sections).insert(
          db.SectionsCompanion.insert(
            id: id,
            userId: Value(userId),
            pieceId: pieceId,
            name: name,
            orderIndex: orderIndex,
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
      orderIndex: orderIndex,
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

  @override
  Future<List<Section>> getByPieceId(String pieceId) async {
    final rows = await (_db.select(_db.sections)
          ..where((t) => t.pieceId.equals(pieceId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();

    return rows
        .map(
          (row) => Section(
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
          ),
        )
        .toList();
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
