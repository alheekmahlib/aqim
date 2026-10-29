import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../core/services/notification_permission_cache.dart';
import '../../prayers.dart';
import '../data/pending_prayer_feature_capabilities.dart';
import '../data/prayer_feature_capabilities_policy.dart';
import '../data/stored_prayer_feature_settings.dart';
import '../domain/prayer_feature.dart';
import '../domain/prayer_feature_capabilities.dart';
import '../domain/prayer_feature_settings.dart';
import '../domain/prayer_feature_settings_repository.dart';
import '../domain/save_prayer_feature_settings.dart';
import 'prayer_feature_settings_controller.dart';

class PrayerFeaturesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PrayerFeatureSettingsRepository>()) {
      Get.put<PrayerFeatureSettingsRepository>(
        StoredPrayerFeatureSettings(GetStorage()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<NotificationPermissionCache>()) {
      final cache = Get.put<NotificationPermissionCache>(
        NotificationPermissionCache(),
        permanent: true,
      );
      unawaited(cache.refresh());
    }
    if (!Get.isRegistered<PrayerFeatureCapabilities>()) {
      Get.put<PrayerFeatureCapabilities>(
        PrayerFeatureCapabilitiesPolicy(
          pending: PendingPrayerFeatureCapabilities(
            isAndroid: Platform.isAndroid,
            isIOS: Platform.isIOS,
            isMacOS: Platform.isMacOS,
          ),
          notificationPermissionGranted: () =>
              Get.find<NotificationPermissionCache>().granted,
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<PrayerFeatureSettingsController>()) {
      Get.lazyPut<PrayerFeatureSettingsController>(
        () => PrayerFeatureSettingsController(
          repository: Get.find<PrayerFeatureSettingsRepository>(),
          capabilities: Get.find<PrayerFeatureCapabilities>(),
          save: SavePrayerFeatureSettings(
            Get.find<PrayerFeatureSettingsRepository>(),
            Get.find<PrayerFeatureCapabilities>(),
          ),
          refreshAvailability: Get.find<NotificationPermissionCache>().refresh,
          onSaved: _synchronizeRemindersAfterSave,
        ),
        fenix: true,
      );
    }
  }
}

/// أثر حفظ الإعدادات على التذكيرات: تفعيل/تعطيل الميزة على iOS يغيّر عدد
/// الخانات المحجوزة فيُعاد أفق الأذان كاملًا؛ وما عدا ذلك مزامنة للتذكير.
Future<void> _synchronizeRemindersAfterSave(
  PrayerFeatureSettings previous,
  PrayerFeatureSettings next,
) async {
  final before = previous[PrayerFeature.reminder];
  final after = next[PrayerFeature.reminder];
  if (before.enabled != after.enabled && Platform.isIOS) {
    await PrayersNotificationsCtrl.instance.reschedulePrayers();
    return;
  }
  if (before.enabled || after.enabled) {
    await PrayersNotificationsCtrl.instance.synchronizePrayerReminders();
  }
}
