/// Provides UTC timestamps for createdAt/updatedAt/deletedAt and local yyyy-MM-dd dates.
abstract interface class AppClock {
  DateTime nowUtc();
  String todayLocalDate();
  String yesterdayLocalDate();
}

class SystemAppClock implements AppClock {
  const SystemAppClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  @override
  String todayLocalDate() => _formatLocalDate(DateTime.now());

  @override
  String yesterdayLocalDate() =>
      _formatLocalDate(DateTime.now().subtract(const Duration(days: 1)));

  String _formatLocalDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
