part of '../../../prayers.dart';

class CalendarPrayerCard extends StatelessWidget {
  const CalendarPrayerCard({
    super.key,
    required this.data,
    required this.prayerIndex,
  });
  final DashboardViewData data;
  final int? prayerIndex;
  @override
  Widget build(BuildContext context) => DashboardCard(
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'dashboardPanel_calendar'.tr,
                style: dashboardText(context, 18),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Text(
                data.ramadan,
                textAlign: TextAlign.end,
                style: dashboardText(context, 13),
              ),
            ),
          ],
        ),
        const Gap(16),
        LayoutBuilder(
          builder: (context, constraints) {
            final dates = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.weekday,
                  textAlign: TextAlign.center,
                  style: dashboardText(
                    context,
                    24,
                  ).copyWith(color: Theme.of(context).colorScheme.surface),
                ),
                Text(
                  '${data.hijriDay} ${data.hijriMonth} ${data.hijriYear}',
                  textAlign: TextAlign.center,
                  style: dashboardText(context, 17),
                ),
                Text(
                  data.gregorianDate,
                  textAlign: TextAlign.center,
                  style: dashboardText(context, 16),
                ),
              ],
            );
            final moon = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DashboardMoon(info: data.moonInfo, size: 65),
                Text(data.illumination, style: dashboardText(context, 13)),
                Text(
                  data.moonName,
                  textAlign: TextAlign.center,
                  style: dashboardText(context, 11),
                ),
              ],
            );
            if (constraints.maxWidth < 340 ||
                MediaQuery.textScalerOf(context).scale(16) > 22) {
              return Column(children: [dates, const Gap(12), moon]);
            }
            return Row(
              children: [
                Expanded(flex: 5, child: dates),
                const Gap(12),
                Expanded(flex: 2, child: moon),
              ],
            );
          },
        ),
        const Gap(24),
        Text(
          data.location,
          style: dashboardText(context, 14),
          textAlign: TextAlign.center,
        ),
        const Gap(16),
        CompactPrayerTimes(
          prayers: data.prayers,
          currentPrayerIndexOverride: prayerIndex,
        ),
        const Gap(18),
        NightTimesRow(times: data.night),
      ],
    ),
  );
}
