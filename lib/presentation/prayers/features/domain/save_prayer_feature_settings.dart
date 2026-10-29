import 'prayer_feature.dart';
import 'prayer_feature_availability.dart';
import 'prayer_feature_capabilities.dart';
import 'prayer_feature_settings.dart';
import 'prayer_feature_settings_repository.dart';

class SavePrayerFeatureSettings {
  const SavePrayerFeatureSettings(this._repository, this._capabilities);

  final PrayerFeatureSettingsRepository _repository;
  final PrayerFeatureCapabilities _capabilities;

  Future<void> call(PrayerFeatureSettings settings) async {
    for (final feature in PrayerFeature.values) {
      final preference = settings[feature];
      if (preference.enabled &&
          _capabilities.availability(feature) !=
              PrayerFeatureAvailability.available) {
        throw StateError('Feature is not available: ${feature.name}');
      }
      if (feature.hasTiming) {
        _validateMinutes(preference.minutes, feature);
        for (final override in preference.overrides.values) {
          if (override.minutes != null) {
            _validateMinutes(override.minutes, feature);
          }
        }
      } else if (preference.minutes != null ||
          preference.overrides.isNotEmpty) {
        throw ArgumentError('Only timed features accept prayer overrides');
      }
    }
    await _repository.save(settings);
  }

  void _validateMinutes(int? minutes, PrayerFeature feature) {
    if (minutes == null || minutes < 1 || minutes > feature.maxMinutes!) {
      throw ArgumentError.value(minutes, '${feature.name} minutes');
    }
  }
}
