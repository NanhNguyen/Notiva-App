import '../../domain/models/section.dart';

/// Formats measure range and page reference, e.g. "Ô nhịp 1 đến 8, tr.1".
String formatSectionLocation(Section section) {
  final parts = <String>[];
  if (section.measureStart != null && section.measureEnd != null) {
    parts.add('Ô nhịp ${section.measureStart} đến ${section.measureEnd}');
  } else if (section.measureStart != null) {
    parts.add('Từ ô nhịp ${section.measureStart}');
  } else if (section.measureEnd != null) {
    parts.add('Đến ô nhịp ${section.measureEnd}');
  }

  final page = section.pageRef?.trim();
  if (page != null && page.isNotEmpty) {
    parts.add('tr.$page');
  }

  return parts.join(', ');
}

