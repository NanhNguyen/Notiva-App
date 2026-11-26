import 'piece.dart';
import 'plan_item.dart';
import 'section.dart';

/// Read model pairing a [PlanItem] with its [Section] and [Piece].
class TodayPlanItemView {
  const TodayPlanItemView({
    required this.item,
    required this.section,
    required this.piece,
  });

  final PlanItem item;
  final Section section;
  final Piece piece;
}

