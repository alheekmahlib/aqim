import 'package:family_bottom_sheet/family_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import '/core/utils/constants/extensions/extensions.dart';
import '/core/utils/constants/extensions/svg_extensions.dart';
import '/core/utils/helpers/glass_tokens.dart';
import '/core/widgets/glass/glass_container.dart';
import '../../../widgets/custom_button.dart';
import '../svg_constants.dart';

extension BottomSheetExtension on void {
  /// Opens a sheet whose pages can be navigated without opening another route.
  Future<void> customFamilyBottomSheet({
    required Widget child,
    required String textTitle,
    Color? containerColor,
  }) async {
    final context = Get.context!;
    await FamilyModalSheet.show<void>(
      context: context,
      contentBackgroundColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      mainContentPadding: EdgeInsets.zero,
      mainContentBorderRadius: BorderRadius.zero,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      constraints: BoxConstraints(
        maxWidth: context.customOrientation(Get.width, Get.width * .5),
      ),
      // The package invokes this builder in initState, so defer inherited
      // widget lookups until the page is actually built.
      builder: (_) => _FamilySheetPage(
        title: textTitle,
        containerColor: containerColor,
        child: child,
      ),
    );
  }

  void customPushToPage({
    required BuildContext context,
    required Widget child,
    required String textTitle,
    Color? containerColor,
  }) {
    FamilyModalSheet.of(context).pushPage(
      _FamilySheetPage(
        title: textTitle,
        containerColor: containerColor,
        isSubpage: true,
        child: child,
      ),
    );
  }

  /// Navigates inside a family sheet when available, otherwise opens a sheet.
  void customSettingsPage({
    required BuildContext context,
    required Widget child,
    required String textTitle,
    Color? containerColor,
  }) {
    if (context.findAncestorStateOfType<FamilyModalSheetState>() != null) {
      context.customPushToPage(
        context: context,
        child: child,
        textTitle: textTitle,
        containerColor: containerColor,
      );
    } else {
      context.customBottomSheet(
        child: child,
        textTitle: textTitle,
        containerColor: containerColor,
      );
    }
  }

  void customBottomSheet({
    required Widget child,
    Widget? titleChild,
    String? textTitle,
    Color? containerColor,
    bool scrollChild = true,
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
              child: scrollChild
                  ? SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(children: [child]),
                    )
                  : child,
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

class _FamilySheetPage extends StatelessWidget {
  const _FamilySheetPage({
    required this.title,
    required this.child,
    this.containerColor,
    this.isSubpage = false,
  });

  final String title;
  final Widget child;
  final Color? containerColor;
  final bool isSubpage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox().customSvgWithColor(
                SvgPath.svgCloseCarve,
                width: 120,
                color: theme.colorScheme.inversePrimary,
              ),
              Container(
                width: 70,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const Gap(8),
          context.hDivider(
            color: theme.colorScheme.inversePrimary,
            height: 1,
            width: 70,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSubpage ? 56 : 0),
                  child: Text(
                    title.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.inversePrimary,
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                if (isSubpage)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox(
                      height: 35,
                      child: CustomButton(
                        onPressed: () => FamilyModalSheet.of(context).popPage(),
                        width: 40,
                        iconSize: 24,
                        horizontalPadding: 8.0,
                        verticalPadding: 0.0,
                        icon: Icons.arrow_back_ios,
                        svgColor: context.theme.colorScheme.surface,
                        borderColor: context.theme.colorScheme.surface
                            .withValues(alpha: .3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Gap(8),
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: child,
            ),
          ),
          const Gap(32),
        ],
      ),
    );
    final surface = context.glassTokens == null
        ? Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: containerColor ?? theme.colorScheme.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: body,
          )
        : GlassContainer(
            radius: 16,
            variant: GlassVariant.opaque,
            padding: const EdgeInsets.only(bottom: 16),
            child: body,
          );
    if (!isSubpage) return surface;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // The package also mounts an offstage copy for measuring the page.
        if (!didPop &&
            context.findAncestorWidgetOfExactType<Offstage>()?.offstage !=
                true) {
          FamilyModalSheet.of(context).popPage();
        }
      },
      child: surface,
    );
  }
}
