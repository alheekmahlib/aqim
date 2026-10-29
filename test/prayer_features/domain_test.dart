import 'package:aqim/presentation/prayers/features/data/prayer_feature_settings_codec.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature_availability.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature_preferences.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature_settings.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_id.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_override.dart';
import 'package:aqim/presentation/prayers/features/domain/save_prayer_feature_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_prayer_feature_capabilities.dart';
import 'fake_prayer_feature_repository.dart';

void main() {
  const codec = PrayerFeatureSettingsCodec();

  test(
    'defaults are off and timed preferences include only the five prayers',
    () {
      final settings = PrayerFeatureSettings();
      expect(PrayerId.values, hasLength(5));
      expect(settings[PrayerFeature.silence].minutes, 20);
      expect(settings[PrayerFeature.reminder].minutes, 10);
      for (final feature in PrayerFeature.values) {
        expect(settings[feature].enabled, isFalse);
        for (final prayer in PrayerId.values) {
          expect(settings[feature].isEnabledFor(prayer), isFalse);
        }
      }
    },
  );

  test(
    'custom duration wins, exclusions retain it, reset inherits latest global',
    () {
      final initial = PrayerFeaturePreferences(enabled: true, minutes: 20);
      final custom = initial.withOverride(
        PrayerId.fajr,
        const PrayerOverride(minutes: 30),
      );
      final changed = custom.copyWith(minutes: 25);
      expect(changed.minutesFor(PrayerId.fajr), 30);
      expect(changed.minutesFor(PrayerId.isha), 25);
      final excluded = changed.withOverride(
        PrayerId.fajr,
        const PrayerOverride(enabled: false, minutes: 30),
      );
      expect(excluded.isEnabledFor(PrayerId.fajr), isFalse);
      expect(excluded.minutesFor(PrayerId.fajr), 30);
      final reset = excluded.withOverride(PrayerId.fajr, null);
      expect(reset.isEnabledFor(PrayerId.fajr), isTrue);
      expect(reset.minutesFor(PrayerId.fajr), 25);
      expect(initial.overrides, isEmpty);
      expect(() => custom.overrides.clear(), throwsUnsupportedError);
    },
  );

  test('codec round trips durations, exclusions and independent toggles', () {
    final original = PrayerFeatureSettings(
      preferences: {
        PrayerFeature.silence: PrayerFeaturePreferences(
          enabled: true,
          minutes: 24,
          overrides: {
            PrayerId.fajr: const PrayerOverride(minutes: 31),
            PrayerId.asr: const PrayerOverride(enabled: false),
          },
        ),
        PrayerFeature.flipToStop: PrayerFeaturePreferences(enabled: true),
      },
    );
    final restored = codec.decode(codec.encode(original));
    expect(codec.encode(restored), codec.encode(original));
    expect(restored[PrayerFeature.silence].minutesFor(PrayerId.asr), 24);
    expect(restored[PrayerFeature.volumeToStop].enabled, isFalse);
  });

  test('malformed values recover independently without inventing prayers', () {
    final restored = codec.decode({
      'version': 1,
      'features': {
        'silence': {
          'enabled': 'true',
          'minutes': 121,
          'overrides': {
            'fajr': {'minutes': 0, 'enabled': false},
            'dhuhr': {'minutes': 35},
            'asr': 'invalid',
            'sunrise': {'minutes': 15},
          },
        },
        'reminder': {'minutes': 15},
        'volumeToStop': {
          'minutes': 10,
          'overrides': {
            'fajr': {'minutes': 10},
          },
        },
      },
    });
    expect(restored[PrayerFeature.silence].enabled, isFalse);
    expect(restored[PrayerFeature.silence].minutes, 20);
    expect(restored[PrayerFeature.silence].minutesFor(PrayerId.fajr), 20);
    expect(
      restored[PrayerFeature.silence].includesPrayer(PrayerId.fajr),
      isFalse,
    );
    expect(restored[PrayerFeature.silence].minutesFor(PrayerId.dhuhr), 35);
    expect(restored[PrayerFeature.silence].overrides, hasLength(2));
    expect(restored[PrayerFeature.reminder].minutes, 15);
    expect(restored[PrayerFeature.volumeToStop].minutes, isNull);
    expect(restored[PrayerFeature.volumeToStop].overrides, isEmpty);
    for (final invalid in [
      null,
      'invalid',
      [],
      {'version': 2},
      {'version': 1, 'features': []},
    ]) {
      expect(
        codec.encode(codec.decode(invalid)),
        codec.encode(PrayerFeatureSettings()),
      );
    }
  });

  for (final feature in [PrayerFeature.silence, PrayerFeature.reminder]) {
    test(
      '${feature.name}: enforce duration limits including overrides',
      () async {
        final repository = FakePrayerFeatureRepository();
        final save = SavePrayerFeatureSettings(
          repository,
          FakePrayerFeatureCapabilities(),
        );
        for (final minutes in [1, feature.maxMinutes!]) {
          await save(
            PrayerFeatureSettings(
              preferences: {
                feature: PrayerFeaturePreferences(minutes: minutes),
              },
            ),
          );
        }
        for (final invalid in [0, -1, feature.maxMinutes! + 1]) {
          await expectLater(
            save(
              PrayerFeatureSettings(
                preferences: {
                  feature: PrayerFeaturePreferences(minutes: invalid),
                },
              ),
            ),
            throwsArgumentError,
          );
          await expectLater(
            save(
              PrayerFeatureSettings(
                preferences: {
                  feature: PrayerFeaturePreferences(
                    minutes: feature.defaultMinutes,
                    overrides: {
                      PrayerId.isha: PrayerOverride(minutes: invalid),
                    },
                  ),
                },
              ),
            ),
            throwsArgumentError,
          );
        }
        expect(repository.saves, 2);
      },
    );
  }

  test(
    'unavailable and permission-required features cannot be enabled',
    () async {
      final repository = FakePrayerFeatureRepository();
      for (final status in PrayerFeatureAvailability.values.where(
        (s) => s != PrayerFeatureAvailability.available,
      )) {
        final save = SavePrayerFeatureSettings(
          repository,
          FakePrayerFeatureCapabilities(value: status),
        );
        for (final feature in PrayerFeature.values) {
          final settings = PrayerFeatureSettings();
          await expectLater(
            save(
              settings.withPreference(
                feature,
                settings[feature].copyWith(enabled: true),
              ),
            ),
            throwsStateError,
          );
        }
      }
      expect(repository.saves, 0);
    },
  );
}
