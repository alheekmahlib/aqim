import 'package:flutter/material.dart';
import 'package:liquid_glass_plus/liquid_glass_plus.dart';

import '../../utils/helpers/glass_tokens.dart';

/// Intensity preset of a glass surface.
enum GlassVariant {
  /// Dense glass for hero surfaces (next-prayer card, headers, sheets).
  hero,

  /// Light glass for tiles and list items (cheaper to render).
  subtle,

  /// Near-opaque dark glass — the backdrop barely shows through,
  /// for content-heavy surfaces where readability comes first.
  opaque,
}

/// Theme-aware glass surface.
///
/// Renders a classic themed container when no [GlassTokens] are attached
/// to the active theme, and a Liquid Glass shape when they are — callers
/// never branch on the theme themselves.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 16,
    this.variant = GlassVariant.subtle,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
  });

  final Widget child;
  final double radius;
  final GlassVariant variant;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  /// Classic-mode fill; falls back to `surfaceContainer`.
  final Color? backgroundColor;

  /// Classic-mode border.
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    final borderRadius = BorderRadius.circular(radius);

    final tokens = context.glassTokens;
    if (tokens == null) {
      Widget classic = Material(
        color:
            backgroundColor ?? Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: borderRadius,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      );
      if (border != null) {
        classic = Container(
          decoration: BoxDecoration(border: border, borderRadius: borderRadius),
          child: classic,
        );
      }
      return classic;
    }

    final glass = LiquidGlass.withOwnLayer(
      settings: switch (variant) {
        GlassVariant.hero => tokens.heroSettings,
        GlassVariant.subtle => tokens.subtleSettings,
        GlassVariant.opaque => tokens.opaqueSettings,
      },
      shape: LiquidRoundedSuperellipse(borderRadius: radius),
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );

    if (onTap == null) return glass;
    return GlassGlow(glowColor: Colors.white24, child: glass);
  }
}
