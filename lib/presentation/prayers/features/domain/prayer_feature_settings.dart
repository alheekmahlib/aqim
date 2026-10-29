import 'prayer_feature.dart';
import 'prayer_feature_preferences.dart';

class PrayerFeatureSettings {
  PrayerFeatureSettings({
    Map<PrayerFeature, PrayerFeaturePreferences> preferences = const {},
  }) : preferences = Map.unmodifiable({
         for (final feature in PrayerFeature.values)
           feature:
               preferences[feature] ??
               PrayerFeaturePreferences(minutes: feature.defaultMinutes),
       });

  final Map<PrayerFeature, PrayerFeaturePreferences> preferences;

  PrayerFeaturePreferences operator [](PrayerFeature feature) =>
      preferences[feature]!;

  PrayerFeatureSettings withPreference(
    PrayerFeature feature,
    PrayerFeaturePreferences preference,
  ) =>
      PrayerFeatureSettings(preferences: {...preferences, feature: preference});
}
