part of '../../../prayers.dart';

typedef PanelBuilder = Widget Function(DashboardPanelContext context);

class DashboardPanelDefinition {
  const DashboardPanelDefinition(this.panel, this.previewBuilder, this.builder);
  final PrayerPanel panel;
  final Widget Function(DashboardPreviewData data) previewBuilder;
  final PanelBuilder builder;
  String get title => 'dashboardPanel_${panel.id}'.tr;
}

class DashboardPanelContext {
  const DashboardPanelContext(this.data, this.controller, this.week);
  final DashboardViewData data;
  final DashboardController controller;
  final WeekCalendarViewData week;
  Widget get navigation => DashboardDateNavigation(
    label: data.dateLabel,
    onPrevious: controller.canGoBack ? controller.previousDay : null,
    onNext: controller.canGoForward ? controller.nextDay : null,
    onToday: controller.today,
  );
}

/// The catalog is the single presentation registry for rendering and selection.
final dashboardRegistry = <PrayerPanel, DashboardPanelDefinition>{
  PrayerPanel.currentPrayer: DashboardPanelDefinition(
    PrayerPanel.currentPrayer,
    (data) => PrayerDialPreview(data: data),
    (_) => const PrayerNowWidget(),
  ),
  PrayerPanel.locationDate: DashboardPanelDefinition(
    PrayerPanel.locationDate,
    (data) => DashboardLocationDate(
      data: data.card,
      onRefresh: _ignorePreviewAction,
      refreshing: false,
    ),
    (c) => DashboardLocationDate(
      data: c.data,
      onRefresh: c.controller.updateLocation,
      refreshing: c.controller.refreshingLocation.value,
    ),
  ),
  PrayerPanel.weekCalendar: DashboardPanelDefinition(
    PrayerPanel.weekCalendar,
    (_) => const PrayerWeekPreview(),
    (c) => DashboardWeekCalendar(
      data: c.week,
      onDateChange: c.controller.selectDate,
    ),
  ),
  PrayerPanel.prohibition: DashboardPanelDefinition(
    PrayerPanel.prohibition,
    (_) => const PrayerProhibitionPreview(),
    (_) => const ProhibitionWidget(),
  ),
  PrayerPanel.timeline: DashboardPanelDefinition(
    PrayerPanel.timeline,
    (data) => PrayerTimelinePreview(data: data),
    (c) => PrayerBuild(
      prayersOverride: [
        ...c.data.prayers,
        ...c.data.night,
      ].map((p) => p.legacy).toList(),
      currentPrayerIndexOverride: c.data.currentIndex,
      bottomPadding: 0,
    ),
  ),
  PrayerPanel.verticalTimes: DashboardPanelDefinition(
    PrayerPanel.verticalTimes,
    (data) => VerticalPrayerCard(
      data: data.card,
      navigation: _previewNavigation(data),
    ),
    (c) => VerticalPrayerCard(data: c.data, navigation: c.navigation),
  ),
  PrayerPanel.moon: DashboardPanelDefinition(
    PrayerPanel.moon,
    (data) => MoonPrayerCard(data: data.card),
    (c) => MoonPrayerCard(data: c.data),
  ),
  PrayerPanel.calendar: DashboardPanelDefinition(
    PrayerPanel.calendar,
    (data) => CalendarPrayerCard(
      data: data.card,
      prayerIndex: data.card.currentIndex,
    ),
    (c) => CalendarPrayerCard(data: c.data, prayerIndex: c.data.currentIndex),
  ),
  PrayerPanel.countdown: DashboardPanelDefinition(
    PrayerPanel.countdown,
    (data) => CountdownPrayerCard(
      data: data.card,
      countdown: data.countdown,
      navigation: _previewNavigation(data),
      prayerIndex: data.card.currentIndex,
    ),
    (c) => Obx(
      () => CountdownPrayerCard(
        data: c.data,
        countdown: const DashboardPresenter().presentCountdown(
          c.controller.countdown.value,
        ),
        navigation: c.navigation,
        prayerIndex: c.data.currentIndex,
      ),
    ),
  ),
};

