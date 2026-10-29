import 'prayer_feature_settings.dart';

abstract interface class PrayerFeatureSettingsRepository {
  PrayerFeatureSettings read();
  Future<void> save(PrayerFeatureSettings settings);
}
