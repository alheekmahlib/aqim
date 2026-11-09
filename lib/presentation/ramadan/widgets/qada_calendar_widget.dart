part of '../events.dart';

/// تقويم هجري لاختيار أيام القضاء
/// Hijri calendar for selecting Qada days
class QadaCalendarWidget extends StatelessWidget {
  const QadaCalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = RamadanController.instance;
    final isDark = context.theme.brightness == Brightness.dark;
    final weekDays = ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // أسماء الأيام
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: context.theme.colorScheme.surface.withValues(alpha: .2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays
                .map(
                  (day) => Expanded(
                    child: Text(
                      day.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: day == 'Fri'
                            ? context.theme.colorScheme.inverseSurface
                            : context.theme.colorScheme.inversePrimary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const Gap(8),

        // شبكة الأيام
        Obx(() {
          final daysInMonth = ctrl.ramadanDaysCount;
          // Capture both reactive lists here: GridView builds its cells later,
          // outside the Obx callback that establishes subscriptions.
          final missedDays = ctrl.missedDays
              .where((day) => day.year == ctrl.hijriNow.hYear && day.month == 9)
              .map((day) => day.day)
              .toSet();
          final fastedDays = ctrl.fastedDays
              .where((day) => day.year == ctrl.hijriNow.hYear && day.month == 9)
              .map((day) => day.day)
              .toSet();

          // حساب يوم الأسبوع لأول يوم رمضان (الجمعة = 5، السبت = 6، الأحد = 0...)
          final firstDayOfRamadan = HijriDate.fromHijri(
            ctrl.hijriNow.hYear,
            9,
            1,
          ).hijriToGregorian(ctrl.hijriNow.hYear, 9, 1);
          final firstWeekday = firstDayOfRamadan.weekday; // 1=Mon, 7=Sun
          // تحويل ليبدأ من الجمعة: الجمعة=0, السبت=1, الأحد=2, الاثنين=3, الثلاثاء=4, الأربعاء=5, الخميس=6
          final startOffset =
              (firstWeekday + 1) % 7; // +1 لأن الجمعة=5 في Dart تصبح 0
          final totalCells = startOffset + daysInMonth;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              // إذا كان Index أقل من startOffset، عرض خلية فارغة
              if (index < startOffset) {
                return const SizedBox.shrink();
              }

              final day = index - startOffset + 1;
              final isMissed = missedDays.contains(day);
              final isFasted = fastedDays.contains(day);

              return _ModernDayCell(
                day: day,
                isMissed: isMissed,
                isFasted: isFasted,
                isDark: isDark,
                onTap: () => isMissed && !isFasted
                    ? _showFastDialog(context, ctrl, day)
                    : ctrl.toggleQadaDay(day),
                onLongPress: isMissed && !isFasted
                    ? () => _showFastDialog(context, ctrl, day)
                    : null,
              );
            },
          );
        }),

        // مفتاح الألوان
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(
              color: context.theme.colorScheme.inverseSurface,
              label: 'missedDay'.tr,
              isDark: isDark,
            ),
            const Gap(16),
            _LegendItem(
              color: context.theme.colorScheme.surface,
              label: 'fastedDay'.tr,
              isDark: isDark,
            ),
          ],
        ),
        const Gap(8),
        // شريط التعليمات
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: context.theme.colorScheme.surface.withValues(alpha: .2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                SolarIconsOutline.infoCircle,
                color: context.theme.colorScheme.inversePrimary,
                size: 18,
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  'tapToSelectMissedDays'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'cairo',
                    color: context.theme.colorScheme.inversePrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFastDialog(BuildContext context, RamadanController ctrl, int day) {
    Get.dialog(
      AlertDialog(
        constraints: BoxConstraints(minHeight: 100, minWidth: Get.width * 0.9),
        titlePadding: const EdgeInsets.all(8.0),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        backgroundColor: context.theme.colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.theme.colorScheme.surface.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                SolarIconsBold.checkCircle,
                color: context.theme.colorScheme.surface.withValues(alpha: 0.8),
                size: 24,
              ),
            ),
            const Gap(12),
            Text(
              'markAsFasted'.tr,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'cairo',
                fontWeight: FontWeight.bold,
                color: context.theme.colorScheme.inversePrimary,
              ),
            ),
          ],
        ),
        content: Text(
          '${'markDayAsFastedConfirm'.tr} ${'$day'.convertNumbersToCurrentLang()}?',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'cairo',
            color: context.theme.colorScheme.inversePrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'cairo',
                color: context.theme.colorScheme.inversePrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ctrl.markDayAsFasted(day);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.colorScheme.surface,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'confirm'.tr,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'cairo',
                color: context.theme.canvasColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// مفتاح الألوان
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const Gap(6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'cairo',
            color: context.theme.colorScheme.inversePrimary.withValues(
              alpha: .6,
            ),
          ),
        ),
      ],
    );
  }
}

/// خلية يوم محسّنة
class _ModernDayCell extends StatelessWidget {
  final int day;
  final bool isMissed;
  final bool isFasted;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ModernDayCell({
    required this.day,
    required this.isMissed,
    required this.isFasted,
    required this.isDark,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (isFasted) {
      backgroundColor = context.theme.colorScheme.surface.withValues(
        alpha: isDark ? 0.3 : 0.15,
      );
      textColor = context.theme.colorScheme.surface;
      borderColor = context.theme.colorScheme.surface.withValues(alpha: 0.3);
    } else if (isMissed) {
      backgroundColor = context.theme.colorScheme.inverseSurface.withValues(
        alpha: isDark ? 0.3 : 0.15,
      );
      textColor = context.theme.colorScheme.inverseSurface;
      borderColor = context.theme.colorScheme.inverseSurface.withValues(
        alpha: 0.3,
      );
    } else {
      backgroundColor = context.theme.colorScheme.surface.withValues(
        alpha: 0.1,
      );
      textColor = context.theme.colorScheme.inversePrimary;
      borderColor = context.theme.colorScheme.surface.withValues(alpha: 0.3);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: isMissed || isFasted ? 2 : 1,
            ),
            boxShadow: (isMissed || isFasted)
                ? [
                    BoxShadow(
                      color:
                          (isFasted
                                  ? context.theme.colorScheme.surface
                                        .withValues(alpha: 0.3)
                                  : context.theme.colorScheme.inverseSurface
                                        .withValues(alpha: 0.3))
                              .withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$day'.convertNumbersToCurrentLang(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontFamily: 'cairo',
                  height: 1.4,
                  fontWeight: isMissed || isFasted
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
              if (isFasted)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Icon(
                    SolarIconsBold.checkCircle,
                    size: 10,
                    color: context.theme.colorScheme.surface,
                  ),
                ),
              if (isMissed && !isFasted)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Icon(
                    SolarIconsBold.closeCircle,
                    size: 10,
                    color: context.theme.colorScheme.inverseSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
