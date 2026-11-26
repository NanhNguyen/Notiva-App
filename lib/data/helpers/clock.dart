/// Provides UTC timestamps for createdAt/updatedAt/deletedAt and local yyyy-MM-dd dates.
abstract interface class AppClock {
  DateTime nowUtc();
  String todayLocalDate();
}

class SystemAppClock implements AppClock {
  const SystemAppClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  @override
  String todayLocalDate() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

