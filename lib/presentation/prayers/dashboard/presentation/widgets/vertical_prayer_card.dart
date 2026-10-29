part of '../../../prayers.dart';

class VerticalPrayerCard extends StatelessWidget {
  const VerticalPrayerCard({
    super.key,
    required this.data,
    required this.navigation,
  });
  final DashboardViewData data;
  final Widget navigation;
  @override
  Widget build(BuildContext context) => DashboardCard(
    child: Column(
      crossAxisAlignment: .center,
      children: [
        Column(
          crossAxisAlignment: .center,
          children: [
            for (final prayer in data.prayers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: .center,
                  children: [
                    Icon(
                      prayer.icon,
                      color: Theme.of(context).colorScheme.surface,
                      size: 28,
                    ),
                    const Gap(16),
                    Expanded(
                      child: Text(
                        prayer.name,
                        style: dashboardText(context, 20),
                      ),
                    ),
                    const Gap(12),
                    Flexible(
                      child: Text(
                        prayer.time,
                        style: dashboardText(context, 20),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            const Gap(12),
            NightTimesRow(times: data.night),
          ],
        ),
        const Gap(12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: .05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: navigation,
        ),
      ],
    ),
  );
}
