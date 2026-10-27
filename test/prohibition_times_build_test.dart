import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:aqim/presentation/prayers/prayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// محاكاة path_provider حتى يعمل GetStorage داخل بيئة الاختبار.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

/// نسخة اختبارية تخطي دورة حياة التطبيق الثقيلة (مؤقتات وإشعارات وخدمات).
class _TestAdhanController extends AdhanController {
  @override
  Future<void> onInit() async {}

  @override
  void onClose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('almasjid_prohibition');
    addTearDown(() async => dir.delete(recursive: true));
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
  });

  PrayerTimes buildPrayerTimes() => PrayerTimes(
    Coordinates(21.4225, 39.8262),
    DateComponents.from(DateTime.now()),
    CalculationMethod.umm_al_qura.getParameters(),
  );

  testWidgets(
    'قراءة prohibitionTimesBool أثناء البناء لا تستدعي update (لا setState during build)',
    (WidgetTester tester) async {
      final controller = _TestAdhanController();
      // تصريف مؤقت GetStorage الداخلي حتى لا يبقى معلقًا عند نهاية الاختبار
      await controller.state.box.initStorage;
      controller.state.prayerTimes = buildPrayerTimes();

      // نسختان بنفس المعرف تمامًا كتكوين الشاشة (عمودي/أفقي)
      // أو أثناء انتقال المسارات حيث تتواجد نسختان حيتان من الشاشة.
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              GetBuilder<AdhanController>(
                global: false,
                init: controller,
                id: 'prohibitionTimes',
                builder: (ctrl) => Text('A:${ctrl.prohibitionTimesBool}'),
              ),
              GetBuilder<AdhanController>(
                global: false,
                init: controller,
                id: 'prohibitionTimes',
                builder: (ctrl) => Text('B:${ctrl.prohibitionTimesBool}'),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );

  test(
    'prohibitionTimesBool نقي: يعيد قيمة متسقة ويضبط الفهرس دون إشعارات',
    () {
      final controller = _TestAdhanController();
      controller.state.prayerTimes = buildPrayerTimes();

      var notified = false;
      void listener() => notified = true;
      controller.addListenerId('prohibitionTimes', listener);
      addTearDown(
        () => controller.removeListenerId('prohibitionTimes', listener),
      );

      final visible = controller.prohibitionTimesBool;

      expect(visible, isA<bool>());
      // إن كنا داخل وقت نهي فالفهرس 0-2 وإلا فهو -1
      if (visible) {
        expect(
          controller.state.prohibitionTimesIndex.value,
          inInclusiveRange(0, 2),
        );
      } else {
        expect(controller.state.prohibitionTimesIndex.value, -1);
      }
      expect(
        notified,
        isFalse,
        reason: 'الـ getter يجب ألا يستدعي update أثناء قراءته في مرحلة البناء',
      );
    },
  );
}
