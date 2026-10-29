class PrayerTimeEntry {
  const PrayerTimeEntry({
    required this.index,
    required this.name,
    required this.at,
    this.iqama,
  });
  final int index;
  final String name;
  final DateTime at;
  final DateTime? iqama;
  bool get isPrayer => const {0, 2, 3, 4, 5}.contains(index);
}

enum LunarPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

class LunarData {
  const LunarData({
    required this.phase,
    required this.illumination,
    required this.age,
    required this.nextFullMoon,
    required this.nextNewMoon,
  });
  final LunarPhase phase;
  final double illumination;
  final double age;
  final DateTime nextFullMoon;
  final DateTime nextNewMoon;
}

class CalendarData {
  const CalendarData({
    required this.year,
    required this.month,
    required this.day,
    required this.daysToRamadan,
    required this.inRamadan,
  });
  final int year;
  final int month;
  final int day;
  final int daysToRamadan;
  final bool inRamadan;
}

class DashboardData {
  DashboardData({
    required this.date,
    required this.location,
    required Iterable<PrayerTimeEntry> times,
    required Iterable<PrayerTimeEntry> liveTimes,
    required this.calendar,
    required this.moon,
    required this.showIqama,
  }) : times = List.unmodifiable(times),
       liveTimes = List.unmodifiable(liveTimes);
  final DateTime date;
  final String location;
  final List<PrayerTimeEntry> times;
  final List<PrayerTimeEntry> liveTimes;
  final CalendarData calendar;
  final LunarData moon;
  final bool showIqama;
}

enum DashboardAvailability { ready, loading, locationRequired }

abstract interface class DashboardDataRepository {
  DashboardAvailability get availability;
  Stream<void> get changes;
  Future<DashboardData> load(DateTime date, DateTime now);
  Future<void> updateLocation();
}

abstract interface class DashboardClock {
  DateTime now();
  Stream<DateTime> ticks(Duration interval);
}

class PrayerCountdown {
  const PrayerCountdown({
    required this.previous,
    required this.next,
    required this.remaining,
    required this.progress,
  });
  final PrayerTimeEntry previous;
  final PrayerTimeEntry next;
  final Duration remaining;
  final double progress;
}

class PreparePrayerDashboard {
  const PreparePrayerDashboard(this.repository);
  final DashboardDataRepository repository;

  Future<DashboardData> load(DateTime date, DateTime now) =>
      repository.load(date, now);

  static DateTime day(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  static bool sameDay(DateTime a, DateTime b) => day(a) == day(b);
  static DateTime shiftDay(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  static DateTime constrainDate(DateTime date, DateTime now) {
    final first = shiftDay(now, -7);
    final last = shiftDay(now, 7);
    final normalized = day(date);
    return normalized.isBefore(first)
        ? first
        : normalized.isAfter(last)
        ? last
        : normalized;
  }

  static PrayerCountdown? countdown(
    List<PrayerTimeEntry> entries,
    DateTime now,
  ) {
    final prayers = entries.where((p) => p.isPrayer).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    PrayerTimeEntry? previous;
    for (final prayer in prayers) {
      if (!prayer.at.isAfter(now)) {
        previous = prayer;
      } else if (previous != null) {
        final total = prayer.at.difference(previous.at).inMilliseconds;
        return PrayerCountdown(
          previous: previous,
          next: prayer,
          remaining: prayer.at.difference(now),
          progress: total <= 0
              ? 0
              : (now.difference(previous.at).inMilliseconds / total).clamp(
                  0.0,
                  1.0,
                ),
        );
      }
    }
    return null;
  }
}
