import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:aqim/core/utils/helpers/app_themes.dart';
import 'package:aqim/core/widgets/custom_switch_widget.dart';
import 'package:aqim/presentation/prayers/features/data/pending_prayer_feature_capabilities.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature_availability.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_id.dart';
import 'package:aqim/presentation/prayers/features/domain/save_prayer_feature_settings.dart';
import 'package:aqim/presentation/prayers/features/presentation/prayer_feature_settings_controller.dart';
import 'package:aqim/presentation/prayers/features/presentation/widgets/prayer_features_section.dart';
import 'package:aqim/presentation/prayers/features/presentation/widgets/prayer_timing_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'fake_prayer_feature_capabilities.dart';
import 'fake_prayer_feature_repository.dart';
import 'feature_test_translations.dart';

Widget host(
  Widget child, {
  String language = 'en',
  ThemeData? theme,
  double scale = 1,
}) => GetMaterialApp(
  locale: Locale(language),
  supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  translations: FeatureTestTranslations(),
  theme: theme ?? blueTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    backgroundColor: (theme ?? blueTheme).colorScheme.primaryContainer,
    body: RepaintBoundary(
      key: const ValueKey('preview'),
      child: ColoredBox(
        color: (theme ?? blueTheme).colorScheme.primaryContainer,
        child: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final font = FontLoader('cairo')
      ..addFont(rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    await font.load();
  });

  setUp(() {
    Get.testMode = true;
  });
  tearDown(Get.reset);

  PrayerFeatureSettingsController create(
    FakePrayerFeatureRepository repository,
  ) {
    final caps = FakePrayerFeatureCapabilities(
      value: PrayerFeatureAvailability.comingSoon,
    );
    return Get.put(
      PrayerFeatureSettingsController(
        repository: repository,
        capabilities: caps,
        save: SavePrayerFeatureSettings(repository, caps),
      ),
    );
  }

  for (final language in ['ar', 'en']) {
    for (final entry in {
      'light': blueTheme,
      'dark': darkTheme,
      'glass': liquidGlassTheme,
    }.entries) {
      testWidgets(
        '${entry.key} $language: sections and timing editors fit at 2x text, 320px',
        (tester) async {
          tester.view.physicalSize = const Size(320, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final controller = create(FakePrayerFeatureRepository());
          await tester.pumpWidget(
            host(
              PrayerFeaturesSection(controller: controller),
              language: language,
              theme: entry.value,
              scale: 2,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final context = tester.element(find.byType(PrayerFeaturesSection));
          expect(
            Directionality.of(context),
            language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          for (final feature in [
            PrayerFeature.silence,
            PrayerFeature.reminder,
          ]) {
            await tester.pumpWidget(
              host(
                PrayerTimingSettingsSheet(
                  controller: controller,
                  feature: feature,
                ),
                language: language,
                theme: entry.value,
                scale: 2,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.byType(CustomSwitch), findsNWidgets(5));
          }
        },
      );
    }
  }

  testWidgets(
    'unfinished switches cannot show optimistic success or save enabled state',
    (tester) async {
      final repo = FakePrayerFeatureRepository();
      final controller = create(repo);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(PrayerFeaturesSection(controller: controller)),
        );
        await tester.pumpAndSettle();
        final toggle = find.byKey(const ValueKey('feature-silence'));
        final node = tester.getSemantics(toggle);
        expect(
          node,
          matchesSemantics(
            label: 'Silence during prayer',
            hasEnabledState: true,
            isEnabled: false,
            hasToggledState: true,
            isToggled: false,
          ),
        );
        await tester.tapAt(tester.getCenter(toggle));
        await tester.pumpAndSettle();
        expect(repo.saves, 0);
        for (final widget in tester.widgetList<CustomSwitch>(
          find.byType(CustomSwitch),
        )) {
          expect(widget.value, isFalse);
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'opens existing bottom sheet and saves global, custom and reset values',
    (tester) async {
      final repo = FakePrayerFeatureRepository();
      final controller = create(repo);
      await tester.pumpWidget(
        host(PrayerFeaturesSection(controller: controller)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('configure-silence')));
      await tester.pumpAndSettle();
      expect(find.byType(PrayerTimingSettingsSheet), findsOneWidget);
      final global = find.byKey(const ValueKey('global-minutes'));
      await tester.ensureVisible(global);
      await tester.tap(
        find.descendant(
          of: global,
          matching: find.byKey(const ValueKey('increase')),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.stored[PrayerFeature.silence].minutes, 21);
      final fajr = find.byKey(const ValueKey('prayer-fajr'));
      final increase = find.descendant(
        of: fajr,
        matching: find.byKey(const ValueKey('increase')),
      );
      await tester.ensureVisible(increase);
      await tester.tap(increase);
      await tester.pumpAndSettle();
      expect(repo.stored[PrayerFeature.silence].minutesFor(PrayerId.fajr), 22);
      final reset = find.text('Reset prayer to defaults');
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(repo.stored[PrayerFeature.silence].overrides, isEmpty);
      expect(repo.stored[PrayerFeature.silence].minutesFor(PrayerId.fajr), 21);
    },
  );

  testWidgets(
    'iOS explains device silence limitation without an active switch',
    (tester) async {
      final repo = FakePrayerFeatureRepository();
      const caps = PendingPrayerFeatureCapabilities(
        isAndroid: false,
        isIOS: true,
        isMacOS: false,
      );
      final controller = Get.put(
        PrayerFeatureSettingsController(
          repository: repo,
          capabilities: caps,
          save: SavePrayerFeatureSettings(repo, caps),
        ),
      );
      await tester.pumpWidget(
        host(PrayerFeaturesSection(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Use Focus or Do Not Disturb'),
        findsOneWidget,
      );
      expect(controller.canToggle(PrayerFeature.silence), isFalse);
    },
  );

  test(
    'every supported locale includes all feature strings and keeps placeholders',
    () {
      final english =
          jsonDecode(File('assets/locales/en.json').readAsStringSync())
              as Map<String, dynamic>;
      final keys = english.keys
          .where((key) => key.startsWith('prayerFeatures'))
          .toSet();
      expect(keys, hasLength(28));
      for (final file in Directory(
        'assets/locales',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
        final locale =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        for (final key in keys) {
          expect(locale[key], isA<String>(), reason: '${file.path}: $key');
          expect((locale[key] as String).trim(), isNotEmpty);
        }
        expect(locale['prayerFeaturesMinutes'], contains('@minutes'));
      }
    },
  );

  testWidgets('optional review previews', (tester) async {
    const directory = String.fromEnvironment('PRAYER_FEATURE_PREVIEW_DIR');
    if (directory.isEmpty) return;
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = create(FakePrayerFeatureRepository());
    for (final entry in {'light': blueTheme, 'dark': darkTheme}.entries) {
      await tester.pumpWidget(
        host(
          PrayerFeaturesSection(controller: controller),
          language: 'ar',
          theme: entry.value,
        ),
      );
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(directory).create(recursive: true);
        await File(
          '$directory/prayer-features-${entry.key}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
