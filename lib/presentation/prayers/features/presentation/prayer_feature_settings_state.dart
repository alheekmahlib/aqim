import '../domain/prayer_feature_settings.dart';

class PrayerFeatureSettingsState {
  const PrayerFeatureSettingsState({
    required this.settings,
    this.saving = false,
    this.loadFailed = false,
    this.errorKey,
  });

  final PrayerFeatureSettings settings;
  final bool saving;
  final bool loadFailed;
  final String? errorKey;
}
