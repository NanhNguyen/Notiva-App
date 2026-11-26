import '../../domain/models/session.dart';
import '../database/app_database.dart' as db;
import '../helpers/clock.dart';
import '../helpers/id_generator.dart';

/// Repository interface for practice sessions and entries.
abstract interface class SessionRepository {
  Future<List<Session>> getRecent({int limit = 20});
}

/// Drift-backed skeleton implementation of [SessionRepository].
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
}
