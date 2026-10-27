import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'glass_tokens.dart';

final ThemeData blueTheme = ThemeData.light(useMaterial3: false).copyWith(
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xff001A23),
    onPrimary: Color(0xff001A23),
    secondary: Color(0xffeFF4FE),
    onSecondary: Color(0xff31493C),
    error: Color(0xffB3EFB2),
    onError: Color(0xffB3EFB2),
    surface: Color(0xff7A9E7E),
    onSurface: Color(0xffB3EFB2),
    inversePrimary: Color(0xff000000),
    inverseSurface: Color(0xffCD9974),
    primaryContainer: Color(0xffE8F1F2),
    onPrimaryContainer: Color(0xfff3efdf),
    onInverseSurface: Color(0xff000000),
    surfaceContainer: Color(0xfffaf7f3),
    secondaryContainer: Color(0xffFFFFFF),
  ),
  primaryColor: const Color(0xff001A23),
  primaryColorLight: const Color(0xff7A9E7E),
  primaryColorDark: const Color(0xff001A23),
  dividerColor: const Color(0xff31493C),
  highlightColor: const Color(0xff7A9E7E).withValues(alpha: 0.4),
  scaffoldBackgroundColor: const Color(0xff001A23),
  canvasColor: const Color(0xffEFF4FE),
  hoverColor: const Color(0xffEFF4FE).withValues(alpha: 0.3),
  disabledColor: const Color(0Xff000000),
  hintColor: const Color(0xff001A23),
  focusColor: const Color(0xffB3EFB2),
  secondaryHeaderColor: const Color(0xff7A9E7E),
  cardColor: const Color(0xff001A23),
  dividerTheme: const DividerThemeData(color: Color(0xff31493C)),
  textSelectionTheme: TextSelectionThemeData(
    selectionColor: const Color(0xffB3EFB2).withValues(alpha: 0.3),
    selectionHandleColor: const Color(0xffB3EFB2),
  ),
  cupertinoOverrideTheme: const CupertinoThemeData(
    primaryColor: Color(0xff7A9E7E),
  ),
  timePickerTheme: TimePickerThemeData(
    backgroundColor: const Color(0xff31493C),
    dialBackgroundColor: const Color(0xffEFF4FE),
    dialHandColor: const Color(0xff31493C),
    dialTextColor: const Color(0xff000000).withValues(alpha: .6),
    entryModeIconColor: const Color(0xff000000).withValues(alpha: .6),
    hourMinuteTextColor: const Color(0xff000000).withValues(alpha: .6),
    dayPeriodTextColor: const Color(0xff000000).withValues(alpha: .6),
    cancelButtonStyle: ButtonStyle(
      backgroundColor: WidgetStateProperty.all(
        const Color(0xff000000).withValues(alpha: .6),
      ),
      foregroundColor: WidgetStateProperty.all(const Color(0xffEFF4FE)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontFamily: 'cairo', fontSize: 16),
      ),
    ),
    confirmButtonStyle: ButtonStyle(
      backgroundColor: WidgetStateProperty.all(
        const Color(0xff000000).withValues(alpha: .8),
      ),
      foregroundColor: WidgetStateProperty.all(const Color(0xffEFF4FE)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontFamily: 'cairo', fontSize: 16),
      ),
    ),
  ),
  textTheme: const TextTheme(
    titleMedium: TextStyle(
      fontWeight: FontWeight.bold,
      fontFamily: 'cairo',
      fontSize: 12,
      color: Color(0xff001A23),
    ),
  ),
);

