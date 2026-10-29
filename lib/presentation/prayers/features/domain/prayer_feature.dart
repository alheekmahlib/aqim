/// Stable identifiers used by storage and the platform adapters.
enum PrayerFeature {
  silence(defaultMinutes: 20, maxMinutes: 120),
  reminder(defaultMinutes: 10, maxMinutes: 60),
  flipToStop,
  volumeToStop,
  customAdhan;

  const PrayerFeature({this.defaultMinutes, this.maxMinutes});

  final int? defaultMinutes;
  final int? maxMinutes;
  bool get hasTiming => defaultMinutes != null;
}
