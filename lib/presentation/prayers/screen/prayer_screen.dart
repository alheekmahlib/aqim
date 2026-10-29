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
              trailing: IconButton(
                key: const ValueKey('customize-prayer-dashboard'),
                tooltip: 'dashboardCustomize'.tr,
                onPressed: () => _customize(context),
                icon: const Icon(Icons.dashboard_customize_outlined),
                color: Theme.of(context).colorScheme.inversePrimary,
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
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              key: const PageStorageKey('prayer-dashboard'),
              padding: const EdgeInsets.only(top: 16, bottom: 120),
              children: [
                if (refreshing) const LinearProgressIndicator(),
                if (locationFailed)
                  TextButton(
                    onPressed: controller.updateLocation,
                    child: Text('dashboardLocationRetry'.tr),
                  ),
                for (final preference in panels)
                  KeyedSubtree(
                    key: ValueKey('panel-${preference.panel.id}'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: dashboardRegistry[preference.panel]!.builder(
                        panelContext,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
    }
  }
}
