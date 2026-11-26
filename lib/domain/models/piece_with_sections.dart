import '../enums/hand_status.dart';
import 'piece.dart';
import 'section.dart';

/// Read model pairing a [Piece] with its active [Section]s (derived, not stored).
class PieceWithSections {
  const PieceWithSections({
    required this.piece,
    required this.sections,
  });

  final Piece piece;
  final List<Section> sections;

  /// Latest practice timestamp across all sections of this piece, if any.
  DateTime? get lastPracticedAt {
    DateTime? latest;
    for (final s in sections) {
      final dt = s.lastPracticedAt;
      if (dt != null && (latest == null || dt.isAfter(latest))) {
        latest = dt;
      }
    }
    return latest;
  }

  /// HT statuses ordered by [Section.orderIndex] for [PieceKeysBar].
  List<HandStatus> get htStatuses =>
      sections.map((s) => s.htStatus).toList(growable: false);

  /// Caption beneath [PieceKeysBar]: "Chưa có đoạn" or "N đoạn: ...".
  String get sectionsSummaryCaption {
    if (sections.isEmpty) {
      return 'Chưa có đoạn';
    }
    final counts = [0, 0, 0, 0];
    for (final s in sections) {
      counts[s.htStatus.value]++;
    }
    final parts = <String>[
      if (counts[3] > 0) '${counts[3]} thuần thục',
      if (counts[2] > 0) '${counts[2]} khá ổn',
      if (counts[1] > 0) '${counts[1]} đang tập',
      if (counts[0] > 0) '${counts[0]} chưa tập',
    ];
    return '${sections.length} đoạn: ${parts.join(', ')}';
  }
}

