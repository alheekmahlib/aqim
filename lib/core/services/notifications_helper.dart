import 'dart:async';
import 'dart:developer' show log;
import 'dart:io' show Platform;

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../presentation/feedback/controller/feedback_controller.dart';
import '../../presentation/prayers/prayers.dart';
import '../utils/constants/lists.dart';
import '../utils/helpers/app_router.dart';
import '../utils/constants/shared_preferences_constants.dart';
import '../widgets/local_notification/controller/local_notifications_controller.dart';
import 'adhan_alarms_scheduler.dart';
import 'local_notifications_service.dart';
import 'notification_permission_cache.dart';

export 'local_notifications_service.dart' show LocalReceivedNotification;

class NotifyHelper {
  static bool _initialized = false;
  String get audioPath =>
      GetStorage('AdhanSounds').read<String?>(ADHAN_PATH) ??
      'resource://raw/aqsa_athan';
  String get audioFajirPath =>
      GetStorage('AdhanSounds').read<String?>(ADHAN_PATH_FAJIR) ??
      'resource://raw/aqsa_fajir_athan';

  static const String _permissionFlagKey = 'notifications_permission_granted';
  static const String _notificationSetupSeenKey = 'notification_setup_seen';

  bool get isAllowed => GetStorage().read<bool>(_permissionFlagKey) ?? false;

  /// تحقق مما إذا كان المستخدم قد شاهد شاشة تفعيل الإشعارات من قبل
  bool get hasSeenNotificationSetup =>
      GetStorage().read<bool>(_notificationSetupSeenKey) ?? false;

  /// تعيين أن المستخدم قد شاهد شاشة تفعيل الإشعارات
  void markNotificationSetupAsSeen() {
    GetStorage().write(_notificationSetupSeenKey, true);
    log('Marked notification setup as seen', name: 'NotifyHelper');
  }

