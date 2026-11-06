import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/background_services.dart';
import '../../../core/services/internet_connection_controller.dart';
import '../../../core/services/location/locations.dart';
import '../../../core/utils/constants/shared_preferences_constants.dart';
import '../../../core/widgets/home_widget/home_widget.dart';
import '../../prayers/prayers.dart';
import '../../qibla/qibla.dart';
import '../../splash/splash.dart';
import 'general_state.dart';

class GeneralController extends GetxController with WidgetsBindingObserver {
  static GeneralController get instance => Get.isRegistered<GeneralController>()
      ? Get.find<GeneralController>()
      : Get.put<GeneralController>(GeneralController());

  GeneralState state = GeneralState();
  Completer<void>? _settingsCompleter;
  bool _isActivatingLocation = false;

  // @override
  @override
  void onInit() async {
    state.activeLocation.value = state.box.read(ACTIVE_LOCATION) ?? false;

    if (BGServices.isHeadless) {
      Location.instance.restoreFromStorage();
      super.onInit();
      return;
    }

    if (state.activeLocation.value) {
      // استرداد بيانات الموقع المحفوظة
      // Restore saved location data
      Location.instance.restoreFromStorage();
      await initLocation(isOpenSettings: false, refreshUI: false);

      if (Platform.isIOS || Platform.isAndroid) {
        await BGServices().registerTask();
        // await HijriWidgetConfig.initialize();
        await PrayersWidgetConfig.initialize();
        await BackgroundTaskHandler.initializeHandler();
      } else if (Platform.isMacOS) {
        // على macOS لا نستخدم BGServices، لكن نحتاج دفع بيانات الودجت
        // إلى App Group حتى لا يظهر fallback (12:00).
        await PrayersWidgetConfig.initialize();
        Future.delayed(const Duration(seconds: 2)).then((_) {
          PrayersWidgetConfig().updatePrayersDate();
        });
      }
    }

    // macOS: حتى لو لم يكن الموقع مفعلًا، نهيّئ الودجت ونحاول دفع الكاش (إن وُجد)
    // لتجنب ظهور قيم fallback مثل 12:00.
    if (Platform.isMacOS && !state.activeLocation.value) {
      await PrayersWidgetConfig.initialize();
      Future.delayed(const Duration(seconds: 2)).then((_) {
        PrayersWidgetConfig().updatePrayersDate();
      });
    }
    WidgetsBinding.instance.addObserver(this);
    // HijriWidgetConfig().updateHijriDate();
    // PrayersWidgetConfig.onPrayerWidgetClicked();
    // HijriWidgetConfig.onHijriWidgetClicked();

    super.onInit();
  }

  @override
  void onClose() {
    BGServices.cancelForegroundMidnightTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// -------- [Methods] ----------

  /// Greeting
  void updateGreeting() {
    final now = DateTime.now();
    final isMorning = now.hour < 12;
    state.greeting.value = isMorning
        ? 'صبحكم الله بالخير'
        : 'مساكم الله بالخير';
  }

  /// -------- [PrayersMethods] ----------

  // ✅ هذه الدالة تُستدعى عند تغيير حالة التطبيق
  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    super.didChangeAppLifecycleState(appState);

    // عندما يعود المستخدم للتطبيق
    if (appState == AppLifecycleState.resumed) {
      if (_settingsCompleter != null && !_settingsCompleter!.isCompleted) {
        _settingsCompleter!.complete();
      }

      // إعادة جدولة Timer منتصف الليل عند العودة للتطبيق
      // Reschedule foreground midnight timer on resume
      if (state.activeLocation.value && (Platform.isIOS || Platform.isAndroid)) {
        BGServices.scheduleForegroundMidnightTimer();
      }

      // تحديث الـ widget عند عودة التطبيق من الخلفية
      // Update widget when app returns from background
      if (state.activeLocation.value &&
          (Platform.isIOS || Platform.isAndroid || Platform.isMacOS)) {
        Future.delayed(const Duration(milliseconds: 500), () async {
          // التحقق من تغيّر اليوم لتحديث التاريخ الهجري والصلوات
          // Check if date changed to update Hijri date and prayers
          final today = DateTime.now().toIso8601String().substring(0, 10);
          final lastDate = state.box.read('last_widget_update_date') as String?;
          if (lastDate != today) {
            // إعادة حساب أوقات الصلاة لليوم الجديد
            // Recalculate prayer times for new day
            await AdhanController.instance.initializeStoredAdhan(
              forceUpdate: false,
            );

            // تحديث الويدجت صراحةً بعد إعادة الحساب
            // Explicitly update widget after recalculation
            // await HijriWidgetConfig.initialize();
            await PrayersWidgetConfig.initialize();
            // await HijriWidgetConfig().updateHijriDate();
            await PrayersWidgetConfig().updatePrayersDate();

            // كتابة التاريخ بعد نجاح التحديث فقط
            // Write date only after successful update
            if (PrayersWidgetConfig.lastUpdateSucceeded) {
              state.box.write('last_widget_update_date', today);
            }
            log(
              'Date changed on resume: recalculated prayer times',
              name: 'GeneralController',
            );
          } else {
            PrayersWidgetConfig().updatePrayersDate();
          }
          log('Widget updated on app resume', name: 'GeneralController');
        });
      }
    }
  }

