import '../enums/hand_status.dart';

/// Domain model for a practice section within a piece.
class Section {
  const Section({
    required this.id,
    this.userId,
    required this.pieceId,
    required this.name,
    required this.orderIndex,
    this.pageRef,
    this.measureStart,
    this.measureEnd,
    this.difficultyTags = const [],
    this.note,
    this.links = const [],
    this.rhStatus = HandStatus.notStarted,
    this.lhStatus = HandStatus.notStarted,
    this.htStatus = HandStatus.notStarted,
    this.nextAction,
    this.lastPracticedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? userId;
  final String pieceId;
  final String name;
  final int orderIndex;
  final String? pageRef;
  final int? measureStart;
  final int? measureEnd;
  final List<String> difficultyTags;
  final String? note;
  final List<String> links;
  final HandStatus rhStatus;
  final HandStatus lhStatus;
  final HandStatus htStatus;
  final String? nextAction;
  final DateTime? lastPracticedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

