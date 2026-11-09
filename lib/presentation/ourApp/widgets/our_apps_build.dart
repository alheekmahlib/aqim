import 'package:connectivity_kit/connectivity_kit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/core/utils/constants/lottie_constants.dart';
import '../../../../core/services/services_locator.dart';
import '../../../../core/utils/constants/extensions/extensions.dart';
import '../../../../core/utils/constants/lottie.dart';
import '../controller/our_apps_controller.dart';
import 'app_card.dart';

/// بناء قائمة "تطبيقاتنا" مع حالات التحميل والخطأ وانقطاع الاتصال.
class OurAppsBuild extends StatelessWidget {
  const OurAppsBuild({super.key});

  @override
  Widget build(BuildContext context) {
    final ourApps = sl<OurAppsController>();
    final controller = ConnectionController.instance;
    if (!controller.isOnline) {
      return Center(
        child: customLottieWithColor(
          LottieConstants.assetsLottieNoInternet,
          width: 150.0,
          height: 150.0,
          color: context.theme.colorScheme.surface.withValues(alpha: .7),
        ),
      );
    }
    return Obx(() {
      if (ourApps.isLoading.value) {
        return Center(
          child: customLottie(
            LottieConstants.assetsLottieSplashLoading,
            width: 200.0,
            height: 200.0,
          ),
        );
      }
      if (ourApps.errorMessage.value.isNotEmpty) {
        return Center(
          child: customLottie(
            LottieConstants.assetsLottieNoInternet,
            width: 150.0,
            height: 150.0,
          ),
        );
      }
      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: ourApps.apps.length,
        separatorBuilder: (context, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: context.hDivider(),
        ),
        itemBuilder: (context, index) =>
            AppCard(app: ourApps.apps[index], onLaunch: ourApps.launchApp),
      );
    });
  }
}
