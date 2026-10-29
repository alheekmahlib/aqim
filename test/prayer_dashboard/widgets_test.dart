import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:aqim/core/services/languages/localization_controller.dart';
import 'package:aqim/core/widgets/custom_switch_widget.dart';
import 'package:aqim/core/widgets/container_button_widget.dart';
import 'package:aqim/core/utils/helpers/app_themes.dart';
import 'package:aqim/core/utils/constants/extensions/bottom_sheet_extension.dart';
import 'package:aqim/presentation/prayers/dashboard/domain/dashboard_data.dart';
import 'package:aqim/presentation/prayers/dashboard/domain/dashboard_layout.dart';
import 'package:aqim/presentation/prayers/dashboard/presentation/dashboard_controller.dart';
import 'package:aqim/presentation/prayers/dashboard/presentation/dashboard_layout_controller.dart';
import 'package:aqim/presentation/prayers/dashboard/presentation/dashboard_presenter.dart';
import 'package:aqim/presentation/prayers/dashboard/presentation/dashboard_preview_data.dart';
import 'package:aqim/presentation/prayers/dashboard/presentation/widgets/dashboard_panel_preview.dart';
import 'package:aqim/presentation/prayers/dashboard/presentation/widgets/dashboard_customization_sheet.dart';
import 'package:aqim/presentation/prayers/dashboard/presentation/widgets/dashboard_registry.dart';
import 'package:aqim/presentation/prayers/dashboard/presentation/widgets/prayer_dashboard_cards.dart';
import 'package:aqim/presentation/prayers/screen/prayer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hijri_date/hijri.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'fixtures.dart';

class _Translations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    for (final lang in ['ar', 'en'])
      lang:
          (jsonDecode(File('assets/locales/$lang.json').readAsStringSync())
                  as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, value.toString())),
  };
}

