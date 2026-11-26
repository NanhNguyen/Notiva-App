import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../data/helpers/clock.dart';
import '../../../data/repositories/piece_repository.dart';
import '../../../data/repositories/plan_repository.dart';
import '../../../data/repositories/section_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../domain/enums/hand_status.dart';
import '../../../domain/enums/plan_item_state.dart';
import '../../../domain/enums/practice_outcome.dart';
import '../../../domain/models/piece.dart';
import '../../../domain/models/section.dart';
import 'session_state.dart';

class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required SessionRepository sessionRepository,
    required PlanRepository planRepository,
    required SectionRepository sectionRepository,
    required PieceRepository pieceRepository,
    required AppClock clock,
  })  : _sessionRepository = sessionRepository,
        _planRepository = planRepository,
        _sectionRepository = sectionRepository,
        _pieceRepository = pieceRepository,
        _clock = clock,
        super(const SessionState());

  final SessionRepository _sessionRepository;
  final PlanRepository _planRepository;
  final SectionRepository _sectionRepository;
  final PieceRepository _pieceRepository;
  final AppClock _clock;

  Future<void> startSession({String? initialSectionId}) async {
    emit(const SessionState(isStarting: true));

    final session = await _sessionRepository.startSession();
    final todayItems = await _planRepository.watchTodayPlan().first;

    final queue = <PracticeQueueItem>[
      for (final item in todayItems)
        PracticeQueueItem(
          section: item.section,
          piece: item.piece,
          planItemId: item.item.id,
          loggedOutcome:
              item.item.state == PlanItemState.done ? PracticeOutcome.same : null,
        ),
    ];

    var startIndex = queue.indexWhere((q) => !q.isDone);
    if (startIndex < 0) startIndex = 0;

    if (initialSectionId != null) {
      final existingIdx =
          queue.indexWhere((q) => q.section.id == initialSectionId);
      if (existingIdx >= 0) {
        startIndex = existingIdx;
      } else {
        final section = await _sectionRepository.getById(initialSectionId);
        if (section != null) {
          final piece = await _pieceRepository.getById(section.pieceId);
          if (piece != null) {
            queue.insert(0, PracticeQueueItem(section: section, piece: piece));
            startIndex = 0;
          }
        }
      }
    }

    await _setWakelock(true);

    emit(
      SessionState(
        isStarting: false,
        session: session,
        queue: queue,
        currentIndex: startIndex,
      ),
    );
  }

  Future<void> togglePause() async {
    if (!state.isActive) return;
    final now = _clock.nowUtc();
    if (state.isPaused) {
      final extraPause = state.pausedAt != null
          ? now.difference(state.pausedAt!)
          : Duration.zero;
      await _setWakelock(true);
      emit(
        state.copyWith(
          isPaused: false,
          clearPausedAt: true,
          accumulatedPause: state.accumulatedPause + extraPause,
        ),
      );
    } else {
      await _setWakelock(false);
      emit(state.copyWith(isPaused: true, pausedAt: now));
    }
  }

  void selectIndex(int index) {
    if (index < 0 || index >= state.queue.length) return;
    emit(state.copyWith(currentIndex: index));
  }

  void addExtraSection(Section section, Piece piece) {
    final existingIdx =
        state.queue.indexWhere((q) => q.section.id == section.id);
    if (existingIdx >= 0) {
      emit(state.copyWith(currentIndex: existingIdx));
      return;
    }

    final updated = List<PracticeQueueItem>.from(state.queue)
      ..add(PracticeQueueItem(section: section, piece: piece));
    emit(
      state.copyWith(
        queue: updated,
        currentIndex: updated.length - 1,
      ),
    );
  }

  Future<LogEntryDefaults> loadDefaults(Section section) {
    return _sessionRepository.getDefaultsForSection(section);
  }

  Future<void> logEntry({
    required PracticeQueueItem item,
    required List<String> hands,
    int? tempo,
    required PracticeOutcome outcome,
    String? note,
    String? nextAction,
    required HandStatus rhAfter,
    required HandStatus lhAfter,
    required HandStatus htAfter,
  }) async {
    final session = state.session;
    if (session == null) return;

    await _sessionRepository.saveEntry(
      sessionId: session.id,
      section: item.section,
      planItemId: item.planItemId,
      hands: hands,
      tempo: tempo,
      outcome: outcome,
      note: note,
      nextAction: nextAction,
      rhAfter: rhAfter,
      lhAfter: lhAfter,
      htAfter: htAfter,
    );

    final updatedSection = item.section.copyWith(
      rhStatus: rhAfter,
      lhStatus: lhAfter,
      htStatus: htAfter,
      nextAction: (nextAction == null || nextAction.trim().isEmpty)
          ? null
          : nextAction.trim(),
      clearNextAction: nextAction == null || nextAction.trim().isEmpty,
      lastPracticedAt: _clock.nowUtc(),
    );

    final updatedQueue = [
      for (final q in state.queue)
        if (q.section.id == item.section.id)
          q.copyWith(section: updatedSection, loggedOutcome: outcome)
        else
          q,
    ];

    var nextIndex = updatedQueue.indexWhere((q) => !q.isDone);
    if (nextIndex < 0) nextIndex = state.currentIndex;

    emit(state.copyWith(queue: updatedQueue, currentIndex: nextIndex));
  }

  Future<void> endSession({
    required int durationMinutes,
    String? note,
  }) async {
    final session = state.session;
    if (session != null) {
      await _sessionRepository.endSession(
        sessionId: session.id,
        durationMinutes: durationMinutes,
        note: note,
      );
    }
    await _setWakelock(false);
    emit(const SessionState());
  }

  Future<void> _setWakelock(bool enable) async {
    try {
      await WakelockPlus.toggle(enable: enable);
    } catch (_) {
      // Ignore platform channel errors in headless unit/widget tests.
    }
  }

  @override
  Future<void> close() async {
    await _setWakelock(false);
    return super.close();
  }
}

