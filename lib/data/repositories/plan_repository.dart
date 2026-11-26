import 'package:drift/drift.dart';

import '../../domain/enums/hand_status.dart';
import '../../domain/enums/piece_status.dart';
import '../../domain/enums/plan_item_priority.dart';
import '../../domain/enums/plan_item_state.dart';
import '../../domain/models/piece.dart';
import '../../domain/models/plan_item.dart';
import '../../domain/models/plan_selection_draft.dart';
import '../../domain/models/section.dart';
import '../../domain/models/today_plan_item_view.dart';
import '../database/app_database.dart' as db;
import '../helpers/clock.dart';
import '../helpers/id_generator.dart';

/// Repository interface for daily practice plan items.
abstract interface class PlanRepository {
  Future<List<PlanItem>> getByDate(String date);

  Stream<List<TodayPlanItemView>> watchTodayPlan();

  Future<List<PlanItem>> getIncompleteFromYesterday();

  Future<void> toggleItemDone(PlanItem item);

  Future<void> saveTodayPlan(List<PlanSelectionDraft> selections);

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
    return rows.map(_mapPlanItem).toList();
  }

  @override
  Stream<List<TodayPlanItemView>> watchTodayPlan() {
    final today = _clock.todayLocalDate();
    final query = _db.select(_db.planItems).join([
      innerJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.planItems.sectionId) &
            _db.sections.deletedAt.isNull(),
      ),
      innerJoin(
        _db.pieces,
        _db.pieces.id.equalsExp(_db.sections.pieceId) &
            _db.pieces.deletedAt.isNull(),
      ),
    ])
      ..where(
        _db.planItems.date.equals(today) & _db.planItems.deletedAt.isNull(),
      )
      ..orderBy([
        OrderingTerm.asc(_db.planItems.createdAt),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final itemRow = row.readTable(_db.planItems);
        final sectionRow = row.readTable(_db.sections);
        final pieceRow = row.readTable(_db.pieces);
        return TodayPlanItemView(
          item: _mapPlanItem(itemRow),
          section: _mapSection(sectionRow),
          piece: _mapPiece(pieceRow),
        );
      }).toList();
    });
  }

  @override
  Future<List<PlanItem>> getIncompleteFromYesterday() async {
    final yesterday = _clock.yesterdayLocalDate();
    final rows = await (_db.select(_db.planItems)
          ..where(
            (t) =>
                t.date.equals(yesterday) &
                t.state.isNotValue(PlanItemState.done.name) &
                t.deletedAt.isNull(),
          ))
        .get();
    return rows.map(_mapPlanItem).toList();
  }

  @override
  Future<void> toggleItemDone(PlanItem item) async {
    final now = _clock.nowUtc();
    final nextState = item.state == PlanItemState.done
        ? PlanItemState.pending
        : PlanItemState.done;

    await (_db.update(_db.planItems)
          ..where((t) => t.id.equals(item.id) & t.deletedAt.isNull()))
        .write(
      db.PlanItemsCompanion(
        state: Value(nextState.name),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> saveTodayPlan(List<PlanSelectionDraft> selections) async {
    final today = _clock.todayLocalDate();
    final now = _clock.nowUtc();

    await _db.transaction(() async {
      final existingRows = await (_db.select(_db.planItems)
            ..where((t) => t.date.equals(today) & t.deletedAt.isNull()))
          .get();

      final existingBySection = {
        for (final row in existingRows) row.sectionId: row,
      };
      final desiredSectionIds = selections.map((s) => s.sectionId).toSet();

      // Soft-delete unselected items for today.
      for (final row in existingRows) {
        if (!desiredSectionIds.contains(row.sectionId)) {
          await (_db.update(_db.planItems)
                ..where((t) => t.id.equals(row.id)))
              .write(
            db.PlanItemsCompanion(
              updatedAt: Value(now),
              deletedAt: Value(now),
            ),
          );
        }
      }

      // Insert new or update existing items.
      for (final draft in selections) {
        final cleanedGoal = _trimOrNull(draft.goal);
        final existing = existingBySection[draft.sectionId];
        if (existing != null) {
          await (_db.update(_db.planItems)
                ..where((t) => t.id.equals(existing.id)))
              .write(
            db.PlanItemsCompanion(
              goal: Value(cleanedGoal),
              priority: Value(draft.priority.name),
              updatedAt: Value(now),
            ),
          );
        } else {
          await _db.into(_db.planItems).insert(
                db.PlanItemsCompanion.insert(
                  id: _idGenerator.nextId(),
                  sectionId: draft.sectionId,
                  date: today,
                  goal: Value(cleanedGoal),
                  priority: draft.priority.name,
                  state: PlanItemState.pending.name,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }
      }
    });
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

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  PlanItem _mapPlanItem(db.PlanItem row) {
    return PlanItem(
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
}
