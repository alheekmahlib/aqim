class PrayerOverride {
  const PrayerOverride({this.enabled = true, this.minutes});

  final bool enabled;

  /// Null inherits the global duration, even when this prayer is excluded.
  final int? minutes;
}
