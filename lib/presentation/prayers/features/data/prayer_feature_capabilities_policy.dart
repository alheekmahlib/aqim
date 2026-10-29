import '../domain/prayer_feature.dart';
import '../domain/prayer_feature_availability.dart';
import '../domain/prayer_feature_capabilities.dart';
import 'pending_prayer_feature_capabilities.dart';

/// سياسة الإتاحة بعد ربط التذكير (المرحلة الثانية): التذكير متاح فعليًا
/// متى مُنح إذن الإشعارات على منصة مدعومة، وإلا فيعرض حالة الحاجة للإذن.
/// تبقى المميزات الأصلية الأخرى معلّقة (comingSoon) حتى مرحلتها.
class PrayerFeatureCapabilitiesPolicy implements PrayerFeatureCapabilities {
  const PrayerFeatureCapabilitiesPolicy({
    required this.pending,
    required this.notificationPermissionGranted,
  });

  final PendingPrayerFeatureCapabilities pending;
  final bool Function() notificationPermissionGranted;

  @override
  PrayerFeatureAvailability availability(PrayerFeature feature) {
    final pendingAvailability = pending.availability(feature);
    if (feature != PrayerFeature.reminder) return pendingAvailability;
    if (pendingAvailability == PrayerFeatureAvailability.unsupported) {
      return pendingAvailability;
    }
    return notificationPermissionGranted()
        ? PrayerFeatureAvailability.available
        : PrayerFeatureAvailability.needsPermission;
  }
}
