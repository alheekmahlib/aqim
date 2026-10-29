import 'dart:async';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '/core/widgets/local_notification/controller/local_notifications_controller.dart';
import '/presentation/controllers/settings_controller.dart';
import '../../presentation/calendar/events.dart';
import '../../presentation/controllers/theme_controller.dart';
import '../../presentation/feedback/controller/feedback_controller.dart';
import '../../presentation/ourApp/controller/our_apps_controller.dart';
import '../../presentation/prayers/prayers.dart';
import '../../presentation/prayers/features/presentation/prayer_features_binding.dart';
import '../../presentation/splash/splash.dart';
import '../../presentation/whats_new/whats_new.dart';
import '../utils/helpers/rate_app_helper.dart';
import 'connectivity_service.dart';
import 'internet_connection_controller.dart';

final sl = GetIt.instance;

class ServicesLocator {
  Future<void> init() async {
    await Future.wait([GetStorage.init('AdhanSounds')]);

    PrayerFeaturesBinding().dependencies();

    // Controllers
    sl.registerLazySingleton<ThemeController>(
      () => Get.put<ThemeController>(ThemeController(), permanent: true),
    );

    sl.registerLazySingleton<SettingsController>(
      () => Get.put<SettingsController>(SettingsController(), permanent: true),
    );

    sl.registerLazySingleton<SplashScreenController>(
      () => Get.put<SplashScreenController>(
        SplashScreenController(),
        permanent: true,
      ),
    );

    sl.registerLazySingleton<WhatsNewController>(
      () => Get.put<WhatsNewController>(WhatsNewController(), permanent: true),
    );

    sl.registerLazySingleton<LocalNotificationsController>(
      () => Get.put<LocalNotificationsController>(
        LocalNotificationsController(),
        permanent: true,
      ),
    );

    sl.registerLazySingleton<AdhanController>(
      () => Get.put<AdhanController>(AdhanController(), permanent: true),
    );

    sl.registerLazySingleton<PrayersNotificationsCtrl>(
      () => Get.put<PrayersNotificationsCtrl>(
        PrayersNotificationsCtrl(),
        permanent: true,
      ),
    );

    sl.registerLazySingleton<OurAppsController>(
      () => Get.put<OurAppsController>(OurAppsController(), permanent: true),
    );

    sl.registerLazySingleton<FeedbackController>(
      () => Get.put<FeedbackController>(FeedbackController(), permanent: true),
    );

    sl.registerLazySingleton<RamadanController>(
      () => Get.put<RamadanController>(RamadanController(), permanent: true),
    );

    Get.put(InternetConnectionService(), permanent: true);
    Get.put(InternetConnectionController(), permanent: true);

    // بوابة التقييم التلقائية: تعدّ الإطلاق وتخزّن الحالة داخل المنصة.
    RateAppHelper.initReviewGate();
    try {
      final TimezoneInfo timezone = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezone.identifier;
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fallback gracefully if plugin not available or throws
      tz.initializeTimeZones();
      // tz.local uses platform default when available
      // No explicit setLocalLocation to avoid crashing on unsupported platforms
    }
  }
}
