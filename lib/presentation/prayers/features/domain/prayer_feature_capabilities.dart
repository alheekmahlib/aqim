import 'prayer_feature.dart';
import 'prayer_feature_availability.dart';

abstract interface class PrayerFeatureCapabilities {
  PrayerFeatureAvailability availability(PrayerFeature feature);
}
