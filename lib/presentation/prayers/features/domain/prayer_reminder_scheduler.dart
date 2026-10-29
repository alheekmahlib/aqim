import 'prayer_feature_preferences.dart';

/// Stage 2 adapter owns only pre-prayer notification IDs. It reads the current
/// prayer timetable and skips past reminders when synchronizing.
abstract interface class PrayerReminderScheduler {
  Future<void> synchronize(PrayerFeaturePreferences preferences);
  Future<void> cancelReminders();
}
