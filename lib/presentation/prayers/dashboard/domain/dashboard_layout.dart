/// Stable identifiers are persisted; never use enum ordinals as storage keys.
enum PrayerPanel {
  currentPrayer('current_prayer', true),
  locationDate('location_date', true),
  weekCalendar('week_calendar', true),
  prohibition('prohibition', true),
  timeline('timeline', true),
  verticalTimes('vertical_times', false),
  moon('moon', false),
  calendar('calendar', false),
  countdown('countdown', false);

  const PrayerPanel(this.id, this.visibleByDefault);
  final String id;
  final bool visibleByDefault;
}

class PanelPreference {
  const PanelPreference(this.panel, this.visible);
  final PrayerPanel panel;
  final bool visible;
}

class DashboardLayout {
  DashboardLayout(Iterable<PanelPreference> panels)
    : panels = List.unmodifiable(panels);

  factory DashboardLayout.defaults() => DashboardLayout(
    PrayerPanel.values.map((p) => PanelPreference(p, p.visibleByDefault)),
  );

  final List<PanelPreference> panels;

  DashboardLayout toggle(PrayerPanel panel, bool visible) => DashboardLayout(
    panels.map((p) => p.panel == panel ? PanelPreference(panel, visible) : p),
  );

  DashboardLayout reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= panels.length ||
        newIndex < 0 ||
        newIndex >= panels.length) {
      return this;
    }
    final reordered = panels.toList();
    reordered.insert(newIndex, reordered.removeAt(oldIndex));
    return DashboardLayout(reordered);
  }
}

abstract interface class DashboardLayoutRepository {
  DashboardLayout load();
  Future<void> save(DashboardLayout layout);
}

class CustomizeDashboard {
  const CustomizeDashboard(this.repository);
  final DashboardLayoutRepository repository;
  DashboardLayout load() => repository.load();
  Future<void> save(DashboardLayout layout) => repository.save(layout);
  DashboardLayout defaults() => DashboardLayout.defaults();
}
