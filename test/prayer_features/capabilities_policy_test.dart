import 'package:aqim/presentation/prayers/features/data/pending_prayer_feature_capabilities.dart';
import 'package:aqim/presentation/prayers/features/data/prayer_feature_capabilities_policy.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature_availability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PrayerFeatureCapabilitiesPolicy policy({
    required bool isAndroid,
    required bool isIOS,
    required bool isMacOS,
    required bool granted,
    bool dndGranted = false,
    bool silenceSupported = true,
  }) => PrayerFeatureCapabilitiesPolicy(
    pending: PendingPrayerFeatureCapabilities(
      isAndroid: isAndroid,
      isIOS: isIOS,
      isMacOS: isMacOS,
    ),
    notificationPermissionGranted: () => granted,
    silenceSupported: () => silenceSupported,
    dndAccessGranted: () => dndGranted,
  );

  test('reminder becomes available once notifications are granted', () {
    for (final platform in [
      (android: true, ios: false, mac: false),
      (android: false, ios: true, mac: false),
      (android: false, ios: false, mac: true),
    ]) {
      final caps = policy(
        isAndroid: platform.android,
        isIOS: platform.ios,
        isMacOS: platform.mac,
        granted: true,
      );
      expect(
        caps.availability(PrayerFeature.reminder),
        PrayerFeatureAvailability.available,
      );
      final denied = policy(
        isAndroid: platform.android,
        isIOS: platform.ios,
        isMacOS: platform.mac,
        granted: false,
      );
      expect(
        denied.availability(PrayerFeature.reminder),
        PrayerFeatureAvailability.needsPermission,
      );
    }
  });

  test('reminder stays unsupported on other platforms even when granted', () {
    final caps = policy(
      isAndroid: false,
      isIOS: false,
      isMacOS: false,
      granted: true,
    );
    expect(
      caps.availability(PrayerFeature.reminder),
      PrayerFeatureAvailability.unsupported,
    );
  });

  test('silence mirrors DND access on Android', () {
    final granted = policy(
      isAndroid: true,
      isIOS: false,
      isMacOS: false,
      granted: true,
      dndGranted: true,
    );
    expect(
      granted.availability(PrayerFeature.silence),
      PrayerFeatureAvailability.available,
    );
    final denied = policy(
      isAndroid: true,
      isIOS: false,
      isMacOS: false,
      granted: true,
      dndGranted: false,
    );
    expect(
      denied.availability(PrayerFeature.silence),
      PrayerFeatureAvailability.needsPermission,
    );
  });

  test('silence is unsupported below Android 10 even with access', () {
    final caps = policy(
      isAndroid: true,
      isIOS: false,
      isMacOS: false,
      granted: true,
      dndGranted: true,
      silenceSupported: false,
    );
    expect(
      caps.availability(PrayerFeature.silence),
      PrayerFeatureAvailability.unsupported,
    );
  });

  test('silence stays unsupported off-Android regardless of access', () {
    for (final platform in [(ios: true, mac: false), (ios: false, mac: true)]) {
      final caps = policy(
        isAndroid: false,
        isIOS: platform.ios,
        isMacOS: platform.mac,
        granted: true,
        dndGranted: true,
      );
      expect(
        caps.availability(PrayerFeature.silence),
        PrayerFeatureAvailability.unsupported,
      );
    }
  });

  test('native features of later stages remain pending', () {
    final caps = policy(
      isAndroid: true,
      isIOS: false,
      isMacOS: false,
      granted: true,
    );
    expect(
      caps.availability(PrayerFeature.flipToStop),
      PrayerFeatureAvailability.comingSoon,
    );
    expect(
      caps.availability(PrayerFeature.volumeToStop),
      PrayerFeatureAvailability.comingSoon,
    );
    expect(
      caps.availability(PrayerFeature.customAdhan),
      PrayerFeatureAvailability.comingSoon,
    );
  });
}
