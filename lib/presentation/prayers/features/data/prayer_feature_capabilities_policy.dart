import '../domain/prayer_feature.dart';
import '../domain/prayer_feature_availability.dart';
import '../domain/prayer_feature_capabilities.dart';
import 'pending_prayer_feature_capabilities.dart';

/// سياسة الإتاحة بعد ربط التذكير (المرحلة الثانية) والتصميت (الثالثة):
/// التذكير متاح متى مُنح إذن الإشعارات، والتصميت متاح على أندرويد 10+
/// متى مُنح وصول عدم الإزعاج، وإلا فيعرضان حالة الحاجة للإذن. تبقى بقية
/// المميزات الأصلية معلّقة (comingSoon) حتى مرحلتها.
class PrayerFeatureCapabilitiesPolicy implements PrayerFeatureCapabilities {
  const PrayerFeatureCapabilitiesPolicy({
    required this.pending,
    required this.notificationPermissionGranted,
    required this.silenceSupported,
    required this.dndAccessGranted,
    required this.isIOSPlatform,
  });

  final PendingPrayerFeatureCapabilities pending;
  final bool Function() notificationPermissionGranted;
  final bool Function() silenceSupported;
  final bool Function() dndAccessGranted;
  final bool Function() isIOSPlatform;

  @override
  PrayerFeatureAvailability availability(PrayerFeature feature) {
    final pendingAvailability = pending.availability(feature);
    if (pendingAvailability == PrayerFeatureAvailability.unsupported) {
      return pendingAvailability;
    }
    switch (feature) {
      case PrayerFeature.reminder:
        return notificationPermissionGranted()
            ? PrayerFeatureAvailability.available
            : PrayerFeatureAvailability.needsPermission;
      case PrayerFeature.silence:
        if (!silenceSupported()) return PrayerFeatureAvailability.unsupported;
        return dndAccessGranted()
            ? PrayerFeatureAvailability.available
            : PrayerFeatureAvailability.needsPermission;
      case PrayerFeature.flipToStop:
        // القلب يعمل داخل التطبيق على المنصتين المدعومتين.
        return PrayerFeatureAvailability.available;
      case PrayerFeature.volumeToStop:
        // أزرار الصوت تُستقبل في الواجهة النشطة على أندرويد فقط؛
        // iOS لا تسمح باعتراضها بواجهة عامة فتُعرض بلا وعد كاذب.
        return isIOSPlatform()
            ? PrayerFeatureAvailability.unsupported
            : PrayerFeatureAvailability.available;
      default:
        return pendingAvailability;
    }
  }
}
