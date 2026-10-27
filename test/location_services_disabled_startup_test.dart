import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:aqim/core/services/connectivity_service.dart';
import 'package:aqim/core/services/internet_connection_controller.dart';
import 'package:aqim/core/services/location/locations.dart';
import 'package:aqim/core/utils/constants/shared_preferences_constants.dart';
import 'package:aqim/presentation/controllers/general/general_controller.dart';
import 'package:aqim/presentation/prayers/prayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';

/// geolocator بخدمات معطلة وإذن ممنوح — سيناريو الخطأ الأصلي.
class _DisabledServicesGeolocator extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => false;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    throw const LocationServiceDisabledException();
  }
}

/// geolocator بخدمات مفعلة لكن جلب الموقع يفشل (تعطّلت أثناء التشغيل).
class _FailingFetchGeolocator extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    throw const LocationServiceDisabledException();
  }
}

/// نسخة اختبارية تخطي دورة حياة التطبيق الثقيلة (خدمات خلفية/ودجت/مراقب).
class _TestGeneralController extends GeneralController {
  @override
  void onInit() async {}
}

/// نسخة اختبارية تخطي جدولة الإشعارات والمؤقتات الدورية.
class _TestAdhanController extends AdhanController {
  @override
  Future<void> onInit() async {}
}

/// اختبار الانحدار للخطأ الأصلي:
/// تعطيل خدمات الموقع ثم فتح التطبيق كان يرمي Null check operator، لأن
/// استثناء Geolocator.getCurrentPosition كان يقفز فوق initializeStoredAdhan
/// (تحميل كاش الـ 30 يومًا). الإصلاح: تجاهل فشل الجلب والاكتفاء بالموقع المخزّن.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GeolocatorPlatform originalGeolocator;

  /// تهيئة التخزين والاتصال (متصل — وهو مسار الخطأ الأصلي) وتسجيل الكونترولرات.
  Future<GeneralController> seedAndRegister() async {
    final box = GetStorage();

    // بيانات موقع مخزنة كما لو أن المستخدم فعّل الموقع سابقًا
    await box.write(CURRENT_LOCATION, {
      'latitude': 21.4225,
      'longitude': 39.8262,
      'city': 'Makkah',
      'country': 'Saudi Arabia',
      'timestamp': DateTime.now().toIso8601String(),
    });
    await box.write(ACTIVE_LOCATION, true);
    // كاش reverse geocoding حتى لا يلمس الاختبار الشبكة إطلاقًا
    const geo = {'city': 'Makkah', 'country': 'Saudi Arabia'};
    await box.write('NOMINATIM_REVERSE_CACHE_V1', {
      '21.4225,39.8262:en': geo,
      '21.4225,39.8262:ar': geo,
    });
    Location.instance.restoreFromStorage();

    // كاش شهري صالح لليوم الحالي (مذهب حنفي = الافتراضي SHAFI ?? true)
    final params = CalculationMethod.umm_al_qura.getParameters()
      ..madhab = Madhab.hanafi;
    final now = DateTime.now();
    await MonthlyPrayerCache.saveMonthlyPrayerData(
      location: const LatLng(21.4225, 39.8262),
      params: params,
      month: DateTime(now.year, now.month, 1),
    );

    final generalCtrl = Get.put<GeneralController>(
      _TestGeneralController(),
      permanent: true,
    );
    Get.put<AdhanController>(_TestAdhanController(), permanent: true);
    generalCtrl.state.activeLocation.value = true;
    return generalCtrl;
  }

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('almasjid_loc_disabled');
    addTearDown(() async => dir.delete(recursive: true));

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
    // إنترنت متصل + بلا أحداث اتصال لاحقة — السيناريو الذي كان ينفجر
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => <String>['wifi'],
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (call) async => null,
    );

    await GetStorage.init();

    originalGeolocator = GeolocatorPlatform.instance;

    // نفس ترتيب ServicesLocator في التطبيق
    Get.put(InternetConnectionService());
    Get.put(InternetConnectionController(), permanent: true);
    // تصريف المهام الدقيقة حتى تُحسم حالة الاتصال إلى "متصل"
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    GeolocatorPlatform.instance = originalGeolocator;
    await GetStorage().save(); // تصريف أي كتابات معلقة قبل إعادة التهيئة
    Get.reset();
  });

  test(
    'initLocation مع خدمات موقع معطلة (متصل بالإنترنت) يحمّل كاش الصلاة ولا يرمي',
    () async {
      GeolocatorPlatform.instance = _DisabledServicesGeolocator();
      final generalCtrl = await seedAndRegister();

      await generalCtrl.initLocation(isOpenSettings: false, refreshUI: false);

      // تصريف رد نداء تحديث الويدجت المؤجل (500ms) داخل حدود الاختبار
      await Future<void>.delayed(const Duration(milliseconds: 700));

      final adhanCtrl = Get.find<AdhanController>();
      expect(
        adhanCtrl.state.prayerTimes,
        isNotNull,
        reason: 'يجب تحميل كاش الـ 30 يومًا رغم تعطل خدمات الموقع',
      );
      expect(adhanCtrl.state.sunnahTimes, isNotNull);
    },
  );

  test(
    'فشل جلب الموقع أثناء التشغيل لا يوقف تحميل الكاش (تحصين إضافي)',
    () async {
      GeolocatorPlatform.instance = _FailingFetchGeolocator();
      final generalCtrl = await seedAndRegister();

      await generalCtrl.initLocation(isOpenSettings: false, refreshUI: false);

      await Future<void>.delayed(const Duration(milliseconds: 700));

      final adhanCtrl = Get.find<AdhanController>();
      expect(
        adhanCtrl.state.prayerTimes,
        isNotNull,
        reason:
            'استثناء getPositionDetails يجب أن يُبتلع ويُستخدم الموقع المخزّن',
      );
    },
  );

  test('getPositionDetails لا يرمي استثناءً عند تعطل خدمات الموقع', () async {
    GeolocatorPlatform.instance = _DisabledServicesGeolocator();
    await seedAndRegister();

    await expectLater(LocationHelper.instance.getPositionDetails(), completes);
  });
}
