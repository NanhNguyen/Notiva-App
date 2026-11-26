import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/piece_repository.dart';
import '../../../domain/enums/piece_status.dart';
import '../../../domain/models/piece.dart';
import '../../../domain/models/piece_with_sections.dart';
import 'pieces_state.dart';

class PiecesCubit extends Cubit<PiecesState> {
  PiecesCubit(this._pieceRepository) : super(const PiecesState()) {
    _subscription = _pieceRepository.watchAllWithSections().listen((pieces) {
      emit(state.copyWith(isLoading: false, allPieces: pieces));
    });
  }

  final PieceRepository _pieceRepository;
  StreamSubscription<List<PieceWithSections>>? _subscription;

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setStatusFilter(PieceStatus? status) {
    if (status == null) {
      emit(state.copyWith(clearStatusFilter: true));
    } else {
      emit(state.copyWith(statusFilter: status));
    }
  }

  Future<Piece> createPiece({
    required String title,
    String? composer,
    required PieceStatus status,
  }) {
    final trimmedComposer = composer?.trim();
    return _pieceRepository.create(
      title: title.trim(),
      composer:
          (trimmedComposer == null || trimmedComposer.isEmpty) ? null : trimmedComposer,
      status: status,
    );
  }

  Future<Piece> updatePiece(
    Piece original, {
    required String title,
    String? composer,
    required PieceStatus status,
  }) {
    final trimmedComposer = composer?.trim();
    final hasComposer = trimmedComposer != null && trimmedComposer.isNotEmpty;
    return _pieceRepository.update(
      original.copyWith(
        title: title.trim(),
        composer: hasComposer ? trimmedComposer : null,
        clearComposer: !hasComposer,
        status: status,
      ),
    );
  }

  Future<void> deletePiece(String id) {
    return _pieceRepository.softDelete(id);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

