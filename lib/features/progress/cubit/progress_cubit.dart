import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/piece_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../domain/models/piece_with_sections.dart';
import '../../../domain/models/progress_models.dart';
import 'progress_state.dart';

class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit({
    required SessionRepository sessionRepository,
    required PieceRepository pieceRepository,
  })  : _sessionRepository = sessionRepository,
        _pieceRepository = pieceRepository,
        super(const ProgressState()) {
    _snapshotSub = _sessionRepository.watchProgressSnapshot().listen((snapshot) {
      emit(state.copyWith(isLoading: false, snapshot: snapshot));
    });
    _piecesSub = _pieceRepository.watchAllWithSections().listen((pieces) {
      String? nextSelected = state.selectedSectionId;
      if (nextSelected == null) {
        for (final p in pieces) {
          if (p.sections.isNotEmpty) {
            nextSelected = p.sections.first.id;
            break;
          }
        }
      }
      emit(
        state.copyWith(
          piecesWithSections: pieces,
          selectedSectionId: nextSelected,
        ),
      );
      if (nextSelected != null && _tempoSub == null) {
        _subscribeTempo(nextSelected);
      }
    });
  }

  final SessionRepository _sessionRepository;
  final PieceRepository _pieceRepository;

  StreamSubscription<ProgressSnapshot>? _snapshotSub;
  StreamSubscription<List<PieceWithSections>>? _piecesSub;
  StreamSubscription<List<TempoDataPoint>>? _tempoSub;

  void setTabMode(ProgressTabMode mode) {
    emit(state.copyWith(tabMode: mode));
  }

  void selectTempoSection(String sectionId) {
    emit(state.copyWith(selectedSectionId: sectionId));
    _subscribeTempo(sectionId);
  }

  void _subscribeTempo(String sectionId) {
    _tempoSub?.cancel();
    _tempoSub = _sessionRepository.watchTempoSeries(sectionId).listen((points) {
      emit(state.copyWith(tempoPoints: points));
    });
  }

  @override
  Future<void> close() async {
    await _snapshotSub?.cancel();
    await _piecesSub?.cancel();
    await _tempoSub?.cancel();
    return super.close();
  }
}

