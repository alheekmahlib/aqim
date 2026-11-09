part of '../../prayers.dart';

class SetTimingCalculations extends StatelessWidget {
  SetTimingCalculations({super.key});

  final adhanCtrl = AdhanController.instance;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdhanController>(
      id: 'init_athan',
      builder: (adhanCtrl) => Column(
        children: [
          Text(
            'setTimingCalculations'.tr,
            style: TextStyle(
              color: context.theme.colorScheme.inversePrimary,
              fontFamily: 'cairo',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Gap(4),
          CustomSwitchWidget<AdhanController>(
            controller: AdhanController.instance,
            startPadding: 16.0,
            endPadding: 16.0,
            title: 'automaticallyDetermineCalculationMethod',
            value: adhanCtrl.state.autoCalculationMethod.value,
            onChanged: (bool value) => adhanCtrl.switchAutoCalculation(value),
          ),
          Obx(
            () => !adhanCtrl.state.autoCalculationMethod.value
                ? PickCalculationMethod()
                : const SizedBox.shrink(),
          ),
          Text(
            'madhab'.tr,
            style: TextStyle(
              color: context.theme.colorScheme.inversePrimary.withValues(
                alpha: .7,
              ),
              fontFamily: 'cairo',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Gap(4),
          _PrayerCalculationChoice(
            title: 'shafie',
            selected: !adhanCtrl.state.isHanafi,
            onTap: () => adhanCtrl.hanafiOnTap(false),
          ),
          _PrayerCalculationChoice(
            title: 'hanafe',
            selected: adhanCtrl.state.isHanafi,
            onTap: () => adhanCtrl.hanafiOnTap(true),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'madhabNote'.tr,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.theme.colorScheme.inversePrimary.withValues(
                  alpha: .5,
                ),
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          const Gap(32),
          _PrayerCalculationChoice(
            title: 'middleOfTheNight',
            selected: adhanCtrl.state.middleOfTheNight.value,
            onTap: () => adhanCtrl.getHighLatitudeRule(0),
          ),
          _PrayerCalculationChoice(
            title: 'SeventhOfTheNight',
            selected: adhanCtrl.state.seventhOfTheNight.value,
            onTap: () => adhanCtrl.getHighLatitudeRule(1),
          ),
          _PrayerCalculationChoice(
            title: 'usingTheAngle',
            selected: adhanCtrl.state.twilightAngle.value,
            onTap: () => adhanCtrl.getHighLatitudeRule(2),
          ),
        ],
      ),
    );
  }
}

class _PrayerCalculationChoice extends StatelessWidget {
  const _PrayerCalculationChoice({
    required this.title,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    inMutuallyExclusiveGroup: true,
    child: Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: context.theme.colorScheme.inversePrimary,
        ),
        title: Text(
          title.tr,
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.inversePrimary,
          ),
        ),
      ),
    ),
  );
}
