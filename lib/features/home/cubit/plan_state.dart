import '../../../domain/enums/plan_item_state.dart';
import '../../../domain/models/piece_with_sections.dart';
import '../../../domain/models/smart_resume_data.dart';
import '../../../domain/models/today_plan_item_view.dart';

class PlanState {
  const PlanState({
    this.isLoading = true,
    this.piecesWithSections = const [],
    this.todayItems = const [],
    this.smartResume,
  });

  final bool isLoading;
  final List<PieceWithSections> piecesWithSections;
  final List<TodayPlanItemView> todayItems;
  final SmartResumeData? smartResume;

  bool get hasAnyPieces => piecesWithSections.isNotEmpty;

  int get completedTodayCount => todayItems
      .where((item) => item.item.state == PlanItemState.done)
      .length;

  int get totalTodayCount => todayItems.length;

  PlanState copyWith({
    bool? isLoading,
    List<PieceWithSections>? piecesWithSections,
    List<TodayPlanItemView>? todayItems,
    SmartResumeData? smartResume,
    bool clearSmartResume = false,
  }) {
    return PlanState(
      isLoading: isLoading ?? this.isLoading,
      piecesWithSections: piecesWithSections ?? this.piecesWithSections,
      todayItems: todayItems ?? this.todayItems,
      smartResume:
          clearSmartResume ? null : (smartResume ?? this.smartResume),
    );
  }
}

