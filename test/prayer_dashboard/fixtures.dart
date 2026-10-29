import 'dart:async';
import 'package:aqim/presentation/prayers/dashboard/domain/dashboard_data.dart';
import 'package:aqim/presentation/prayers/dashboard/domain/dashboard_layout.dart';

DashboardData dashboardFixture(DateTime date) {
  List<PrayerTimeEntry> times(DateTime day) => [
    for (var i = 0; i < 8; i++)
      PrayerTimeEntry(
        index: i,
        name: [
          'Fajr',
          'Sunrise',
          'Dhuhr',
          'Asr',
          'Maghrib',
          'Isha',
          'middleOfTheNight',
          'lastThirdOfTheNight',
        ][i],
        at: DateTime(
          day.year,
          day.month,
          day.day + (i > 5 ? 1 : 0),
          [5, 6, 12, 15, 18, 20, 0, 2][i],
        ),
      ),
  ];
  return DashboardData(
    date: date,
    location: 'Portland',
    times: times(date),
    liveTimes: [
      for (final offset in [-1, 0, 1])
        ...times(DateTime(2026, 10, 26 + offset)),
    ],
    calendar: const CalendarData(
      year: 1448,
      month: 5,
      day: 15,
      daysToRamadan: 104,
      inRamadan: false,
    ),
    moon: LunarData(
      phase: LunarPhase.waningGibbous,
      illumination: .93,
      age: 18,
      nextFullMoon: DateTime(2026, 11, 25),
      nextNewMoon: DateTime(2026, 11, 10),
    ),
    showIqama: false,
  );
}

class MemoryLayout implements DashboardLayoutRepository {
  DashboardLayout value = DashboardLayout.defaults();
  bool fail = false;
  @override
  DashboardLayout load() => value;
  @override
  Future<void> save(DashboardLayout layout) async {
    if (fail) throw StateError('disk full');
    value = layout;
  }
}

class FakeClock implements DashboardClock {
  DateTime value = DateTime(2026, 10, 26, 21);
  final stream = StreamController<DateTime>.broadcast(sync: true);
  Duration? interval;
  @override
  DateTime now() => value;
  @override
  Stream<DateTime> ticks(Duration interval) {
    this.interval = interval;
    return stream.stream;
  }

  void emit(DateTime time) {
    value = time;
    stream.add(time);
  }
}

class FakeDataRepository implements DashboardDataRepository {
  @override
  DashboardAvailability availability = DashboardAvailability.ready;
  final events = StreamController<void>.broadcast(sync: true);
  final requests = <({DateTime date, Completer<DashboardData> result})>[];
  bool delayed = false;
  bool fail = false;
  @override
  Stream<void> get changes => events.stream;
  @override
  Future<DashboardData> load(DateTime date, DateTime now) {
    if (fail) return Future.error(StateError('load failed'));
    if (!delayed) return Future.value(dashboardFixture(date));
    final result = Completer<DashboardData>();
    requests.add((date: date, result: result));
    return result.future;
  }

  @override
  Future<void> updateLocation() async {}
}
