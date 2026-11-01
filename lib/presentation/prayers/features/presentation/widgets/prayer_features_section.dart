import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/constants/extensions/bottom_sheet_extension.dart';
import '../../../../../../core/widgets/container_button_widget.dart';
import '../../domain/prayer_feature.dart';
import '../../domain/prayer_feature_availability.dart';
import '../custom_adhan_controller.dart';
import '../prayer_feature_labels.dart';
import '../prayer_feature_settings_controller.dart';
import 'custom_adhan_section.dart';
import 'prayer_feature_toggle.dart';
import 'prayer_features_status.dart';
import 'prayer_timing_settings_sheet.dart';

class PrayerFeaturesSection extends StatelessWidget {
  const PrayerFeaturesSection({super.key, required this.controller});

  final PrayerFeatureSettingsController controller;

  @override
  Widget build(BuildContext context) =>
      GetBuilder<PrayerFeatureSettingsController>(
        init: controller,
        autoRemove: false,
        builder: (controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'prayerFeaturesTitle'.tr,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
            PrayerFeaturesStatus(controller: controller),
            for (final feature in PrayerFeature.values.where(
              (feature) =>
                  controller.availability(feature) !=
                  PrayerFeatureAvailability.unsupported,
            )) ...[
              PrayerFeatureToggle(
                key: ValueKey('feature-${feature.name}'),
                controller: controller,
                titleKey: feature.titleKey,
                value: controller.isEnabled(feature),
                enabled: controller.canToggle(feature),
                onChanged: (value) => controller.setEnabled(feature, value),
              ),
              const Gap(8),
              if (feature == PrayerFeature.customAdhan &&
                  controller.isEnabled(feature))
                CustomAdhanSection(
                  controller: Get.find<CustomAdhanController>(),
                ),
              // وصول عدم الإزعاج لا يُمنح برمجيًا؛ مسار منح صريح للتصميت.
              if (feature == PrayerFeature.silence &&
                  controller.availability(feature) ==
                      PrayerFeatureAvailability.needsPermission)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ContainerButtonWidget(
                    key: const ValueKey('grant-silence'),
                    title: 'prayerFeaturesGrantSilence'.tr,
                    titleColor: Theme.of(context).colorScheme.inversePrimary,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: .15),
                    borderRadius: 8,
                    withShape: false,
                    useGradient: false,
                    onPressed: controller.grantSilenceAccess,
                  ),
                ),
              if (feature.hasTiming)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ContainerButtonWidget(
                    key: ValueKey('configure-${feature.name}'),
                    title: feature.timingTitleKey.tr,
                    titleColor: Theme.of(context).colorScheme.inversePrimary,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: .15),
                    borderRadius: 8,
                    withShape: false,
                    useGradient: false,
                    onPressed: () => context.customBottomSheet(
                      textTitle: feature.timingTitleKey,
                      containerColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: PrayerTimingSettingsSheet(
                        controller: controller,
                        feature: feature,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
}
