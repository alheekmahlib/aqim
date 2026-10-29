import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:aqim/presentation/prayers/dashboard/domain/dashboard_data.dart';
import 'package:aqim/presentation/prayers/dashboard/domain/dashboard_layout.dart';
import 'package:aqim/presentation/prayers/dashboard/presentation/dashboard_controller.dart';
import 'package:aqim/presentation/prayers/dashboard/presentation/dashboard_layout_controller.dart';
import 'fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => Get.reset());

  test(
    'latest selected date wins when responses arrive out of order',
    () async {
      final repository = FakeDataRepository()..delayed = true;
      final clock = FakeClock();
      final controller = Get.put(
        DashboardController(PreparePrayerDashboard(repository), clock),
      );
      final select = controller.selectDate(DateTime(2026, 10, 28));
      repository.requests.last.result.complete(
        dashboardFixture(DateTime(2026, 10, 28)),
      );
      await select;
      repository.requests.first.result.complete(
        dashboardFixture(DateTime(2026, 10, 26)),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.data.value!.date, DateTime(2026, 10, 28));
      expect(controller.countdown.value!.next.at, DateTime(2026, 10, 27, 5));
      await Get.delete<DashboardController>();
      await repository.events.close();
      await clock.stream.close();
    },
  );
  test(
    'clock advances today, pauses in background and releases subscriptions',
    () async {
      final repository = FakeDataRepository();
      final clock = FakeClock();
      final controller = Get.put(
        DashboardController(PreparePrayerDashboard(repository), clock),
      );
      await controller.reload();
      controller.setCountdownVisible(true);
      expect(clock.interval, const Duration(seconds: 1));
      clock.emit(DateTime(2026, 10, 26, 21, 0, 1));
      expect(
        controller.countdown.value!.remaining,
        const Duration(hours: 7, minutes: 59, seconds: 59),
      );
      clock.emit(DateTime(2026, 10, 27, 0));
      await Future<void>.delayed(Duration.zero);
      expect(controller.selectedDate.value, DateTime(2026, 10, 27));
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(clock.stream.hasListener, isFalse);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(clock.stream.hasListener, isTrue);
      controller.setCountdownVisible(false);
      expect(clock.interval, const Duration(minutes: 1));
      controller.setVisible(false);
      expect(clock.stream.hasListener, isFalse);
      await Future<void>.delayed(Duration.zero);
      clock.value = DateTime(2026, 10, 28, 8);
      controller.setVisible(true);
      await Future<void>.delayed(Duration.zero);
      expect(controller.selectedDate.value, DateTime(2026, 10, 28));
      await Get.delete<DashboardController>();
      expect(repository.events.hasListener, isFalse);
      await repository.events.close();
      await clock.stream.close();
    },
  );
  test('missing location, errors and retry are explicit view states', () async {
    final repository = FakeDataRepository()
      ..availability = DashboardAvailability.locationRequired;
    final clock = FakeClock();
    final controller = Get.put(
      DashboardController(PreparePrayerDashboard(repository), clock),
    );
    await controller.reload();
    expect(controller.status.value, DashboardStatus.locationRequired);
    repository.availability = DashboardAvailability.ready;
    repository.fail = true;
    await controller.reload();
    expect(controller.status.value, DashboardStatus.error);
    repository.fail = false;
    await controller.reload();
    expect(controller.status.value, DashboardStatus.ready);
    await Get.delete<DashboardController>();
    await repository.events.close();
    await clock.stream.close();
  });
  test(
    'rapid edits persist the last order and save failure can be retried',
    () async {
      final repository = MemoryLayout();
      final controller = Get.put(
        DashboardLayoutController(CustomizeDashboard(repository)),
      );
      controller.toggle(PrayerPanel.moon, true);
      controller.reorder(6, 0);
      controller.toggle(PrayerPanel.currentPrayer, false);
      await controller.pendingWrites;
      expect(repository.value.panels.first.panel, PrayerPanel.moon);
      expect(repository.value.panels.first.visible, isTrue);
      repository.fail = true;
      controller.reset();
      await controller.pendingWrites;
      expect(controller.saveFailed.value, isTrue);
      repository.fail = false;
      controller.retrySave();
      await controller.pendingWrites;
      expect(controller.saveFailed.value, isFalse);
      final restored = DashboardLayoutController(CustomizeDashboard(repository))
        ..onInit();
      expect(
        restored.layout.value.panels.first.panel,
        PrayerPanel.currentPrayer,
      );
    },
  );
}
