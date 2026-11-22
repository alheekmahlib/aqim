// أداة توليد معاينات PNG لبطاقات المشاركة.
//
// Usage:
//   flutter test tool/share_design_preview_test.dart
//
// writes PNG files into build/share_previews/

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:aqim/core/utils/constants/svg_constants.dart';
import 'package:aqim/core/utils/helpers/app_themes.dart';
import 'package:aqim/core/widgets/container_button_widget.dart';
import 'package:aqim/presentation/prayers/prayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gap/gap.dart';

const String _outDir = 'build/share_previews';

ShareCardData _sampleData() {
  return const ShareCardData(
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
}

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

  // خط أيقونات Material (من حزمة Flutter SDK وليس من أصول المشروع)
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      '/Volumes/HawazenSSD/Applications/Flutter';
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final bytes = icons.readAsBytesSync();
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}

Future<void> _renderPreview(
  WidgetTester tester,
  ShareCardDesign design,
  String fileName, {
  required double width,
  double? height,
  double pixelRatio = 3,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height ?? 400);
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF101820),
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: width,
                height: height,
                child: ShareCardView(design: design, data: _sampleData()),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  late Uint8List bytes;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    bytes = data!.buffer.asUint8List();
    image.dispose();
  });

  final dir = Directory(_outDir);
  if (!dir.existsSync()) dir.createSync(recursive: true);
  File('$_outDir/$fileName').writeAsBytesSync(bytes);
  // ignore: avoid_print
  print('✅ $_outDir/$fileName  (${bytes.length} bytes)');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFonts);

  testWidgets('01 classic', (tester) async {
    await _renderPreview(
      tester,
      ShareCardDesign.classic,
      '01_classic.png',
      width: 400,
    );
  });

  testWidgets('02 timetable', (tester) async {
    await _renderPreview(
      tester,
      ShareCardDesign.timetable,
      '02_timetable.png',
      width: 400,
    );
  });

  testWidgets('03 story', (tester) async {
    await _renderPreview(
      tester,
      ShareCardDesign.story,
      '03_story.png',
      width: 360,
      height: 640,
      pixelRatio: 3,
    );
  });

  testWidgets('04 sheet mock', (tester) async {
    Get.addTranslations({
      'ar':
          (jsonDecode(File('assets/locales/ar.json').readAsStringSync())
                  as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, value.toString())),
    });
    Get.locale = const Locale('ar');

    const width = 382.0;
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(width, 900);
    addTearDown(tester.view.reset);

    for (final design in ShareCardDesign.values) {
      final key = GlobalKey();
      await tester.pumpWidget(
        GetMaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          theme: darkTheme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: darkTheme.colorScheme.primary,
              body: Center(
                child: RepaintBoundary(
                  key: key,
                  child: Container(
                    width: width,
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
                    decoration: BoxDecoration(
                      color: darkTheme.colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ShareDesignPicker(selected: design, onSelected: (_) {}),
                        const Gap(16),
                        ShareCardPreview(design: design, data: _sampleData()),
                        const Gap(16),
                        ContainerButtonWidget(
                          onPressed: () {},
                          height: 56,
                          borderRadius: 16,
                          backgroundColor: darkTheme.colorScheme.surface
                              .withValues(alpha: .3),
                          useGradient: false,
                          title: 'shareImage'.tr,
                          svgPath: SvgPath.svgShareShare,
                          svgHeight: 24,
                          svgColor: darkTheme.colorScheme.inversePrimary,
                          titleColor: darkTheme.colorScheme.inversePrimary,
                          fontSize: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      late Uint8List bytes;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        bytes = data!.buffer.asUint8List();
        image.dispose();
      });
      final dir = Directory(_outDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      File('$_outDir/sheet_${design.name}.png').writeAsBytesSync(bytes);
      // ignore: avoid_print
      print('✅ $_outDir/sheet_${design.name}.png  (${bytes.length} bytes)');
    }
  });
}
