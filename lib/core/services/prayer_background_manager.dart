import 'dart:developer' show log;
import 'dart:io' show Platform;

import 'package:connectivity_kit/connectivity_kit.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hijri_date/hijri_date.dart';
import 'package:latlong2/latlong.dart';

import '/core/services/location/locations.dart';
import '/core/services/notifications_helper.dart';
import '/core/services/prayer_countdown_notification_service.dart';
import '/core/widgets/home_widget/home_widget.dart';
import '../../presentation/prayers/prayers.dart';

/// مدير العمليات في الخلفية للصلوات
/// Background operations manager for prayers
class PrayerBackgroundManager {
  static const String _tag = 'PrayerBackgroundManager';

  /// التحقق من أوقات الصلاة وتحديثها إذا لزم الأمر
  /// Check prayer times and update if necessary
  static Future<bool> checkAndUpdatePrayerTimes() async {
    try {
      log('Starting prayer times check...', name: _tag);

      // الحصول على الموقع الحالي
      // Get current location
      final currentLocation = await _getCurrentLocation();
      if (currentLocation == null) {
        log('Unable to get current location', name: _tag);
        return false;
      }

      var resolvedCountry = false;
      final knownPosition = Location.instance.position;
      final controller = ConnectionController.instance;
      if (Location.instance.country.isEmpty &&
          knownPosition != null &&
          (knownPosition.latitude - currentLocation.latitude).abs() <= 0.01 &&
          (knownPosition.longitude - currentLocation.longitude).abs() <= 0.01 &&
          controller.isOnline) {
        try {
          final address = await NominatimReverseGeocodingService.instance
              .reverse(
                latitude: currentLocation.latitude,
                longitude: currentLocation.longitude,
              );
          if (address.country.isNotEmpty && address.country != 'Unknown') {
            Location.instance.updateLocation(
              city: address.city,
              country: address.country,
              position: knownPosition,
            );
            resolvedCountry = true;
          }
        } catch (e) {
          log('Unable to resolve location country: $e', name: _tag);
        }
      }

      // التحقق من صحة التخزين الشهري أولاً
      // Check monthly cache validity first
      final isMonthlyValid = MonthlyPrayerCache.isMonthlyDataValid(
        currentLocation: currentLocation,
      );

      // التحقق من صحة التخزين اليومي
      // Check daily cache validity
      final isDailyValid = PrayerCacheManager.isCacheValid(
        currentLocation: currentLocation,
      );

      if ((isMonthlyValid || isDailyValid) &&
          !(resolvedCountry &&
              AdhanController.instance.state.autoCalculationMethod.value)) {
        log('Prayer times cache is valid, no update needed', name: _tag);
        return false; // لا حاجة للتحديث / No update needed
      }

      log('Prayer times cache is invalid, updating...', name: _tag);

      final previous = Location.instance.position;
      if (previous == null ||
          (previous.latitude - currentLocation.latitude).abs() > 0.01 ||
          (previous.longitude - currentLocation.longitude).abs() > 0.01) {
        Location.instance.updateCoordinates(
          currentLocation.latitude,
          currentLocation.longitude,
        );
        AdhanController.instance.state.localizedCity.value = '';
      }

      // تحديث أوقات الصلاة
      // Update prayer times
      await AdhanController.instance.initializeStoredAdhan(
        newLocation: currentLocation,
        forceUpdate: true,
      );

      // إعادة جدولة الإشعارات
      // Reschedule notifications
      await PrayersNotificationsCtrl.instance.reschedulePrayers();

      log('Prayer times updated successfully', name: _tag);
      return true; // تم التحديث / Updated
    } catch (e) {
      log('Error checking/updating prayer times: $e', name: _tag);
      return false;
    }
  }

