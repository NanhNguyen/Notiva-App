import 'package:drift/drift.dart';

import '../../domain/enums/plan_item_priority.dart';
import '../../domain/enums/plan_item_state.dart';
import '../../domain/models/plan_item.dart';
import '../database/app_database.dart' as db;
import '../helpers/clock.dart';
import '../helpers/id_generator.dart';

/// Repository interface for daily practice plan items.
abstract interface class PlanRepository {
  Future<List<PlanItem>> getByDate(String date);

  /// Adds [sectionId] to today's plan with [goal], avoiding duplicates.
  /// Returns true if a new item was created, false if it already existed.
  Future<bool> addSectionToToday({
    required String sectionId,
    String? goal,
    String? userId,
  });
}

/// Drift-backed implementation of [PlanRepository].
class DriftPlanRepository implements PlanRepository {
  DriftPlanRepository({
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
  Future<List<PlanItem>> getByDate(String date) async {
    final rows = await (_db.select(_db.planItems)
          ..where((t) => t.date.equals(date) & t.deletedAt.isNull()))
        .get();
    return rows
        .map(
          (row) => PlanItem(
            id: row.id,
            userId: row.userId,
            sectionId: row.sectionId,
            date: row.date,
            goal: row.goal,
            priority: PlanItemPriority.values.firstWhere(
              (e) => e.name == row.priority,
              orElse: () => PlanItemPriority.normal,
            ),
            state: PlanItemState.values.firstWhere(
              (e) => e.name == row.state,
              orElse: () => PlanItemState.pending,
            ),
            createdAt: row.createdAt.toUtc(),
            updatedAt: row.updatedAt.toUtc(),
            deletedAt: row.deletedAt?.toUtc(),
          ),
        )
        .toList();
  }

  @override
  Future<bool> addSectionToToday({
    required String sectionId,
    String? goal,
    String? userId,
  }) async {
    final today = _clock.todayLocalDate();
    final existing = await (_db.select(_db.planItems)
          ..where(
            (t) =>
                t.sectionId.equals(sectionId) &
                t.date.equals(today) &
                t.deletedAt.isNull(),
          ))
        .getSingleOrNull();

    if (existing != null) {
      return false;
    }

    final now = _clock.nowUtc();
    await _db.into(_db.planItems).insert(
          db.PlanItemsCompanion.insert(
            id: _idGenerator.nextId(),
            userId: Value(userId),
            sectionId: sectionId,
            date: today,
            goal: Value(goal),
            priority: PlanItemPriority.normal.name,
            state: PlanItemState.pending.name,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return true;
  }
}
