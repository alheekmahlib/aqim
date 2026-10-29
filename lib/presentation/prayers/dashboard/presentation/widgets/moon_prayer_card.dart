part of '../../../prayers.dart';

class MoonPrayerCard extends StatelessWidget {
  const MoonPrayerCard({super.key, required this.data});
  final DashboardViewData data;
  @override
  Widget build(BuildContext context) => DashboardCard(
    child: Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'dashboardPanel_moon'.tr,
            style: dashboardText(context, 20),
          ),
        ),
        const Gap(12),
        LayoutBuilder(
          builder: (context, constraints) {
            final moon = Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 185,
                  height: 185,
                  child: CustomPaint(
                    painter: _MoonArcPainter(
                      Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
                DashboardMoon(info: data.moonInfo),
              ],
            );
            final rise = _SolarTime(
              label: 'dashboardSunrise'.tr,
              time: data.prayers[1].time,
            );
            final set = _SolarTime(
              label: 'dashboardSunset'.tr,
              time: data.prayers[4].time,
            );
            if (constraints.maxWidth < 340 ||
                MediaQuery.textScalerOf(context).scale(16) > 22) {
              return Column(
                children: [
                  moon,
                  Row(
                    children: [
                      Expanded(child: rise),
                      Expanded(child: set),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: rise),
                moon,
                Expanded(child: set),
              ],
            );
          },
        ),
        const Gap(14),
        Text(
          '${data.illumination} • ${data.moonName}',
          textAlign: TextAlign.center,
          style: dashboardText(context, 17),
        ),
      ],
    ),
  );
}
