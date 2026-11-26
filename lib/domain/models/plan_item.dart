import '../enums/plan_item_priority.dart';
import '../enums/plan_item_state.dart';

/// Domain model for a planned section practice item on a local calendar date.
class PlanItem {
  const PlanItem({
    required this.id,
    this.userId,
    required this.sectionId,
    required this.date,
    this.goal,
    this.priority = PlanItemPriority.normal,
    this.state = PlanItemState.pending,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? userId;
  final String sectionId;
  final String date;
  final String? goal;
  final PlanItemPriority priority;
  final PlanItemState state;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

