import 'dart:io';
import 'package:adhan/adhan.dart';
import 'package:aqim/core/services/location/locations.dart';
import 'package:aqim/presentation/calendar/events.dart';
import 'package:aqim/presentation/controllers/general/general_controller.dart';
import 'package:aqim/presentation/prayers/prayers.dart';
import 'package:aqim/presentation/prayers/dashboard/data/adhan_dashboard_repository.dart';
import 'package:aqim/presentation/prayers/dashboard/data/stored_dashboard_layout.dart';
import 'package:aqim/presentation/prayers/dashboard/domain/dashboard_layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hijri_date/hijri.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AdhanController adhan;
  late EventController events;
  late AdhanDashboardRepository repository;
  final current = DateTime.now();
  final date = DateTime(current.year, current.month, current.day);
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp(
      'aqim_dashboard_repository',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => dir.path,
        );
    await GetStorage.init();
    addTearDown(() async {
      await GetStorage().save();
      await dir.delete(recursive: true);
    });
  });
  setUp(() async {
    await GetStorage().erase();
    // Do not register these legacy controllers: their app startup side effects
    // are unrelated to this adapter's read-only contract.
    adhan = AdhanController();
    events = EventController();
    final general = GeneralController();
    general.state.activeLocation.value = true;
    final state = adhan.state;
    state.coordinates = Coordinates(45.52, -122.67);
    state.params = CalculationMethod.north_america.getParameters()
      ..madhab = Madhab.hanafi
      ..highLatitudeRule = HighLatitudeRule.middle_of_the_night;
    state.prayerTimes = PrayerTimes(
      state.coordinates,
      DateComponents.from(date),
      state.params,
    );
    state.sunnahTimes = SunnahTimes(state.prayerTimes!);
    Location.instance.updateLocation(
      city: 'Portland',
      country: 'US',
      position: Position(
        latitude: 45.52,
        longitude: -122.67,
        timestamp: date,
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );
    repository = AdhanDashboardRepository(
      adhan,
      general,
      events,
      readLocationName: () async => 'Portland',
    );
  });
  tearDown(() => Get.reset());
  test(
    'calculated and cached selected days match and never change shared selection',
    () async {
      final selected = DateTime(date.year, date.month, date.day + 1);
      final original = adhan.state.selectedDate;
      final calculated = await repository.load(selected, date);
      await MonthlyPrayerCache.saveMonthlyPrayerData(
        location: const LatLng(45.52, -122.67),
        params: adhan.state.params,
        month: date,
      );
      final cached = await repository.load(selected, date);
      expect(cached.times.map((p) => p.at), calculated.times.map((p) => p.at));
      expect(
        cached.times.first.at,
        PrayerTimes(
          adhan.state.coordinates,
          DateComponents.from(selected),
          adhan.state.params,
        ).fajr.toLocal(),
      );
      expect(adhan.state.selectedDate, original);
      expect(cached.liveTimes.where((p) => p.index == 0).length, 4);
    },
  );
  test(
    'Hijri adjustment crosses months without shifting the lunar phase',
    () async {
      final calendar = HijriDate.fromHijri(1448, 8, 1);
      final ramadan = calendar.hijriToGregorian(1448, 9, 1);
      final before = DateTime(ramadan.year, ramadan.month, ramadan.day - 1);
      final original = await repository.load(before, date);
      events.adjustHijriDays.value = 1;
      final adjusted = await repository.load(before, date);
      expect(original.calendar.daysToRamadan, 1);
      expect(adjusted.calendar.month, 9);
      expect(adjusted.calendar.day, 1);
      expect(adjusted.calendar.inRamadan, isTrue);
      expect(adjusted.calendar.daysToRamadan, 0);
      expect(adjusted.moon.illumination, original.moon.illumination);
      events.adjustHijriDays.value = -1;
      final negative = await repository.load(ramadan, date);
      expect(negative.calendar.month, 8);
      expect(negative.calendar.daysToRamadan, 1);
    },
  );
  test(
    'moon information is supplied by hijri_date for the actual civil day',
    () async {
      final data = await repository.load(date, date);
      final expected = MoonPhaseCalculator.getMoonPhase(
        DateTime.utc(date.year, date.month, date.day, 12),
      );
      expect(data.moon.phase.name, expected.phase.name);
      expect(data.moon.illumination, expected.illumination);
    },
  );
  test(
    'layout persists to storage and can be reconstructed by a new repository',
    () async {
      final stored = StoredDashboardLayout(GetStorage());
      final layout = DashboardLayout.defaults()
          .toggle(PrayerPanel.countdown, true)
          .reorder(8, 0);
      await stored.save(layout);
      await GetStorage().save();
      final restored = StoredDashboardLayout(GetStorage()).load();
      expect(restored.panels.first.panel, PrayerPanel.countdown);
      expect(restored.panels.first.visible, isTrue);
      final raw = GetStorage().read(StoredDashboardLayout.storageKey);
      expect(raw['version'], 1);
      expect(raw['panels'].first['id'], 'countdown');
    },
  );
  test(
    'legacy update subscriptions are released when the dashboard unsubscribes',
    () async {
      var updates = 0;
      final subscription = repository.changes.listen((_) => updates++);
      await Future<void>.delayed(Duration.zero);
      adhan.update(['init_athan']);
      await Future<void>.delayed(Duration.zero);
      expect(updates, 1);
      await subscription.cancel();
      adhan.update(['init_athan']);
      await Future<void>.delayed(Duration.zero);
      expect(updates, 1);
    },
  );
}
