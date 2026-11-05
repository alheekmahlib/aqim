part of '../../prayers.dart';

class DashboardLayoutController extends GetxController {
  DashboardLayoutController(this.customize);
  final CustomizeDashboard customize;
  final layout = DashboardLayout.defaults().obs;
  final saveFailed = false.obs;
  Future<void> _writes = Future.value();

  @override
  void onInit() {
    super.onInit();
    layout.value = customize.load();
  }

  Future<void> toggle(PrayerPanel panel, bool visible) =>
      _persist(layout.value.toggle(panel, visible));
  void reorder(int oldIndex, int newIndex) =>
      _persist(layout.value.reorder(oldIndex, newIndex));
  void reset() => _persist(customize.defaults());
  void retrySave() => _persist(layout.value);

  Future<void> _persist(DashboardLayout next) {
    layout.value = next;
    // Serialize disk writes so rapid toggles cannot restore an older layout.
    _writes = _writes.then((_) async {
      try {
        await customize.save(next);
        if (!isClosed) saveFailed.value = false;
      } catch (_) {
        if (!isClosed) saveFailed.value = true;
      }
    });
    return _writes;
  }

  Future<void> get pendingWrites => _writes;
}
