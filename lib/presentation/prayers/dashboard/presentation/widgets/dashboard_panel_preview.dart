part of '../../../prayers.dart';

/// Render a full-width composition, then scale the entire widget into a
/// thumbnail. No live controllers, input handlers or timers are mounted here.
class DashboardPanelPreview extends StatelessWidget {
  const DashboardPanelPreview({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: TickerMode(
        enabled: false,
        child: Container(
          width: 88,
          height: 80,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.inversePrimary.withValues(alpha: .2),
            ),
          ),
          child: ClipRect(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: const Size(400, 800),
                textScaler: TextScaler.noScaling,
              ),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(width: 400, child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class PrayerDialPreview extends StatelessWidget {
  const PrayerDialPreview({super.key, required this.data});
  final DashboardPreviewData data;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: RadialGauge(
      radius: 180,
      value: 58,
      axis: GaugeAxis(
        min: 0,
        max: 100,
        sweepDegrees: 200,
        style: GaugeAxisStyle(
          thickness: 30,
          zoneSpacing: 10,
          background: Theme.of(context).colorScheme.primaryContainer,
          cornerRadius: const Radius.circular(8),
        ),
        pointer: GaugePointer.circle(
          radius: 8,
          color: Theme.of(context).canvasColor,
        ),
        zones: const [
          GaugeZone(from: 0, to: 20, color: Color(0xff4b4c4f)),
          GaugeZone(from: 20, to: 40, color: Color(0xff0098EE)),
          GaugeZone(from: 40, to: 60, color: Color(0xffB8E0EA)),
          GaugeZone(from: 60, to: 80, color: Color(0xfff8a159)),
          GaugeZone(from: 80, to: 100, color: Color(0xff4b4c4f)),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              data.card.prayers[3].icon,
              size: 54,
              color: Theme.of(context).colorScheme.surface,
            ),
            Text(data.card.prayers[3].name, style: dashboardText(context, 26)),
            Text(data.card.prayers[3].time, style: dashboardText(context, 26)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                data.countdown.remaining,
                style: dashboardText(context, 32),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PrayerTimelinePreview extends StatelessWidget {
  const PrayerTimelinePreview({super.key, required this.data});
  final DashboardPreviewData data;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        for (final (index, prayer) in [
          ...data.card.prayers,
          ...data.card.night,
        ].indexed)
          Row(
            children: [
              SizedBox(
                width: 70,
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 5,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: .4),
                    ),
                    Container(
                      width: index == 3 ? 42 : 28,
                      height: index == 3 ? 42 : 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Icon(
                        prayer.icon,
                        size: index == 3 ? 28 : 16,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: index == 3
                        ? Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: .5)
                        : null,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: .2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          prayer.name,
                          style: dashboardText(context, 16),
                        ),
                      ),
                      Text(prayer.time, style: dashboardText(context, 19)),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

class PrayerWeekPreview extends StatelessWidget {
  const PrayerWeekPreview({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      children: [
        for (final (index, day) in [
          'Fri',
          'Sat',
          'Sun',
          'Mon',
          'Tue',
          'Wed',
          'Thu',
        ].indexed)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 65,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: index == 3
                    ? Theme.of(context).colorScheme.surface
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${12 + index}'.convertNumbersToCurrentLang(),
                    style: dashboardText(context, 22).copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      color: index == 3 ? Colors.white : null,
                    ),
                  ),
                  Text(
                    day.tr,
                    style: dashboardText(context, 16).copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      color: index == 3 ? Colors.white : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class PrayerProhibitionPreview extends StatelessWidget {
  const PrayerProhibitionPreview({super.key});
  @override
  Widget build(BuildContext context) => ContainerButtonWidget(
    title: 'prohibitionTimes'.tr,
    horizontalMargin: 24,
    backgroundColor: const Color(0xfff8a159).withValues(alpha: .2),
    borderColor: Theme.of(context).colorScheme.surface,
    titleColor: Theme.of(context).colorScheme.inversePrimary,
    useGradient: false,
    withShape: false,
  );
}
