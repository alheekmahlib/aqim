part of '../../prayers.dart';

class VerticalPrayerTimelineCard extends StatelessWidget {
  const VerticalPrayerTimelineCard({
    super.key,
    required this.data,
    required this.navigation,
  });

  final DashboardViewData data;
  final Widget navigation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textColor = colors.inversePrimary;
    const accent = Color(0xffd6ad61);
    final dateNavigation = navigation;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        radius: 28,
        variant: GlassVariant.hero,
        backgroundColor: colors.surface.withValues(alpha: .08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: dateNavigation is DashboardDateNavigation
                  ? Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: dateNavigation.onToday,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.gregorianDate,
                                  style: dashboardText(context, 20, textColor),
                                ),
                                const Gap(3),
                                Text(
                                  '${data.hijriDay} ${data.hijriMonth} ${data.hijriYear}',
                                  style: dashboardText(
                                    context,
                                    12,
                                    textColor.withValues(alpha: .75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _TimelineDateButton(
                          icon: Icons.chevron_left,
                          tooltip: 'dashboardPreviousDay'.tr,
                          onPressed: dateNavigation.onPrevious,
                          color: textColor,
                        ),
                        const Gap(6),
                        _TimelineDateButton(
                          icon: Icons.chevron_right,
                          tooltip: 'dashboardNextDay'.tr,
                          onPressed: dateNavigation.onNext,
                          color: textColor,
                        ),
                      ],
                    )
                  : dateNavigation,
            ),
            const Gap(12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (var index = 0; index < data.prayers.length; index++)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 18,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  top: index == 0 ? 24 : 0,
                                  bottom: index == data.prayers.length - 1
                                      ? 24
                                      : 0,
                                  child: Container(
                                    width: 1,
                                    color: textColor.withValues(alpha: .38),
                                  ),
                                ),
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == data.currentIndex
                                        ? accent
                                        : colors.primaryContainer,
                                    border: Border.all(
                                      color: index == data.currentIndex
                                          ? accent
                                          : textColor.withValues(alpha: .7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => context.customBottomSheet(
                                textTitle: 'prayerDetails'.tr,
                                containerColor:
                                    context.theme.colorScheme.primaryContainer,
                                child: PrayerDetails(
                                  prayerName:
                                      data.prayers[index].legacy['title']
                                          as String,
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: index == data.currentIndex
                                      ? textColor.withValues(alpha: .12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      data.prayers[index].icon,
                                      color: accent,
                                      size: 22,
                                    ),
                                    const Gap(10),
                                    Expanded(
                                      child: Text(
                                        data.prayers[index].name,
                                        style: dashboardText(
                                          context,
                                          16,
                                          textColor,
                                        ),
                                      ),
                                    ),
                                    const Gap(8),
                                    Flexible(
                                      child: Text(
                                        data.prayers[index].time,
                                        textAlign: TextAlign.end,
                                        style: dashboardText(
                                          context,
                                          15,
                                          textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Gap(14),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              child: CustomPaint(
                painter: _TimelineFooterPainter(color: textColor),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 18,
                    runSpacing: 12,
                    children: [
                      for (final time in data.night)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(time.icon, size: 22, color: accent),
                            const Gap(8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  time.name,
                                  style: dashboardText(
                                    context,
                                    12,
                                    textColor.withValues(alpha: .8),
                                  ),
                                ),
                                Text(
                                  time.time,
                                  style: dashboardText(context, 14, textColor),
                                ),
                              ],
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
      ),
    );
  }
}

class _TimelineDateButton extends StatelessWidget {
  const _TimelineDateButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) => Material(
    color: color.withValues(alpha: .08),
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      color: color,
      disabledColor: color.withValues(alpha: .3),
    ),
  );
}

class _TimelineFooterPainter extends CustomPainter {
  const _TimelineFooterPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final edge = ui.Path()
      ..moveTo(0, 28)
      ..cubicTo(size.width * .16, 0, size.width * .4, 18, size.width, 0);
    final fill = ui.Path.from(edge)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: .045));
    canvas.drawPath(
      edge,
      Paint()
        ..color = color.withValues(alpha: .22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _TimelineFooterPainter oldDelegate) =>
      oldDelegate.color != color;
}
