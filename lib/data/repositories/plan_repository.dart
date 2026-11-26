import 'package:drift/drift.dart';

import '../../domain/models/plan_item.dart';
import '../database/app_database.dart' as db;
import '../helpers/clock.dart';
import '../helpers/id_generator.dart';

/// Repository interface for daily practice plan items.
abstract interface class PlanRepository {
  Future<List<PlanItem>> getByDate(String date);
}

/// Drift-backed skeleton implementation of [PlanRepository].
class DriftPlanRepository implements PlanRepository {
  DriftPlanRepository({
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
  Future<List<PlanItem>> getByDate(String date) async {
    await (_db.select(_db.planItems)
          ..where((t) => t.date.equals(date) & t.deletedAt.isNull()))
        .get();
    return const [];
  }
}