final ThemeData darkTheme = ThemeData.dark(useMaterial3: false).copyWith(
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xff001A23),
    onPrimary: Color(0xff000000),
    secondary: Color(0xffeFF4FE),
    onSecondary: Color(0xff373737),
    error: Color(0xff001A23),
    onError: Color(0xff001A23),
    surface: Color(0xff7A9E7E),
    onSurface: Color(0xff001A23),
    inversePrimary: Color(0xffeFF4FE),
    inverseSurface: Color(0xffCD9974),
    primaryContainer: Color(0xff001A23),
    onPrimaryContainer: Color(0xff1E1E1E),
    onInverseSurface: Color(0xff000000),
    surfaceContainer: Color(0xff1E1E1E),
    secondaryContainer: Color(0xff1E1E1E),
  ),
  primaryColor: const Color(0xff1E1E1E),
  primaryColorLight: const Color(0xff373737),
  primaryColorDark: const Color(0xff010101),
  dividerColor: const Color(0xff001A23),
  highlightColor: const Color(0xff7A9E7E).withValues(alpha: 0.2),
  scaffoldBackgroundColor: const Color(0xff000000),
  canvasColor: const Color(0xffF6F6EE),
  hoverColor: const Color(0xffF6F6EE).withValues(alpha: 0.3),
  disabledColor: const Color(0xff000000),
  hintColor: const Color(0xffeFF4FE),
  focusColor: const Color(0xff001A23),
  secondaryHeaderColor: const Color(0xff001A23),
  cardColor: const Color(0xffF6F6EE),
  textSelectionTheme: TextSelectionThemeData(
    selectionColor: const Color(0xff001A23).withValues(alpha: 0.3),
    selectionHandleColor: const Color(0xff001A23),
  ),
  cupertinoOverrideTheme: const CupertinoThemeData(
    primaryColor: Color(0xff001A23),
  ),
  timePickerTheme: TimePickerThemeData(
    backgroundColor: const Color(0xff7A9E7E),
    dialBackgroundColor: const Color(0xff1E1E1E),
    dialHandColor: const Color(0xff7A9E7E),
    dialTextColor: const Color(0xffF6F6EE).withValues(alpha: .6),
    entryModeIconColor: const Color(0xffF6F6EE).withValues(alpha: .6),
    hourMinuteTextColor: const Color(0xffF6F6EE).withValues(alpha: .6),
    dayPeriodTextColor: const Color(0xffF6F6EE).withValues(alpha: .6),
    dayPeriodColor: const Color(0xff1E1E1E),
    cancelButtonStyle: ButtonStyle(
      backgroundColor: WidgetStateProperty.all(
        const Color(0xffF6F6EE).withValues(alpha: .6),
      ),
      foregroundColor: WidgetStateProperty.all(const Color(0xff1E1E1E)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontFamily: 'cairo', fontSize: 16),
      ),
    ),
    confirmButtonStyle: ButtonStyle(
      backgroundColor: WidgetStateProperty.all(
        const Color(0xffF6F6EE).withValues(alpha: .8),
      ),
      foregroundColor: WidgetStateProperty.all(const Color(0xff1E1E1E)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontFamily: 'cairo', fontSize: 16),
      ),
    ),
  ),
  textTheme: const TextTheme(
    titleMedium: TextStyle(
      fontWeight: FontWeight.bold,
      fontFamily: 'cairo',
      fontSize: 12,
      color: Color(0xff001A23),
    ),
  ),
);

/// Dark Liquid Glass theme: a deep petrol gradient backdrop with light
/// text roles (mirroring [darkTheme] semantics) and translucent dark
/// content surfaces, so glass shapes blur a colorful backdrop and their
/// refraction/edges read clearly.
final ThemeData liquidGlassTheme = ThemeData.light(useMaterial3: false)
    .copyWith(
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xff001A23),
        onPrimary: Color(0xff000000),
        secondary: Color(0xffeFF4FE),
        onSecondary: Color(0xff373737),
        error: Color(0xff001A23),
        onError: Color(0xff001A23),
        surface: Color(0xff7A9E7E),
        onSurface: Color(0xff001A23),
        inversePrimary: Color(0xffeFF4FE),
        inverseSurface: Color(0xffCD9974),
        primaryContainer: Color(0x66001A23),
        onPrimaryContainer: Color(0xffeFF4FE),
        onInverseSurface: Color(0xff000000),
        surfaceContainer: Color(0x801E1E1E),
        secondaryContainer: Color(0x661E1E1E),
      ),
      primaryColor: const Color(0xff001A23),
      primaryColorLight: const Color(0xff7A9E7E),
      primaryColorDark: const Color(0xff010101),
      dividerColor: const Color(0xff001A23),
      highlightColor: const Color(0xff7A9E7E).withValues(alpha: 0.2),
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: const Color(0xffF6F6EE),
      hoverColor: const Color(0xffF6F6EE).withValues(alpha: 0.3),
      disabledColor: const Color(0Xff000000),
      hintColor: const Color(0xffeFF4FE),
      focusColor: const Color(0xffB3EFB2),
      secondaryHeaderColor: const Color(0xff001A23),
      cardColor: const Color(0xCCF6F6EE),
      dividerTheme: const DividerThemeData(color: Color(0xff001A23)),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: const Color(0xffB3EFB2).withValues(alpha: 0.3),
        selectionHandleColor: const Color(0xffB3EFB2),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: Color(0xff7A9E7E),
      ),
      textTheme: const TextTheme(
        titleMedium: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'cairo',
          fontSize: 12,
          color: Color(0xffeFF4FE),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[GlassTokens.defaults],
    );
