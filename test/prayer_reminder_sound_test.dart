import 'dart:convert';

import 'package:aqim/core/services/local_notifications_service.dart';
import 'package:aqim/core/services/prayer_reminder_sound.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'initialize' ? true : null;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void usePlatform(TargetPlatform platform) {
    debugDefaultTargetPlatformOverride = platform;
    switch (platform) {
      case TargetPlatform.android:
        AndroidFlutterLocalNotificationsPlugin.registerWith();
      case TargetPlatform.iOS:
        IOSFlutterLocalNotificationsPlugin.registerWith();
      case TargetPlatform.macOS:
        MacOSFlutterLocalNotificationsPlugin.registerWith();
      default:
        throw UnsupportedError('$platform');
    }
  }

  Future<Map<dynamic, dynamic>> schedule(
    Map<String, String?> payload, {
    String soundType = 'bell',
  }) async {
    await LocalNotificationsService.instance.scheduleNotification(
      id: 21100,
      title: 'Reminder',
      body: 'Prayer is approaching',
      scheduledTime: DateTime.now().add(const Duration(minutes: 10)),
      soundType: soundType,
      payload: payload,
    );
    final args =
        calls.lastWhere((c) => c.method == 'zonedSchedule').arguments
            as Map<dynamic, dynamic>;
    expect(jsonDecode(args['payload'] as String), payload);
    return args['platformSpecifics'] as Map<dynamic, dynamic>;
  }

  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.macOS,
  ]) {
    test(
      '$platform schedules the five distinct bundled reminder sounds',
      () async {
        usePlatform(platform);
        final channelIds = <String>{};
        for (final prayer in prayers) {
          final details = await schedule({
            'type': 'prayer_reminder',
            'sound_type': 'bell',
            'prayer': prayer,
          });
          if (platform == TargetPlatform.android) {
            expect(details['sound'], 'prayer_reminder_$prayer');
            expect(details['channelId'], 'prayer_reminder_${prayer}_v1');
            expect(details['playSound'], isTrue);
            expect(details['fullScreenIntent'], isFalse);
            channelIds.add(details['channelId'] as String);
            final sound = PrayerReminderSound.values.singleWhere(
              (s) => s.prayer == prayer,
            );
            expect(details['channelId'], sound.androidChannelId);
            expect(details['channelName'], sound.androidChannelName);
          } else {
            expect(
              details['sound'],
              platform == TargetPlatform.macOS
                  ? 'prayer_reminder_$prayer'
                  : 'prayer_reminder_$prayer.aiff',
            );
            expect(details['presentSound'], isTrue);
          }
        }
        if (platform == TargetPlatform.android) {
          expect(channelIds, hasLength(5));
        }
      },
    );

    test(
      '$platform preserves the bell for other and malformed notifications',
      () async {
        usePlatform(platform);
        for (final payload in <Map<String, String?>>[
          {'sound_type': 'bell'}, // Iqama and ordinary bell notifications.
          {'prayer': 'fajr'}, // A prayer name alone must not change the sound.
          {'type': 'prayer_reminder'},
          {'type': 'prayer_reminder', 'prayer': 'sunrise'},
          {'type': 'prayer_reminder', 'prayer': '../fajr'},
        ]) {
          final details = await schedule(payload);
          if (platform == TargetPlatform.android) {
            expect(details['sound'], 'notification');
            expect(
              details['channelId'],
              LocalNotificationsService.bellChannelId,
            );
          } else {
            expect(
              details['sound'],
              platform == TargetPlatform.macOS
                  ? 'notification'
                  : 'notification.aiff',
            );
          }
        }
      },
    );

    test('$platform respects silent reminders', () async {
      usePlatform(platform);
      final details = await schedule({
        'type': 'prayer_reminder',
        'prayer': 'fajr',
      }, soundType: 'silent');
      expect(details['sound'], isNull);
      expect(
        details[platform == TargetPlatform.android
            ? 'playSound'
            : 'presentSound'],
        isFalse,
      );
    });
  }
}
