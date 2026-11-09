import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import '/core/utils/constants/extensions/extensions.dart';
import '/core/utils/constants/extensions/svg_extensions.dart';
import '../../../core/utils/constants/svg_constants.dart';
import '../../../core/utils/helpers/app_router.dart';
import '../../../core/widgets/container_button_widget.dart';
import '../../controllers/general/general_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../home/home.dart';
import 'language_list.dart';
import 'theme_change.dart';

class SettingsList extends StatelessWidget {
  SettingsList({super.key});
  final generalCtrl = GeneralController.instance;

  /// التنقل من داخل قائمة الشريط العائم: نغلق القائمة أولاً حتى لا تبقى
  /// طبقة الإغلاق (barrier) الخاصة بها فوق المسار الجديد فتبتلع النقرات،
  /// فيتعطل زر الرجوع بينما يظل سحب الحافة يعمل.
  void _navigateFromMenu(String route) {
    HomeController.instance.floatyMenuController.close();
    Future.delayed(const Duration(seconds: 5));
    if (HomeController.instance.floatyMenuController.isOpen.obs.value) {
      log('floatyMenuController opened');
    }
    Get.toNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              const LanguageList(),
              const Gap(8),
              ThemeChange(),
              const Gap(8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: context.theme.highlightColor,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _customButtonWidget(
                      context,
                      title: 'ourApps',
                      svgPath: SvgPath.svgAlheekmahLogo,
                      onTap: () => _navigateFromMenu(AppRouter.ourApps),
                    ),
                    const Gap(4),
                    _customButtonWidget(
                      context,
                      title: 'aboutApp',
                      iconWidth: 40.0,
                      svgPath: SvgPath.svgLogoAqemLogo,
                      onTap: () => _navigateFromMenu(AppRouter.aboutApp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _customButtonWidget(
    BuildContext context, {
    required VoidCallback onTap,
    required String svgPath,
    required String title,
    double? iconWidth,
  }) {
    return SizedBox(
      height: 45,
      child: ContainerButtonWidget(
        glassBackdrop: false,
        onPressed: onTap,
        backgroundColor: context.theme.colorScheme.primaryContainer,
        svgColor: context.theme.colorScheme.surface,
        shapeColor: context.theme.colorScheme.surface.withValues(alpha: 0.1),
        verticalPadding: 0.0,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: customSvgWithColor(
                svgPath,
                width: (iconWidth ?? 60.0),
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
            context.vDivider(height: 20.0),
            Expanded(
              flex: 8,
              child: Text(
                title.tr,
                style: TextStyle(
                  fontSize: 17,
                  color: context.theme.colorScheme.inversePrimary.withValues(
                    alpha: .6,
                  ),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'cairo',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
