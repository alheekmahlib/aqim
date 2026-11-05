part of '../../prayers.dart';

class CalendarPrayerCard extends StatelessWidget {
  const CalendarPrayerCard({
    super.key,
    required this.data,
    required this.prayerIndex,
  });
  final DashboardViewData data;
  final int? prayerIndex;

  @override
  Widget build(BuildContext context) {
    final ink = context.theme.colorScheme.inversePrimary;
    final sage = context.theme.colorScheme.surface.withValues(alpha: .2);
    const darkGreen = Color(0xff204b3d);

    Widget panel(Widget child, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );

    final date = panel(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.weekday,
            textAlign: TextAlign.center,
            style: dashboardText(context, 17, ink),
          ),
          Text(
            data.hijriDay,
            textAlign: TextAlign.center,
            style: dashboardText(context, 42, ink).copyWith(height: 1.15),
          ),
          Text(
            '${data.hijriMonth} ${data.hijriYear}',
            textAlign: TextAlign.center,
            style: dashboardText(context, 15, ink),
          ),
          const Gap(8),
          Text(
            data.gregorianDate,
            textAlign: TextAlign.center,
            style: dashboardText(context, 13, ink),
          ),
        ],
      ),
      sage,
    );
    final moon = panel(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DashboardMoon(info: data.moonInfo, size: 90, height: 80),
          const Gap(4),
          Text(
            data.moonName,
            textAlign: TextAlign.center,
            style: dashboardText(context, 13, context.theme.canvasColor),
          ),
          Text(
            data.illumination,
            textAlign: TextAlign.center,
            style: dashboardText(context, 12, context.theme.canvasColor),
          ),
        ],
      ),
      darkGreen.withValues(alpha: .9),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ink.withValues(alpha: .14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .07),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'dashboardPanel_calendar'.tr,
              textAlign: TextAlign.center,
              style: dashboardText(context, 21, ink),
            ),
            const Gap(10),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: sage,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  data.ramadan,
                  textAlign: TextAlign.center,
                  style: dashboardText(context, 13, ink),
                ),
              ),
            ),
            const Gap(16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 280 ||
                    MediaQuery.textScalerOf(context).scale(16) > 22) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [date, const Gap(10), moon],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: date),
                    const Gap(10),
                    Expanded(child: moon),
                  ],
                );
              },
            ),
            const Gap(14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: ink),
                const Gap(4),
                Flexible(
                  child: Text(
                    data.location,
                    textAlign: TextAlign.center,
                    style: dashboardText(context, 13, ink),
                  ),
                ),
              ],
            ),
            const Gap(14),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth < 260 ||
                        MediaQuery.textScalerOf(context).scale(16) > 22
                    ? 2
                    : 3;
                const spacing = 8.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final (index, prayer) in data.prayers.indexed)
                      SizedBox(
                        width: width,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => context.customBottomSheet(
                              textTitle: 'prayerDetails'.tr,
                              containerColor:
                                  context.theme.colorScheme.primaryContainer,
                              child: PrayerDetails(
                                prayerName: prayer.legacy['title'] as String,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: index == prayerIndex
                                    ? ink.withValues(alpha: .14)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: ink.withValues(alpha: .18),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(prayer.icon, size: 22, color: ink),
                                  Text(
                                    prayer.name,
                                    textAlign: TextAlign.center,
                                    style: dashboardText(context, 12, ink),
                                  ),
                                  Text(
                                    prayer.shortTime,
                                    textAlign: TextAlign.center,
                                    style: dashboardText(context, 13, ink),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const Gap(14),
            panel(
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (final time in data.night)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time.name,
                          textAlign: TextAlign.center,
                          style: dashboardText(context, 12, ink),
                        ),
                        const Gap(6),
                        Text(
                          time.time,
                          textAlign: TextAlign.center,
                          style: dashboardText(context, 14, ink),
                        ),
                      ],
                    ),
                ],
              ),
              context.theme.colorScheme.surface.withValues(alpha: .2),
            ),
          ],
        ),
      ),
    );
  }
}
