part of '../../prayers.dart';

class PrayerTimeView {
  const PrayerTimeView(
    this.name,
    this.time,
    this.shortTime,
    this.icon,
    this.legacy,
  );
  final String name;
  final String time;
  final String shortTime;
  final IconData icon;
  final Map<String, dynamic> legacy;
}

class DashboardViewData {
  const DashboardViewData({
    required this.location,
    required this.locationDetails,
    required this.weekday,
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriMonthAsset,
    required this.hijriYear,
    required this.gregorianDate,
    required this.dateLabel,
    required this.ramadan,
    required this.moonInfo,
    required this.moonName,
    required this.illumination,
    required this.prayers,
    required this.night,
    required this.currentIndex,
  });
  final String location, weekday, hijriDay, hijriMonth, hijriYear;
  final String locationDetails, hijriMonthAsset;
  final String gregorianDate, dateLabel, ramadan, moonName, illumination;
  final MoonPhaseInfo moonInfo;
  final List<PrayerTimeView> prayers;
  final List<PrayerTimeView> night;
  final int currentIndex;
}

class CountdownViewData {
  const CountdownViewData(
    this.title,
    this.remaining,
    this.previous,
    this.next,
    this.progress,
  );
  final String title, remaining, previous, next;
  final double progress;
}

class WeekCalendarViewData {
  const WeekCalendarViewData(
    this.date,
    this.minDate,
    this.maxDate,
    this.hijriDate,
    this.hijriMinDate,
    this.hijriMaxDate,
  );
  final DateTime date, minDate, maxDate;
  final HijriDate hijriDate, hijriMinDate, hijriMaxDate;
}

/// Formatting and adaptation for views only; no storage or prayer calculations.
class DashboardPresenter {
  const DashboardPresenter();
  static const icons = [
    SolarIconsBold.moonFog,
    SolarIconsBold.sunrise,
    SolarIconsBold.sun,
    SolarIconsBold.sun2,
    SolarIconsBold.sunset,
    SolarIconsBold.moon,
    SolarIconsBold.moonStars,
    SolarIconsBold.moonStars,
  ];
  String number(Object value) => '$value'.convertNumbersToCurrentLang();
  String get _locale => Get.locale?.languageCode == 'ph'
      ? 'fil'
      : Get.locale?.languageCode ?? 'ar';
  String formatDate(DateTime date, String pattern) {
    try {
      return number(intl.DateFormat(pattern, _locale).format(date));
    } catch (_) {
      return number(intl.DateFormat(pattern, 'en').format(date));
    }
  }

  String time(DateTime date) => formatDate(date, 'h:mm a');

  WeekCalendarViewData week(DashboardData data, DateTime now) {
    final h = data.calendar;
    final hijri = HijriDate.fromHijri(h.year, h.month, h.day);
    final first = PreparePrayerDashboard.shiftDay(now, -7);
    final last = PreparePrayerDashboard.shiftDay(now, 7);
    final adjusted = hijri.hijriToGregorian(h.year, h.month, h.day);
    final offset = DateTime.utc(adjusted.year, adjusted.month, adjusted.day)
        .difference(
          DateTime.utc(data.date.year, data.date.month, data.date.day),
        )
        .inDays;
    return WeekCalendarViewData(
      data.date,
      first,
      last,
      hijri,
      HijriDate.fromDate(PreparePrayerDashboard.shiftDay(first, offset)),
      HijriDate.fromDate(PreparePrayerDashboard.shiftDay(last, offset)),
    );
  }

  DashboardViewData present(DashboardData data, DateTime now) {
    final h = data.calendar;
    final hijri = HijriDate.fromHijri(h.year, h.month, h.day);
    final month = hijri.getLongMonthName().tr;
    final moon = data.moon;
    final moonInfo = MoonPhaseInfo(
      phase: MoonPhase.values.byName(moon.phase.name),
      illumination: moon.illumination,
      age: moon.age,
      nextFullMoon: moon.nextFullMoon,
      nextNewMoon: moon.nextNewMoon,
      arabicName: 'dashboardMoon_${moon.phase.name}'.tr,
      englishName: 'dashboardMoon_${moon.phase.name}'.tr,
    );
    final entries = data.times
        .map(
          (p) => PrayerTimeView(
            p.name.tr,
            time(p.at),
            formatDate(p.at, 'h:mm'),
            icons[p.index],
            {
              'title': p.name,
              'time': time(p.at),
              'dateTime': p.at,
              'icon': icons[p.index],
              'iqamaTime': data.showIqama && p.iqama != null
                  ? time(p.iqama!)
                  : null,
            },
          ),
        )
        .toList(growable: false);
    var currentIndex = -1;
    if (PreparePrayerDashboard.sameDay(data.date, now)) {
      for (final p in data.times) {
        if (!p.at.isAfter(now)) currentIndex = p.index;
      }
    }
    return DashboardViewData(
      location: data.location.replaceAll('\n', ' · '),
      locationDetails: data.location,
      weekday: formatDate(data.date, 'EEEE'),
      hijriDay: number(h.day),
      hijriMonth: month,
      hijriMonthAsset: 'assets/svg/hijri/${h.month}.svg',
      hijriYear: number(h.year),
      gregorianDate: formatDate(data.date, 'd MMMM yyyy'),
      dateLabel: '${number(h.day)} $month • ${formatDate(data.date, 'd MMM')}',
      ramadan: h.inRamadan
          ? 'dashboardRamadanNow'.tr
          : 'dashboardRamadanIn'.trParams({'days': number(h.daysToRamadan)}),
      moonInfo: moonInfo,
      moonName: 'dashboardMoon_${moon.phase.name}'.tr,
      illumination: '${number((moon.illumination * 100).round())}%',
      prayers: entries.take(6).toList(),
      night: entries.skip(6).toList(),
      currentIndex: currentIndex,
    );
  }

  CountdownViewData? presentCountdown(PrayerCountdown? countdown) {
    if (countdown == null) return null;
    final seconds = countdown.remaining.inSeconds;
    final value =
        '${(seconds ~/ 3600).toString().padLeft(2, '0')}:'
        '${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
    return CountdownViewData(
      'dashboardTimeUntil'.trParams({'prayer': countdown.next.name.tr}),
      number(value),
      '${countdown.previous.name.tr} ${time(countdown.previous.at)}',
      '${countdown.next.name.tr} ${time(countdown.next.at)}',
      countdown.progress,
    );
  }
}
