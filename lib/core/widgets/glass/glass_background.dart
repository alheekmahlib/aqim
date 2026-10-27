import 'package:flutter/material.dart';

import '../../utils/helpers/glass_tokens.dart';

/// Brand gradient with soft radial blobs painted behind the app content.
///
/// Painted only while glass tokens are attached (Liquid Glass theme);
/// in classic themes it collapses to nothing.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.glassTokens;
    if (tokens == null) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(gradient: tokens.backgroundGradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortestSide = constraints.biggest.shortestSide;
          return Stack(
            fit: StackFit.expand,
            children: [
              for (final blob in tokens.blobs)
                Align(
                  alignment: blob.alignment,
                  child: Container(
                    width: shortestSide * blob.radius,
                    height: shortestSide * blob.radius,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [blob.color, blob.color.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
