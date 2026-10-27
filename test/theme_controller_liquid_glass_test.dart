import 'dart:io' show Directory;

import 'package:aqim/core/utils/constants/lists.dart';
import 'package:aqim/core/utils/constants/shared_preferences_constants.dart';
import 'package:aqim/core/utils/helpers/app_themes.dart';
import 'package:aqim/core/utils/helpers/glass_tokens.dart';
import 'package:aqim/presentation/controllers/theme_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// ثيم Liquid Glass: دورة الحفظ/الاستعادة + ربط ThemeData بالرموز الزجاجية.
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

  test('liquidGlass preference round-trips through GetStorage', () async {
    final box = GetStorage();
    await box.write(SET_THEME, AppTheme.liquidGlass.toString());

    final ctrl = ThemeController();
    final loaded = await ctrl.loadThemePreference();

    expect(loaded, AppTheme.liquidGlass);
    expect(ctrl.initialTheme, AppTheme.liquidGlass);

    ctrl.checkTheme();
    expect(ctrl.initialThemeData, liquidGlassTheme);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('missing/unknown preference falls back to blue', () async {
    final ctrl = ThemeController();
    final loaded = await ctrl.loadThemePreference();

    expect(loaded, AppTheme.blue);
    ctrl.checkTheme();
    expect(ctrl.initialThemeData, blueTheme);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('liquidGlassTheme carries GlassTokens, classic themes do not', () {
    expect(liquidGlassTheme.extension<GlassTokens>(), isNotNull);
    expect(blueTheme.extension<GlassTokens>(), isNull);
    expect(darkTheme.extension<GlassTokens>(), isNull);
  });

  test('themeList exposes every AppTheme value exactly once', () {
    final names = themeList.map((entry) => entry['name'] as AppTheme).toList();
    expect(names.toSet(), AppTheme.values.toSet());
    expect(names.length, AppTheme.values.length);
  });
}
