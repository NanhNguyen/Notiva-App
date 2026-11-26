/// Self-assessed practice status (0..3) for RH, LH, and HT.
enum HandStatus {
  notStarted(0, 'Chưa tập'),
  learning(1, 'Đang tập'),
  solid(2, 'Khá ổn'),
  mastered(3, 'Thuần thục');

  const HandStatus(this.value, this.label);

  final int value;
  final String label;

  static HandStatus fromValue(int value) {
    return HandStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HandStatus.notStarted,
    );
  }
}

