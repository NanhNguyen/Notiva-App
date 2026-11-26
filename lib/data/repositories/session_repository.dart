import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/enums/hand_status.dart';
import '../../domain/enums/piece_status.dart';
import '../../domain/enums/plan_item_state.dart';
import '../../domain/enums/practice_outcome.dart';
import '../../domain/models/entry.dart';
import '../../domain/models/piece.dart';
import '../../domain/models/section.dart';
import '../../domain/models/session.dart';
import '../../domain/models/smart_resume_data.dart';
import '../database/app_database.dart' as db;
import '../helpers/clock.dart';
import '../helpers/id_generator.dart';

/// Smart defaults computed for logging a section (A4).
class LogEntryDefaults {
  const LogEntryDefaults({
    required this.hands,
    this.lastTempo,
    required this.outcome,
    required this.rh,
    required this.lh,
    required this.ht,
    this.nextAction,
  });

  final List<String> hands;
  final int? lastTempo;
  final PracticeOutcome outcome;
  final HandStatus rh;
  final HandStatus lh;
  final HandStatus ht;
  final String? nextAction;
}

/// Repository interface for practice sessions and entries.
abstract interface class SessionRepository {
  Future<List<Session>> getRecent({int limit = 20});

  Stream<List<Entry>> watchEntriesForSection(String sectionId);

  Stream<SmartResumeData?> watchSmartResume();

  Future<Session> startSession();

  Future<void> endSession({
    required String sessionId,
    required int durationMinutes,
    String? note,
  });

  Future<LogEntryDefaults> getDefaultsForSection(Section section);

  /// Saves an entry, updates the section, and marks any linked plan item done
  /// in a single database transaction.
  Future<Entry> saveEntry({
    required String sessionId,
    required Section section,
    String? planItemId,
    required List<String> hands,
    int? tempo,
    required PracticeOutcome outcome,
    String? note,
    String? nextAction,
    required HandStatus rhAfter,
    required HandStatus lhAfter,
    required HandStatus htAfter,
  });

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
    final rows = await (_db.select(_db.sessions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
    return rows.map(_mapSession).toList();
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
  Future<Session> startSession() async {
    final now = _clock.nowUtc();
    final today = _clock.todayLocalDate();
    final id = _idGenerator.nextId();

    await _db.into(_db.sessions).insert(
          db.SessionsCompanion.insert(
            id: id,
            startedAt: Value(now),
            date: today,
            createdAt: now,
            updatedAt: now,
          ),
        );

    return Session(
      id: id,
      startedAt: now,
      date: today,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> endSession({
    required String sessionId,
    required int durationMinutes,
    String? note,
  }) async {
    final now = _clock.nowUtc();
    final trimmed = note?.trim();
    final cleanedNote =
        (trimmed == null || trimmed.isEmpty) ? null : trimmed;

    await (_db.update(_db.sessions)
          ..where((t) => t.id.equals(sessionId) & t.deletedAt.isNull()))
        .write(
      db.SessionsCompanion(
        durationMinutes: Value(durationMinutes),
        note: Value(cleanedNote),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<LogEntryDefaults> getDefaultsForSection(Section section) async {
    final lastRow = await (_db.select(_db.entries)
          ..where(
            (t) => t.sectionId.equals(section.id) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();

    final lastEntry = lastRow == null ? null : _mapEntry(lastRow);
    final hands = (lastEntry != null && lastEntry.hands.isNotEmpty)
        ? lastEntry.hands
        : const ['ht'];

    return LogEntryDefaults(
      hands: hands,
      lastTempo: lastEntry?.tempo,
      outcome: PracticeOutcome.same,
      rh: section.rhStatus,
      lh: section.lhStatus,
      ht: section.htStatus,
      nextAction: section.nextAction,
    );
  }

  @override
  Future<Entry> saveEntry({
    required String sessionId,
    required Section section,
    String? planItemId,
    required List<String> hands,
    int? tempo,
    required PracticeOutcome outcome,
    String? note,
    String? nextAction,
    required HandStatus rhAfter,
    required HandStatus lhAfter,
    required HandStatus htAfter,
  }) async {
    final now = _clock.nowUtc();
    final id = _idGenerator.nextId();
    final cleanedNote = _trimOrNull(note);
    final cleanedNext = _trimOrNull(nextAction);

    await _db.transaction(() async {
      await _db.into(_db.entries).insert(
            db.EntriesCompanion.insert(
              id: id,
              sessionId: sessionId,
              sectionId: section.id,
              planItemId: Value(planItemId),
              hands: Value(jsonEncode(hands)),
              tempo: Value(tempo),
              outcome: outcome.name,
              note: Value(cleanedNote),
              nextAction: Value(cleanedNext),
              rhBefore: section.rhStatus.value,
              lhBefore: section.lhStatus.value,
              htBefore: section.htStatus.value,
              rhAfter: rhAfter.value,
              lhAfter: lhAfter.value,
              htAfter: htAfter.value,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await (_db.update(_db.sections)
            ..where((t) => t.id.equals(section.id) & t.deletedAt.isNull()))
          .write(
        db.SectionsCompanion(
          rhStatus: Value(rhAfter.value),
          lhStatus: Value(lhAfter.value),
          htStatus: Value(htAfter.value),
          nextAction: Value(cleanedNext),
          lastPracticedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      if (planItemId != null) {
        await (_db.update(_db.planItems)
              ..where((t) => t.id.equals(planItemId) & t.deletedAt.isNull()))
            .write(
          db.PlanItemsCompanion(
            state: Value(PlanItemState.done.name),
            updatedAt: Value(now),
          ),
        );
      }
    });

    return Entry(
      id: id,
      sessionId: sessionId,
      sectionId: section.id,
      planItemId: planItemId,
      hands: hands,
      tempo: tempo,
      outcome: outcome,
      note: cleanedNote,
      nextAction: cleanedNext,
      rhBefore: section.rhStatus,
      lhBefore: section.lhStatus,
      htBefore: section.htStatus,
      rhAfter: rhAfter,
      lhAfter: lhAfter,
      htAfter: htAfter,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> recordQuickEntry({
    required Section section,
    int? tempo,
    required PracticeOutcome outcome,
    String? note,
    String? nextAction,
  }) async {
    final session = await startSession();
    await saveEntry(
      sessionId: session.id,
      section: section,
      hands: const ['ht'],
      tempo: tempo,
      outcome: outcome,
      note: note,
      nextAction: nextAction ?? section.nextAction,
      rhAfter: section.rhStatus,
      lhAfter: section.lhStatus,
      htAfter: section.htStatus,
    );
    await endSession(sessionId: session.id, durationMinutes: 15);
  }

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Session _mapSession(db.Session row) {
    return Session(
      id: row.id,
      userId: row.userId,
      startedAt: row.startedAt?.toUtc(),
      date: row.date,
      durationMinutes: row.durationMinutes,
      note: row.note,
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
      deletedAt: row.deletedAt?.toUtc(),
    );
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
