import 'dart:convert';
import 'dart:io';

import 'package:aqim/presentation/prayers/features/data/stored_prayer_feature_settings.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature_settings.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_id.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_override.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'persists to disk and restores in a fresh container without touching legacy values',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'aqim_prayer_features_',
      );
      const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProvider, (_) async => directory.path);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProvider, null),
      );
      final name = directory.path.split(Platform.pathSeparator).last;
      final box = GetStorage(name, directory.path);
      await box.initStorage;
      await box.write('IQAMA_OFFSET_FAJR', 25);
      await box.write('scheduledAdhan_Fajr', 'athan');
      final repository = StoredPrayerFeatureSettings(box);
      final defaults = PrayerFeatureSettings();
      await repository.save(
        defaults.withPreference(
          PrayerFeature.reminder,
          defaults[PrayerFeature.reminder]
              .copyWith(minutes: 12)
              .withOverride(
                PrayerId.fajr,
                const PrayerOverride(enabled: false, minutes: 18),
              ),
        ),
      );

      // GetStorage queues disk flushes. Wait for the persisted payload, not just
      // its shared in-memory singleton, before checking restart behavior.
      final file = File('${directory.path}/$name.gs');
      Map<String, dynamic>? persisted;
      for (var attempt = 0; attempt < 100; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        try {
          final value =
              jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          if (value.containsKey(StoredPrayerFeatureSettings.storageKey)) {
            persisted = value;
            break;
          }
        } on FormatException {
          // A queued write may be between truncation and flushing.
        }
      }
      expect(persisted, isNotNull);
      expect(persisted!['IQAMA_OFFSET_FAJR'], 25);
      expect(persisted['scheduledAdhan_Fajr'], 'athan');
      final restoredName = '${name}_restored';
      await File(
        '${directory.path}/$restoredName.gs',
      ).writeAsString(jsonEncode(persisted));
      final fresh = GetStorage(restoredName, directory.path);
      await fresh.initStorage;
      final restored = StoredPrayerFeatureSettings(fresh).read();
      expect(restored[PrayerFeature.reminder].minutes, 12);
      expect(
        restored[PrayerFeature.reminder].includesPrayer(PrayerId.fajr),
        isFalse,
      );
      expect(restored[PrayerFeature.reminder].minutesFor(PrayerId.fajr), 18);
      expect(restored[PrayerFeature.silence].minutes, 20);
      await directory.delete(recursive: true);
    },
  );
}
