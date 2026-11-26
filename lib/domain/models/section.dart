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

  Section copyWith({
    String? id,
    String? userId,
    String? pieceId,
    String? name,
    int? orderIndex,
    String? pageRef,
    bool clearPageRef = false,
    int? measureStart,
    bool clearMeasureStart = false,
    int? measureEnd,
    bool clearMeasureEnd = false,
    List<String>? difficultyTags,
    String? note,
    bool clearNote = false,
    List<String>? links,
    HandStatus? rhStatus,
    HandStatus? lhStatus,
    HandStatus? htStatus,
    String? nextAction,
    bool clearNextAction = false,
    DateTime? lastPracticedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Section(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pieceId: pieceId ?? this.pieceId,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
      pageRef: clearPageRef ? null : (pageRef ?? this.pageRef),
      measureStart:
          clearMeasureStart ? null : (measureStart ?? this.measureStart),
      measureEnd: clearMeasureEnd ? null : (measureEnd ?? this.measureEnd),
      difficultyTags: difficultyTags ?? this.difficultyTags,
      note: clearNote ? null : (note ?? this.note),
      links: links ?? this.links,
      rhStatus: rhStatus ?? this.rhStatus,
      lhStatus: lhStatus ?? this.lhStatus,
      htStatus: htStatus ?? this.htStatus,
      nextAction: clearNextAction ? null : (nextAction ?? this.nextAction),
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

