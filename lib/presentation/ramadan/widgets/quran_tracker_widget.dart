part of '../events.dart';

/// عداد ختمات القرآن
/// Quran Khatma tracker widget
class QuranTrackerWidget extends StatelessWidget {
  const QuranTrackerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 30,
          height: 150,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              'quranSection'.tr,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'cairo',
                fontWeight: FontWeight.bold,
                color: context.theme.canvasColor,
                height: 1.4,
              ),
            ),
          ),
        ),
        const Spacer(),
        // الدائرة الرئيسية مع العدد
        GetBuilder<RamadanController>(
          init: RamadanController.instance,
          builder: (ctrl) {
            final isCompleted = ctrl.currentJuz.value >= 30;
            return Stack(
              alignment: Alignment.center,
              children: [
                // دائرة التقدم
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: ctrl.khatmaProgress / 100,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    backgroundColor: context.theme.colorScheme.surface
                        .withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted
                          ? context.theme.colorScheme.surface
                          : context.theme.colorScheme.surface.withValues(
                              alpha: .7,
                            ),
                    ),
                  ),
                ),
                // العدد
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${ctrl.currentJuz.value}'.convertNumbersToCurrentLang(),
                      style: TextStyle(
                        height: 1.4,
                        fontSize: 26,
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                        color: context.theme.colorScheme.surface,
                      ),
                    ),
                    Text(
                      'juz'.tr,
                      style: TextStyle(
                        height: 1.4,
                        fontSize: 14,
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                        color: context.theme.colorScheme.surface,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const Spacer(),
        GetBuilder<RamadanController>(
          init: RamadanController.instance,
          builder: (ctrl) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // عرض الختمات المكتملة
              // if (ctrl.completedKhatmasCount > 0) ...[
              Container(
                height: 150,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.theme.colorScheme.surface.withValues(
                    alpha: .1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          SolarIconsBold.medalRibbonStar,
                          size: 28,
                          color: context.theme.colorScheme.surface,
                        ),
                        const Gap(16),
                        Text(
                          '${ctrl.completedKhatmasCount} ${'khatmas'.tr}'
                              .convertNumbersToCurrentLang(),
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'cairo',
                            fontWeight: FontWeight.bold,
                            color: context.theme.colorScheme.surface,
                          ),
                        ),
                        const Gap(16),
                        GestureDetector(
                          onTap: ctrl.resetQuranData,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: context.theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'reset'.tr,
                              style: TextStyle(
                                height: 1.4,
                                fontSize: 14,
                                fontFamily: 'cairo',
                                color: context.theme.canvasColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    // أزرار التحكم
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ModernControlButton(
                          icon: SolarIconsBold.minusCircle,
                          onTap: ctrl.decrementJuz,
                          color: context.theme.colorScheme.surface,
                          isDark: isDark,
                        ),
                        // const Spacer(),
                        _ModernControlButton(
                          icon: SolarIconsBold.addCircle,
                          onTap: ctrl.incrementJuz,
                          color: context.theme.colorScheme.surface,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ],
            ],
          ),
        ),
      ],
    );
  }
}

/// زر تحكم محسّن
class _ModernControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool isDark;

  const _ModernControlButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Icon(icon, size: 28, color: color),
        ),
      ),
    );
  }
}
