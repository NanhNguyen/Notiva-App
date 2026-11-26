import 'entry.dart';
import 'piece.dart';
import 'section.dart';

/// Derived Smart Resume read model (never stored).
class SmartResumeData {
  const SmartResumeData({
    required this.section,
    required this.piece,
    required this.latestEntry,
  });

  final Section section;
  final Piece piece;
  final Entry latestEntry;
}

