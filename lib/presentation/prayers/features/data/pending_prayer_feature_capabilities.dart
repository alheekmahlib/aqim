import '../domain/prayer_feature.dart';
import '../domain/prayer_feature_availability.dart';
import '../domain/prayer_feature_capabilities.dart';

/// No platform functionality is wired in stage 1. Subsequent stages replace
/// this policy with tested availability and real permission checks.
class PendingPrayerFeatureCapabilities implements PrayerFeatureCapabilities {
  const PendingPrayerFeatureCapabilities({
    required this.isAndroid,
    required this.isIOS,
    required this.isMacOS,
  });

  final bool isAndroid;
  final bool isIOS;
  final bool isMacOS;

  @override
  PrayerFeatureAvailability availability(PrayerFeature feature) {
    final supported = switch (feature) {
      PrayerFeature.silence => isAndroid,
      PrayerFeature.flipToStop ||
      PrayerFeature.volumeToStop => isAndroid || isIOS,
      PrayerFeature.reminder ||
      PrayerFeature.customAdhan => isAndroid || isIOS || isMacOS,
    };
    return supported
        ? PrayerFeatureAvailability.comingSoon
        : PrayerFeatureAvailability.unsupported;
  }
}