Widget host(
  Widget child, {
  String locale = 'ar',
  ThemeData? theme,
  double scale = 1,
}) => GetMaterialApp(
  locale: Locale(locale),
  supportedLocales: const [Locale('ar'), Locale('en')],
  translations: _Translations(),
  theme: theme ?? darkTheme,
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    backgroundColor: (theme ?? darkTheme).colorScheme.primaryContainer,
    body: child,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting();
    final fonts = FontLoader('cairo')
      ..addFont(rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    await fonts.load();
    final solarFonts = FontLoader('packages/solar_icons/SolarIconsBold')
      ..addFont(
        rootBundle.load('packages/solar_icons/fonts/SolarIconsBold.ttf'),
      );
    await solarFonts.load();
    final materialFonts = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialFonts.load();
    final dir = await Directory.systemTemp.createTemp('aqim_dashboard_widgets');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => dir.path,
        );
    await GetStorage.init();
    addTearDown(() => dir.delete(recursive: true));
  });
  tearDown(() => Get.reset());

  testWidgets(
    'legacy location and week styles retain refresh and date actions',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final scenario in [
        (width: 320.0, locale: 'ar', scale: 1.8, theme: darkTheme),
        (width: 414.0, locale: 'en', scale: 1.0, theme: blueTheme),
        (width: 740.0, locale: 'ar', scale: 1.0, theme: liquidGlassTheme),
      ]) {
        tester.view.physicalSize = Size(scenario.width, 900);
        Get.locale = Locale(scenario.locale);
        Get.addTranslations(_Translations().keys);
        final date = DateTime(2026, 10, 26);
        final raw = dashboardFixture(date);
        const presenter = DashboardPresenter();
        final data = presenter.present(raw, date);
        var refreshCount = 0;
        DateTime? selected;
        Widget content({bool refreshing = false}) => host(
          Column(
            children: [
              DashboardLocationDate(
                data: data,
                refreshing: refreshing,
                onRefresh: () => refreshCount++,
              ),
              DashboardWeekCalendar(
                data: presenter.week(raw, date),
                onDateChange: (date) => selected = date,
              ),
            ],
          ),
          locale: scenario.locale,
          theme: scenario.theme,
          scale: scenario.scale,
        );
        await tester.pumpWidget(content());
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${scenario.locale} layout',
        );
        expect(find.byIcon(Icons.place_rounded), findsOneWidget);
        expect(find.text(data.locationDetails), findsOneWidget);
        final button = find.byType(ContainerButtonWidget);
        // The overlaid refresh badge must not swallow the button tap.
        final rect = tester.getRect(button);
        await tester.tapAt(
          Offset(
            scenario.locale == 'ar' ? rect.left + 15 : rect.right - 15,
            rect.top + 15,
          ),
        );
        expect(refreshCount, 1);
        final days = find
            .descendant(
              of: find.byType(HorizontalWeekCalendar),
              matching: find.byType(GestureDetector),
            )
            .hitTestable();
        await tester.tap(days.last);
        await tester.pumpAndSettle();
        expect(selected, isNotNull);
        expect(selected, isNot(date));
        await tester.pumpWidget(content(refreshing: true));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.tap(button);
        expect(refreshCount, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets('four cards fit RTL, LTR, large text, narrow and wide screens', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    for (final scenario in [
      (width: 320.0, locale: 'ar', scale: 1.8, theme: darkTheme),
      (width: 414.0, locale: 'en', scale: 1.0, theme: blueTheme),
      (width: 740.0, locale: 'ar', scale: 1.0, theme: liquidGlassTheme),
    ]) {
      tester.view.physicalSize = Size(scenario.width, 1800);
      tester.view.devicePixelRatio = 1;
      Get.locale = Locale(scenario.locale);
      Get.addTranslations(_Translations().keys);
      const presenter = DashboardPresenter();
      final raw = dashboardFixture(DateTime(2026, 10, 26));
      final data = presenter.present(raw, DateTime(2026, 10, 26, 21));
      final navigation = DashboardDateNavigation(
        label: data.dateLabel,
        onPrevious: () {},
        onNext: () {},
        onToday: () {},
      );
      final cards = <Widget>[
        VerticalPrayerCard(data: data, navigation: navigation),
        MoonPrayerCard(data: data),
        CalendarPrayerCard(data: data),
        CountdownPrayerCard(
          data: data,
          navigation: navigation,
          countdown: presenter.presentCountdown(
            PreparePrayerDashboard.countdown(
              raw.liveTimes,
              DateTime(2026, 10, 26, 21),
            ),
          ),
        ),
      ];
      for (var i = 0; i < cards.length; i++) {
        final boundary = GlobalKey();
        await tester.pumpWidget(
          host(
            SingleChildScrollView(
              child: RepaintBoundary(
                key: boundary,
                child: ColoredBox(
                  color: scenario.theme.colorScheme.primaryContainer,
                  child: cards[i],
                ),
              ),
            ),
            locale: scenario.locale,
            theme: scenario.theme,
            scale: scenario.scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'card $i, ${scenario.locale}, ${scenario.width}',
        );
        if (Platform.environment['AQIM_DASHBOARD_PREVIEW'] == '1' &&
            scenario.width == 414) {
          final repaint =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await repaint.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File('build/preview/prayer_card_$i.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    }
  });

  testWidgets(
    'custom sheet toggles, drags, restores and fits a short landscape viewport',
    (tester) async {
      tester.view.physicalSize = const Size(430, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repository = MemoryLayout();
      final controller = Get.put(
        DashboardLayoutController(CustomizeDashboard(repository)),
      );
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => context.customBottomSheet(
                  textTitle: 'dashboardCustomize',
                  scrollChild: false,
                  child: DashboardCustomizationSheet(controller: controller),
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardCustomizationSheet), findsOneWidget);
      expect(
        find.byType(CustomSwitchWidget<DashboardLayoutController>),
        findsWidgets,
      );
      expect(find.byType(Switch), findsNothing);
      await tester.tap(find.byType(CustomSwitch).first);
      await tester.pumpAndSettle();
      expect(controller.layout.value.panels.first.visible, isFalse);
      await tester.drag(
        find.byType(ReorderableDragStartListener).first,
        const Offset(0, 170),
      );
      await tester.pumpAndSettle();
      expect(
        controller.layout.value.panels.first.panel,
        isNot(PrayerPanel.currentPrayer),
      );
      await controller.pendingWrites;
      expect(
        repository.load().panels.first.panel,
        controller.layout.value.panels.first.panel,
      );
      await tester.tap(find.text('استعادة الافتراضي'));
      await tester.pumpAndSettle();
      expect(
        controller.layout.value.panels.first.panel,
        PrayerPanel.currentPrayer,
      );
      expect(controller.layout.value.panels.first.visible, isTrue);
      tester.view.physicalSize = const Size(850, 430);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Get.back<void>();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'screen shows saved cards, changes date and supports empty layout',
    (tester) async {
      tester.view.physicalSize = const Size(414, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Get.put(LocalizationController());
      final clock = FakeClock();
      final repository = FakeDataRepository();
      final controller = Get.put(
        DashboardController(PreparePrayerDashboard(repository), clock),
      );
      final layouts = MemoryLayout()
        ..value = DashboardLayout([
          for (final p in PrayerPanel.values)
            PanelPreference(p, p == PrayerPanel.verticalTimes),
        ]);
      final layout = Get.put(
        DashboardLayoutController(CustomizeDashboard(layouts)),
      );
      await controller.reload();
      await tester.pumpWidget(
        host(
          PrayerScreen(controller: controller, layoutController: layout),
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VerticalPrayerCard), findsOneWidget);
      await tester.tap(find.byTooltip('Next day'));
      await tester.pumpAndSettle();
      expect(controller.data.value!.date, DateTime(2026, 10, 27));
      layout.toggle(PrayerPanel.verticalTimes, false);
      await tester.pumpAndSettle();
      expect(find.text('No widgets selected'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('customize-prayer-dashboard')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DashboardCustomizationSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await Get.delete<DashboardController>();
      await repository.events.close();
      await clock.stream.close();
    },
  );

  test('registry covers every stable panel identifier', () {
    expect(dashboardRegistry.keys.toSet(), PrayerPanel.values.toSet());
  });

  testWidgets('every panel has a scaled preview without live controllers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final locale in ['ar', 'en']) {
      Get.locale = Locale(locale);
      Get.addTranslations(_Translations().keys);
      final data = DashboardPreviewData.localized();
      for (final definition in dashboardRegistry.values) {
        await tester.pumpWidget(
          host(
            Center(
              child: DashboardPanelPreview(
                child: definition.previewBuilder(data),
              ),
            ),
            locale: locale,
            scale: 1.8,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${definition.panel}: $locale',
        );
        expect(find.byType(FittedBox), findsWidgets);
        expect(Get.isRegistered<DashboardController>(), isFalse);
        expect(Get.isRegistered<DashboardLayoutController>(), isFalse);
      }
    }
  });
}
