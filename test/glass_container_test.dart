import 'package:aqim/core/utils/helpers/glass_tokens.dart';
import 'package:aqim/core/widgets/glass/glass_background.dart';
import 'package:aqim/core/widgets/glass/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_plus/liquid_glass_plus.dart';

/// GlassContainer/GlassBackground: الكلاسيكي بدون رموز، والزجاج معها.
/// الإعدادات الزجاجية مُجبرة على fake glass حتى لا يحمّل الاختبار shader.
void main() {
  const fakeOn = FakeGlassConfigs(forceEnabled: true);
  const fakeTokens = GlassTokens(
    heroSettings: LiquidGlassSettings(fakeGlassConfigs: fakeOn),
    subtleSettings: LiquidGlassSettings(fakeGlassConfigs: fakeOn),
    opaqueSettings: LiquidGlassSettings(fakeGlassConfigs: fakeOn),
    backgroundGradient: LinearGradient(
      colors: [Colors.white, Color(0xFFE6F2EC)],
    ),
    blobs: [],
  );

  Widget host(ThemeData theme, Widget child) => MaterialApp(
    theme: theme,
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('renders classic container when no tokens attached', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(ThemeData.light(), const GlassContainer(child: Text('classic'))),
    );

    expect(find.text('classic'), findsOneWidget);
    expect(find.byType(LiquidGlass), findsNothing);
  });

  testWidgets('renders a LiquidGlass shape when tokens attached', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(
        ThemeData.light().copyWith(extensions: [fakeTokens]),
        const GlassContainer(child: Text('glass')),
      ),
    );
    await tester.pump();

    expect(find.text('glass'), findsOneWidget);
    expect(find.byType(LiquidGlass), findsOneWidget);
  });

  testWidgets('hero variant maps to hero settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(
        ThemeData.light().copyWith(extensions: [fakeTokens]),
        const GlassContainer(variant: GlassVariant.hero, child: Text('hero')),
      ),
    );
    await tester.pump();

    final glass = tester.widget<LiquidGlass>(find.byType(LiquidGlass));
    expect(glass.ownLayerSettings, fakeTokens.heroSettings);
  });

  testWidgets('opaque variant maps to opaque settings and is darker', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(
        ThemeData.light().copyWith(extensions: [GlassTokens.defaults]),
        const GlassContainer(
          variant: GlassVariant.opaque,
          child: Text('opaque'),
        ),
      ),
    );
    await tester.pump();

    final glass = tester.widget<LiquidGlass>(find.byType(LiquidGlass));
    expect(glass.ownLayerSettings, GlassTokens.defaults.opaqueSettings);
    // الأغمق يعني: صبغة أعلى عتامة وأقل تشبعًا للخلفية من النسخة البطلة.
    final opaque = GlassTokens.defaults.opaqueSettings;
    final hero = GlassTokens.defaults.heroSettings;
    expect(opaque.glassColor.a, greaterThan(hero.glassColor.a));
    expect(opaque.saturation, lessThanOrEqualTo(hero.saturation));
  });

  testWidgets('background paints only with tokens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(ThemeData.light(), const GlassBackground()));
    expect(find.byType(GlassBackground), findsOneWidget);

    await tester.pumpWidget(
      host(
        ThemeData.light().copyWith(extensions: [fakeTokens]),
        const GlassBackground(),
      ),
    );
    await tester.pump();
    expect(find.byType(GlassBackground), findsOneWidget);
  });
}
