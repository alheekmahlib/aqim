import 'package:aqim/core/utils/constants/extensions/svg_extensions.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import '../../../core/utils/constants/lists.dart';
import '../../../core/utils/constants/svg_constants.dart';
import '../../controllers/theme_controller.dart';
import 'button_with_new_style.dart';

class ThemeChange extends StatelessWidget {
  ThemeChange({super.key});

  final themeCtrl = ThemeController.instance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'themeTitle'.tr,
              style: TextStyle(
                color: context.theme.colorScheme.inversePrimary,
                fontFamily: 'cairo',
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Gap(4),
            Container(
              width: Get.width,
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.theme.highlightColor,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                children: List.generate(
                  themeList.length,
                  (index) => ButtonWithNewStyle(
                    onTap: () async {
                      await themeCtrl.setTheme(themeList[index]['name']);
                      Get.forceAppUpdate().then((_) {
                        Get.back();
                      });
                    },
                    controller: themeCtrl,
                    containerHeight: 70,
                    value: themeList[index]['name'] == themeCtrl.currentTheme,
                    imagePath: null,
                    svgPath: null,
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.dark == themeList[index]['name']
                            ? context.theme.colorScheme.primary
                            : AppTheme.blue == themeList[index]['name']
                            ? context.theme.canvasColor
                            : context.theme.colorScheme.primary.withValues(
                                alpha: .4,
                              ),
                      ),
                      child: customSvgWithCustomColor(
                        SvgPath.svgLogoAqemLogo,
                        height: 20,
                        color: context.theme.colorScheme.surface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
