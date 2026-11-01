/// Bundled sounds for pre-prayer reminders. Resource names and Android channel
/// IDs are stable so app upgrades preserve the user's notification settings.
class PrayerReminderSound {
  const PrayerReminderSound._(this.prayer, this.label);

  static const values = [
    PrayerReminderSound._('fajr', 'الفجر'),
    PrayerReminderSound._('dhuhr', 'الظهر'),
    PrayerReminderSound._('asr', 'العصر'),
    PrayerReminderSound._('maghrib', 'المغرب'),
    PrayerReminderSound._('isha', 'العشاء'),
  ];

  final String prayer;
  final String label;

  String get resourceName => 'prayer_reminder_$prayer';
  String get iosFileName => '$resourceName.aiff';
  String get androidChannelId => '${resourceName}_v1';
  String get androidChannelName => 'تذكير قبل أذان $label';

  static PrayerReminderSound? fromPayload(
    Map<String, String?> payload, {
    required String? soundType,
  }) {
    if (soundType != 'bell' || payload['type'] != 'prayer_reminder') {
      return null;
    }
    for (final sound in values) {
      if (sound.prayer == payload['prayer']) return sound;
    }
    return null;
  }
}
