import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:aqim/core/utils/helpers/app_themes.dart';
import 'package:aqim/presentation/prayers/prayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';

const ShareCardData _data = ShareCardData(
  prayerName: 'المغرب',
  prayerTime: '٦:٢٨ م',
  nextPrayerLabel: 'الصلاة القادمة',
  timeLeftTitle: 'الوقت المتبقي',
  timeLeftValue: '٠٢:٥٤ س',
  hijriDate: '١٧ ربيع الآخر ١٤٤٨',
  weekday: 'الجمعة',
  location: 'وهران، الجزائر',
  appName: 'أقِم - مكتبة الحكمة',
  prayerTimesTitle: 'أوقات الصلاة',
  progress: 0.68,
  hijriMonth: 5,
  prayers: [
    SharePrayerSlot(name: 'الفجر', time: '٠٥:١٢'),
    SharePrayerSlot(name: 'الظهر', time: '١٢:٤٥'),
    SharePrayerSlot(name: 'العصر', time: '١٦:١٢'),
    SharePrayerSlot(name: 'المغرب', time: '٦:٢٨ م', isNext: true),
    SharePrayerSlot(name: 'العشاء', time: '٨:٠٣ م'),
  ],
  gradient: LinearGradient(
    colors: [Color(0xffF17148), Color(0xffCF4B6D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
);

Future<void> _loadFonts() async {
  const files = [
    'Cairo-Regular.ttf',
    'Cairo-Medium.ttf',
    'Cairo-SemiBold.ttf',
    'Cairo-Bold.ttf',
  ];
  for (final file in files) {
    final loader = FontLoader('cairo')
      ..addFont(rootBundle.load('assets/fonts/$file'));
    await loader.load();
  }
}

/// يبني بطاقة المشاركة بنفس طريقة التصدير داخل [ShareController].
Widget _exportCard(ShareCardDesign design) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: SizedBox(
      width: design.exportWidth,
      height: design.exportHeight,
      child: ShareCardView(design: design, data: _data),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
    Get.addTranslations({
      'ar':
          (jsonDecode(File('assets/locales/ar.json').readAsStringSync())
                  as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, value.toString())),
    });
    Get.locale = const Locale('ar');
  });

  testWidgets('every design renders without layout errors', (tester) async {
    for (final design in ShareCardDesign.values) {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(
        design.exportWidth,
        design.exportHeight ?? 400,
      );
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(child: _exportCard(design)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'design ${design.name} must render without exceptions',
      );
      expect(find.byType(ShareCardView), findsOneWidget);
    }
  });

  testWidgets('exported image keeps the expected aspect ratio', (tester) async {
    for (final design in ShareCardDesign.values) {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(
        design.exportWidth,
        design.exportHeight ?? 400,
      );
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: _exportCard(design)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ShareCardView));
      final height = design.exportHeight;

      late ui.Image image;
      await tester.runAsync(() async {
        final bytes = await ScreenshotController().captureFromLongWidget(
          _exportCard(design),
          context: context,
          delay: const Duration(milliseconds: 20),
          pixelRatio: 3,
          constraints: height == null
              ? BoxConstraints(maxWidth: design.exportWidth)
              : BoxConstraints.tight(Size(design.exportWidth, height)),
        );
        expect(bytes, isNotEmpty);

        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        image = frame.image;
      });

      // العرض المنطقي مضروبًا في 3 = العرض الفعلي بالبكسل.
      expect(
        image.width,
        design.exportWidth * 3,
        reason: 'design ${design.name} must export at 3x its logical width',
      );
      if (design.isVertical) {
        expect(image.height, 640 * 3);
        expect(image.width / image.height, closeTo(9 / 16, 0.001));
      } else {
        expect(image.height, greaterThan(0));
        expect(image.width / image.height, greaterThan(1.4));
      }
      image.dispose();
    }
  });

  testWidgets('design picker lists every design and reports the selection', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(382, 800);
    addTearDown(tester.view.reset);

    ShareCardDesign? picked;
    await tester.pumpWidget(
      GetMaterialApp(
        locale: const Locale('ar'),
        theme: darkTheme,
        home: Scaffold(
          body: ShareDesignPicker(
            selected: ShareCardDesign.timetable,
            onSelected: (design) => picked = design,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ShareDesignChip), findsNWidgets(3));

    await tester.tap(find.byType(ShareDesignChip).last);
    await tester.pumpAndSettle();
    expect(picked, ShareCardDesign.story);
  });

  testWidgets('preview keeps every design inside the sheet bounds', (
    tester,
  ) async {
    for (final width in [320.0, 382.0, 430.0]) {
      for (final design in ShareCardDesign.values) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          GetMaterialApp(
            locale: const Locale('ar'),
            theme: darkTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: ShareCardPreview(design: design, data: _data),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'preview of ${design.name} must not overflow at $width',
        );
        expect(find.byType(ShareCardView), findsOneWidget);
      }
    }
  });
}
