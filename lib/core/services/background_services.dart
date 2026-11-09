// ignore_for_file: avoid_log

import 'dart:async';
import 'dart:developer' show log;
import 'dart:io' show Platform;

import 'package:background_fetch/background_fetch.dart';
import 'package:connectivity_kit/connectivity_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '/core/services/prayer_background_manager.dart';
import '../../presentation/feedback/controller/feedback_controller.dart';
import '../../presentation/prayers/features/presentation/prayer_features_binding.dart';
import '../../presentation/prayers/prayers.dart';
import '../widgets/home_widget/home_widget.dart';
import '../widgets/local_notification/controller/local_notifications_controller.dart';
import 'location/locations.dart';

/// مُعالج المهام في الخلفية (headless)
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessEvent task) async {
  final taskId = task.taskId;
  if (task.timeout) {
    log('Headless task timed-out: $taskId', name: 'Background service');
    _timedOutTasks.add(taskId);
    BackgroundFetch.finish(taskId);
    return;
  }
  log('Headless event received: $taskId', name: 'Background service');
  try {
    BGServices.isHeadless = true;
    WidgetsFlutterBinding.ensureInitialized();
    await GetStorage.init();
    await GetStorage.init('AdhanSounds');
    if (_timedOutTasks.contains(taskId)) return;
    Location.instance.restoreFromStorage();
    if (!Get.isRegistered<ConnectionController>()) {
      Get.put(ConnectionController(), permanent: true);
    }
    PrayerFeaturesBinding().dependencies();
    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      log('Unable to set local timezone: $e', name: 'Background service');
    }
    if (_timedOutTasks.contains(taskId)) return;
    await AdhanController.instance.initializeStoredAdhan();
    if (_timedOutTasks.contains(taskId)) return;
    await _executeBackgroundTask(taskId);
  } catch (e, stack) {
    log(
      'Headless task failed: $e',
      name: 'Background service',
      stackTrace: stack,
    );
  } finally {
    if (!_timedOutTasks.remove(taskId)) BackgroundFetch.finish(taskId);
  }
}

class BGServices {
  static bool isHeadless = false;
  static Timer? _midnightTimer;

  Future<void> registerTask() async {
    await BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

    await BackgroundFetch.configure(
          BackgroundFetchConfig(
            minimumFetchInterval: 20,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.NONE,
          ),
          _onFetch,
          _onTimeOut,
        )
        .then((int status) {
          log('configure success: $status', name: 'Background service');
        })
        .catchError((e) {
          log('configure ERROR: $e', name: 'Background service');
        });

    await BackgroundFetch.start()
        .then((v) async {
          await _executeBackgroundTask('initial');
          log('Background Service Started $v', name: 'Background service');
        })
        .catchError((e) {
          log('Error on Background Service $e', name: 'Background service');
        });

    if (Platform.isAndroid) {
      // Remove the redundant task installed by earlier versions.
      try {
        await BackgroundFetch.stop('com.transistorsoft.fetchNotifications');
      } catch (e) {
        log('Could not remove old task: $e', name: 'Background service');
      }
    }

    // جدولة Timer منتصف الليل في الواجهة الأمامية
    scheduleForegroundMidnightTimer();
  }

  /// جدولة Timer في الواجهة الأمامية لتحديث الودجت عند منتصف الليل
  static void scheduleForegroundMidnightTimer() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 1);
    final delay = nextMidnight.difference(now);

    _midnightTimer = Timer(delay, () async {
      log(
        'Foreground midnight timer fired at ${DateTime.now()}',
        name: 'Background service',
      );
      await _executeBackgroundTask('foreground_midnight');
      // إعادة جدولة Timer التالي
      scheduleForegroundMidnightTimer();
    });

    log(
      'Foreground midnight timer scheduled for $nextMidnight (${delay.inMinutes} min)',
      name: 'Background service',
    );
  }

  /// إلغاء Timer منتصف الليل
  static void cancelForegroundMidnightTimer() {
    _midnightTimer?.cancel();
    _midnightTimer = null;
  }
}

