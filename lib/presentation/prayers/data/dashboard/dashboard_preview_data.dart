part of '../../prayers.dart';

/// Illustrative presentation values, independent of permissions, storage and
/// live prayer controllers. They are never used by the actual dashboard.
class DashboardPreviewData {
  const DashboardPreviewData(this.card, this.countdown);
  final DashboardViewData card;
  final CountdownViewData countdown;

  factory DashboardPreviewData.localized() {
    const presenter = DashboardPresenter();
    const names = [
      'Fajr',
      'Sunrise',
      'Dhuhr',
      'Asr',
      'Maghrib',
      'Isha',
      'middleOfTheNight',
      'lastThirdOfTheNight',
    ];
    const times = [
      '5:20',
      '6:40',
      '12:15',
      '3:30',
      '6:10',
      '7:30',
      '12:00',
      '2:15',
    ];
    final entries = List.generate(
      names.length,
      (i) => PrayerTimeView(
        names[i].tr,
        presenter.number(times[i]),
        presenter.number(times[i]),
        DashboardPresenter.icons[i],
        const {},
      ),
    );
    final phaseName = 'dashboardMoon_waningGibbous'.tr;
    final card = DashboardViewData(
      location: 'dashboardPanel_location_date'.tr,
      locationDetails: 'dashboardPanel_location_date'.tr,
      weekday: 'Mon'.tr,
      hijriDay: presenter.number(15),
      hijriMonth: 'Jumada Al-Awwal'.tr,
      hijriMonthAsset: 'assets/svg/hijri/5.svg',
      hijriYear: presenter.number(1448),
      gregorianDate: presenter.number('26 / 10 / 2026'),
      dateLabel: '${presenter.number(15)} ${'Jumada Al-Awwal'.tr}',
      ramadan: 'dashboardRamadanIn'.trParams({'days': presenter.number(104)}),
      moonInfo: MoonPhaseInfo(
        phase: MoonPhase.waningGibbous,
        illumination: .85,
        age: 18,
        nextFullMoon: DateTime(2026, 11, 24),
        nextNewMoon: DateTime(2026, 11, 9),
        arabicName: phaseName,
        englishName: phaseName,
      ),
      moonName: phaseName,
      illumination: presenter.number('85%'),
      prayers: List.unmodifiable(entries.take(6)),
      night: List.unmodifiable(entries.skip(6)),
      currentIndex: 3,
    );
    return DashboardPreviewData(
      card,
      CountdownViewData(
        'dashboardTimeUntil'.trParams({'prayer': 'Maghrib'.tr}),
        presenter.number('02:14:36'),
        '${'Asr'.tr} ${presenter.number('3:30')}',
        '${'Maghrib'.tr} ${presenter.number('6:10')}',
        .42,
      ),
    );
  }
}
