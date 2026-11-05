part of '../../prayers.dart';

class VerticalPrayerCard extends StatelessWidget {
  const VerticalPrayerCard({
    super.key,
    required this.data,
    required this.navigation,
  });
  final DashboardViewData data;
  final Widget navigation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          navigation,
          const Gap(14),
          for (final (index, prayer) in data.prayers.indexed) ...[
            GlassContainer(
              onTap: () => context.customBottomSheet(
                textTitle: 'prayerDetails'.tr,
                containerColor: context.theme.colorScheme.primaryContainer,
                child: PrayerDetails(
                  prayerName: prayer.legacy['title'] as String,
                ),
              ),
              radius: 24,
              variant: GlassVariant.subtle,
              backgroundColor: colors.surface.withValues(alpha: .12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: index == data.currentIndex
                      ? colors.surface.withValues(alpha: .28)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(prayer.icon, color: colors.surface, size: 24),
                    const Gap(14),
                    Expanded(
                      child: Text(
                        prayer.name,
                        style: dashboardText(context, 17),
                      ),
                    ),
                    const Gap(8),
                    Flexible(
                      child: Text(
                        prayer.time,
                        textAlign: TextAlign.end,
                        style: dashboardText(context, 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(8),
          ],
          const Gap(8),
          GlassContainer(
            radius: 20,
            variant: GlassVariant.subtle,
            backgroundColor: colors.surface.withValues(alpha: .1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: NightTimesRow(times: data.night),
          ),
        ],
      ),
    );
  }
}