class DashboardLocationDate extends StatelessWidget {
  const DashboardLocationDate({
    super.key,
    required this.data,
    required this.onRefresh,
    required this.refreshing,
  });
  final DashboardViewData data;
  final VoidCallback onRefresh;
  final bool refreshing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                ContainerButtonWidget(
                  onPressed: refreshing ? null : onRefresh,
                  height:
                      (MediaQuery.textScalerOf(context).scale(16) * 2.6 + 16)
                          .clamp(60.0, double.infinity),
                  svgHeight: 80,
                  width: double.infinity,
                  withShape: false,
                  useGradient: false,
                  backgroundColor: Colors.transparent,
                  borderColor: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: .2),
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      Icon(
                        Icons.place_rounded,
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: .1),
                        size: 70,
                      ),
                      Text(
                        data.locationDetails,
                        style: dashboardText(
                          context,
                          16,
                        ).copyWith(fontWeight: FontWeight.bold, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  // The badge is part of the button's tap target.
                  child: IgnorePointer(
                    child: Container(
                      height: 30,
                      width: 30,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: refreshing
                          ? CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).canvasColor,
                            )
                          : customSvgWithColor(
                              SvgPath.svgPrayerRefresh,
                              height: 24,
                              color: Theme.of(context).canvasColor,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  customSvgWithColor(
                    data.hijriMonthAsset,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: .4),
                    height: 48,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.hijriDay,
                        style: dashboardText(
                          context,
                          24,
                        ).copyWith(fontWeight: FontWeight.w700, height: 1.2),
                      ),
                      Text(
                        data.weekday,
                        textAlign: TextAlign.center,
                        style: dashboardText(
                          context,
                          18,
                        ).copyWith(fontWeight: FontWeight.w700, height: 1.2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class DashboardWeekCalendar extends StatelessWidget {
  const DashboardWeekCalendar({
    super.key,
    required this.data,
    required this.onDateChange,
  });
  final WeekCalendarViewData data;
  final ValueChanged<DateTime> onDateChange;
  @override
  Widget build(BuildContext context) {
    final dayStyle = dashboardText(
      context,
      22,
    ).copyWith(fontWeight: FontWeight.bold, height: 1.1);
    final nameStyle = dashboardText(
      context,
      16,
    ).copyWith(fontWeight: FontWeight.bold, height: 1.1);
    final dayNames = [
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
    ].map((day) => day.tr).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) => HorizontalWeekCalendar(
          key: ValueKey('${data.date}-${data.hijriDate.hDay}'),
          initialDate: data.date,
          minDate: data.minDate,
          maxDate: data.maxDate,
          hijriInitialDate: data.hijriDate,
          hijriMinDate: data.hijriMinDate,
          hijriMaxDate: data.hijriMaxDate,
          onDateChange: onDateChange,
          useHijriDates: true,
          showTopNavbar: false,
          monthFormat: 'MMMM yyyy',
          showNavigationButtons: true,
          weekStartFrom: WeekStartFrom.friday,
          carouselHeight: _calendarHeight(
            context,
            constraints.maxWidth / 7 - 6,
            dayNames,
            dayStyle,
            nameStyle,
          ),
          borderRadius: BorderRadius.circular(12),
          itemBorderColor: Colors.transparent,
          translateNumbers: true,
          languageCode: Get.locale?.languageCode ?? 'ar',
          activeBackgroundColor: Theme.of(context).colorScheme.surface,
          activeTextColor: Colors.white,
          inactiveBackgroundColor: Colors.transparent,
          inactiveTextColor: Theme.of(context).colorScheme.inversePrimary,
          disabledTextColor: Colors.grey,
          disabledBackgroundColor: Colors.grey.withValues(alpha: .3),
          activeNavigatorColor: Theme.of(context).colorScheme.surface,
          inactiveNavigatorColor: Colors.grey,
          monthColor: Theme.of(context).colorScheme.surface,
          scrollPhysics: const BouncingScrollPhysics(),
          dayTextStyle: dayStyle,
          dayNameTextStyle: nameStyle,
          monthTextStyle: dashboardText(
            context,
            18,
          ).copyWith(fontWeight: FontWeight.bold, height: 1.5),
          customDayNames: dayNames,
        ),
      ),
    );
  }

  // Keep the original 65px row, expanding only when text wraps or is enlarged.
  double _calendarHeight(
    BuildContext context,
    double cellWidth,
    List<String> names,
    TextStyle dayStyle,
    TextStyle nameStyle,
  ) {
    double tallest(Iterable<String> labels, TextStyle style) {
      var height = 0.0;
      for (final label in labels) {
        final painter = TextPainter(
          text: TextSpan(text: label, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
        )..layout(maxWidth: cellWidth.clamp(1.0, double.infinity));
        if (painter.height > height) height = painter.height;
        painter.dispose();
      }
      return height;
    }

    final days = List.generate(
      30,
      (i) => const DashboardPresenter().number(i + 1),
    );
    return (tallest(days, dayStyle) + tallest(names, nameStyle) + 2).clamp(
      65.0,
      double.infinity,
    );
  }
}

void _ignorePreviewAction() {}

Widget _previewNavigation(DashboardPreviewData data) => DashboardDateNavigation(
  label: data.card.dateLabel,
  onPrevious: _ignorePreviewAction,
  onNext: _ignorePreviewAction,
  onToday: _ignorePreviewAction,
);
