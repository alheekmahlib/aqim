part of '../../prayers.dart';

class PrayerSettings extends StatelessWidget {
  const PrayerSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final features = Get.find<PrayerFeatureSettingsController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _PrayerSettingsEntry(
            title: 'prayerSettingsLocation',
            description: 'prayerSettingsLocationDesc',
            icon: Icons.location_on_outlined,
            child: GetBuilder<GeneralController>(
              builder: (generalCtrl) => Column(
                children: [
                  CustomSwitchWidget(
                    controller: generalCtrl,
                    title: 'detectLocation',
                    value: generalCtrl.state.activeLocation.value,
                    startPadding: 16,
                    endPadding: 16,
                    onChanged: (_) => generalCtrl.toggleLocationService(),
                  ),
                  const Gap(8),
                  SetTimingCalculations(),
                ],
              ),
            ),
          ),
          _PrayerSettingsEntry(
            title: 'SetPrayerTimes',
            description: 'prayerSettingsTimesDesc',
            icon: Icons.schedule,
            child: GetBuilder<AdhanController>(
              id: 'init_athan',
              builder: (adhanCtrl) => Column(
                children: [
                  const Gap(8),
                  CustomSwitchWidget<AdhanController>(
                    controller: adhanCtrl,
                    title: 'showIqamaTimes',
                    value: adhanCtrl.state.showIqamaTimes.value,
                    startPadding: 16,
                    endPadding: 16,
                    onChanged: adhanCtrl.toggleShowIqamaTimes,
                  ),
                  const Gap(8),
                  const SettingPrayerTimes(
                    isOnePrayer: false,
                    showGeneralOptions: false,
                  ),
                ],
              ),
            ),
          ),
          _PrayerSettingsEntry(
            title: 'prayerSettingsSound',
            description: 'prayerSettingsSoundDesc',
            icon: Icons.volume_up_outlined,
            child: Column(
              children: [
                AdhanSounds(),
                const Gap(8),
                PrayerFeaturesSection(
                  controller: features,
                  features: const {
                    PrayerFeature.customAdhan,
                    PrayerFeature.flipToStop,
                    PrayerFeature.volumeToStop,
                  },
                ),
              ],
            ),
          ),
          _PrayerSettingsEntry(
            title: 'prayerSettingsNotifications',
            description: 'prayerSettingsNotificationsDesc',
            icon: Icons.notifications_outlined,
            child: GetBuilder<AdhanController>(
              id: 'init_athan',
              builder: (adhanCtrl) => Column(
                children: [
                  PrayerFeaturesSection(
                    controller: features,
                    features: const {PrayerFeature.reminder},
                  ),
                  CustomSwitchWidget<AdhanController>(
                    controller: adhanCtrl,
                    title: 'iqamaNotifications',
                    value: adhanCtrl.state.iqamaNotificationsEnabled.value,
                    startPadding: 16,
                    endPadding: 16,
                    onChanged: adhanCtrl.toggleIqamaNotifications,
                  ),
                  CustomSwitchWidget<AdhanController>(
                    controller: adhanCtrl,
                    title: 'prayerCountdownNotification',
                    value: adhanCtrl.state.prayerCountdownEnabled.value,
                    startPadding: 16,
                    endPadding: 16,
                    onChanged: adhanCtrl.togglePrayerCountdownNotification,
                  ),
                ],
              ),
            ),
          ),
          if (features.availability(PrayerFeature.silence) ==
              PrayerFeatureAvailability.available)
            _PrayerSettingsEntry(
              title: 'prayerSettingsSilent',
              description: 'prayerSettingsSilentDesc',
              icon: Icons.volume_off_outlined,
              child: PrayerFeaturesSection(
                controller: features,
                features: const {PrayerFeature.silence},
              ),
            ),
        ],
      ),
    );
  }
}

class _PrayerSettingsEntry extends StatelessWidget {
  const _PrayerSettingsEntry({
    required this.title,
    required this.description,
    required this.icon,
    required this.child,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: GlassContainer(
      onTap: () => context.customPushToPage(
        context: context,
        textTitle: title,
        containerColor: context.theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ),
      radius: 24,
      variant: GlassVariant.hero,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      backgroundColor: context.theme.colorScheme.surface.withValues(alpha: .3),
      child: Row(
        children: [
          Icon(icon, color: context.theme.colorScheme.inversePrimary),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  title.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.bold,
                    color: context.theme.colorScheme.inversePrimary,
                  ),
                ),
                Text(
                  description.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'cairo',
                    color: context.theme.colorScheme.inversePrimary.withValues(
                      alpha: .7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          Icon(
            Icons.chevron_right,
            textDirection: Directionality.of(context),
            color: context.theme.colorScheme.inversePrimary,
          ),
        ],
      ),
    ),
  );
}
