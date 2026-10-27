import 'dart:io';

import 'package:aqim/core/services/location/locations.dart';
import 'package:aqim/core/utils/constants/shared_preferences_constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// الـ getter ‏LocationHelper.currentLocation كان يرمي
/// "Null check operator used on a null value" عندما لا يوجد موقع مخزّن
/// (الـ setter لا يُستدعى أبدًا فكان _currentLocation! دائمًا null).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    final dir = await Directory.systemTemp.createTemp('almasjid_loc_helper');
    addTearDown(() async => dir.delete(recursive: true));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => dir.path,
        );

    await GetStorage.init();
    await GetStorage().remove(CURRENT_LOCATION);
  });

  test('يعيد الإحداثيات المخزونة من CURRENT_LOCATION', () async {
    await GetStorage().write(CURRENT_LOCATION, {
      'latitude': 21.4225,
      'longitude': 39.8262,
    });

    final loc = LocationHelper.instance.currentLocation;

    expect(loc, isNotNull);
    expect(loc!.latitude, closeTo(21.4225, 1e-9));
    expect(loc.longitude, closeTo(39.8262, 1e-9));
  });

  test('يعيد null بدل الرمي عند غياب الموقع المخزون', () {
    // قبل الإصلاح: Null check operator used on a null value
    expect(LocationHelper.instance.currentLocation, isNull);
  });
}
