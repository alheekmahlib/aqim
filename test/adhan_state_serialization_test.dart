import 'dart:io';

import 'package:aqim/presentation/prayers/prayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// AdhanState.toJson كان يقرأ حقول late غير مهيأة (coordinates/params)
/// عندما تُستدعى قبل تحميل بيانات الصلاة → LateInitializationError.
/// الإصلاح: حارس في المقدمة يعيد map فارغة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    final dir = await Directory.systemTemp.createTemp('almasjid_state_ser');
    addTearDown(() async => dir.delete(recursive: true));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => dir.path,
        );

    await GetStorage.init();
  });

  test('toJson على حالة غير مهيأة يعيد map فارغة ولا يرمي', () async {
    final state = AdhanState();
    await state.box.initStorage;

    final json = state.toJson();

    expect(json, isEmpty);
  });
}