  /// الحصول على الموقع الحالي
  /// Get current location
  static Future<LatLng?> _getCurrentLocation() async {
    try {
      final position = await LocationHelper().fetchCurrentPosition;
      if (position != null) {
        return LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      log('Error getting location: $e', name: _tag);
    }
    return PrayerCacheManager.getStoredLocation();
  }

  /// تنفيذ المهام اليومية
  /// Execute daily tasks
  static Future<void> executeDailyTasks({
    bool Function()? shouldContinue,
  }) async {
    try {
      log('Executing daily tasks...', name: _tag);

      // تحديث أوقات الصلاة
      // Update prayer times
      await checkAndUpdatePrayerTimes();
      if (shouldContinue?.call() == false) return;

      // تحديث البيانات الشهرية في الخلفية
      // Update monthly data in background
      await AdhanController.instance.updateMonthlyDataInBackground();
      if (shouldContinue?.call() == false) return;

      // تنظيف البيانات القديمة
      // Clean up old data
      await AdhanController.instance.cleanupOldData();
      if (shouldContinue?.call() == false) return;

      // تحديث التاريخ الهجري في الويدجت
      // Update Hijri date in widget
      // await HijriWidgetConfig().updateHijriDate();

      // جدولة تنبيهات رمضان
      // Schedule Ramadan notifications
      await scheduleRamadanNotificationsIfNeeded();
      if (shouldContinue?.call() == false) return;

      // تحديث تاريخ آخر تشغيل للمهام اليومية
      // Update last daily task run date
      final location = PrayerCacheManager.getStoredLocation();
      if (location == null ||
          !MonthlyPrayerCache.isMonthlyDataValid(currentLocation: location) ||
          AdhanController.instance.state.prayerTimes == null) {
        log('Daily prayer data is incomplete; will retry', name: _tag);
        return;
      }
      await _updateLastDailyTaskRun();

      log('Daily tasks completed successfully', name: _tag);
    } catch (e) {
      log('Error executing daily tasks: $e', name: _tag);
    }
  }

  /// جدولة تنبيهات رمضان إذا كنا في رمضان
  /// Schedule Ramadan notifications if we're in Ramadan
  static Future<void> scheduleRamadanNotificationsIfNeeded() async {
    try {
      final storage = GetStorage();
      final suhoorEnabled =
          storage.read('ramadan_suhoor_notification') ?? false;
      final iftarEnabled = storage.read('ramadan_iftar_notification') ?? false;

      if (!suhoorEnabled && !iftarEnabled) return;

      // التحقق من أننا في رمضان
      // Check if we're in Ramadan
      final hijriNow = HijriDate.now();
      if (hijriNow.hMonth != 9) return;

      log('Scheduling Ramadan notifications...', name: _tag);

      final prayerTimes = AdhanController.instance.state.prayerTimes;
      if (prayerTimes == null) return;

      // تنبيه السحور - قبل الفجر
      // Suhoor notification - before Fajr
      if (suhoorEnabled) {
        final suhoorMinutes = storage.read('ramadan_suhoor_minutes') ?? 60;
        final suhoorTime = prayerTimes.fajr.subtract(
          Duration(minutes: suhoorMinutes),
        );

        if (suhoorTime.isAfter(DateTime.now())) {
          await NotifyHelper().scheduledNotification(
            reminderId: 1000,
            title: 'تذكير السحور',
            summary: 'رمضان',
            body: 'حان وقت السحور - تبقى $suhoorMinutes دقيقة على أذان الفجر',
            isRepeats: false,
            time: suhoorTime,
            payload: {'sound_type': 'bell'},
          );
          log('Suhoor notification scheduled for $suhoorTime', name: _tag);
        }
      }

      // تنبيه الإفطار - قبل المغرب
      // Iftar notification - before Maghrib
      if (iftarEnabled) {
        final iftarMinutes = storage.read('ramadan_iftar_minutes') ?? 30;
        final iftarTime = prayerTimes.maghrib.subtract(
          Duration(minutes: iftarMinutes),
        );

        if (iftarTime.isAfter(DateTime.now())) {
          await NotifyHelper().scheduledNotification(
            reminderId: 1001,
            title: 'تذكير الإفطار',
            summary: 'رمضان',
            body: 'استعد للإفطار - تبقى $iftarMinutes دقيقة على أذان المغرب',
            isRepeats: false,
            time: iftarTime,
            payload: {'sound_type': 'bell'},
          );
          log('Iftar notification scheduled for $iftarTime', name: _tag);
        }
      }
    } catch (e) {
      log('Error scheduling Ramadan notifications: $e', name: _tag);
    }
  }

  /// تنفيذ المهام الدورية (كل 20 دقيقة)
  /// Execute periodic tasks (every 20 minutes)
  static Future<void> executePeriodicTasks({
    bool Function()? shouldContinue,
  }) async {
    try {
      log('Executing periodic tasks...', name: _tag);

      // التحقق من أوقات الصلاة
      // Check prayer times
      final updated = await checkAndUpdatePrayerTimes();
      if (shouldContinue?.call() == false) return;

      // تجديد نافذة إشعارات الإقامة (اليوم+الغد على iOS) حتى مع صلاحية الكاش —
      // iOS لا ينفّذ كودًا عند ظهور إشعار، فالنافذة تتقدم بالتجديد الدوري.
      // Rolling iqama window refresh even when the cache is still valid.
      try {
        if (AdhanController.instance.state.iqamaNotificationsEnabled.value) {
          await PrayersNotificationsCtrl.instance.scheduleIqamaNotifications();
        }
      } catch (e) {
        log('Iqama notifications refresh failed: $e', name: _tag);
      }
      if (shouldContinue?.call() == false) return;

      // تجديد نافذة تذكيرات ما قبل الصلاة بنفس منطق الإقامة أعلاه.
      try {
        await PrayersNotificationsCtrl.instance.synchronizePrayerReminders();
      } catch (e) {
        log('Prayer reminders refresh failed: $e', name: _tag);
      }
      if (shouldContinue?.call() == false) return;

      // تجديد فترات التصميت (يوسّع تسليح المنبّهات الأصلي ويصحح الانحراف).
      try {
        await PrayersNotificationsCtrl.instance.synchronizePrayerSilence();
      } catch (e) {
        log('Prayer silence refresh failed: $e', name: _tag);
      }
      if (shouldContinue?.call() == false) return;

      // تحديث ويدجت الصلوات في كل مرة - Update prayers widget every time
      if (Platform.isIOS || Platform.isAndroid) {
        try {
          await PrayersWidgetConfig().updatePrayersDate();
        } catch (e) {
          log('Periodic widget update failed: $e', name: _tag);
        }
      }
      if (shouldContinue?.call() == false) return;

      // تجديد نافذة الإشعار الدائم (حدود الغد) — الكرونومتر الأصلي نفسه
      // يستمر، هذا التجديد يضمن قلب النصوص عند الحدود بعد قتل التطبيق.
      try {
        await PrayerCountdownNotificationService.instance.refresh();
      } catch (e) {
        log('Countdown notification refresh failed: $e', name: _tag);
      }
      if (shouldContinue?.call() == false) return;

      // التحقق من المهام اليومية إذا لزم الأمر
      // Check daily tasks if needed
      if (await _shouldExecuteDailyTasks()) {
        await executeDailyTasks(shouldContinue: shouldContinue);
      }

      log(
        'Periodic tasks completed${updated ? ' (prayer times updated)' : ''} - Widget updated',
        name: _tag,
      );
    } catch (e) {
      log('Error executing periodic tasks: $e', name: _tag);
    }
  }

  /// التحقق من ضرورة تنفيذ المهام اليومية
  /// Check if daily tasks should be executed
  static Future<bool> _shouldExecuteDailyTasks() async {
    try {
      final storage = GetStorage();
      final lastRun = storage.read('last_daily_task_run') as String?;

      if (lastRun == null) return true;

      final lastRunDate = DateTime.parse(lastRun);
      final now = DateTime.now();

      return lastRunDate.year != now.year ||
          lastRunDate.month != now.month ||
          lastRunDate.day != now.day;
    } catch (e) {
      log('Error checking daily tasks need: $e', name: _tag);
      return true; // في حالة الخطأ، نفذ المهام / On error, execute tasks
    }
  }

  /// تحديث تاريخ آخر تشغيل للمهام اليومية
  /// Update last daily task run date
  static Future<void> _updateLastDailyTaskRun() async {
    try {
      final storage = GetStorage();
      await storage.write(
        'last_daily_task_run',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      log('Error updating last daily task run: $e', name: _tag);
    }
  }

  /// الحصول على إحصائيات العمليات في الخلفية
  /// Get background operations statistics
  static Map<String, dynamic> getStats() {
    final storage = GetStorage();
    final dailyCacheStats = PrayerCacheManager.getCacheStats();

    // إحصائيات التخزين الشهري
    final currentLocation = PrayerCacheManager.getStoredLocation();
    final isMonthlyValid = currentLocation != null
        ? MonthlyPrayerCache.isMonthlyDataValid(
            currentLocation: currentLocation,
          )
        : false;

    return {
      'dailyCacheStats': dailyCacheStats,
      'monthlyCacheValid': isMonthlyValid,
      'currentLocation': currentLocation != null
          ? {
              'latitude': currentLocation.latitude,
              'longitude': currentLocation.longitude,
            }
          : null,
      'lastDailyTaskRun': storage.read('last_daily_task_run'),
      'shouldExecuteDailyTasks': false, // سيتم حسابها في runtime
      'cacheSystemVersion': '2.0', // نسخة النظام الجديد
    };
  }
}