/// معالج المهام في الخلفية المحلي (MethodChannel)
class BackgroundTaskHandler {
  static const MethodChannel platform = MethodChannel(
    'com.alheekmah.alheekmahLibrary/background_tasks',
  );

  static Future<void> initializeHandler() async {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'performDailyTasks') {
        await PrayerBackgroundManager.executeDailyTasks();
      } else if (call.method == 'performBackgroundFetch') {
        await _executeBackgroundTask('native_callback');
      }
    });
  }
}

/// المنطق المشترك لجميع المهام — يُستدعى من كل المسارات
bool _backgroundTaskRunning = false;
final Set<String> _timedOutTasks = <String>{};

Future<void> _executeBackgroundTask(String taskId) async {
  final controller = ConnectionController.instance;
  if (_backgroundTaskRunning) {
    log('Skipping overlapping task: $taskId', name: 'Background service');
    return;
  }
  _backgroundTaskRunning = true;
  log('Executing task: $taskId', name: 'Background service');

  try {
    await GetStorage.init();
    final storage = GetStorage();

    // المهام الدورية (إشعارات وغيرها)
    await PrayerBackgroundManager.executePeriodicTasks(
      shouldContinue: () => !_timedOutTasks.contains(taskId),
    );
    if (_timedOutTasks.contains(taskId)) return;

    // فحص ردود المشرف على ملاحظات المستخدم (مثل تطبيق القرآن).
    try {
      if (controller.isOnline) {
        await FeedbackController.checkNewRepliesBackground();
        final today = DateTime.now().toIso8601String().substring(0, 10);
        if (storage.read('last_background_posts_date') != today &&
            await LocalNotificationsController.instance
                .fetchNewNotifications()) {
          await storage.write('last_background_posts_date', today);
        }
      }
    } catch (e) {
      log('feedback replies check failed: $e', name: 'Background service');
    }
    if (_timedOutTasks.contains(taskId)) return;

    // التحقق من تغيّر التاريخ (يوم جديد بعد منتصف الليل)
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = storage.read('last_widget_update_date') as String?;

    if (lastDate == null || lastDate != today) {
      log(
        'New day detected ($lastDate -> $today), updating prayers & widget',
        name: 'Background service',
      );

      // محاولة إعادة حساب أوقات الصلاة لليوم الجديد
      try {
        await AdhanController.instance.initializeStoredAdhan(
          forceUpdate: false,
        );
      } catch (e) {
        log(
          'initializeStoredAdhan failed (will try cache fallback): $e',
          name: 'Background service',
        );
      }
      if (Platform.isIOS || Platform.isAndroid) {
        // await HijriWidgetConfig.initialize();
        await PrayersWidgetConfig.initialize();
        // await HijriWidgetConfig().updateHijriDate();
        await PrayersWidgetConfig().updatePrayersDate();
      }

      // لا نكتب التاريخ إلا إذا نجح تحديث ويدجت الصلوات فعلاً
      if (PrayersWidgetConfig.lastUpdateSucceeded) {
        await storage.write('last_widget_update_date', today);
      } else {
        log(
          'Prayer widget update failed — will retry on next background task',
          name: 'Background service',
        );
      }
    }
  } catch (e) {
    log('Error in background task ($taskId): $e', name: 'Background service');
  } finally {
    _backgroundTaskRunning = false;
  }
}

Future<void> _onFetch(String taskId) async {
  log('Event received $taskId', name: 'Background service');
  try {
    await _executeBackgroundTask(taskId);
  } finally {
    if (!_timedOutTasks.remove(taskId)) BackgroundFetch.finish(taskId);
  }
}

Future<void> _onTimeOut(String taskId) async {
  log('Task timeout: $taskId', name: 'Background service');
  _timedOutTasks.add(taskId);
  BackgroundFetch.finish(taskId);
}
