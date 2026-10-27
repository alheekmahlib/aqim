import 'dart:io' show Directory;

import 'package:aqim/core/utils/constants/shared_preferences_constants.dart';
import 'package:aqim/core/utils/helpers/glass_tokens.dart';
import 'package:aqim/presentation/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// التبديل بين الثيمات: حالة المتحكم + انتشار GlassTokens عبر
/// GetMaterialApp + الحفظ في GetStorage. إعادة الضخ الصريحة تحاكي
/// دورة Get.forceAppUpdate التي تُطبق الثيم في التطبيق الحقيقي.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();

    // GetStorage يعتمد path_provider — نحاكي قناته بمجلد مؤقت.
    const pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          return Directory.systemTemp.path;
        });

    await GetStorage.init();
    await GetStorage().remove(SET_THEME);
  });

  Widget hostApp(ThemeController ctrl) => ScreenUtilInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    builder: (_, child) => GetBuilder<ThemeController>(
      builder: (c) => GetMaterialApp(
        theme: c.currentThemeData,
        home: Scaffold(
          body: Builder(
            builder: (context) => Text(
              Theme.of(context).extension<GlassTokens>() == null
                  ? 'CLASSIC'
                  : 'GLASS',
            ),
          ),
        ),
      ),
    ),
  );

  /// performReassemble (من forceAppUpdate) يترك إطارًا مجدولًا لا يُفرَّغ
  /// إلا بحلقة أحداث حقيقية — نمنحها فرصة قبل الضخ التالي.
  Future<void> settleRealTime(WidgetTester tester) => tester.runAsync<void>(
    () => Future<void>.delayed(const Duration(milliseconds: 250)),
  );

  testWidgets('switching themes toggles GlassTokens live', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final ctrl = Get.put(ThemeController(), permanent: true);

    await tester.pumpWidget(hostApp(ctrl));
    await tester.pump(const Duration(milliseconds: 300));
    // onInit يعمل setTheme(blue) — الثيم الافتراضي بلا رموز زجاجية.
    expect(ctrl.currentTheme, AppTheme.blue);
    expect(find.text('CLASSIC'), findsOneWidget);

    await ctrl.setTheme(AppTheme.liquidGlass);
    await settleRealTime(tester);
    await tester.pumpWidget(hostApp(ctrl));
    await tester.pump(const Duration(milliseconds: 300));

    expect(ctrl.isLiquidGlass, isTrue);
    expect(ctrl.currentThemeData.extension<GlassTokens>(), isNotNull);
    expect(GetStorage().read(SET_THEME), AppTheme.liquidGlass.toString());
    expect(find.text('GLASS'), findsOneWidget);

    await ctrl.setTheme(AppTheme.dark);
    await settleRealTime(tester);
    await tester.pumpWidget(hostApp(ctrl));
    await tester.pump(const Duration(milliseconds: 300));

    expect(ctrl.isLiquidGlass, isFalse);
    expect(find.text('CLASSIC'), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
