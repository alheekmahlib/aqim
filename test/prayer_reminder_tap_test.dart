import 'dart:convert';
import 'dart:io';

import 'package:aqim/core/services/notifications_helper.dart';
import 'package:aqim/core/utils/helpers/app_router.dart';
import 'package:aqim/presentation/prayers/prayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late Directory storageDirectory;

  setUpAll(() async {
    storageDirectory = await Directory.systemTemp.createTemp(
      'aqim_reminder_tap_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => storageDirectory.path,
        );
    await GetStorage.init();
  });

  tearDownAll(() async {
    Get.reset();
    debugDefaultTargetPlatformOverride = null;
    await storageDirectory.delete(recursive: true);
  });

  testWidgets(
    'native reminder tap opens prayer screen without starting adhan',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      IOSFlutterLocalNotificationsPlugin.registerWith();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'initialize') return true;
        return null;
      });
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(
              name: '/',
              page: () => const Scaffold(body: Text('Home')),
            ),
            GetPage(
              name: AppRouter.prayerScreen,
              page: () =>
                  const Scaffold(body: Text('Prayer screen destination')),
            ),
          ],
        ),
      );
      await tester.runAsync(() => NotifyHelper().ensureInitialized());
      expect(Get.isRegistered<PrayersNotificationsCtrl>(), isFalse);

      tester.binding.channelBuffers.push(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('didReceiveNotificationResponse', {
            'notificationResponseType': 0,
            'id': 21100,
            'payload': jsonEncode({
              'type': 'prayer_reminder',
              'prayer': 'fajr',
              'sound_type': 'bell',
              // Even a title matching an adhan must take the reminder route.
              'title': 'Fajr'.tr,
              'fired_at': '${DateTime.now().millisecondsSinceEpoch}',
            }),
          }),
        ),
        (_) {},
      );
      await tester.pumpAndSettle();
      expect(find.text('Prayer screen destination'), findsOneWidget);
      expect(Get.currentRoute, AppRouter.prayerScreen);
      expect(Get.isRegistered<PrayersNotificationsCtrl>(), isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
