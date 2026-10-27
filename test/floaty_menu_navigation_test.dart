import 'package:aqim/core/services/connectivity_service.dart';
import 'package:aqim/core/services/internet_connection_controller.dart';
import 'package:aqim/core/services/services_locator.dart';
import 'package:aqim/presentation/ourApp/controller/our_apps_controller.dart';
import 'package:aqim/presentation/ourApp/screen/our_apps_screen.dart';
import 'package:floatica/floatica.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// اختبارات انحدار لعلة قائمة FloatyNavBar:
/// الدخول إلى "تطبيقاتنا" من داخل القائمة يترك طبقة الإغلاق (barrier)
/// فوق المسار المفتوح فتبتلع النقرات (زر رجوع ميت وسحب الحافة يعمل)،
/// وإعادة الفتح السريع كانت تنعزل isOpen عن الحالة الداخلية فلا تُغلق
/// القائمة في الزيارات التالية أبدًا.
/// السلوك الصحيح (SettingsList._navigateFromMenu + floatica 1.2.1):
/// إغلاق القائمة قبل التنقل، ومزامنة الحالة وتنظيف أي حاجز تالف.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FloaticaMenuController menuController = FloaticaMenuController();

  Future<void> pumpApp(WidgetTester tester) async {
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
          home: Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  const Center(child: Text('HOME_TAB')),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FloatyNavBar(
                      height: 45,
                      backgroundColor: Colors.green.withValues(alpha: .8),
                      selectedTab: 0,
                      tabs: [
                        FloaticaTab(
                          isSelected: true,
                          title: 'tab',
                          onTap: () {},
                          icon: const Icon(Icons.home),
                        ),
                      ],
                      menu: FloaticaMenu(
                        controller: menuController,
                        child: Material(
                          color: Colors.white,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                key: const Key('goOurApps'),
                                title: const Text('GO_OURAPPS'),
                                // نفس نمط SettingsList._navigateFromMenu
                                onTap: () {
                                  menuController.close();
                                  Get.toNamed('/ourApps');
                                },
                              ),
                            ],
                          ),
                        ),
                        icon: const Icon(Icons.menu),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          getPages: [GetPage(name: '/ourApps', page: () => const OurApps())],
        ),
      ),
    );
    await tester.pump();
  }

  setUp(() async {
    Get.reset();
    await sl.reset();
    menuController = FloaticaMenuController();

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

  testWidgets(
    'slow pacing: two full menu→ourApps→back cycles keep the back button working',
    (WidgetTester tester) async {
      await pumpApp(tester);

      for (var cycle = 1; cycle <= 2; cycle++) {
        menuController.open();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(menuController.isOpen, isTrue, reason: 'cycle $cycle open');

        await tester.tap(find.byKey(const Key('goOurApps')));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(Get.currentRoute, '/ourApps', reason: 'cycle $cycle navigate');
        expect(menuController.isOpen, isFalse, reason: 'cycle $cycle closed');

        await tester.tap(find.byIcon(Icons.arrow_back_ios), warnIfMissed: true);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(Get.currentRoute, '/', reason: 'cycle $cycle back');
      }
    },
  );

  testWidgets(
    'quick pacing: reopening the menu before the close animation finishes must not break the second visit',
    (WidgetTester tester) async {
      await pumpApp(tester);

      // الدورة الأولى: فتح القائمة ثم الدخول لتطبيقاتنا
      menuController.open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(menuController.isOpen, isTrue);

      await tester.tap(find.byKey(const Key('goOurApps')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(Get.currentRoute, '/ourApps');
      // أنيميشن إغلاق القائمة متجمد تحت المسار (TickerMode) — الحالة الداخلية ما تزال مفتوحة

      // رجوع وبعده مباشرة إعادة فتح القائمة قبل اكتمال الإغلاق المُجمَّد
      await tester.tap(find.byIcon(Icons.arrow_back_ios), warnIfMissed: true);
      await tester.pump(const Duration(milliseconds: 50));
      expect(Get.currentRoute, '/');

      menuController.open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        menuController.isOpen,
        isTrue,
        reason: 'open() must sync state even if the navbar was still "open"',
      );

      // الزيارة الثانية يجب أن تعمل كما الأولى
      await tester.tap(find.byKey(const Key('goOurApps')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(Get.currentRoute, '/ourApps');
      expect(menuController.isOpen, isFalse);

      await tester.tap(find.byIcon(Icons.arrow_back_ios), warnIfMissed: true);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(Get.currentRoute, '/');
    },
  );
}
