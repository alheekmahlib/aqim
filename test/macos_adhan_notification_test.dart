import 'dart:io';

import 'package:aqim/core/services/local_notifications_service.dart';
import 'package:aqim/core/utils/constants/shared_preferences_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late Directory storageDirectory;
  final calls = <MethodCall>[];

  setUpAll(() async {
    storageDirectory = await Directory.systemTemp.createTemp('aqim_mac_adhan_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => storageDirectory.path,
        );
    await GetStorage.init('AdhanSounds');
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    MacOSFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'initialize' ? true : null;
        });
  });

  tearDownAll(() async {
    debugDefaultTargetPlatformOverride = null;
    await storageDirectory.delete(recursive: true);
  });

  test('macOS schedules the selected reciter, not the ordinary bell', () async {
    const reciters = ['aqsa', 'saqqaf', 'sarihi', 'baset', 'qatami', 'salah'];
    final storage = GetStorage('AdhanSounds');
    for (var index = 0; index < reciters.length; index++) {
      await storage.write(ADHAN_SELECTED_INDEX, '$index');
      await LocalNotificationsService.instance.scheduleNotification(
        id: 20000,
        title: 'Fajr',
        body: 'Adhan',
        soundType: 'sound',
        payload: {'sound_type': 'sound'},
        scheduledTime: DateTime.now().add(const Duration(minutes: 10)),
      );
      final args =
          calls.lastWhere((c) => c.method == 'zonedSchedule').arguments as Map;
      final details = args['platformSpecifics'] as Map;
      expect(details['sound'], '${reciters[index]}_athan');
      expect(details['presentSound'], isTrue);
    }
  }, skip: !Platform.isMacOS);
}
