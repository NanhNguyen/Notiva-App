import '../../../domain/enums/practice_outcome.dart';
import '../../../domain/models/piece.dart';
import '../../../domain/models/section.dart';
import '../../../domain/models/session.dart';

class PracticeQueueItem {
  const PracticeQueueItem({
    required this.section,
    required this.piece,
    this.planItemId,
    this.loggedOutcome,
  });

  final Section section;
  final Piece piece;
  final String? planItemId;
  final PracticeOutcome? loggedOutcome;

  bool get isDone => loggedOutcome != null;

  PracticeQueueItem copyWith({
    Section? section,
    PracticeOutcome? loggedOutcome,
  }) {
    return PracticeQueueItem(
      section: section ?? this.section,
      piece: piece,
      planItemId: planItemId,
      loggedOutcome: loggedOutcome ?? this.loggedOutcome,
    );
  }
}

class SessionState {
  const SessionState({
    this.isStarting = false,
    this.session,
    this.queue = const [],
    this.currentIndex = 0,
    this.isPaused = false,
    this.pausedAt,
    this.accumulatedPause = Duration.zero,
  });

  final bool isStarting;
  final Session? session;
  final List<PracticeQueueItem> queue;
  final int currentIndex;
  final bool isPaused;
  final DateTime? pausedAt;
  final Duration accumulatedPause;

  bool get isActive => session != null;

  Duration elapsedAt(DateTime nowUtc) {
    final start = session?.startedAt;
    if (start == null) return Duration.zero;
    final activePause = (isPaused && pausedAt != null)
        ? nowUtc.difference(pausedAt!)
        : Duration.zero;
    final total = nowUtc.difference(start) - accumulatedPause - activePause;
    return total.isNegative ? Duration.zero : total;
  }

  SessionState copyWith({
    bool? isStarting,
    Session? session,
    bool clearSession = false,
    List<PracticeQueueItem>? queue,
    int? currentIndex,
    bool? isPaused,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    Duration? accumulatedPause,
  }) {
    return SessionState(
      isStarting: isStarting ?? this.isStarting,
      session: clearSession ? null : (session ?? this.session),
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPaused: isPaused ?? this.isPaused,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      accumulatedPause: accumulatedPause ?? this.accumulatedPause,
    );
  }
}

