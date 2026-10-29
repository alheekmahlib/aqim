import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/services/adhan_alarms_scheduler.dart';
import '../../../../core/services/notification_permission_cache.dart';
import '../../../../core/services/prayer_silence_access.dart';
import '../../prayers.dart';
import '../data/adhan_audio_prober.dart';
import '../data/custom_adhan_selector.dart';
import '../data/darwin_notification_sound.dart';
import '../data/in_app_adhan_session.dart';
import '../data/local_adhan_playback_control.dart';
import '../data/local_adhan_stop_gestures.dart';
import '../data/stored_custom_adhan_repository.dart';
import '../domain/custom_adhan_repository.dart';
import '../data/pending_prayer_feature_capabilities.dart';
import '../data/prayer_feature_capabilities_policy.dart';
import '../data/stored_prayer_feature_settings.dart';
import '../domain/prayer_feature.dart';
import '../domain/prayer_feature_capabilities.dart';
import '../domain/prayer_feature_settings.dart';
import '../domain/prayer_feature_settings_repository.dart';
import '../domain/save_prayer_feature_settings.dart';
import 'custom_adhan_controller.dart';
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
          isIOSPlatform: () => Platform.isIOS,
        ),
        permanent: true,
      );
    }
    // المؤذن المخصص (المرحلة الخامسة): مستودع دائم ومحدد ومتحكم.
    if (!Get.isRegistered<CustomAdhanRepository>()) {
      const darwinSound = DarwinNotificationSound();
      Get.put<CustomAdhanRepository>(
        StoredCustomAdhanRepository(
          baseDirectory: () async {
            final docs = await getApplicationDocumentsDirectory();
            final dir = Directory(
              '${docs.path}${Platform.pathSeparator}custom_adhan',
            );
            return dir;
          },
          storage: GetStorage(),
          probeDuration: const AdhanAudioProber().probe,
          prepareNotificationCopy: (sourcePath, id) =>
              darwinSound.prepare(sourcePath: sourcePath, id: id),
          removeNotificationCopy: darwinSound.remove,
        ),
        permanent: true,
      );
    }
    final customSelector = CustomAdhanSelector(
      adhanSounds: GetStorage('AdhanSounds'),
      preferences: GetStorage(),
    );
    if (!Get.isRegistered<CustomAdhanController>()) {
      Get.lazyPut<CustomAdhanController>(
        () => CustomAdhanController(
          repository: Get.find<CustomAdhanRepository>(),
          selector: customSelector,
          pickAudioFile: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions:
                  StoredCustomAdhanRepository.supportedExtensions,
            );
            return result?.files.single.path;
          },
          reschedule: PrayersNotificationsCtrl.instance.reschedulePrayers,
          selectStandardAdhan: (index) async =>
              PrayersNotificationsCtrl.instance.switchAdhanOnTap(index),
          probeForPreview: const AdhanAudioProber().probe,
        ),
        fenix: true,
      );
    }

    // الإيقاف الموحد وإيماءات المرحلة الرابعة.
    final repository = Get.find<PrayerFeatureSettingsRepository>();
    final playbackControl = LocalAdhanPlaybackControl(
      stopNativeService: AdhanAlarmsScheduler.stopPlayback,
      stopInAppPlayer: () async {
        if (Get.isRegistered<PrayersNotificationsCtrl>()) {
          await PrayersNotificationsCtrl.instance.state.adhanPlayer.stop();
        }
      },
    );
    InAppAdhanSession.instance.configure(
      flipEnabled: () => repository.read()[PrayerFeature.flipToStop].enabled,
      onStopRequested: playbackControl.stopCurrentAdhan,
    );
    AdhanStopChannelHandler(
      onStopFromVolumeKey: playbackControl.stopCurrentAdhan,
    ).register();
    _synchronizeStopGestures(repository.read());

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

  // تعطيل المؤذن المخصص مع وجود مختار نشط: عودة لآخر قياسي صالح
  // وإعادة الجدولة.
  if (previous[PrayerFeature.customAdhan].enabled &&
      !next[PrayerFeature.customAdhan].enabled &&
      Get.isRegistered<CustomAdhanController>()) {
    await Get.find<CustomAdhanController>().fallbackToStandard();
  }

  // إيماءات الإيقاف: تفعيل/تعطيل أي منهما يُحدَّث في المنصة فورًا.
  if (previous[PrayerFeature.flipToStop].enabled !=
          next[PrayerFeature.flipToStop].enabled ||
      previous[PrayerFeature.volumeToStop].enabled !=
          next[PrayerFeature.volumeToStop].enabled) {
    _synchronizeStopGestures(next);
  }
}

void _synchronizeStopGestures(PrayerFeatureSettings settings) {
  LocalAdhanStopGestures(
    flipEnabled: settings[PrayerFeature.flipToStop].enabled,
    volumeEnabled: settings[PrayerFeature.volumeToStop].enabled,
  ).synchronize();
}
