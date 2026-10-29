part of '../../prayers.dart';

class StoredDashboardLayout implements DashboardLayoutRepository {
  StoredDashboardLayout(this.storage);
  final GetStorage storage;
  static const storageKey = 'prayer_dashboard_layout_v1';

  @override
  DashboardLayout load() => decode(storage.read(storageKey));

  static DashboardLayout decode(Object? raw) {
    if (raw is! Map || raw['version'] != 1 || raw['panels'] is! List) {
      return DashboardLayout.defaults();
    }
    final known = {for (final p in PrayerPanel.values) p.id: p};
    final seen = <PrayerPanel>{};
    final result = <PanelPreference>[];
    for (final row in raw['panels'] as List) {
      if (row is! Map) continue;
      final panel = known[row['id']];
      if (panel == null || !seen.add(panel)) continue;
      result.add(
        PanelPreference(
          panel,
          row['visible'] is bool
              ? row['visible'] as bool
              : panel.visibleByDefault,
        ),
      );
    }
    for (final panel in PrayerPanel.values.where((p) => !seen.contains(p))) {
      result.add(PanelPreference(panel, panel.visibleByDefault));
    }
    return DashboardLayout(result);
  }

  @override
  Future<void> save(DashboardLayout layout) => storage.write(storageKey, {
    'version': 1,
    'panels': [
      for (final p in layout.panels) {'id': p.panel.id, 'visible': p.visible},
    ],
  });
}
