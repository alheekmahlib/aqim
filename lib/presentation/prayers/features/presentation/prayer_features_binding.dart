import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../core/services/notification_permission_cache.dart';
import '../../../../core/services/prayer_silence_access.dart';
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
    if (!Get.isRegistered<PrayerSilenceAccess>()) {
      final access = Get.put<PrayerSilenceAccess>(
        PrayerSilenceAccess(),
        permanent: true,
      );
      unawaited(access.refresh());
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
          silenceSupported: () => Get.find<PrayerSilenceAccess>().supported,
          dndAccessGranted: () => Get.find<PrayerSilenceAccess>().granted,
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
          refreshAvailability: () => Future.wait([
            Get.find<NotificationPermissionCache>().refresh(),
            Get.find<PrayerSilenceAccess>().refresh(),
          ]),
          openDndSettings: Get.find<PrayerSilenceAccess>().openSettings,
          onSaved: _applySettingsSideEffects,
        ),
        fenix: true,
      );
    }
  }
}

/// أثر حفظ الإعدادات:
/// - التذكير: تفعيل/تعطيل على iOS يغيّر الخانات المحجوزة فيُعاد أفق الأذان
///   كاملًا؛ وما عدا ذلك مزامنة للتذكير وحده.
/// - التصميت: أي تغيير (تفعيل أو مدة أو استثناء) يعيد مزامنة الفترات؛
///   وتعديل الإقامات يمر عبر reschedulePrayers.
Future<void> _applySettingsSideEffects(
  PrayerFeatureSettings previous,
  PrayerFeatureSettings next,
) async {
  final reminderBefore = previous[PrayerFeature.reminder];
  final reminderAfter = next[PrayerFeature.reminder];
  if (reminderBefore.enabled != reminderAfter.enabled && Platform.isIOS) {
    await PrayersNotificationsCtrl.instance.reschedulePrayers();
  } else if (reminderBefore.enabled || reminderAfter.enabled) {
    await PrayersNotificationsCtrl.instance.synchronizePrayerReminders();
  }

  final silenceBefore = previous[PrayerFeature.silence];
  final silenceAfter = next[PrayerFeature.silence];
  if (silenceBefore.enabled != silenceAfter.enabled || silenceAfter.enabled) {
    await PrayersNotificationsCtrl.instance.synchronizePrayerSilence();
  }
}
