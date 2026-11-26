import '../../../domain/enums/piece_status.dart';
import '../../../domain/models/piece_with_sections.dart';

class PiecesState {
  const PiecesState({
    this.isLoading = true,
    this.allPieces = const [],
    this.searchQuery = '',
    this.statusFilter,
  });

  final bool isLoading;
  final List<PieceWithSections> allPieces;
  final String searchQuery;
  final PieceStatus? statusFilter;

  bool get hasAnyPieces => allPieces.isNotEmpty;

  List<PieceWithSections> get filteredPieces {
    final q = searchQuery.trim().toLowerCase();
    return allPieces.where((item) {
      if (statusFilter != null && item.piece.status != statusFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      final titleMatch = item.piece.title.toLowerCase().contains(q);
      final composerMatch =
          item.piece.composer?.toLowerCase().contains(q) ?? false;
      return titleMatch || composerMatch;
    }).toList(growable: false);
  }

  PiecesState copyWith({
    bool? isLoading,
    List<PieceWithSections>? allPieces,
    String? searchQuery,
    PieceStatus? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return PiecesState(
      isLoading: isLoading ?? this.isLoading,
      allPieces: allPieces ?? this.allPieces,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

