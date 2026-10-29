import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/widgets/custom_switch_widget.dart';
import '../prayer_feature_settings_controller.dart';

/// Adds true disabled semantics without changing the shared legacy switch.
class PrayerFeatureToggle extends StatelessWidget {
  const PrayerFeatureToggle({
    super.key,
    required this.controller,
    required this.titleKey,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final PrayerFeatureSettingsController controller;
  final String titleKey;
  final bool value;
  final bool enabled;
  final Future<void> Function(bool) onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: titleKey.tr,
    toggled: value,
    enabled: enabled,
    onTap: enabled ? () => onChanged(!value) : null,
    child: ExcludeSemantics(
      child: IgnorePointer(
        ignoring: !enabled,
        child: Opacity(
          opacity: enabled ? 1 : .55,
          child: CustomSwitchWidget<PrayerFeatureSettingsController>(
            controller: controller,
            title: titleKey,
            titleWidget: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Text(
                titleKey.tr,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
            value: value,
            startPadding: 12,
            endPadding: 12,
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );
}
