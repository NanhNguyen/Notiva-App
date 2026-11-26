import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/piece_repository.dart';
import '../../../data/repositories/plan_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../domain/models/piece_with_sections.dart';
import '../../../domain/models/plan_selection_draft.dart';
import '../../../domain/models/smart_resume_data.dart';
import '../../../domain/models/today_plan_item_view.dart';
import 'plan_state.dart';

class PlanCubit extends Cubit<PlanState> {
  PlanCubit({
    required PieceRepository pieceRepository,
    required PlanRepository planRepository,
    required SessionRepository sessionRepository,
  })  : _pieceRepository = pieceRepository,
        _planRepository = planRepository,
        _sessionRepository = sessionRepository,
        super(const PlanState()) {
    _piecesSub = _pieceRepository.watchAllWithSections().listen((pieces) {
      emit(state.copyWith(isLoading: false, piecesWithSections: pieces));
    });
    _todaySub = _planRepository.watchTodayPlan().listen((items) {
      emit(state.copyWith(todayItems: items));
    });
    _resumeSub = _sessionRepository.watchSmartResume().listen((resume) {
      emit(
        state.copyWith(
          smartResume: resume,
          clearSmartResume: resume == null,
        ),
      );
    });
  }

  final PieceRepository _pieceRepository;
  final PlanRepository _planRepository;
  final SessionRepository _sessionRepository;

  StreamSubscription<List<PieceWithSections>>? _piecesSub;
  StreamSubscription<List<TodayPlanItemView>>? _todaySub;
  StreamSubscription<SmartResumeData?>? _resumeSub;

  Future<void> togglePlanItem(TodayPlanItemView item) {
    return _planRepository.toggleItemDone(item.item);
  }

  Future<Set<String>> loadCarryOverSectionIds() async {
    final incomplete = await _planRepository.getIncompleteFromYesterday();
    return incomplete.map((item) => item.sectionId).toSet();
  }

  Future<void> savePlan(List<PlanSelectionDraft> selections) {
    return _planRepository.saveTodayPlan(selections);
  }

  @override
  Future<void> close() async {
    await _piecesSub?.cancel();
    await _todaySub?.cancel();
    await _resumeSub?.cancel();
    return super.close();
  }
}

