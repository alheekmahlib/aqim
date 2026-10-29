part of '../../../prayers.dart';

TextStyle dashboardText(BuildContext context, [double size = 16]) => TextStyle(
  fontFamily: 'cairo',
  fontSize: size,
  color: Theme.of(context).colorScheme.inversePrimary,
  fontWeight: FontWeight.w600,
);

class DashboardCard extends StatelessWidget {
  const DashboardCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    ),
  );
}

class DashboardDateNavigation extends StatelessWidget {
  const DashboardDateNavigation({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });
  final String label;
  final VoidCallback? onPrevious, onNext;
  final VoidCallback onToday;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: onPrevious,
        tooltip: 'dashboardPreviousDay'.tr,
        icon: const Icon(Icons.chevron_left),
        color: Theme.of(context).colorScheme.inversePrimary,
      ),
      Expanded(
        child: TextButton(
          onPressed: onToday,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: dashboardText(context, 15),
          ),
        ),
      ),
      IconButton(
        onPressed: onNext,
        tooltip: 'dashboardNextDay'.tr,
        icon: const Icon(Icons.chevron_right),
        color: Theme.of(context).colorScheme.inversePrimary,
      ),
    ],
  );
}

class NightTimesRow extends StatelessWidget {
  const NightTimesRow({super.key, required this.times});
  final List<PrayerTimeView> times;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 20,
    runSpacing: 6,
    children: [
      for (final time in times)
        Text(
          '${time.name} ${time.time}',
          textAlign: TextAlign.center,
          style: dashboardText(context, 13).copyWith(
            color: Theme.of(
              context,
            ).colorScheme.inversePrimary.withValues(alpha: .65),
          ),
        ),
    ],
  );
}

class CompactPrayerTimes extends StatelessWidget {
  const CompactPrayerTimes({
    super.key,
    required this.prayers,
    required this.currentPrayerIndexOverride,
  });
  final List<PrayerTimeView> prayers;
  final int? currentPrayerIndexOverride;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 300 &&
              MediaQuery.textScalerOf(context).scale(16) <= 22
          ? 6
          : 3;
      return Wrap(
        runSpacing: 8,
        children: [
          for (final prayer in prayers)
            InkWell(
              onTap: () => context.customBottomSheet(
                textTitle: 'prayerDetails'.tr,
                containerColor: context.theme.colorScheme.primaryContainer,
                child: PrayerDetails(prayerName: prayer.name.tr),
              ),
              child: SizedBox(
                width: constraints.maxWidth / columns,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      prayer.icon,
                      size: 27,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    const Gap(8),
                    Text(
                      prayer.name,
                      textAlign: TextAlign.center,
                      style: dashboardText(context, columns == 6 ? 12 : 14),
                    ),
                    Text(
                      prayer.shortTime,
                      textAlign: TextAlign.center,
                      style: dashboardText(context, columns == 6 ? 14 : 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class DashboardMoon extends StatelessWidget {
  const DashboardMoon({super.key, required this.info, this.size = 145});
  final MoonPhaseInfo info;
  final double size;
  @override
  Widget build(BuildContext context) => MoonPhaseWidget(
    moonInfo: info,
    size: size,
    overlayOpacity: .92,
    backgroundAssetPath: null,
  );
}

class _SolarTime extends StatelessWidget {
  const _SolarTime({required this.label, required this.time});
  final String label, time;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        textAlign: TextAlign.center,
        style: dashboardText(context, 13),
      ),
      Text(
        time,
        textAlign: TextAlign.center,
        style: dashboardText(context, 16),
      ),
    ],
  );
}

class _MoonArcPainter extends CustomPainter {
  const _MoonArcPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: .35),
          color,
          color.withValues(alpha: .35),
        ],
      ).createShader(rect);
    canvas.drawArc(rect, math.pi * .75, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(_MoonArcPainter oldDelegate) => oldDelegate.color != color;
}
