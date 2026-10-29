import 'prayer_id.dart';
import 'prayer_override.dart';

class PrayerFeaturePreferences {
  PrayerFeaturePreferences({
    this.enabled = false,
    this.minutes,
    Map<PrayerId, PrayerOverride> overrides = const {},
  }) : overrides = Map.unmodifiable(overrides);

  final bool enabled;
  final int? minutes;
  final Map<PrayerId, PrayerOverride> overrides;

  bool includesPrayer(PrayerId prayer) => overrides[prayer]?.enabled ?? true;
  bool isEnabledFor(PrayerId prayer) => enabled && includesPrayer(prayer);
  int? minutesFor(PrayerId prayer) => overrides[prayer]?.minutes ?? minutes;

  PrayerFeaturePreferences copyWith({
    bool? enabled,
    int? minutes,
    Map<PrayerId, PrayerOverride>? overrides,
  }) => PrayerFeaturePreferences(
    enabled: enabled ?? this.enabled,
    minutes: minutes ?? this.minutes,
    overrides: overrides ?? this.overrides,
  );

  PrayerFeaturePreferences withOverride(
    PrayerId prayer,
    PrayerOverride? value,
  ) {
    final updated = Map<PrayerId, PrayerOverride>.of(overrides);
    if (value == null) {
      updated.remove(prayer);
    } else {
      updated[prayer] = value;
    }
    return copyWith(overrides: updated);
  }
}
