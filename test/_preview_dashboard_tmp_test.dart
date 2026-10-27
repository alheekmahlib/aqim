// ملف مؤقّت للمعاينة البصرية فقط — يُحذف بعد التحقق.
import 'package:adhan/adhan.dart';
import 'package:aqim/core/utils/helpers/app_themes.dart';
import 'package:aqim/presentation/controllers/general/general_controller.dart';
import 'package:aqim/presentation/prayers/prayers.dart';
import 'package:aqim/presentation/prayers/screen/prayer_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';

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

  setUp(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => <String>['wifi'],
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (call) async => null,
    );

    await GetStorage.init();
    await initializeDateFormatting();

    final general = _TestGeneralController();
    general.state.activeLocation.value = true;
    Get.put<GeneralController>(general, permanent: true);

    final ctrl = _TestAdhanController();
    Get.put<AdhanController>(ctrl, permanent: true);

    final s = ctrl.state;
    s.params = CalculationMethod.umm_al_qura.getParameters();
    s.coordinates = Coordinates(21.4225, 39.8262);
    s.dateComponents = DateComponents.from(DateTime.now());
    s.prayerTimes = PrayerTimes(s.coordinates, s.dateComponents, s.params);
    s.sunnahTimes = SunnahTimes(s.prayerTimes!);
    final pt = s.prayerTimes!;
    s.fajrTime.value = _fmt(pt.fajr);
    s.sunriseTime.value = _fmt(pt.sunrise);
    s.dhuhrTime.value = _fmt(pt.dhuhr);
    s.asrTime.value = _fmt(pt.asr);
    s.maghribTime.value = _fmt(pt.maghrib);
    s.ishaTime.value = _fmt(pt.isha);
    s.midnightTime.value = _fmt(s.sunnahTimes!.middleOfTheNight);
    s.lastThirdTime.value = _fmt(s.sunnahTimes!.lastThirdOfTheNight);
  });

  tearDown(() => Get.reset());

  testWidgets('preview', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: darkTheme,
        locale: const Locale('ar'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        home: const PrayerDashboardScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await expectLater(
      find.byType(PrayerDashboardScreen),
      matchesGoldenFile('../build/preview/dashboard_dark.png'),
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

String _fmt(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')}';
}
