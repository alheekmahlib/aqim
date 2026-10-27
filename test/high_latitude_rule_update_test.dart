import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:aqim/core/utils/constants/shared_preferences_constants.dart';
import 'package:aqim/presentation/prayers/prayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// getHighLatitudeRule كان يغيّر أعلام RxBool ويكتب في التخزين دون
/// update(['init_athan'])، فلا يُعاد بناء GetBuilder(id: 'init_athan')
/// في شيت الإعدادات وتبقى المفاتيح بحالتها القديمة حتى إغلاق الشيت.
/// كما لم يكن يزامن highLatitudeRuleIndex فتعيده أي إعادة حساب لاحقة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    final dir = await Directory.systemTemp.createTemp('almasjid_hlr');
    addTearDown(() async => dir.delete(recursive: true));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => dir.path,
        );

    await GetStorage.init();
    // GetStorage يبقي الحاوية في الذاكرة بين اختبارات العملية نفسها
    await GetStorage().erase();
  });

  test('اختيار قاعدة ينبّه init_athan ويزامن الفهرس والتخزين', () async {
    final controller = AdhanController();
    var notified = 0;
    controller.addListenerId('init_athan', () => notified++);

    final rule = await controller.getHighLatitudeRule(1);

    expect(rule, HighLatitudeRule.seventh_of_the_night);
    expect(notified, 1);
    expect(controller.state.middleOfTheNight.value, isFalse);
    expect(controller.state.seventhOfTheNight.value, isTrue);
    expect(controller.state.twilightAngle.value, isFalse);
    expect(controller.state.highLatitudeRuleIndex.value, 1);
    expect(controller.state.box.read(HIGH_LATITUDE_RULE), 1);
  });

  test('فهرس غير صالح لا يغيّر الأعلام ولا ينبّه الواجهة', () async {
    final controller = AdhanController();
    var notified = 0;
    controller.addListenerId('init_athan', () => notified++);

    final rule = await controller.getHighLatitudeRule(99);

    expect(rule, HighLatitudeRule.middle_of_the_night);
    expect(notified, 0);
    expect(controller.state.middleOfTheNight.value, isTrue);
    expect(controller.state.box.read(HIGH_LATITUDE_RULE), isNull);
  });
}
