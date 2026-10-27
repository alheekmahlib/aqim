import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import '/core/services/location/locations.dart';
import '/core/utils/constants/extensions/bottom_sheet_extension.dart';
import '/core/utils/constants/extensions/extensions.dart';
import '/presentation/controllers/general/general_controller.dart';
import '../../../../core/utils/constants/lottie.dart';
import '../../../../core/utils/constants/lottie_constants.dart';
import '../../../../core/widgets/container_button_widget.dart';
import '../../../controllers/huawei_map_controller.dart';
import '../../splash.dart';
import 'huawei_map_widget.dart';

class ActiveLocationWidget extends StatelessWidget {
  ActiveLocationWidget({super.key});

  final generalCtrl = GeneralController.instance;
  final mapCtrl = FlutterMapController.instance;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: HuaweiLocationHelper.instance.isHuaweiDevice(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final isHuaweiDevice = snapshot.data ?? false;

        return context.customOrientation(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Gap(16),
              customLottieWithColor(
                LottieConstants.assetsLottieLocation,
                height: 150.0.h,
                color: context.theme.colorScheme.surface,
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 32.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                decoration: BoxDecoration(
                  color: context.theme.colorScheme.surface.withValues(
                    alpha: .2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'locationNote'.tr,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 12.sp.clamp(12, 22),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: context.theme.canvasColor,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              const Spacer(),
              _buttonsBuild(context, isHuaweiDevice),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Opacity(
                      opacity: 0.2,
                      child: customLottieWithColor(
                        LottieConstants.assetsLottieLocation,
                        width: 250.0,
                        color: context.theme.colorScheme.surface,
                      ),
                    ),
                    // const Spacer(),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _buttonsBuild(context, isHuaweiDevice),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: context.theme.colorScheme.surface.withValues(
                      alpha: .2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'locationNote'.tr,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 8.sp.clamp(8, 18),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: context.theme.canvasColor,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMapBottomSheet(BuildContext context) {
    customBottomSheet(
      textTitle: 'searchForCity'.tr,
      containerColor: context.theme.colorScheme.primaryContainer,
      child: const HuaweiMapLocationWidget(),
    );
  }

  Widget _buttonsBuild(BuildContext context, bool isHuaweiDevice) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          !isHuaweiDevice
              ? Obx(
                  () => ContainerButtonWidget(
                    onPressed: generalCtrl.state.isLocationLoading.value
                        ? null
                        : () async =>
                              await generalCtrl.initLocation().then((_) async {
                                generalCtrl.state.activeLocation.value = true;
                                await SplashScreenController.instance
                                    .isNotificationAllowed();
                              }),
                    height: 45,
                    width: Get.width,
                    horizontalMargin: 0,
                    useGradient: false,
                    withShape: false,
                    isLoading: generalCtrl.state.isLocationLoading.value,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    borderColor: context.theme.colorScheme.surface,
                    title: isHuaweiDevice ? 'searchForCity'.tr : 'locate'.tr,
                  ),
                )
              : const SizedBox.shrink(),
          !isHuaweiDevice ? const Gap(8) : const SizedBox.shrink(),
          ContainerButtonWidget(
            onPressed: () => context.showSearchBottomSheet(context),
            height: 45,
            width: Get.width,
            horizontalMargin: 0,
            useGradient: false,
            withShape: false,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            borderColor: context.theme.colorScheme.surface,
            title: 'searchForCity'.tr,
          ),
          const Gap(8),
          ContainerButtonWidget(
            onPressed: () => _showMapBottomSheet(context),
            height: 45,
            width: Get.width,
            horizontalMargin: 0,
            useGradient: false,
            withShape: false,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            borderColor: context.theme.colorScheme.surface,
            title: 'selectFromMap'.tr,
          ),
          const Gap(8),
          ContainerButtonWidget(
            onPressed: () async => await generalCtrl.cancelLocation(),
            height: 45,
            width: Get.width,
            horizontalMargin: 0,
            useGradient: false,
            withShape: false,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            borderColor: Colors.red,
            title: 'cancel'.tr,
          ),
        ],
      ),
    );
  }
}
