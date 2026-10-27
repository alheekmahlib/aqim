import 'package:aqim/presentation/splash/splash.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '/core/widgets/glass/glass_background.dart';
import '/core/widgets/local_notification/controller/local_notifications_controller.dart';
import 'core/services/languages/app_constants.dart';
import 'core/services/languages/localization_controller.dart';
import 'core/services/languages/messages.dart';
import 'core/services/services_locator.dart';
import 'core/utils/helpers/app_router.dart';
import 'core/utils/helpers/glass_tokens.dart';
import 'presentation/controllers/theme_controller.dart';

class MyApp extends StatelessWidget {
  final Map<String, Map<String, String>> languages;

  const MyApp({super.key, required this.languages});

  @override
  Widget build(BuildContext context) {
    sl<ThemeController>().checkTheme();
    final localizationCtrl = Get.find<LocalizationController>();
    LocalNotificationsController.instance;
    const TextScaler fixedScaler = TextScaler.linear(1.0);
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      // Use builder only if you need to use library outside ScreenUtilInit context
      builder: (_, child) {
        return GetBuilder<ThemeController>(
          builder: (themeCtrl) => GetMaterialApp(
            // navigatorKey: sl<GeneralController>().navigatorNotificationKey,
            debugShowCheckedModeBanner: false,
            title: 'Al Quran Al Kareem',
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            locale: localizationCtrl.locale,
            translations: Messages(languages: languages),
            fallbackLocale: Locale(
              AppConstants.languages[1].languageCode,
              AppConstants.languages[1].countryCode,
            ),
            theme: themeCtrl.currentThemeData,
            // theme: brownTheme,
            builder: (context, child) {
              // الحفاظ على BotToast مع ضبط الاتجاه ديناميكياً حسب اللغة
              final botToast = BotToastInit();
              final botChild = botToast(context, child);
              final langCode =
                  Get.locale?.languageCode ??
                  localizationCtrl.locale.languageCode;
              const rtlLangs = {'ar', 'ku', 'ur', 'fa'};
              final isRtl = rtlLangs.contains(langCode);
              final mq = MediaQuery.of(context);
              // خلفية الزجاج خلف كل الشاشات — تظهر فقط مع ثيم Liquid Glass
              final glassBackground = context.glassTokens == null
                  ? null
                  : const GlassBackground();
              return MediaQuery(
                data: mq.copyWith(textScaler: fixedScaler),
                child: Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: glassBackground == null
                      ? botChild
                      : Stack(
                          children: [
                            Positioned.fill(child: glassBackground),
                            botChild,
                          ],
                        ),
                ),
              );
            },
            navigatorObservers: [BotToastNavigatorObserver()],
            getPages: AppRouter.pages,
            home: SplashScreen(),
          ),
        );
      },
    );
  }
}
