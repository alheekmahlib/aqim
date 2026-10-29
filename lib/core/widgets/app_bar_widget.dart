import 'package:aqim/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:get/route_manager.dart';

import '/core/utils/constants/extensions/svg_extensions.dart';
import '../utils/constants/svg_constants.dart';

class AppBarWidget extends StatelessWidget {
  final bool? withBackButton;
  final Widget? trailing;
  const AppBarWidget({super.key, this.withBackButton = false, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface.withValues(alpha: .1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16.0),
          bottomRight: Radius.circular(16.0),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (trailing != null)
            Align(alignment: AlignmentDirectional.centerEnd, child: trailing),
          customSvgWithCustomColor(
            SvgPath.svgLogoAqemLogo,
            height: 25,
            color: context.theme.colorScheme.surface,
          ),
          withBackButton!
              ? Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: CustomButton(
                    onPressed: () => Get.back(),
                    width: 60,
                    iconSize: 24,
                    icon: Icons.arrow_back_ios,
                    svgColor: context.theme.colorScheme.inversePrimary,
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
