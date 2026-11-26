import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/enums/hand_status.dart';
import '../../domain/enums/piece_status.dart';
import '../../domain/enums/practice_outcome.dart';
import '../../domain/models/entry.dart';
import '../../domain/models/piece.dart';
import '../../domain/models/section.dart';
import '../../domain/models/session.dart';
import '../../domain/models/smart_resume_data.dart';
import '../database/app_database.dart' as db;
import '../helpers/clock.dart';
import '../helpers/id_generator.dart';

/// Repository interface for practice sessions and entries.
abstract interface class SessionRepository {
  Future<List<Session>> getRecent({int limit = 20});

  Stream<List<Entry>> watchEntriesForSection(String sectionId);

  Stream<SmartResumeData?> watchSmartResume();

  /// Creates a session + entry and updates the section in one transaction.
  Future<void> recordQuickEntry({
    required Section section,
    int? tempo,
    required PracticeOutcome outcome,
    String? note,
    String? nextAction,
  });
}

/// Drift-backed implementation of [SessionRepository].
class DriftSessionRepository implements SessionRepository {
  DriftSessionRepository({
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
  Future<List<Session>> getRecent({int limit = 20}) async {
    await (_db.select(_db.sessions)
          ..where((t) => t.deletedAt.isNull())
          ..limit(limit))
        .get();
    return const [];
  }

  @override
  Stream<List<Entry>> watchEntriesForSection(String sectionId) {
    return (_db.select(_db.entries)
          ..where((t) => t.sectionId.equals(sectionId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_mapEntry).toList());
  }

  @override
  Stream<SmartResumeData?> watchSmartResume() {
    // Watch active entries joined with active sections & pieces,
    // then select the section with the latest lastPracticedAt and its latest entry.
    final query = _db.select(_db.entries).join([
      innerJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.entries.sectionId) &
            _db.sections.deletedAt.isNull(),
      ),
      innerJoin(
        _db.pieces,
        _db.pieces.id.equalsExp(_db.sections.pieceId) &
            _db.pieces.deletedAt.isNull(),
      ),
    ])
      ..where(_db.entries.deletedAt.isNull())
      ..orderBy([
        OrderingTerm.desc(_db.sections.lastPracticedAt),
        OrderingTerm.desc(_db.entries.createdAt),
      ]);

    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      // Pick rows whose section has a non-null lastPracticedAt if available.
      final withPracticedAt = rows.where(
        (r) => r.readTable(_db.sections).lastPracticedAt != null,
      );
      final chosen =
          withPracticedAt.isNotEmpty ? withPracticedAt.first : rows.first;
      return SmartResumeData(
        section: _mapSection(chosen.readTable(_db.sections)),
        piece: _mapPiece(chosen.readTable(_db.pieces)),
        latestEntry: _mapEntry(chosen.readTable(_db.entries)),
      );
    });
  }

  @override
  Future<void> recordQuickEntry({
    required Section section,
    int? tempo,
    required PracticeOutcome outcome,
    String? note,
    String? nextAction,
  }) async {
    final now = _clock.nowUtc();
    final today = _clock.todayLocalDate();
    final sessionId = _idGenerator.nextId();
    final entryId = _idGenerator.nextId();

    await _db.transaction(() async {
      await _db.into(_db.sessions).insert(
            db.SessionsCompanion.insert(
              id: sessionId,
              startedAt: Value(now),
              date: today,
              durationMinutes: const Value(15),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await _db.into(_db.entries).insert(
            db.EntriesCompanion.insert(
              id: entryId,
              sessionId: sessionId,
              sectionId: section.id,
              hands: Value(jsonEncode(['ht'])),
              tempo: Value(tempo),
              outcome: outcome.name,
              note: Value(note),
              nextAction: Value(nextAction),
              rhBefore: section.rhStatus.value,
              lhBefore: section.lhStatus.value,
              htBefore: section.htStatus.value,
              rhAfter: section.rhStatus.value,
              lhAfter: section.lhStatus.value,
              htAfter: section.htStatus.value,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await (_db.update(_db.sections)
            ..where((t) => t.id.equals(section.id) & t.deletedAt.isNull()))
          .write(
        db.SectionsCompanion(
          nextAction: Value(nextAction ?? section.nextAction),
          lastPracticedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  Entry _mapEntry(db.Entry row) {
    return Entry(
      id: row.id,
      userId: row.userId,
      sessionId: row.sessionId,
      sectionId: row.sectionId,
      planItemId: row.planItemId,
      hands: _decodeList(row.hands),
      tempo: row.tempo,
      outcome: PracticeOutcome.values.firstWhere(
        (e) => e.name == row.outcome,
        orElse: () => PracticeOutcome.same,
      ),
      note: row.note,
      nextAction: row.nextAction,
      rhBefore: HandStatus.fromValue(row.rhBefore),
      lhBefore: HandStatus.fromValue(row.lhBefore),
      htBefore: HandStatus.fromValue(row.htBefore),
      rhAfter: HandStatus.fromValue(row.rhAfter),
      lhAfter: HandStatus.fromValue(row.lhAfter),
      htAfter: HandStatus.fromValue(row.htAfter),
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
      deletedAt: row.deletedAt?.toUtc(),
    );
  }

  Section _mapSection(db.Section row) {
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

  Piece _mapPiece(db.Piece row) {
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
