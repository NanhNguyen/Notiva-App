/// Outcome of practicing a section during a session.
enum PracticeOutcome {
  improved('Tiến bộ'),
  same('Giữ nguyên'),
  difficult('Vẫn khó');

  const PracticeOutcome(this.label);

  final String label;
}

