part of '../../prayers.dart';

class PrayerDashboardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DashboardLayoutController>()) {
      Get.put(
        DashboardLayoutController(
          CustomizeDashboard(StoredDashboardLayout(GetStorage())),
        ),
      );
    }
    if (!Get.isRegistered<DashboardController>()) {
      final layout = Get.find<DashboardLayoutController>();
      final controller = Get.put(
        DashboardController(
          PreparePrayerDashboard(
            AdhanDashboardRepository(
              AdhanController.instance,
              GeneralController.instance,
              EventController.instance,
              readLocationName: () =>
                  AdhanController.instance.localizedLocation,
            ),
          ),
          const SystemDashboardClock(),
          onExit: () =>
              PrayersNotificationsCtrl.instance.state.adhanPlayer.stop(),
        ),
      );
      void sync(DashboardLayout value) => controller.setCountdownVisible(
        value.panels.any((p) => p.panel == PrayerPanel.countdown && p.visible),
      );
      sync(layout.layout.value);
      controller.attachLayoutWorker(ever(layout.layout, sync));
    } else {
      Get.find<DashboardController>().setVisible(true);
    }
  }
}
