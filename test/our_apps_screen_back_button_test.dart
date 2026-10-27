import 'package:aqim/core/services/connectivity_service.dart';
import 'package:aqim/core/services/internet_connection_controller.dart';
import 'package:aqim/core/services/services_locator.dart';
import 'package:aqim/presentation/ourApp/controller/our_apps_controller.dart';
import 'package:aqim/presentation/ourApp/screen/our_apps_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// إعادة إنتاج كاملة لشاشة تطبيقاتنا ببيئة مطابقة للتطبيق الحقيقي:
/// RTL عربية + ScreenUtilInit + مقاس هاتف عمودي + خدمات مسجلة،
/// ثم النقر على زر الرجوع والتحقق من إغلاق المسار.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    await sl.reset();

    const methodChannel = MethodChannel(
      'dev.fluttercommunity.plus/connectivity',
    );
    const eventChannel = EventChannel(
      'dev.fluttercommunity.plus/connectivity_status',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      if (call.method == 'check') return ['wifi'];
      return null;
    });
    messenger.setMockStreamHandler(
      eventChannel,
      MockStreamHandler.inline(
        onListen: (arguments, sink) {
          sink.success(['wifi']);
        },
      ),
    );

    Get.put(InternetConnectionService());
    InternetConnectionController.instance;
    sl.registerLazySingleton<OurAppsController>(
      () => Get.put<OurAppsController>(OurAppsController(), permanent: true),
    );
  });

  testWidgets('OurApps portrait RTL: back button pops the route', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (_, child) => GetMaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: Center(child: Text('HOME_SCREEN'))),
          getPages: [GetPage(name: '/ourApps', page: () => const OurApps())],
        ),
      ),
    );
    await tester.pump();
    expect(Get.currentRoute, '/');

    Get.toNamed('/ourApps');
    // جُمل محددة بدل pumpAndSettle لأن اللوتي والرسم المتحرك يتكرران
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(Get.currentRoute, '/ourApps');

    final backIcon = find.byIcon(Icons.arrow_back_ios);
    expect(backIcon, findsOneWidget);
    debugPrint('BACK_ICON_RECT: ${tester.getRect(backIcon)}');

    await tester.tap(backIcon, warnIfMissed: true);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    debugPrint('ROUTE_AFTER_TAP: ${Get.currentRoute}');
    expect(Get.currentRoute, '/');
  });
}
