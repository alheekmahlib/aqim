import '../domain/prayer_feature.dart';
import '../domain/prayer_feature_availability.dart';
import '../domain/prayer_id.dart';

extension PrayerFeatureLabels on PrayerFeature {
  String get titleKey => switch (this) {
    PrayerFeature.silence => 'prayerFeaturesSilence',
    PrayerFeature.reminder => 'prayerFeaturesReminder',
    PrayerFeature.flipToStop => 'prayerFeaturesFlip',
    PrayerFeature.volumeToStop => 'prayerFeaturesVolume',
    PrayerFeature.customAdhan => 'prayerFeaturesCustomAdhan',
  };

  String get timingTitleKey => this == PrayerFeature.silence
      ? 'prayerFeaturesSilenceDuration'
      : 'prayerFeaturesReminderMinutes';

  String statusKey(PrayerFeatureAvailability availability, bool enabled) =>
      switch (availability) {
        PrayerFeatureAvailability.available =>
          enabled ? 'prayerFeaturesEnabled' : 'prayerFeaturesDisabled',
        PrayerFeatureAvailability.needsPermission =>
          'prayerFeaturesNeedsPermission',
        PrayerFeatureAvailability.unsupported =>
          this == PrayerFeature.silence
              ? 'prayerFeaturesFocusHint'
              : 'prayerFeaturesUnsupported',
        PrayerFeatureAvailability.comingSoon => 'prayerFeaturesComingSoon',
      };
}

extension PrayerIdLabels on PrayerId {
  String get titleKey => switch (this) {
    PrayerId.fajr => 'Fajr',
    PrayerId.dhuhr => 'Dhuhr',
    PrayerId.asr => 'Asr',
    PrayerId.maghrib => 'Maghrib',
    PrayerId.isha => 'Isha',
  };
}
