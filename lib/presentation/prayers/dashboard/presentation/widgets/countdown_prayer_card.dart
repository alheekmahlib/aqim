part of '../../../prayers.dart';

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
  Widget build(BuildContext context) => DashboardCard(
    child: Column(
      children: [
        Text(
          data.location,
          textAlign: TextAlign.center,
          style: dashboardText(context, 20),
        ),
        if (countdown != null) ...[
          Text(
            countdown!.title,
            textAlign: TextAlign.center,
            style: dashboardText(context, 23),
          ),
          const Gap(8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              countdown!.remaining,
              textDirection: TextDirection.ltr,
              style: dashboardText(context, 62),
            ),
          ),
          const Gap(8),
          LinearProgressIndicator(
            value: countdown!.progress,
            minHeight: 16,
            borderRadius: BorderRadius.circular(6),
            color: Theme.of(context).colorScheme.surface,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.inversePrimary.withValues(alpha: .15),
          ),
          const Gap(12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  countdown!.previous,
                  style: dashboardText(context, 14),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  countdown!.next,
                  textAlign: TextAlign.end,
                  style: dashboardText(context, 14),
                ),
              ),
            ],
          ),
        ],
        const Gap(28),
        CompactPrayerTimes(
          prayers: data.prayers,
          currentPrayerIndexOverride: prayerIndex,
        ),
        const Gap(20),
        NightTimesRow(times: data.night),
        const Gap(12),
        navigation,
      ],
    ),
  );
}
