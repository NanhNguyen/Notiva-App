import '../enums/plan_item_priority.dart';

/// Draft selection used by the Plan screen (A2) when saving today's plan.
class PlanSelectionDraft {
  const PlanSelectionDraft({
    required this.sectionId,
    this.goal,
    this.priority = PlanItemPriority.normal,
  });

  final String sectionId;
  final String? goal;
  final PlanItemPriority priority;
}

