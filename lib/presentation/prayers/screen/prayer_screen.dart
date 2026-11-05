part of '../prayers.dart';

class PrayerScreen extends StatelessWidget {
  PrayerScreen({
    super.key,
    DashboardController? controller,
    DashboardLayoutController? layoutController,
  }) : controller = controller ?? Get.find<DashboardController>(),
       layoutController =
           layoutController ?? Get.find<DashboardLayoutController>();

  final DashboardController controller;
  final DashboardLayoutController layoutController;
  static const presenter = DashboardPresenter();

  void _customize(BuildContext context) => context.customBottomSheet(
    textTitle: 'dashboardCustomize',
    scrollChild: false,
    containerColor: Theme.of(context).colorScheme.primaryContainer,
    child: DashboardCustomizationSheet(controller: layoutController),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      controller.leaveScreen();
      Get.back();
    },
    child: Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: SafeArea(
        child: Column(
          children: [
            AppBarWidget(
              trailing: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    SizedBox(
                      height: 35,
                      child: CustomButton(
                        onPressed: () => context.customBottomSheet(
                          containerColor:
                              context.theme.colorScheme.primaryContainer,
                          textTitle: 'sharePrayerTime',
                          child: ShareOptionsWidget(),
                        ),
                        width: 40,
                        iconSize: 28,
                        isCustomSvgColor: true,
                        svgPath: SvgPath.svgShareShare,
                        svgColor: context.theme.colorScheme.surface,
                        borderColor: context.theme.colorScheme.surface
                            .withValues(alpha: .3),
                      ),
                    ),
                    SizedBox(
                      height: 35,
                      child: CustomButton(
                        key: const ValueKey('customize-prayer-dashboard'),
                        onPressed: () => _customize(context),
                        width: 40,
                        iconSize: 24,
                        horizontalPadding: 0.0,
                        verticalPadding: 0.0,
                        isCustomSvgColor: true,
                        icon: Icons.dashboard_customize_outlined,
                        svgColor: context.theme.colorScheme.surface,
                        borderColor: context.theme.colorScheme.surface
                            .withValues(alpha: .3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GetBuilder<LocalizationController>(
                id: 'changeLanguage',
                builder: (_) => Obx(() => _content(context)),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _content(BuildContext context) {
    final panels = layoutController.layout.value.panels
        .where((p) => p.visible)
        .toList();
    if (panels.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('dashboardEmpty'.tr, style: dashboardText(context)),
            TextButton(
              onPressed: () => _customize(context),
              child: Text('dashboardAdd'.tr),
            ),
          ],
        ),
      );
    }
    switch (controller.status.value) {
      case DashboardStatus.locationRequired:
        return Center(child: ActiveLocationButton());
      case DashboardStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case DashboardStatus.error:
        return Center(
          child: TextButton.icon(
            onPressed: controller.reload,
            icon: const Icon(Icons.refresh),
            label: Text('dashboardLoadRetry'.tr),
          ),
        );
      case DashboardStatus.ready:
        final data = controller.data.value;
        if (data == null) return const SizedBox.shrink();
        // Read reactive values before handing the non-reactive context to builders.
        final formatted = presenter.present(data, controller.now.value);
        final refreshing = controller.refreshingLocation.value;
        final locationFailed = controller.locationFailed.value;
        final panelContext = DashboardPanelContext(
          formatted,
          controller,
          presenter.week(data, controller.now.value),
        );
        final useColumns =
            Theme.of(context).platform == TargetPlatform.macOS ||
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final panelWidgets = [
          for (final preference in panels)
            KeyedSubtree(
              key: ValueKey('panel-${preference.panel.id}'),
              child: dashboardRegistry[preference.panel]!.builder(panelContext),
            ),
        ];
        final statusWidgets = [
          if (refreshing) const LinearProgressIndicator(),
          if (locationFailed)
            TextButton(
              onPressed: controller.updateLocation,
              child: Text('dashboardLocationRetry'.tr),
            ),
        ];
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: useColumns ? 1200 : 760),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                // Keep cards readable as the viewport gains or loses columns.
                final columns = math.max(
                  1,
                  ((constraints.maxWidth + spacing) / (360 + spacing)).floor(),
                );
                if (!useColumns) {
                  return ListView(
                    key: const PageStorageKey('prayer-dashboard'),
                    padding: const EdgeInsets.only(top: 16, bottom: 120),
                    children: [
                      ...statusWidgets,
                      for (final panel in panelWidgets)
                        Padding(
                          padding: const EdgeInsets.only(bottom: spacing),
                          child: panel,
                        ),
                    ],
                  );
                }
                return SingleChildScrollView(
                  key: const PageStorageKey('prayer-dashboard'),
                  padding: const EdgeInsets.only(top: 16, bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...statusWidgets,
                      StaggeredGrid.count(
                        crossAxisCount: columns,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        children: [
                          for (final panel in panelWidgets)
                            StaggeredGridTile.fit(
                              key: ValueKey(('tile', panel.key)),
                              crossAxisCellCount: 1,
                              child: panel,
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
    }
  }
}
