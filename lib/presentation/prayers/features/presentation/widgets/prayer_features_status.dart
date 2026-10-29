import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/widgets/container_button_widget.dart';
import '../prayer_feature_settings_controller.dart';

class PrayerFeaturesStatus extends StatelessWidget {
  const PrayerFeaturesStatus({super.key, required this.controller});

  final PrayerFeatureSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.saving) const LinearProgressIndicator(minHeight: 2),
        if (state.errorKey != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                state.errorKey!.tr,
                style: TextStyle(
                  fontFamily: 'cairo',
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
          ),
        if (state.loadFailed)
          ContainerButtonWidget(
            title: 'prayerFeaturesRetry'.tr,
            titleColor: Theme.of(context).colorScheme.inversePrimary,
            withShape: false,
            useGradient: false,
            onPressed: controller.reload,
          ),
      ],
    );
  }
}
