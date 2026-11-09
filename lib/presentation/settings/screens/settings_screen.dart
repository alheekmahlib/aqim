import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import '/core/utils/constants/extensions/bottom_sheet_extension.dart';
import '/core/utils/constants/extensions/svg_extensions.dart';
import '/presentation/prayers/prayers.dart';
import '../../../core/utils/constants/svg_constants.dart';
import '../../../core/widgets/glass/glass_container.dart';
import '../../home/home.dart';
import '../widgets/settings_list.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const Gap(16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GlassContainer(
              useBackdrop: false,
              onTap: () {
                if (HomeController.instance.floatyMenuController.isOpen) {
                  HomeController.instance.floatyMenuController.close();
                }
                context.customFamilyBottomSheet(
                  containerColor: context.theme.colorScheme.primaryContainer,
                  textTitle: 'prayerSetting',
                  child: const PrayerSettings(),
                );
              },
              radius: 24,
              variant: GlassVariant.subtle,
              padding: const EdgeInsets.all(8),
              border: Border.all(color: context.theme.canvasColor, width: 1),
              backgroundColor: context.theme.canvasColor.withValues(alpha: .3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Gap(8),
                  customSvgWithColor(
                    SvgPath.svgHomeSettings,
                    height: 22,
                    color: context.theme.canvasColor,
                  ),
                  const Gap(16),
                  Text(
                    'prayerSetting'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      color: context.theme.canvasColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'cairo',
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // const Gap(8),
          SettingsList(),
          const Gap(80),
        ],
      ),
    );
  }
}
