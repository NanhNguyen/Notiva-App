import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/enums/hand_status.dart';
import '../../domain/enums/practice_outcome.dart';
import '../../domain/models/entry.dart';
import '../../domain/models/session.dart';
import '../database/app_database.dart' as db;
import '../helpers/clock.dart';
import '../helpers/id_generator.dart';

/// Repository interface for practice sessions and entries.
abstract interface class SessionRepository {
  Future<List<Session>> getRecent({int limit = 20});

  Stream<List<Entry>> watchEntriesForSection(String sectionId);
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
  // Kept for upcoming slices.
  // ignore: unused_field
  final IdGenerator _idGenerator;
  // ignore: unused_field
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

  Entry _mapEntry(db.Entry row) {
    return Entry(
      id: row.id,
      userId: row.userId,
      sessionId: row.sessionId,
      sectionId: row.sectionId,
      planItemId: row.planItemId,
      hands: _decodeHands(row.hands),
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

  List<String> _decodeHands(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } catch (_) {}
    return const [];
  }
}
