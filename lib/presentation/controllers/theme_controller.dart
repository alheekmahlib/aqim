import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/utils/constants/shared_preferences_constants.dart';
import '../../core/utils/helpers/app_themes.dart';

enum AppTheme { blue, dark, liquidGlass }

class ThemeController extends GetxController {
  static ThemeController get instance =>
      GetInstance().putOrFind(() => ThemeController());

  AppTheme? initialTheme;
  ThemeData? initialThemeData;
  final Rx<AppTheme> _currentTheme = AppTheme.blue.obs;
  final box = GetStorage();

  @override
  void onInit() async {
    var theme = await loadThemePreference();
    setTheme(theme);
    super.onInit();
  }

  void checkTheme() {
    switch (initialTheme) {
      case AppTheme.blue:
        initialThemeData = blueTheme;
        break;
      case AppTheme.dark:
        initialThemeData = darkTheme;
        break;
      case AppTheme.liquidGlass:
        initialThemeData = liquidGlassTheme;
        break;
      default:
        initialThemeData = blueTheme;
    }
  }

  Future<AppTheme> loadThemePreference() async {
    String themeString = box.read(SET_THEME) ?? AppTheme.blue.toString();
    return initialTheme = AppTheme.values.firstWhere(
      (e) => e.toString() == themeString,
      orElse: () => AppTheme.blue,
    );
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme.value = theme;
    ThemeData newThemeData;
    switch (theme) {
      case AppTheme.blue:
        newThemeData = blueTheme;
        break;
      case AppTheme.dark:
        newThemeData = darkTheme;
        break;
      case AppTheme.liquidGlass:
        newThemeData = liquidGlassTheme;
        break;
    }

    Get.changeTheme(newThemeData);

    // Save theme preference
    box.write(SET_THEME, theme.toString());
    update();
    Get.forceAppUpdate();
  }

  ThemeData get currentThemeData {
    switch (_currentTheme.value) {
      case AppTheme.blue:
        return blueTheme;
      case AppTheme.dark:
        return darkTheme;
      case AppTheme.liquidGlass:
        return liquidGlassTheme;
    }
  }

  AppTheme get currentTheme => _currentTheme.value;

  bool get isBlueMode => _currentTheme.value == AppTheme.blue;
  bool get isDarkMode => _currentTheme.value == AppTheme.dark;
  bool get isLiquidGlass => _currentTheme.value == AppTheme.liquidGlass;
}
