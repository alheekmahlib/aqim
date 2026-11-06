part of '../../prayers.dart';

class MoonPrayerCard extends StatelessWidget {
  const MoonPrayerCard({super.key, required this.data});
  final DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final ink = context.theme.canvasColor;
    const gold = Color(0xffa87832);
    final background = context.theme.colorScheme.primary;

    Widget solarTime(IconData icon, String label, String time) => Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: .center,
          children: [
            Icon(icon, color: gold, size: 28),
            const Gap(8),
            _SolarTime(label: label, time: time, textColor: ink),
          ],
        ),
      ),
    );

    final details = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.moonName,
          style: dashboardText(context, 20, ink).copyWith(height: 1.4),
        ),
        const Gap(6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          decoration: BoxDecoration(
            color: ink.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            data.illumination,
            style: dashboardText(context, 18, ink),
          ),
        ),
      ],
    );
    final moon = DashboardMoon(info: data.moonInfo, size: 120, height: 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gold.withValues(alpha: .3)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.nights_stay_outlined, color: ink, size: 22),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          'dashboardPanel_moon'.tr,
                          style: dashboardText(context, 18, ink),
                        ),
                      ),
                    ],
                  ),
                  const Gap(6),
                  Divider(color: ink.withValues(alpha: .25), height: 1),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 280 ||
                          MediaQuery.textScalerOf(context).scale(16) > 22) {
                        return Column(
                          children: [
                            moon,
                            const Gap(6),
                            Center(child: details),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: details),
                          const Gap(8),
                          moon,
                        ],
                      );
                    },
                  ),
                  Divider(color: ink.withValues(alpha: .25), height: 1),
                  const Gap(6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      solarTime(
                        Icons.wb_twilight,
                        'dashboardSunrise'.tr,
                        data.prayers[1].time,
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: ink.withValues(alpha: .2),
                      ),
                      solarTime(
                        Icons.wb_sunny_outlined,
                        'dashboardSunset'.tr,
                        data.prayers[4].time,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Opacity(
              opacity: .2,
              child: Transform.flip(
                flipX: true,
                child: customLottie(
                  LottieConstants.assetsLottieCloud,
                  width: Get.width,
                  isRepeat: !MediaQuery.disableAnimationsOf(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
