import 'entry.dart';
import 'piece.dart';
import 'section.dart';
import 'session.dart';

class SessionEntryView {
  const SessionEntryView({
    required this.entry,
    required this.section,
    required this.piece,
  });

  final Entry entry;
  final Section section;
  final Piece piece;
}

class SessionHistoryGroup {
  const SessionHistoryGroup({
    required this.session,
    required this.entries,
  });

  final Session session;
  final List<SessionEntryView> entries;
}

class StatusChangeItem {
  const StatusChangeItem({
    required this.entry,
    required this.section,
    required this.piece,
  });

  final Entry entry;
  final Section section;
  final Piece piece;
}

class TempoDataPoint {
  const TempoDataPoint({
    required this.date,
    required this.tempo,
  });

  final DateTime date;
  final int tempo;
}

class WeeklySummary {
  const WeeklySummary({
    required this.sessionCount,
    required this.totalMinutes,
  });

  final int sessionCount;
  final int totalMinutes;
}

class ProgressSnapshot {
  const ProgressSnapshot({
    required this.thisWeek,
    required this.recentStatusChanges,
    required this.sessionHistory,
  });

  final WeeklySummary thisWeek;
  final List<StatusChangeItem> recentStatusChanges;
  final List<SessionHistoryGroup> sessionHistory;
}

