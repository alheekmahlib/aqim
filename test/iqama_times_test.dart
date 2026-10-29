import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:aqim/core/utils/constants/shared_preferences_constants.dart';
import 'package:aqim/presentation/prayers/prayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// نسخة اختبارية تتجاوز onInit لتفادي سلاسل GeneralController/الخلفيات،
/// فالاختبار يقرأ prayerNameList فقط ولا يعتمد على دورة حياة GetX.
class _TestAdhanController extends AdhanController {
  @override
  // ignore: must_call_super
  Future<void> onInit() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('iqama_test');
    // محاكاة قناة path_provider لتعمل GetStorage داخل بيئة الاختبار.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall call) async => tempDir.path,
        );
    await GetStorage.init();
    await GetStorage.init('iqamaUnit');
    // DateFormatter يعتمد intl؛ في التطبيق تهيئه localizationsDelegates فقط.
    await initializeDateFormatting();
    Intl.defaultLocale = 'en';
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  group('IqamaOffsets', () {
    test('defaults match the agreed per-prayer offsets', () {
      final offsets = IqamaOffsets();
      expect(offsets.values, [25, 15, 15, 10, 15]);
      expect(offsets.getByIndex(0), 25); // Fajr
      expect(offsets.getByIndex(2), 15); // Dhuhr
      expect(offsets.getByIndex(3), 15); // Asr
      expect(offsets.getByIndex(4), 10); // Maghrib
      expect(offsets.getByIndex(5), 15); // Isha
    });

    test('hasIqama is true only for the five prayers', () {
      expect(IqamaOffsets.hasIqama(0), isTrue); // Fajr
      expect(IqamaOffsets.hasIqama(2), isTrue); // Dhuhr
      expect(IqamaOffsets.hasIqama(3), isTrue); // Asr
      expect(IqamaOffsets.hasIqama(4), isTrue); // Maghrib
      expect(IqamaOffsets.hasIqama(5), isTrue); // Isha
      expect(IqamaOffsets.hasIqama(1), isFalse); // Sunrise
      expect(IqamaOffsets.hasIqama(6), isFalse); // Midnight
      expect(IqamaOffsets.hasIqama(7), isFalse); // Last third
    });

    test('adjustByIndex steps by delta and persists', () {
      final box = GetStorage('iqamaUnit');
      final offsets = IqamaOffsets.fromGetStorage(storage: box);

      offsets.adjustByIndex(0, iqamaOffsetStep);
      expect(offsets.fajr, 30);
      expect(box.read(IQAMA_OFFSET_FAJR), 30);

      offsets.adjustByIndex(5, -iqamaOffsetStep);
      expect(offsets.isha, 10);
      expect(box.read(IQAMA_OFFSET_ISHA), 10);
    });

    test('adjustByIndex clamps within 5 and 60 minutes', () {
      final offsets = IqamaOffsets();

      offsets
        ..fajr = iqamaMaxOffset
        ..maghrib = iqamaMinOffset;
      offsets.adjustByIndex(0, iqamaOffsetStep);
      expect(offsets.fajr, iqamaMaxOffset);

      offsets.adjustByIndex(4, -iqamaOffsetStep);
      expect(offsets.maghrib, iqamaMinOffset);
    });

    test('adjustByIndex ignores non-prayer rows', () {
      final offsets = IqamaOffsets();
      offsets.adjustByIndex(1, iqamaOffsetStep); // Sunrise
      expect(offsets.values, [25, 15, 15, 10, 15]);
    });

    test('fromGetStorage reads stored values and falls back to defaults', () {
      final box = GetStorage('iqamaUnit');
      box.erase();
      final defaults = IqamaOffsets.fromGetStorage(storage: box);
      expect(defaults.values, [25, 15, 15, 10, 15]);

      box.write(IQAMA_OFFSET_DHUHR, 20);
      box.write(IQAMA_OFFSET_ISHA, 40);
      final restored = IqamaOffsets.fromGetStorage(storage: box);
      expect(restored.dhuhr, 20);
      expect(restored.isha, 40);
      expect(restored.fajr, 25);
    });
  });

  group('IqamaSchedulePolicy.adhanDaysForIOS', () {
    test('keeps the full 10 days with only adhan enabled', () {
      expect(
        IqamaSchedulePolicy.adhanDaysForIOS(
          enabledAdhanCount: 5,
          iqamaEnabled: false,
          ramadanActive: false,
        ),
        10,
      );
    });

    test('shrinks to 9 days when iqama notifications are enabled', () {
      expect(
        IqamaSchedulePolicy.adhanDaysForIOS(
          enabledAdhanCount: 5,
          iqamaEnabled: true,
          ramadanActive: false,
        ),
        9,
      );
    });

    test('pre-prayer reminders reserve 10 slots and shrink the horizon', () {
      expect(
        IqamaSchedulePolicy.adhanDaysForIOS(
          enabledAdhanCount: 5,
          iqamaEnabled: true,
          ramadanActive: false,
          remindersEnabled: true,
        ),
        7,
      );
      expect(
        IqamaSchedulePolicy.adhanDaysForIOS(
          enabledAdhanCount: 5,
          iqamaEnabled: false,
          ramadanActive: false,
          remindersEnabled: true,
        ),
        9,
      );
    });

    test('reminders with ramadan still keep the minimum horizon', () {
      expect(
        IqamaSchedulePolicy.adhanDaysForIOS(
          enabledAdhanCount: 5,
          iqamaEnabled: true,
          ramadanActive: true,
          remindersEnabled: true,
        ),
        4,
      );
      expect(
        IqamaSchedulePolicy.adhanDaysForIOS(
          enabledAdhanCount: 0,
          iqamaEnabled: true,
          ramadanActive: true,
          remindersEnabled: true,
        ),
        IqamaSchedulePolicy.minAdhanDays,
      );
    });

    test(
      'fixes the latent Ramadan overflow (70 > 64) by shrinking to 6 days',
      () {
        expect(
          IqamaSchedulePolicy.adhanDaysForIOS(
            enabledAdhanCount: 5,
            iqamaEnabled: true,
            ramadanActive: true,
          ),
          6,
        );
        expect(
          IqamaSchedulePolicy.adhanDaysForIOS(
            enabledAdhanCount: 5,
            iqamaEnabled: false,
            ramadanActive: true,
          ),
          8,
        );
      },
    );

    test('never goes below the minimum horizon', () {
      expect(
        IqamaSchedulePolicy.adhanDaysForIOS(
          enabledAdhanCount: 0,
          iqamaEnabled: true,
          ramadanActive: true,
        ),
        IqamaSchedulePolicy.minAdhanDays,
      );
    });
  });

  group('iqama fields in prayer list', () {
    test(
      'iqama time = adhan time + per-prayer offset for the five prayers only',
      () {
        final ctrl = _TestAdhanController();
        Get.put<AdhanController>(ctrl);
        addTearDown(() => Get.delete<AdhanController>());

        final state = ctrl.state;
        state.params = CalculationMethod.other.getParameters();
        state.iqamaOffsets = IqamaOffsets(
          fajr: 25,
          dhuhr: 15,
          asr: 15,
          maghrib: 10,
          isha: 15,
        );

        final coordinates = Coordinates(21.4225, 39.8262);
        final prayerTimes = PrayerTimes(
          coordinates,
          DateComponents.from(DateTime(2026, 8, 18, 12)),
          state.params,
        );
        state.prayerTimes = prayerTimes;
        state.sunnahTimes = SunnahTimes(prayerTimes);

        final list = ctrl.prayerNameList;
        expect(list.length, 8);

        expect(
          list[0]['iqamaDateTime'],
          prayerTimes.fajr.add(const Duration(minutes: 25)),
        );
        expect(
          list[2]['iqamaDateTime'],
          prayerTimes.dhuhr.add(const Duration(minutes: 15)),
        );
        expect(
          list[5]['iqamaDateTime'],
          prayerTimes.isha.add(const Duration(minutes: 15)),
        );

        // الشروق ومنتصف الليل والثلث الأخير بلا إقامة.
        expect(list[1].containsKey('iqamaDateTime'), isFalse);
        expect(list[6].containsKey('iqamaDateTime'), isFalse);
        expect(list[7].containsKey('iqamaDateTime'), isFalse);
      },
    );
  });
}