  /// تهيئة خدمة الإشعارات الموحدة (flutter_local_notifications) لكل المنصات.
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await LocalNotificationsService.instance.initialize(
      onTap: _handleNotificationTap,
    );
    _initialized = true;
    unawaited(_routeDeferredTaps());
  }

  /// توجيه النقر: نفس منطق awesome_notifications السابق.
  static Future<void> _handleNotificationTap(
    LocalReceivedNotification notification,
  ) async {
    log(
      'Received Action: ${notification.title} '
      'Received Action ID: ${notification.id}',
      name: 'NotifyHelper',
    );
    // إشعار رد مشرف على ملاحظة → افتح المحادثة مباشرة.
    if (notification.payload['type'] == 'feedback_reply') {
      final token = notification.payload['feedback_token'];
      if (token != null && token.isNotEmpty) {
        await FeedbackController.instance.openConversation(token);
        Get.toNamed(AppRouter.feedbackConversation);
      }
      return;
    }
    // تذكير ما قبل الصلاة → افتح شاشة الصلاة دون تشغيل الأذان.
    if (notification.payload['type'] == 'prayer_reminder') {
      await Get.toNamed(AppRouter.prayerScreen);
      return;
    }
    if (notification.title != null &&
        prayerListList.contains(notification.title)) {
      await PrayersNotificationsCtrl.instance.onNotificationActionReceived(
        notification,
      );
    }
  }

  /// نقرة وصلت والإقلاع من إشعار أو أثناء الخلفية: تُستهلك بعد جهوزية الواجهة.
  static Future<void> _routeDeferredTaps() async {
    try {
      final launchTap = await LocalNotificationsService.instance
          .consumeLaunchTap();
      final pendingTap =
          launchTap ??
          await LocalNotificationsService.instance.consumePendingTap();
      if (pendingTap == null) return;

      // انتظار سياق الواجهة قبل عرض bottom sheet الأذان.
      if (await _waitForBuildContext()) {
        await _handleNotificationTap(pendingTap);
      }
    } catch (e, stack) {
      log(
        'Error routing deferred notification tap: $e',
        error: e,
        stackTrace: stack,
        name: 'NotifyHelper',
      );
    }
  }

  static Future<bool> _waitForBuildContext({int attempts = 25}) async {
    for (var i = 0; i < attempts; i++) {
      if (Get.context != null) return true;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return Get.context != null;
  }

  // جدولة الإشعار مع الصوت المخصص
  // Schedule notification with custom sound
  Future<void> scheduledNotification({
    required int reminderId,
    required String title,
    required String summary,
    required String body,
    required bool isRepeats,
    DateTime? time,
    Map<String, String?>? payload,
    int? soundIndex,
  }) async {
    final soundType = payload?['sound_type'] ?? 'bell';

    // FLN لا يمرر title/summary في معالج النقر، لذا تُحقن في payload.
    final fullPayload = <String, String?>{
      ...?payload,
      'title': title,
      'summary': summary,
      'fired_at': '${(time ?? DateTime.now()).millisecondsSinceEpoch}',
    };

    // بديل NotificationInterval: جدولة بعد دقيقتين.
    final scheduledTime =
        time ?? DateTime.now().add(const Duration(minutes: 2));

    // نظام معرفات إشعارات الصلوات: 20000 + day*10 + prayerKey (الفجر=0)،
    // فالمعرف المنتهي بصفر ضمن النطاق هو إشعار فجر — له صوته الفجري الخاص.
    final bool isFajrPrayer =
        reminderId >= 20000 && reminderId < 21000 && reminderId % 10 == 0;

    log(
      'audioPath: $audioPath\nsound_type: $soundType\nreminderId: $reminderId',
      name: 'NotifyHelper',
    );

    try {
      await LocalNotificationsService.instance.scheduleNotification(
        id: reminderId,
        title: title,
        body: body,
        summary: summary,
        scheduledTime: scheduledTime,
        soundType: soundType,
        isFajr: isFajrPrayer || reminderId == 0,
        payload: fullPayload,
        badgeNumber: LocalNotificationsController.instance.unreadCount,
        isRepeats: isRepeats,
      );

      // أندرويد: إشعار الأذان صامت؛ خدمة التشغيل الأمامية هي مصدر الصوت،
      // لذا نجدول إنذاراً موازياً بنفس المعرف والوقت — بالنسخة الفجرية للفجر.
      // نمرر بيانات إشعار الصلاة نفسه لتدمج الخدمة إشعارها فيه (إشعار
      // واحد كما في iOS) مع زر إيقاف مترجم أثناء التشغيل.
      if (Platform.isAndroid &&
          soundType == 'sound' &&
          time != null &&
          time.isAfter(DateTime.now())) {
        await AdhanAlarmsScheduler.schedule([
          AdhanAlarm(
            id: reminderId,
            time: time,
            filePath: LocalNotificationsService.selectedAdhanAudioPath(
              fajr: isFajrPrayer,
            ),
            notifId: reminderId,
            notifTitle: title,
            notifText: body,
            stopActionLabel: 'stopAdhan'.tr,
          ),
        ]);
      }

      log(
        'Notification successfully scheduled (id: $reminderId)',
        name: 'NotifyHelper',
      );
    } catch (e, stack) {
      log(
        'Error scheduling notification: $e',
        error: e,
        stackTrace: stack,
        name: 'NotifyHelper',
      );
    }
  }

  Future<void> cancelNotification(int reminderId) async {
    log('Notification ID $reminderId was cancelled', name: 'NotifyHelper');
    if (Platform.isAndroid) {
      await AdhanAlarmsScheduler.cancel([reminderId]);
    }
    return LocalNotificationsService.instance.cancel(reminderId);
  }

  /// طلب صلاحيات الإشعارات لكل المنصات. تُرجع true إذا مُنحت.
  Future<bool> requistPermissions() async {
    if (!_initialized) await ensureInitialized();
    final granted = await LocalNotificationsService.instance
        .requestPermissions();
    await GetStorage().write(_permissionFlagKey, granted);
    // تحديث نسخة الإذن المخبأة لسياسات توفّر المميزات إن سُجّلت.
    if (Get.isRegistered<NotificationPermissionCache>()) {
      unawaited(Get.find<NotificationPermissionCache>().refresh());
    }
    log(
      'Notification permission requested (granted: $granted)',
      name: 'NotifyHelper',
    );
    return granted;
  }

  Future<bool> isNotificationAllowed() async {
    // تحقق أولاً: هل شاهد المستخدم شاشة تفعيل الإشعارات من قبل؟
    // إذا لم يشاهدها، نُرجع false لإظهار الشاشة
    if (hasSeenNotificationSetup) {
      return true;
    }

    try {
      if (!_initialized) {
        await ensureInitialized();
      }
    } catch (_) {}
    return GetStorage().read<bool>(_permissionFlagKey) ?? false;
  }

  /// الشارة تُضبط عبر badgeNumber عند إنشاء كل إشعار (iOS/macOS).
  /// لا توفر flutter_local_notifications واجهة مستقلة لشارة أندرويد
  /// (launcher-specific) — فجوة موثقة في مستند التصميم.
  Future<void> notificationBadgeListener() async {
    log(
      'Badge count: ${LocalNotificationsController.instance.unreadCount} '
      '(applied per-notification on Darwin platforms)',
      name: 'NotifyHelper',
    );
  }

  /// محفوظة للتوافق مع الاستدعاءات القديمة؛
  /// معالجات النقر تُسجَّل داخل ensureInitialized الآن.
  void setNotificationsListeners() {}
}
