import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/piece_repository.dart';
import '../../../data/repositories/plan_repository.dart';
import '../../../data/repositories/section_repository.dart';
import '../../../domain/enums/hand_status.dart';
import '../../../domain/enums/piece_status.dart';
import '../../../domain/models/piece.dart';
import '../../../domain/models/section.dart';
import '../../../ui/widgets/hand_status_stepper.dart';
import 'sections_state.dart';

class SectionsCubit extends Cubit<SectionsState> {
  SectionsCubit({
    required PieceRepository pieceRepository,
    required SectionRepository sectionRepository,
    required PlanRepository planRepository,
  })  : _pieceRepository = pieceRepository,
        _sectionRepository = sectionRepository,
        _planRepository = planRepository,
        super(const SectionsState());

  final PieceRepository _pieceRepository;
  final SectionRepository _sectionRepository;
  final PlanRepository _planRepository;

  StreamSubscription<Piece?>? _pieceSub;
  StreamSubscription<List<Section>>? _sectionsSub;
  StreamSubscription<int>? _sessionCountSub;

  void watchPiece(String pieceId) {
    _pieceSub?.cancel();
    _sectionsSub?.cancel();
    _sessionCountSub?.cancel();

    emit(const SectionsState(isLoading: true));

    _pieceSub = _pieceRepository.watchById(pieceId).listen((piece) {
      emit(state.copyWith(isLoading: false, piece: piece, clearPiece: piece == null));
    });
    _sectionsSub = _sectionRepository.watchByPieceId(pieceId).listen((sections) {
      emit(state.copyWith(sections: sections));
    });
    _sessionCountSub =
        _pieceRepository.watchSessionCountForPiece(pieceId).listen((count) {
      emit(state.copyWith(sessionCount: count));
    });
  }

  Future<void> updatePieceStatus(PieceStatus status) async {
    final piece = state.piece;
    if (piece == null || piece.status == status) return;
    await _pieceRepository.update(piece.copyWith(status: status));
  }

  Future<Section> createSection({
    required String pieceId,
    required String name,
    String? pageRef,
    int? measureStart,
    int? measureEnd,
    List<String> difficultyTags = const [],
    String? note,
    List<String> links = const [],
    String? nextAction,
  }) {
    return _sectionRepository.create(
      pieceId: pieceId,
      name: name.trim(),
      pageRef: _trimOrNull(pageRef),
      measureStart: measureStart,
      measureEnd: measureEnd,
      difficultyTags: difficultyTags,
      note: _trimOrNull(note),
      links: links,
      nextAction: _trimOrNull(nextAction),
    );
  }

  Future<Section> updateSection(
    Section original, {
    required String name,
    String? pageRef,
    int? measureStart,
    int? measureEnd,
    required List<String> difficultyTags,
    String? note,
    required List<String> links,
    String? nextAction,
  }) {
    final cleanedPage = _trimOrNull(pageRef);
    final cleanedNote = _trimOrNull(note);
    final cleanedNext = _trimOrNull(nextAction);

    return _sectionRepository.update(
      original.copyWith(
        name: name.trim(),
        pageRef: cleanedPage,
        clearPageRef: cleanedPage == null,
        measureStart: measureStart,
        clearMeasureStart: measureStart == null,
        measureEnd: measureEnd,
        clearMeasureEnd: measureEnd == null,
        difficultyTags: difficultyTags,
        note: cleanedNote,
        clearNote: cleanedNote == null,
        links: links,
        nextAction: cleanedNext,
        clearNextAction: cleanedNext == null,
      ),
    );
  }

  Future<Section> updateHandStatus(
    Section section,
    PracticeHand hand,
    HandStatus level,
  ) {
    return _sectionRepository.updateHandStatus(
      section.id,
      rh: hand == PracticeHand.rh ? level : null,
      lh: hand == PracticeHand.lh ? level : null,
      ht: hand == PracticeHand.ht ? level : null,
    );
  }

  Future<Section> updateNextAction(Section section, String? nextAction) {
    final cleaned = _trimOrNull(nextAction);
    return _sectionRepository.update(
      section.copyWith(
        nextAction: cleaned,
        clearNextAction: cleaned == null,
      ),
    );
  }

  Future<bool> addToToday(Section section) {
    return _planRepository.addSectionToToday(
      sectionId: section.id,
      goal: section.nextAction,
    );
  }

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  @override
  Future<void> close() async {
    await _pieceSub?.cancel();
    await _sectionsSub?.cancel();
    await _sessionCountSub?.cancel();
    return super.close();
  }
}

