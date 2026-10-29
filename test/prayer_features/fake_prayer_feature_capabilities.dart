import 'package:aqim/presentation/prayers/features/domain/prayer_feature.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature_availability.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature_capabilities.dart';

class FakePrayerFeatureCapabilities implements PrayerFeatureCapabilities {
  FakePrayerFeatureCapabilities({
    this.value = PrayerFeatureAvailability.available,
  });

  PrayerFeatureAvailability value;

  @override
  PrayerFeatureAvailability availability(PrayerFeature feature) => value;
}
