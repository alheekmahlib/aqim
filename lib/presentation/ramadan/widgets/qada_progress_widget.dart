part of '../events.dart';

/// عداد التقدم الدائري للقضاء
/// Circular progress widget for Qada tracking
class QadaProgressWidget extends StatelessWidget {
  const QadaProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = RamadanController.instance;
    final isDark = context.theme.brightness == Brightness.dark;

    return Obx(() {
      final missedCount = ctrl.missedDays.length;
      final fastedCount = ctrl.fastedDays.length;

      if (missedCount == 0) {
        return _EmptyQadaState();
      }

      final progress = missedCount > 0
          ? (fastedCount / missedCount) * 100
          : 0.0;
      final remaining = missedCount - fastedCount;
      final isCompleted = remaining == 0;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // العداد الدائري المحسّن
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // الخلفية
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 10,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.theme.colorScheme.surface.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                // التقدم
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: progress / 100,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted
                          ? context.theme.colorScheme.surface.withValues(
                              alpha: 0.8,
                            )
                          : context.theme.colorScheme.inverseSurface,
                    ),
                  ),
                ),
                // أيقونة النجاح أو النسبة
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.theme.colorScheme.surface.withValues(
                      alpha: 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? Icon(
                          SolarIconsBold.checkCircle,
                          size: 40,
                          color: context.theme.colorScheme.surface.withValues(
                            alpha: 0.8,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${progress.toStringAsFixed(0)}%'
                                  .convertNumbersToCurrentLang(),
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'cairo',
                                height: 1.4,
                                fontWeight: FontWeight.bold,
                                color: context.theme.colorScheme.inverseSurface,
                              ),
                            ),
                            Text(
                              'completed'.tr,
                              style: TextStyle(
                                color: context.theme.colorScheme.inversePrimary,
                                fontSize: 10,
                                height: 1.4,
                                fontFamily: 'cairo',
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const Gap(20),

          // الإحصائيات
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ModernStatItem(
                  icon: SolarIconsBold.closeCircle,
                  label: 'totalMissedDays'.tr,
                  value: missedCount,
                  color: context.theme.colorScheme.inverseSurface,
                  isDark: isDark,
                ),
                const Gap(4),
                _ModernStatItem(
                  icon: SolarIconsBold.checkCircle,
                  label: 'fastedDays'.tr,
                  value: fastedCount,
                  color: context.theme.colorScheme.surface,
                  isDark: isDark,
                ),
                const Gap(4),
                _ModernStatItem(
                  icon: SolarIconsBold.clockCircle,
                  label: 'remainingQada'.tr,
                  value: remaining,
                  color: Colors.orange.shade500,
                  isDark: isDark,
                  highlight: true,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

/// عنصر إحصائية حديث
class _ModernStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final bool isDark;
  final bool highlight;

  const _ModernStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        // color: highlight
        //     ? color.withValues(alpha: 0.1)
        //     : context.theme.canvasColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? color.withValues(alpha: 0.6)
              : color.withValues(alpha: .3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const Gap(8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'cairo',
                color: context.theme.colorScheme.inversePrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.3 : 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$value'.convertNumbersToCurrentLang(),
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'cairo',
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// حالة فارغة للقضاء
class _EmptyQadaState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surface.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            SolarIconsBold.checkCircle,
            size: 28,
            color: context.theme.colorScheme.surface,
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'noMissedDays'.tr,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.theme.colorScheme.inversePrimary,
                ),
              ),
              Text(
                'tapCalendarToAddMissedDays'.tr,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 12,
                  color: context.theme.colorScheme.inversePrimary.withValues(
                    alpha: .8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
