import '../enums/hand_status.dart';
import '../enums/practice_outcome.dart';

/// Domain model for a single section practice entry inside a session.
class Entry {
  const Entry({
    required this.id,
    this.userId,
    required this.sessionId,
    required this.sectionId,
    this.planItemId,
    required this.hands,
    this.tempo,
    required this.outcome,
    this.note,
    this.nextAction,
    required this.rhBefore,
    required this.lhBefore,
    required this.htBefore,
    required this.rhAfter,
    required this.lhAfter,
    required this.htAfter,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? userId;
  final String sessionId;
  final String sectionId;
  final String? planItemId;
  final List<String> hands;
  final int? tempo;
  final PracticeOutcome outcome;
  final String? note;
  final String? nextAction;
  final HandStatus rhBefore;
  final HandStatus lhBefore;
  final HandStatus htBefore;
  final HandStatus rhAfter;
  final HandStatus lhAfter;
  final HandStatus htAfter;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

