import '../domain/prayer_feature.dart';
import '../domain/prayer_feature_preferences.dart';
import '../domain/prayer_feature_settings.dart';
import '../domain/prayer_id.dart';
import '../domain/prayer_override.dart';

/// A separate versioned namespace leaves all legacy prayer settings untouched.
class PrayerFeatureSettingsCodec {
  const PrayerFeatureSettingsCodec();

  Map<String, Object?> encode(PrayerFeatureSettings settings) => {
    'version': 1,
    'features': {
      for (final feature in PrayerFeature.values)
        feature.name: {
          'enabled': settings[feature].enabled,
          if (feature.hasTiming) ...{
            'minutes': settings[feature].minutes,
            'overrides': {
              for (final entry in settings[feature].overrides.entries)
                entry.key.name: {
                  'enabled': entry.value.enabled,
                  if (entry.value.minutes != null)
                    'minutes': entry.value.minutes,
                },
            },
          },
        },
    },
  };

  PrayerFeatureSettings decode(Object? value) {
    if (value is! Map || value['version'] != 1) {
      return PrayerFeatureSettings();
    }
    final features = value['features'];
    if (features is! Map) return PrayerFeatureSettings();
    return PrayerFeatureSettings(
      preferences: {
        for (final feature in PrayerFeature.values)
          feature: _decodePreference(features[feature.name], feature),
      },
    );
  }

  PrayerFeaturePreferences _decodePreference(
    Object? value,
    PrayerFeature feature,
  ) {
    final map = value is Map ? value : const {};
    final overrides = <PrayerId, PrayerOverride>{};
    final rawOverrides = map['overrides'];
    if (feature.hasTiming && rawOverrides is Map) {
      for (final prayer in PrayerId.values) {
        final raw = rawOverrides[prayer.name];
        if (raw is! Map) continue;
        overrides[prayer] = PrayerOverride(
          enabled: raw['enabled'] is bool ? raw['enabled'] as bool : true,
          minutes: _validMinutes(raw['minutes'], feature),
        );
      }
    }
    return PrayerFeaturePreferences(
      enabled: map['enabled'] == true,
      minutes: feature.hasTiming
          ? _validMinutes(map['minutes'], feature) ?? feature.defaultMinutes
          : null,
      overrides: overrides,
    );
  }

  int? _validMinutes(Object? value, PrayerFeature feature) =>
      value is int && value >= 1 && value <= feature.maxMinutes! ? value : null;
}
