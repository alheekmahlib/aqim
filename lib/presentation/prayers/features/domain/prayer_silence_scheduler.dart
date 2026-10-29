import 'prayer_feature_preferences.dart';

/// Stage 3 adapter reads iqama times independently of notification preferences.
/// Cancellation must also end the app's active rule, never another owner's rule.
abstract interface class PrayerSilenceScheduler {
  Future<void> synchronize(PrayerFeaturePreferences preferences);
  Future<void> endAndCancelSilence();
}
