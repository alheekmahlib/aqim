import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/constants/extensions/convert_number_extension.dart';
import '../../../../../../core/widgets/custom_button.dart';

class PrayerMinutesStepper extends StatelessWidget {
  const PrayerMinutesStepper({
    super.key,
    required this.minutes,
    required this.maximum,
    required this.enabled,
    required this.onAdjust,
  });

  final int minutes;
  final int maximum;
  final bool enabled;
  final Future<void> Function(int) onAdjust;

  @override
  Widget build(BuildContext context) {
    final label = 'prayerFeaturesMinutes'.trParams({
      'minutes': '$minutes'.convertNumbersToCurrentLang(),
    });
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        _button(context, -1, enabled && minutes > 1),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        _button(context, 1, enabled && minutes < maximum),
      ],
    );
  }

  Widget _button(BuildContext context, int delta, bool active) => Semantics(
    label: (delta > 0 ? 'prayerFeaturesIncrease' : 'prayerFeaturesDecrease').tr,
    button: true,
    enabled: active,
    onTap: active ? () => onAdjust(delta) : null,
    child: ExcludeSemantics(
      child: IgnorePointer(
        ignoring: !active,
        child: Opacity(
          opacity: active ? 1 : .4,
          child: CustomButton(
            key: ValueKey(delta > 0 ? 'increase' : 'decrease'),
            width: 48,
            icon: delta > 0 ? Icons.add : Icons.remove,
            iconSize: 20,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: .3),
            svgColor: Theme.of(context).colorScheme.inversePrimary,
            onPressed: () => onAdjust(delta),
          ),
        ),
      ),
    ),
  );
}
