import '../../../domain/models/piece_with_sections.dart';
import '../../../domain/models/progress_models.dart';

enum ProgressTabMode { sessions, tempo }

class ProgressState {
  const ProgressState({
    this.isLoading = true,
    this.tabMode = ProgressTabMode.sessions,
    this.snapshot = const ProgressSnapshot(
      thisWeek: WeeklySummary(sessionCount: 0, totalMinutes: 0),
      recentStatusChanges: [],
      sessionHistory: [],
    ),
    this.piecesWithSections = const [],
    this.selectedSectionId,
    this.tempoPoints = const [],
  });

  final bool isLoading;
  final ProgressTabMode tabMode;
  final ProgressSnapshot snapshot;
  final List<PieceWithSections> piecesWithSections;
  final String? selectedSectionId;
  final List<TempoDataPoint> tempoPoints;

  ProgressState copyWith({
    bool? isLoading,
    ProgressTabMode? tabMode,
    ProgressSnapshot? snapshot,
    List<PieceWithSections>? piecesWithSections,
    String? selectedSectionId,
    List<TempoDataPoint>? tempoPoints,
  }) {
    return ProgressState(
      isLoading: isLoading ?? this.isLoading,
      tabMode: tabMode ?? this.tabMode,
      snapshot: snapshot ?? this.snapshot,
      piecesWithSections: piecesWithSections ?? this.piecesWithSections,
      selectedSectionId: selectedSectionId ?? this.selectedSectionId,
      tempoPoints: tempoPoints ?? this.tempoPoints,
    );
  }
}

