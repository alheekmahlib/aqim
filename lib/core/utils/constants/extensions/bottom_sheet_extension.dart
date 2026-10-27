import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import '/core/utils/constants/extensions/extensions.dart';
import '/core/utils/constants/extensions/svg_extensions.dart';
import '/core/utils/helpers/glass_tokens.dart';
import '/core/widgets/glass/glass_container.dart';
import '../svg_constants.dart';

extension BottomSheetExtension on void {
  void customBottomSheet({
    required Widget child,
    Widget? titleChild,
    String? textTitle,
    Color? containerColor,
  }) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      isDismissible: true,
      // showDragHandle: true,
      constraints: BoxConstraints(
        maxWidth: Get.context!.customOrientation(Get.width, Get.width * .5),
      ),
      builder: (context) {
        final Widget body = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox().customSvgWithColor(
                  SvgPath.svgCloseCarve,
                  width: 120,
                  color: Theme.of(Get.context!).colorScheme.inversePrimary,
                ),
                Container(
                  width: 70,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(Get.context!).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const Gap(8),
            Get.context!.hDivider(
              color: Theme.of(Get.context!).colorScheme.inversePrimary,
              height: 1,
              width: 70,
            ),
            if (textTitle != null || titleChild != null) ...[
              titleChild ??
                  Text(
                    textTitle?.tr ?? '',
                    style: TextStyle(
                      color: Theme.of(Get.context!).colorScheme.inversePrimary,
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
            ],
            const Gap(8),
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(children: [child]),
              ),
            ),
            const Gap(32),
          ],
        );
        if (context.glassTokens == null) {
          return Container(
            padding: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color:
                  containerColor ?? Theme.of(Get.context!).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: body,
          );
        }
        // النسخة الزجاجية: شكل Liquid Glass بدل الحاوية المصمتة
        return GlassContainer(
          radius: 16,
          variant: GlassVariant.opaque,
          padding: const EdgeInsets.only(bottom: 16.0),
          child: body,
        );
      },
    );
  }
}
