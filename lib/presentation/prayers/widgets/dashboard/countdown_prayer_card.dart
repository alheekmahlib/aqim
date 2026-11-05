part of '../../prayers.dart';

class CountdownPrayerCard extends StatelessWidget {
  const CountdownPrayerCard({
    super.key,
    required this.data,
    required this.countdown,
    required this.navigation,
    required this.prayerIndex,
  });
  final DashboardViewData data;
  final CountdownViewData? countdown;
  final Widget navigation;
  final int prayerIndex;

  @override
  Widget build(BuildContext context) {
    final ink = context.theme.colorScheme.inversePrimary;
    final cream = context.theme.colorScheme.primaryContainer;
    const gold = Color(0xffb68b38);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: gold.withValues(alpha: .25)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 19, color: ink),
                const Gap(4),
                Flexible(
                  child: Text(
                    data.location,
                    textAlign: TextAlign.center,
                    style: dashboardText(context, 15, ink),
                  ),
                ),
              ],
            ),
            if (countdown != null) ...[
              const Gap(20),
              Text(
                countdown!.title,
                textAlign: TextAlign.center,
                style: dashboardText(context, 19, ink),
              ),
              const Gap(4),
              Stack(
                alignment: Alignment.center,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white10,
                        Colors.white,
                      ],
                    ).createShader(bounds),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      child: Container(
                        color: const Color(0xffe5ddca),
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xff9c7126), Color(0xffe1bf66)],
                          ).createShader(bounds),
                          child: LinearProgressIndicator(
                            value: countdown!.progress.clamp(0.0, 1.0),
                            minHeight: 60,
                            color: Colors.white,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      countdown!.remaining,
                      textDirection: TextDirection.ltr,
                      style: dashboardText(
                        context,
                        54,
                        ink,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Gap(10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      countdown!.previous,
                      style: dashboardText(context, 13, ink),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      countdown!.next,
                      textAlign: TextAlign.end,
                      style: dashboardText(context, 13, ink),
                    ),
                  ),
                ],
              ),
            ],
            const Gap(24),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth < 280 ||
                        MediaQuery.textScalerOf(context).scale(16) > 22
                    ? 2
                    : 3;
                const gap = 8.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final (index, prayer) in data.prayers.indexed)
                      SizedBox(
                        width: width,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
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
                                vertical: 8,
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: index == prayerIndex
                                    ? ink.withValues(alpha: .14)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: gold.withValues(alpha: .22),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(prayer.icon, color: gold, size: 22),
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
            const Gap(16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (final time in data.night)
                    Text(
                      '${time.name} ${time.time}',
                      textAlign: TextAlign.center,
                      style: dashboardText(context, 12, cream),
                    ),
                ],
              ),
            ),
            const Gap(12),
            Theme(
              data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(inversePrimary: ink),
              ),
              child: navigation,
            ),
          ],
        ),
      ),
    );
  }
}
