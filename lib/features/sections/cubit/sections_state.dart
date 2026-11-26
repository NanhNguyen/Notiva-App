import '../../../domain/models/piece.dart';
import '../../../domain/models/piece_with_sections.dart';
import '../../../domain/models/section.dart';

class SectionsState {
  const SectionsState({
    this.isLoading = true,
    this.piece,
    this.sections = const [],
    this.sessionCount = 0,
  });

  final bool isLoading;
  final Piece? piece;
  final List<Section> sections;
  final int sessionCount;

  DateTime? get lastPracticedAt {
    if (piece == null) return null;
    return PieceWithSections(piece: piece!, sections: sections).lastPracticedAt;
  }

  String get sectionsSummaryCaption {
    if (piece == null) return '';
    return PieceWithSections(piece: piece!, sections: sections)
        .sectionsSummaryCaption;
  }

  SectionsState copyWith({
    bool? isLoading,
    Piece? piece,
    bool clearPiece = false,
    List<Section>? sections,
    int? sessionCount,
  }) {
    return SectionsState(
      isLoading: isLoading ?? this.isLoading,
      piece: clearPiece ? null : (piece ?? this.piece),
      sections: sections ?? this.sections,
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }
}