  // ✅ دالة لفتح الإعدادات والانتظار حتى العودة
  Future<void> _openSettingsAndWait() async {
    _settingsCompleter = Completer<void>();

    await Geolocator.openAppSettings();

    // انتظار حتى يعود المستخدم للتطبيق
    await _settingsCompleter!.future;

    // انتظار قليل للتأكد من تحديث الأذونات
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> initLocation({
    bool? isOpenSettings = true,
    bool refreshUI = true,
  }) async {
    try {
      state.isLocationLoading.value = true;

      // عند عدم وجود إنترنت ومع وجود موقع محفوظ: لا نعمل fetch لموقع جديد.
      final storedPosition = Location.instance.position;
      final hasStoredLocation = storedPosition != null;
      final isConnected = InternetConnectionController.instance.isConnected;
      if (!isConnected && hasStoredLocation) {
        log(
          'No internet: using stored location without fetching a new one',
          name: 'GeneralController',
        );
        await _activateLocation(refreshUI: false);
        return;
      }

      await Geolocator.checkPermission();
      LocationPermission permission = await Geolocator.checkPermission();
      bool isEnabled = await Geolocator.isLocationServiceEnabled();

      // حالة الرفض الدائم - فتح الإعدادات والانتظار
      if (isEnabled &&
          isOpenSettings! &&
          permission == LocationPermission.deniedForever) {
        // فتح الإعدادات والانتظار حتى العودة
        await _openSettingsAndWait();

        // ✅ إعادة التحقق من الإذن بعد العودة
        permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          await _activateLocation(refreshUI: refreshUI);
        } else {
          // المستخدم لم يفعّل الموقع
          log('User did not enable location permission');
        }
      } else if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        // ✅ الإذن موجود - تفعيل مباشر

        await Geolocator.requestPermission().then((_) async {
          await _activateLocation(refreshUI: refreshUI);
        });
      } else if (permission == LocationPermission.denied) {
        // ✅ طلب الإذن لأول مرة
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          await Geolocator.requestPermission().then((_) async {
            await _activateLocation(refreshUI: refreshUI);
          });
        }
      }
    } catch (e) {
      log(e.toString(), name: 'Main', error: e);
    } finally {
      state.isLocationLoading.value = false;
    }
  }

  // ✅ دالة منفصلة لتفعيل الموقع
  Future<void> _activateLocation({required bool refreshUI}) async {
    if (_isActivatingLocation) {
      log(
        'Activation already in progress; skipping',
        name: 'GeneralController',
      );
      return;
    }
    _isActivatingLocation = true;
    try {
      final isConnected = InternetConnectionController.instance.isConnected;
      final locationServiceEnabled = await LocationHelper.instance
          .isLocationServiceEnabled();

      final stored = PrayerCacheManager.getStoredLocation();
      final previousCountry = Location.instance.country;
      // Show the last known prayer times before waiting for GPS or the network.
      if (stored != null &&
          Location.instance.position != null &&
          AdhanController.instance.state.prayerTimes == null) {
        await AdhanController.instance.initializeStoredAdhan(
          currentLocation: stored,
        );
      }
      final shouldUseStoredOnly =
          (!isConnected || !locationServiceEnabled) && stored != null;

      if (shouldUseStoredOnly) {
        log(
          'No internet or location services disabled: '
          'skip fetching new position',
          name: 'GeneralController',
        );
      } else {
        // فشل جلب الموقع لا يجوز أن يوقف تحميل كاش الصلاة؛
        // نكمل دائمًا بـ effectiveLocation (الحية أو المخزّنة).
        try {
          await LocationHelper.instance.getPositionDetails();
        } catch (e) {
          log(
            'getPositionDetails failed, falling back to stored location: $e',
            name: 'GeneralController',
          );
        }
      }

      final pos = Location.instance.position;
      final effectiveLocation = pos != null
          ? LatLng(pos.latitude, pos.longitude)
          : stored;
      final moved = stored != null && effectiveLocation != null &&
          ((stored.latitude - effectiveLocation.latitude).abs() > 0.01 ||
              (stored.longitude - effectiveLocation.longitude).abs() > 0.01);
      if (moved) AdhanController.instance.state.localizedCity.value = '';
      final countryChanged = Location.instance.country.isNotEmpty &&
          Location.instance.country != previousCountry;

      log('Location activated: $pos', name: 'Main');
      state.box.write(ACTIVE_LOCATION, true);
      state.box.write(IS_LOCATION_ACTIVE, true);
      state.box.write(FIRST_LAUNCH, true);

      await AdhanController.instance.initializeStoredAdhan(
        newLocation: effectiveLocation,
        forceUpdate: moved ||
            (countryChanged &&
                AdhanController.instance.state.autoCalculationMethod.value),
      );
      final locationName = await AdhanController.instance.localizedLocation;
      AdhanController.instance.state.location = locationName;
      AdhanController.instance.state.localizedCity.value = locationName;
      if (refreshUI) {
        Get.forceAppUpdate();
      }
    } finally {
      _isActivatingLocation = false;
    }
  }

  /// Initialize location with manual selection (for Huawei devices)
  Future<void> initManualLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      state.isLocationLoading.value = true;

      await HuaweiLocationHelper.instance.setManualLocation(
        latitude: latitude,
        longitude: longitude,
      );

      state.activeLocation.value = true;
      state.box.write(ACTIVE_LOCATION, true);
      state.box.write(IS_LOCATION_ACTIVE, true);
      state.box.write(FIRST_LAUNCH, true);

      AdhanController.instance.initializeStoredAdhan();
      Get.forceAppUpdate();
      await SplashScreenController.instance.isNotificationAllowed();
    } catch (e) {
      log(
        'Error initializing manual location: $e',
        name: 'GeneralController',
        error: e,
      );
      rethrow;
    } finally {
      state.isLocationLoading.value = false;
    }
  }

  Future<void> cancelLocation() async {
    state.activeLocation.value = false;
    state.box.write(ACTIVE_LOCATION, false);
    state.box.write(IS_LOCATION_ACTIVE, false);
    state.box.write(FIRST_LAUNCH, true);
    await SplashScreenController.instance.isNotificationAllowed();
    log('Location cancelled', name: 'Main');
  }

  Future<void> toggleLocationService() async {
    if (!state.activeLocation.value) {
      LocationPermission permission = await Geolocator.checkPermission();
      bool isEnabled = await LocationHelper.instance.isLocationServiceEnabled();
      if (!isEnabled) {
        await LocationHelper.instance.openLocationSettings;
      } else if (isEnabled &&
          (permission == LocationPermission.deniedForever ||
              permission == LocationPermission.denied)) {
        await _openSettingsAndWait();
        await Future.delayed(const Duration(seconds: 3));
        if (await LocationHelper.instance.checkPermission()) {
          await _activateLocation(refreshUI: true);
          // await initLocation().then((_) async {
          //   state.activeLocation.value = true;
          //   await AdhanController.instance.initializeStoredAdhan().then((_) {
          //     state.box.write(ACTIVE_LOCATION, true);
          //     Get.forceAppUpdate();
          //   });
          // });
        }
        log('Location services are already enabled.');
      } else {
        await _activateLocation(refreshUI: true);
        // await initLocation().then((_) async {
        //   state.activeLocation.value = true;
        //   await AdhanController.instance.initializeStoredAdhan().then((_) {
        //     state.box.write(ACTIVE_LOCATION, true);
        //     Get.forceAppUpdate();
        //   });
        // });
        log('Location services are already enabled.');
      }
      AdhanController.instance.update();
    } else {
      state.activeLocation.value = false;
      state.box.write(ACTIVE_LOCATION, false);
      Get.forceAppUpdate();
    }
  }

  /// تحديث الموقع وإعادة حساب أوقات الصلاة
  /// Update location and recalculate prayer times
  Future<bool> updateLocationAndPrayerTimes() async {
    final currentLocation = LocationHelper().currentLocation;
    Position? position;
    try {
      position = await LocationHelper().fetchCurrentPosition;
    } catch (e) {
      log('fetchCurrentPosition failed: $e', name: 'GeneralController');
      position = null;
    }
    if (position == null) {
      final context = Get.context;
      if (context!.mounted) {
        context.showSearchBottomSheet(context);
      }
      return false;
    }
    final newLocation = LatLng(position.latitude, position.longitude);

    log(
      'Current Location: $currentLocation, New Location: $newLocation',
      name: 'GeneralController',
    );
    if (newLocation != currentLocation) {
      try {
        log('Updating location and prayer times...', name: 'GeneralController');

        // التحقق من تفعيل خدمة الموقع
        // Check if location service is enabled
        if (!state.activeLocation.value) {
          log('Location service is not active', name: 'GeneralController');
          return false;
        }

        // تحديث الموقع
        // Update location
        await initLocation();

        // إعادة حساب أوقات الصلاة
        // Recalculate prayer times
        await AdhanController.instance.clearCacheAndRecalculate();
        await QiblaController.instance.updateQiblaDirection();

        // تحديث الويدجت
        // Update widget
        // PrayersWidgetConfig().updatePrayersDate();

        log(
          'Location and prayer times updated successfully',
          name: 'GeneralController',
        );
        return true;
      } catch (e) {
        log(
          'Error updating location and prayer times: $e',
          name: 'GeneralController',
        );
        return false;
      }
    }
    log(
      'Location has not changed, no update needed',
      name: 'GeneralController',
    );
    return false;
  }
}
