import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/widgets/container_button_widget.dart';
import '../../domain/prayer_feature.dart';
import '../../domain/prayer_id.dart';
import '../prayer_feature_labels.dart';
import '../prayer_feature_settings_controller.dart';
import 'prayer_feature_toggle.dart';
import 'prayer_features_status.dart';
import 'prayer_minutes_stepper.dart';

class PrayerTimingSettingsSheet extends StatelessWidget {
  const PrayerTimingSettingsSheet({
    super.key,
    required this.controller,
    required this.feature,
  }) : assert(
         feature == PrayerFeature.silence || feature == PrayerFeature.reminder,
       );

  final PrayerFeatureSettingsController controller;
  final PrayerFeature feature;

  @override
  Widget build(BuildContext context) =>
      GetBuilder<PrayerFeatureSettingsController>(
        init: controller,
        autoRemove: false,
        builder: (controller) {
          final preference = controller.state.settings[feature];
          final style = TextStyle(
            fontFamily: 'cairo',
            color: Theme.of(context).colorScheme.inversePrimary,
          );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrayerFeaturesStatus(controller: controller),
                Text(
                  (feature == PrayerFeature.silence
                          ? 'prayerFeaturesSilenceHelp'
                          : 'prayerFeaturesReminderHelp')
                      .tr,
                  style: style,
                ),
                const SizedBox(height: 12),
                Text(
                  'prayerFeaturesGlobal'.tr,
                  style: style.copyWith(fontWeight: FontWeight.bold),
                ),
                PrayerMinutesStepper(
                  key: const ValueKey('global-minutes'),
                  minutes: preference.minutes!,
                  maximum: feature.maxMinutes!,
                  enabled: controller.canEdit,
                  onAdjust: (delta) => controller.adjustMinutes(feature, delta),
                ),
                const SizedBox(height: 12),
                Text('prayerFeaturesPerPrayerHelp'.tr, style: style),
                for (final prayer in PrayerId.values)
                  Padding(
                    key: ValueKey('prayer-${prayer.name}'),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PrayerFeatureToggle(
                          controller: controller,
                          titleKey: prayer.titleKey,
                          value: preference.includesPrayer(prayer),
                          enabled: controller.canEdit,
                          onChanged: (value) => controller.setPrayerIncluded(
                            feature,
                            prayer,
                            value,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 12,
                          ),
                          child: Text(
                            (preference.overrides[prayer]?.minutes == null
                                    ? 'prayerFeaturesInherited'
                                    : 'prayerFeaturesCustomized')
                                .tr,
                            style: style.copyWith(fontSize: 12),
                          ),
                        ),
                        PrayerMinutesStepper(
                          minutes: preference.minutesFor(prayer)!,
                          maximum: feature.maxMinutes!,
                          enabled:
                              controller.canEdit &&
                              preference.includesPrayer(prayer),
                          onAdjust: (delta) => controller.adjustMinutes(
                            feature,
                            delta,
                            prayer: prayer,
                          ),
                        ),
                        if (preference.overrides.containsKey(prayer))
                          ContainerButtonWidget(
                            title: 'prayerFeaturesResetPrayer'.tr,
                            titleColor: Theme.of(
                              context,
                            ).colorScheme.inversePrimary,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: .15),
                            withShape: false,
                            useGradient: false,
                            borderRadius: 8,
                            onPressed: controller.canEdit
                                ? () => controller.resetPrayer(feature, prayer)
                                : null,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      );
}
