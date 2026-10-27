import 'dart:convert';
import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:aqim/core/services/connectivity_service.dart';
import 'package:aqim/core/services/internet_connection_controller.dart';
import 'package:aqim/core/services/location/locations.dart';
import 'package:aqim/core/utils/constants/shared_preferences_constants.dart';
import 'package:aqim/core/widgets/home_widget/home_widget.dart';
import 'package:aqim/presentation/controllers/general/general_controller.dart';
import 'package:aqim/presentation/prayers/prayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';

/// ودجت macOS كان لا يملك مسار الكاش الشهري (بعكس iOS/Android)، فإذا لم
/// يُفتح التطبيق يومًا تعرض أوقات آخر كتابة. الإصلاح: تُرسل بيانات الشهرين
/// (الحالي + التالي) عبر قناة MacOSWidgetService بأمر updateMonthlyPrayerData.
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

class _TestGeneralController extends GeneralController {
  @override
  void onInit() async {}
}

class _TestAdhanController extends AdhanController {
  @override
  Future<void> onInit() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// محاكاة قناة ويدجت macOS والتقاط أوامر البيانات الشهرية.
  final monthlyCalls = <Map<String, String>>[];
  const widgetChannel = MethodChannel('com.alheekmah.aqimApp.prayer-widget');

  setUp(() async {
    monthlyCalls.clear();
    final dir = await Directory.systemTemp.createTemp('almasjid_mac_widget');
    addTearDown(() async => dir.delete(recursive: true));

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
    // محاكاة اتصال بالإنترنت حتى يسلك الاختبار المسار المتصل (الواقعي)
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => <String>['wifi'],
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(widgetChannel, (call) async {
      if (call.method == 'updateMonthlyPrayerData') {
        monthlyCalls.add(
          Map<String, String>.from(
            (call.arguments as Map).cast<String, String>(),
          ),
        );
      }
      return null;
    });

    await GetStorage.init();

    // في التطبيق تُسجَّل بيانات locales عبر flutter_localizations؛ في الاختبار
    // نحتاج initializeDateFormatting وإلا رمى DateFormatter.formatPrayerTime.
    await initializeDateFormatting();

    final originalGeolocator = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = _DisabledServicesGeolocator();
    addTearDown(() => GeolocatorPlatform.instance = originalGeolocator);

    // بذر بيانات موقع + كاش شهري صالح لليوم الحالي
    final box = GetStorage();
    await box.write(CURRENT_LOCATION, {
      'latitude': 21.4225,
      'longitude': 39.8262,
      'city': 'Makkah',
      'country': 'Saudi Arabia',
      'timestamp': DateTime.now().toIso8601String(),
    });
    await box.write(ACTIVE_LOCATION, true);
    Location.instance.restoreFromStorage();

    final params = CalculationMethod.umm_al_qura.getParameters()
      ..madhab = Madhab.hanafi;
    final now = DateTime.now();
    await MonthlyPrayerCache.saveMonthlyPrayerData(
      location: const LatLng(21.4225, 39.8262),
      params: params,
      month: DateTime(now.year, now.month, 1),
    );

    // نفس ترتيب ServicesLocator
    Get.put(InternetConnectionService());
    Get.put(InternetConnectionController(), permanent: true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final generalCtrl = Get.put<GeneralController>(
      _TestGeneralController(),
      permanent: true,
    );
    Get.put<AdhanController>(_TestAdhanController(), permanent: true);
    generalCtrl.state.activeLocation.value = true;
  });

  tearDown(() async {
    await GetStorage().save();
    Get.reset();
  });

  test(
    'تحديث الودجت على macOS يكتب بيانات الشهرين عبر قناة updateMonthlyPrayerData',
    () async {
      final generalCtrl = Get.find<GeneralController>();

      // يحمل كاش الشهر إلى الحالة ثم يطلق تحديث الودجت المؤجل (500ms)
      await generalCtrl.initLocation(isOpenSettings: false, refreshUI: false);
      await Future<void>.delayed(const Duration(milliseconds: 700));

      // التخزين الشهري يحمل شهرًا واحدًا في كل لحظة (مفتاح واحد)؛
      // نحاكي دورة executeDailyTasks التي تنتهي بحفظ الشهر التالي
      // ثم نحدّث الودجت مجددًا ليكتب مفتاح الشهر القادم أيضًا.
      final params = CalculationMethod.umm_al_qura.getParameters()
        ..madhab = Madhab.hanafi;
      final now = DateTime.now();
      await MonthlyPrayerCache.saveMonthlyPrayerData(
        location: const LatLng(21.4225, 39.8262),
        params: params,
        month: DateTime(now.year, now.month + 1, 1),
      );
      await PrayersWidgetConfig().updatePrayersDate();

      expect(
        monthlyCalls,
        isNotEmpty,
        reason: 'يجب إرسال البيانات الشهرية إلى قناة ويدجت macOS',
      );

      final allKeys = monthlyCalls.map((c) => c.keys).expand((k) => k).toSet();
      final nextMonth = DateTime(now.year, now.month + 1);

      expect(
        allKeys,
        containsAll([
          'monthly_prayer_times_${now.year}_${now.month}',
          'monthly_prayer_times_${nextMonth.year}_${nextMonth.month}',
          'monthly_prayer_times', // المفتاح العام للتوافقية
        ]),
      );

      // المفتاح العام يحمل بيانات الشهر الحالي بتنسيق اليوم الثماني الصحيح
      final currentMonthPayload = monthlyCalls.firstWhere(
        (c) => c.containsKey('monthly_prayer_times'),
        orElse: () => monthlyCalls.first,
      );
      final generic =
          jsonDecode(currentMonthPayload['monthly_prayer_times']!)
              as Map<String, dynamic>;
      expect(generic['year'], now.year);
      expect(generic['month'], now.month);

      final days = generic['days'] as Map<String, dynamic>;
      final today = days['${now.day}'] as String?;
      expect(
        today,
        isNotNull,
        reason: 'بيانات اليوم الحالي يجب أن تكون موجودة',
      );
      expect(
        today!.split('|').length,
        8,
        reason:
            'fajr|sunrise|dhuhr|asr|maghrib|isha|midnight|lastThird بصيغة HH:mm',
      );
    },
  );
}
