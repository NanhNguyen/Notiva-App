/// Priority of a daily plan item.
enum PlanItemPriority {
  normal('Bình thường'),
  high('Ưu tiên cao');

  const PlanItemPriority(this.label);

  final String label;
}

