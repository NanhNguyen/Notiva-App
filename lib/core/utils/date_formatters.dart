/// Formats a UTC [DateTime] into a calm Vietnamese relative practice label.
String formatLastPracticedLabel(DateTime? lastPracticedAt, {DateTime? now}) {
  if (lastPracticedAt == null) {
    return 'Chưa tập';
  }
  final current = (now ?? DateTime.now()).toLocal();
  final local = lastPracticedAt.toLocal();

  final today = DateTime(current.year, current.month, current.day);
  final target = DateTime(local.year, local.month, local.day);
  final diffDays = today.difference(target).inDays;

  if (diffDays <= 0) {
    return 'Tập gần nhất: hôm nay';
  }
  if (diffDays == 1) {
    return 'Tập gần nhất: hôm qua';
  }
  if (diffDays < 7) {
    return 'Tập gần nhất: $diffDays ngày trước';
  }
  if (diffDays < 14) {
    return 'Tập gần nhất: tuần trước';
  }
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return 'Tập gần nhất: $d/$m/${local.year}';
}

