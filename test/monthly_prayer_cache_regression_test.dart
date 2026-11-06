import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:aqim/presentation/prayers/prayers.dart';
import 'package:aqim/core/utils/constants/shared_preferences_constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'saving next month preserves the current month and its validity',
    () async {
      final dir = await Directory.systemTemp.createTemp('aqim_monthly_cache');
      addTearDown(() async {
        await GetStorage().save();
        await dir.delete(recursive: true);
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => dir.path,
          );
      await GetStorage.init();
      await GetStorage().erase();
      final now = DateTime.now();
      const location = LatLng(21.4225, 39.8262);
      final params = CalculationMethod.umm_al_qura.getParameters()
      ..madhab = Madhab.shafi;
      await MonthlyPrayerCache.saveMonthlyPrayerData(
        location: location,
        params: params,
        month: DateTime(now.year, now.month),
      );
      await MonthlyPrayerCache.saveMonthlyPrayerData(
        location: location,
        params: params,
        month: DateTime(now.year, now.month + 1),
      );
      expect(MonthlyPrayerCache.getPrayerTimesForDate(now), isNotNull);
      expect(
        MonthlyPrayerCache.getPrayerTimesForDate(
          DateTime(now.year, now.month + 1),
        ),
        isNotNull,
      );
      expect(
        MonthlyPrayerCache.isMonthlyDataValid(currentLocation: location),
        isTrue,
      );
    final restored = MonthlyPrayerData.fromJson(
      MonthlyPrayerCache.dataForMonth(now)!,
    );
    expect(restored.params.method, CalculationMethod.umm_al_qura);
    expect(restored.params.ishaInterval, params.ishaInterval);
    expect(restored.params.ishaAngle, params.ishaAngle);
    await GetStorage().write(ADJUSTMENT_FAJR, 3);
    expect(MonthlyPrayerCache.isMonthlyDataValid(currentLocation: location), isFalse);
    await GetStorage().write(ADJUSTMENT_FAJR, 0);
    final originalState = AdhanState()
      ..coordinates = Coordinates(location.latitude, location.longitude)
      ..dateComponents = DateComponents.from(now)
      ..params = params;
    originalState.prayerTimes = PrayerTimes(
      originalState.coordinates,
      originalState.dateComponents,
      params,
    );
    originalState.sunnahTimes = SunnahTimes(originalState.prayerTimes!);
    final restoredState = AdhanState();
    expect(restoredState.fromJson(originalState.toJson()), isTrue);
    expect(restoredState.params.ishaInterval, params.ishaInterval);
    expect(restoredState.prayerTimes!.isha, originalState.prayerTimes!.isha);
    // A later location update must not relabel old daily prayer data.
    PrayerCacheManager.savePrayerData({'example': true}, location);
    await GetStorage().write(CURRENT_LOCATION, {
      'latitude': 24.7136,
      'longitude': 46.6753,
    });
    expect(
      PrayerCacheManager.isCacheValid(
        currentLocation: const LatLng(24.7136, 46.6753),
      ),
      isFalse,
    );
    },
  );
}
