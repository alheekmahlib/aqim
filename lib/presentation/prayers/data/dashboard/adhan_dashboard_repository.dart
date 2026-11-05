part of '../../prayers.dart';

/// The only bridge between the dashboard and the legacy prayer controllers.
/// Reading a day never changes AdhanState or triggers notification scheduling.
class AdhanDashboardRepository implements DashboardDataRepository {
  AdhanDashboardRepository(
    this.adhan,
    this.general,
    this.events, {
    required this.readLocationName,
  });
  final AdhanController adhan;
  final GeneralController general;
  final EventController events;
  final Future<String> Function() readLocationName;

  @override
  DashboardAvailability get availability {
    if (!general.state.activeLocation.value ||
        Location.instance.position == null) {
      return DashboardAvailability.locationRequired;
    }
    if (adhan.state.isLoadingPrayerData.value ||
        adhan.state.prayerTimes == null) {
      return DashboardAvailability.loading;
    }
    return DashboardAvailability.ready;
  }

  @override
  Stream<void> get changes => Stream<void>.multi((sink) {
    final removePrayerListener = adhan.addListenerId(
      'init_athan',
      () => sink.add(null),
    );
    final removeLoadingListener = adhan.addListenerId(
      'loading_state',
      () => sink.add(null),
    );
    final worker = everAll([
      general.state.activeLocation,
      general.state.isLocationLoading,
      adhan.state.isLoadingPrayerData,
      adhan.state.isPrayerTimesInitialized,
      adhan.state.fajrTime,
      adhan.state.sunriseTime,
      adhan.state.dhuhrTime,
      adhan.state.asrTime,
      adhan.state.maghribTime,
      adhan.state.ishaTime,
      adhan.state.showIqamaTimes,
      adhan.state.localizedCity,
      events.adjustHijriDays,
    ], (_) => sink.add(null));
    sink.onCancel = () {
      worker.dispose();
      removePrayerListener();
      removeLoadingListener();
    };
  });

  @override
  Future<DashboardData> load(DateTime date, DateTime now) async {
    if (availability != DashboardAvailability.ready) {
      throw StateError('Prayer data is not ready');
    }
    final position = Location.instance.position!;
    final cacheValid = MonthlyPrayerCache.isMonthlyDataValid(
      currentLocation: LatLng(position.latitude, position.longitude),
    );
    // Capture all data before awaiting location lookup. No shared selected-date
    // fields are used, including when the monthly cache supplies the times.
    final times = _times(date, cacheValid);
    final liveTimes = <PrayerTimeEntry>[
      for (final offset in [-1, 0, 1, 2])
        ..._times(PreparePrayerDashboard.shiftDay(now, offset), cacheValid),
    ];
    final hijri = HijriDate.fromDate(
      PreparePrayerDashboard.shiftDay(date, events.adjustHijriDays.value),
    );
    final ramadan = hijri.hijriToGregorian(
      hijri.hMonth > 9 ? hijri.hYear + 1 : hijri.hYear,
      9,
      1,
    );
    final adjustedDay = PreparePrayerDashboard.shiftDay(
      date,
      events.adjustHijriDays.value,
    );
    // Calendar-day arithmetic must not lose a day at a DST transition.
    final days = DateTime.utc(ramadan.year, ramadan.month, ramadan.day)
        .difference(
          DateTime.utc(adjustedDay.year, adjustedDay.month, adjustedDay.day),
        )
        .inDays;
    final moon = MoonPhaseCalculator.getMoonPhase(
      DateTime.utc(date.year, date.month, date.day, 12),
    );
    final showIqama = adhan.state.showIqamaTimes.value;
    final location = await readLocationName();
    return DashboardData(
      date: date,
      location: location,
      times: times,
      liveTimes: liveTimes,
      showIqama: showIqama,
      calendar: CalendarData(
        year: hijri.hYear,
        month: hijri.hMonth,
        day: hijri.hDay,
        daysToRamadan: hijri.hMonth == 9 ? 0 : days,
        inRamadan: hijri.hMonth == 9,
      ),
      moon: LunarData(
        phase: LunarPhase.values.byName(moon.phase.name),
        illumination: moon.illumination,
        age: moon.age,
        nextFullMoon: moon.nextFullMoon,
        nextNewMoon: moon.nextNewMoon,
      ),
    );
  }

  List<PrayerTimeEntry> _times(DateTime date, bool cacheValid) {
    final state = adhan.state;
    final cached = cacheValid
        ? MonthlyPrayerCache.getPrayerTimesForDate(date)
        : null;
    final List<DateTime> times;
    if (cached != null) {
      times = [
        cached.fajr,
        cached.sunrise,
        cached.dhuhr,
        cached.asr,
        cached.maghrib,
        cached.isha,
        cached.midnight,
        cached.lastThird,
      ];
    } else {
      final calculated = PrayerTimes(
        state.coordinates,
        DateComponents.from(date),
        state.params,
      );
      final sunnah = SunnahTimes(calculated);
      times = [
        calculated.fajr,
        calculated.sunrise,
        calculated.dhuhr,
        calculated.asr,
        calculated.maghrib,
        calculated.isha,
        sunnah.middleOfTheNight,
        sunnah.lastThirdOfTheNight,
      ];
    }
    final names = [
      'Fajr',
      'Sunrise',
      date.weekday == DateTime.friday ? 'Friday' : 'Dhuhr',
      'Asr',
      'Maghrib',
      'Isha',
      'middleOfTheNight',
      'lastThirdOfTheNight',
    ];
    return List.generate(
      times.length,
      (i) => PrayerTimeEntry(
        index: i,
        name: names[i],
        at: times[i].toLocal(),
        iqama: const {0, 2, 3, 4, 5}.contains(i)
            ? times[i].toLocal().add(state.iqamaOffsets.durationByIndex(i))
            : null,
      ),
    );
  }

  @override
  Future<void> updateLocation() async {
    if (!await general.updateLocationAndPrayerTimes()) {
      throw StateError('Location update failed');
    }
  }
}

class SystemDashboardClock implements DashboardClock {
  const SystemDashboardClock();
  @override
  DateTime now() => DateTime.now();
  @override
  Stream<DateTime> ticks(Duration interval) =>
      Stream.periodic(interval, (_) => now());
}
