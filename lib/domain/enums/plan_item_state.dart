/// Completion state of a daily plan item.
enum PlanItemState {
  pending('Chưa tập'),
  done('Đã tập'),
  postponed('Dời sang hôm sau');

  const PlanItemState(this.label);

  final String label;
}

