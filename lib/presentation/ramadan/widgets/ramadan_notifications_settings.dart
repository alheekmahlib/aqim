part of '../events.dart';

/// إعدادات تنبيهات رمضان
/// Ramadan notifications settings widget
class RamadanNotificationsSettings extends StatelessWidget {
  const RamadanNotificationsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;

    return GetBuilder<RamadanController>(
      init: RamadanController.instance,
      builder: (ctrl) {
        return Column(
          children: [
            // تنبيه السحور
            _ModernNotificationTile(
              icon: SvgPath.svgRamadanSuhoor,
              title: 'suhoorReminder'.tr,
              subtitle:
                  '${'beforeFajr'.tr} ${ctrl.suhoorMinutes.value} ${'minutes'.tr}'
                      .convertNumbersToCurrentLang(),
              value: ctrl.suhoorEnabled.value,
              onChanged: (value) => ctrl.toggleSuhoorNotification(value),
              onSettingsTap: () => _showTimePickerDialog(
                context,
                title: 'suhoorTime'.tr,
                currentMinutes: ctrl.suhoorMinutes.value,
                onChanged: ctrl.updateSuhoorMinutes,
                color: context.theme.colorScheme.inversePrimary,
              ),
              color: context.theme.colorScheme.inversePrimary,
              isDark: isDark,
            ),
            const Gap(12),

            // تنبيه الإفطار
            _ModernNotificationTile(
              icon: SvgPath.svgRamadanCannon,
              title: 'iftarReminder'.tr,
              subtitle:
                  '${'beforeMaghrib'.tr} ${ctrl.iftarMinutes.value} ${'minutes'.tr}'
                      .convertNumbersToCurrentLang(),
              value: ctrl.iftarEnabled.value,
              onChanged: (value) => ctrl.toggleIftarNotification(value),
              onSettingsTap: () => _showTimePickerDialog(
                context,
                title: 'iftarTime'.tr,
                currentMinutes: ctrl.iftarMinutes.value,
                onChanged: ctrl.updateIftarMinutes,
                color: context.theme.colorScheme.inversePrimary,
              ),
              color: context.theme.colorScheme.inversePrimary,
              isDark: isDark,
            ),
            const Gap(12),

            // تنبيهات العشر الأواخر
            _ModernNotificationTile(
              icon: SvgPath.svgRamadanRamadanCalendar,
              title: 'lastTenNights'.tr,
              subtitle: 'lastTenNightsDesc'.tr,
              value: ctrl.lastTenNightsEnabled.value,
              onChanged: (value) => ctrl.toggleLastTenNightsNotification(value),
              color: context.theme.colorScheme.inversePrimary,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  void _showTimePickerDialog(
    BuildContext context, {
    required String title,
    required int currentMinutes,
    required Function(int) onChanged,
    required Color color,
  }) {
    final options = [15, 30, 45, 60, 90, 120];

    Get.dialog(
      AlertDialog(
        backgroundColor: context.theme.colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titlePadding: const EdgeInsets.all(8.0),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.theme.colorScheme.surface.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                SolarIconsBold.clockCircle,
                color: context.theme.colorScheme.surface,
                size: 24,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: context.theme.colorScheme.inversePrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((minutes) {
            final isSelected = minutes == currentMinutes;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    onChanged(minutes);
                    Get.back();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.theme.colorScheme.surface.withValues(
                              alpha: 0.3,
                            )
                          : context.theme.colorScheme.surface.withValues(
                              alpha: 0.2,
                            ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? context.theme.colorScheme.surface
                            : Colors.transparent,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$minutes ${'minutes'.tr}'
                              .convertNumbersToCurrentLang(),
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? color
                                : context.theme.colorScheme.inversePrimary
                                      .withValues(alpha: .7),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            SolarIconsBold.checkCircle,
                            color: context.theme.colorScheme.inversePrimary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.theme.colorScheme.inversePrimary.withValues(
                  alpha: .7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// عنصر تنبيه محسّن
class _ModernNotificationTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onSettingsTap;
  final Color color;
  final bool isDark;

  const _ModernNotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.color,
    required this.isDark,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomSwitchWidget(
      controller: RamadanController.instance,
      title: title,
      value: value,
      startPadding: 16.0,
      endPadding: 16.0,
      continerColor: value
          ? context.theme.colorScheme.surface.withValues(alpha: .3)
          : context.theme.colorScheme.surface.withValues(alpha: .2),
      onChanged: onChanged,
      titleWidget: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: context.theme.colorScheme.primaryContainer.withValues(
                alpha: .5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: customSvgWithColor(
              icon,
              color: context.theme.colorScheme.surface,
              width: 25,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    height: 1.4,
                    fontSize: 16,
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.bold,
                    color: value ? color : color.withValues(alpha: .8),
                  ),
                ),
                const Gap(2),
                Text(
                  subtitle,
                  style: TextStyle(
                    height: 1.4,
                    fontSize: 12,
                    fontFamily: 'cairo',
                    color: context.theme.colorScheme.inversePrimary.withValues(
                      alpha: .7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onSettingsTap != null && value)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSettingsTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.theme.canvasColor.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    SolarIconsOutline.settings,
                    size: 22,
                    color: color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
