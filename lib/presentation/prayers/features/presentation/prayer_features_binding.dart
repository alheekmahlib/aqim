import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/pending_prayer_feature_capabilities.dart';
import '../data/stored_prayer_feature_settings.dart';
import '../domain/prayer_feature_capabilities.dart';
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
    if (!Get.isRegistered<PrayerFeatureCapabilities>()) {
      Get.put<PrayerFeatureCapabilities>(
        PendingPrayerFeatureCapabilities(
          isAndroid: Platform.isAndroid,
          isIOS: Platform.isIOS,
          isMacOS: Platform.isMacOS,
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
        ),
        fenix: true,
      );
    }
  }
}
