part of '../../prayers.dart';

class PrayerSettings extends StatelessWidget {
  const PrayerSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GetBuilder<GeneralController>(builder: (generalCtrl) {
        return Column(
          children: [
            CustomSwitchWidget(
              controller: GeneralController.instance,
              title: 'detectLocation',
              value: generalCtrl.state.activeLocation.value,
              startPadding: 16.0,
              endPadding: 16.0,
              onChanged: (bool value) => generalCtrl.toggleLocationService(),
            ),
            const Gap(8),
            AdhanSounds(),
            const Gap(8),
            SetTimingCalculations(),
            const Gap(8),
            PrayerFeaturesSection(
              controller: Get.find<PrayerFeatureSettingsController>(),
            ),
          ],
        );
      }),
    );
  }
}
