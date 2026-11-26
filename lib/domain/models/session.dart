/// Domain model for a practice session on a local calendar date.
class Session {
  const Session({
    required this.id,
    this.userId,
    this.startedAt,
    required this.date,
    this.durationMinutes,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? userId;
  final DateTime? startedAt;
  final String date;
  final int? durationMinutes;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

