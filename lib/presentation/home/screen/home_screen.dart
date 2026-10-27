part of '../home.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: HomeController.instance,
      builder: (ctrl) {
        return Scaffold(
          extendBody: false,
          backgroundColor: context.theme.colorScheme.primaryContainer,
          body: SafeArea(
            child: Stack(
              children: [
                NavBarTab.values
                    .map((nav) => nav.currentScreen)
                    .toList()[ctrl.currentIndex],
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FloatyNavBar(
                    height: 45,
                    backgroundColor: context.glassTokens == null
                        ? context.theme.colorScheme.surface.withValues(
                            alpha: .8,
                          )
                        : Colors.transparent,
                    glassEffect: context.glassTokens == null
                        ? null
                        : const FloaticaGlassEffect.liquidGlass(),
                    selectedTab: ctrl.currentIndex,
                    margin: EdgeInsets.symmetric(
                      horizontal: context.customOrientation(
                        16.0,
                        Get.width * .2,
                      ),
                      vertical: 16.0,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    menu: FloaticaMenu(
                      height: context.customOrientation(400.0, Get.height * .7),
                      controller: ctrl.floatyMenuController,
                      child: const SettingsScreen(),
                      icon: Obx(
                        () => customSvgWithColor(
                          height: 30,
                          ctrl.floatyMenuController.isOpen.obs.value
                              ? SvgPath.svgHomeClose
                              : SvgPath.svgHomeSettings,
                          color: context.theme.hintColor,
                        ),
                      ),
                      title: 'settings'.tr,
                      titleStyle: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 12,
                        height: 1,
                        color: context.theme.hintColor,
                      ),
                      selectedColor: context.theme.canvasColor.withValues(
                        alpha: .2,
                      ),
                      unselectedColor: Colors.transparent,
                      selectedDisplayMode: FloaticaTabDisplayMode.iconOnly,
                      unselectedDisplayMode: FloaticaTabDisplayMode.iconOnly,
                      labelPosition: FloaticaLabelPosition.bottom,
                    ),
                    tabs: NavBarTab.values
                        .map(
                          (nav) => FloaticaTab(
                            height: 35,
                            // المؤشر الداكن يختفي فوق الزجاج الداكن — صاجاني مع الزجاج
                            indicatorColor: context.glassTokens == null
                                ? context.theme.colorScheme.primary
                                : context.theme.colorScheme.surface,
                            enableHaptics: true,
                            isSelected: ctrl.currentIndex == nav.tapIndex,
                            title: nav.label.tr,
                            margin: EdgeInsets.zero,
                            selectedColor: context.theme.canvasColor.withValues(
                              alpha: .2,
                            ),
                            unselectedColor: Colors.transparent,
                            selectedDisplayMode:
                                FloaticaTabDisplayMode.iconOnly,
                            unselectedDisplayMode:
                                FloaticaTabDisplayMode.iconOnly,
                            labelPosition: FloaticaLabelPosition.bottom,
                            titleStyle: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 12,
                              height: 1,
                              color: context.theme.hintColor,
                            ),
                            icon: customSvgWithColor(
                              height: 30,
                              nav.icon,
                              color: context.theme.hintColor,
                            ),
                            onTap: () => ctrl.changeIndex(nav.tapIndex),
                            floatyActionButton: FloaticaActionButton(
                              size: 50,
                              icon: customSvgWithColor(
                                height: 30,
                                SvgPath.svgHomeRamadan,
                                color: context.theme.hintColor,
                              ),
                              backgroundColor: context.theme.colorScheme.surface
                                  .withValues(alpha: .8),
                              onTap: () => customBottomSheet(
                                containerColor:
                                    context.theme.colorScheme.primaryContainer,
                                child: RamadanScreen(),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
