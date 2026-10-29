import 'package:flutter_test/flutter_test.dart';
import 'package:aqim/presentation/prayers/dashboard/domain/dashboard_data.dart';
import 'package:aqim/presentation/prayers/dashboard/domain/dashboard_layout.dart';
import 'package:aqim/presentation/prayers/dashboard/data/stored_dashboard_layout.dart';
import 'fixtures.dart';

void main() {
  test('defaults keep five existing panels and hide all new designs', () {
    final layout = DashboardLayout.defaults();
    expect(
      layout.panels.where((p) => p.visible).map((p) => p.panel),
      PrayerPanel.values.take(5),
    );
    expect(() => layout.panels.clear(), throwsUnsupportedError);
  });
  test(
    'toggle and both reorder directions preserve identity and visibility',
    () {
      final original = DashboardLayout.defaults();
      final changed = original.toggle(PrayerPanel.moon, true).reorder(6, 0);
      expect(changed.panels.first.panel, PrayerPanel.moon);
      expect(changed.panels.first.visible, isTrue);
      final movedDown = changed.reorder(0, 8);
      expect(movedDown.panels.last.panel, PrayerPanel.moon);
      expect(original.panels.first.panel, PrayerPanel.currentPrayer);
      expect(movedDown.panels.map((p) => p.panel).toSet().length, 9);
    },
  );
  test('malformed, unknown and duplicate saved entries are normalized', () {
    expect(StoredDashboardLayout.decode(null).panels.length, 9);
    expect(
      StoredDashboardLayout.decode({'version': 42}).panels.first.visible,
      isTrue,
    );
    final layout = StoredDashboardLayout.decode({
      'version': 1,
      'panels': [
        {'id': 'moon', 'visible': true},
        {'id': 'moon', 'visible': false},
        {'id': 'future_panel', 'visible': true},
        null,
        {'id': 'timeline', 'visible': 'bad'},
        {'id': 'current_prayer', 'visible': false},
      ],
    });
    expect(layout.panels.length, 9);
    expect(layout.panels.first.panel, PrayerPanel.moon);
    expect(layout.panels.first.visible, isTrue);
    expect(
      layout.panels
          .where((p) => p.panel == PrayerPanel.currentPrayer)
          .single
          .visible,
      isFalse,
    );
  });
  test('empty selection survives decoding', () {
    final layout = StoredDashboardLayout.decode({
      'version': 1,
      'panels': [
        for (final panel in PrayerPanel.values)
          {'id': panel.id, 'visible': false},
      ],
    });
    expect(layout.panels.any((p) => p.visible), isFalse);
  });
  test(
    'countdown skips sunrise and night markers, uses tomorrow actual fajr',
    () {
      final data = dashboardFixture(DateTime(2026, 10, 20));
      final result = PreparePrayerDashboard.countdown(
        data.liveTimes,
        DateTime(2026, 10, 26, 21),
      )!;
      expect(result.previous.index, 5);
      expect(result.next.at, DateTime(2026, 10, 27, 5));
      expect(result.remaining, const Duration(hours: 8));
      expect(result.progress, closeTo(1 / 9, .0001));
      final afterFajr = PreparePrayerDashboard.countdown(
        data.liveTimes,
        DateTime(2026, 10, 26, 5),
      )!;
      expect(afterFajr.next.index, 2);
      expect(afterFajr.progress, 0);
    },
  );
  test(
    'selected date is constrained using calendar days across month boundaries',
    () {
      final now = DateTime(2026, 10, 31, 23);
      expect(
        PreparePrayerDashboard.constrainDate(DateTime(2026, 12), now),
        DateTime(2026, 11, 7),
      );
      expect(
        PreparePrayerDashboard.constrainDate(DateTime(2026, 1), now),
        DateTime(2026, 10, 24),
      );
    },
  );
  test(
    'customization use case round trips through its repository abstraction',
    () async {
      final repository = MemoryLayout();
      final useCase = CustomizeDashboard(repository);
      await useCase.save(
        useCase.load().toggle(PrayerPanel.countdown, true).reorder(8, 0),
      );
      expect(useCase.load().panels.first.panel, PrayerPanel.countdown);
      expect(useCase.defaults().panels.first.panel, PrayerPanel.currentPrayer);
    },
  );
}
