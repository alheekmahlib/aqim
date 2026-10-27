import 'package:flutter/material.dart';
import 'package:liquid_glass_plus/liquid_glass_plus.dart';

/// Design tokens for the Liquid Glass theme.
///
/// Attached only to [liquidGlassTheme]. Its absence from [ThemeData]
/// means the classic look, so widgets never need to know which theme
/// is active — they just read the extension and fall back silently.
class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({
    required this.heroSettings,
    required this.subtleSettings,
    required this.opaqueSettings,
    required this.backgroundGradient,
    required this.blobs,
  });

  /// Dense glass for hero surfaces (next-prayer card, headers, sheets).
  final LiquidGlassSettings heroSettings;

  /// Light glass for tiles and list items (cheaper to render).
  final LiquidGlassSettings subtleSettings;

  /// Near-opaque dark glass for content-heavy surfaces where the
  /// backdrop must barely show through (dense lists, settings).
  final LiquidGlassSettings opaqueSettings;

  /// Gradient painted behind every screen while the theme is active.
  final Gradient backgroundGradient;

  /// Soft radial blobs layered over [backgroundGradient] to give the
  /// blur something colorful to refract.
  final List<GlassBlob> blobs;

  static const GlassTokens defaults = GlassTokens(
    heroSettings: LiquidGlassSettings(
      glassColor: Color.fromARGB(36, 255, 255, 255),
      thickness: 24,
      frostIntensity: 8,
      lightIntensity: .6,
      saturation: 1.4,
    ),
    subtleSettings: LiquidGlassSettings.subtle(),
    opaqueSettings: LiquidGlassSettings(
      glassColor: Color.fromARGB(215, 0x00, 0x1F, 0x28),
      thickness: 8,
      frostIntensity: 10,
      lightIntensity: .35,
      saturation: 1.0,
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xff002E33), Color(0xff001A23), Color(0xff01291F)],
    ),
    blobs: [
      GlassBlob(
        alignment: Alignment(-.7, -.8),
        radius: .9,
        color: Color(0x80B3EFB2),
      ),
      GlassBlob(
        alignment: Alignment(.9, -.4),
        radius: .7,
        color: Color(0x667A9E7E),
      ),
      GlassBlob(
        alignment: Alignment(-.5, .9),
        radius: 1,
        color: Color(0x59CD9974),
      ),
    ],
  );

  @override
  GlassTokens copyWith({
    LiquidGlassSettings? heroSettings,
    LiquidGlassSettings? subtleSettings,
    LiquidGlassSettings? opaqueSettings,
    Gradient? backgroundGradient,
    List<GlassBlob>? blobs,
  }) {
    return GlassTokens(
      heroSettings: heroSettings ?? this.heroSettings,
      subtleSettings: subtleSettings ?? this.subtleSettings,
      opaqueSettings: opaqueSettings ?? this.opaqueSettings,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      blobs: blobs ?? this.blobs,
    );
  }

  // Theme swapping is instant (no cross-theme animation), so a step
  // lerp is enough to satisfy the ThemeExtension contract.
  @override
  GlassTokens lerp(covariant GlassTokens? other, double t) {
    if (other == null || t < .5) return this;
    return other;
  }
}

/// A soft radial light blob of the glass background.
class GlassBlob {
  const GlassBlob({
    required this.alignment,
    required this.color,
    this.radius = .8,
  });

  final Alignment alignment;
  final Color color;

  /// Radius relative to the background's shortest side.
  final double radius;
}

/// Reads glass tokens from the active theme, or null in classic themes.
extension GlassTokensContext on BuildContext {
  GlassTokens? get glassTokens => Theme.of(this).extension<GlassTokens>();
}
