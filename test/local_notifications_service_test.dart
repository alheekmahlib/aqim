import 'dart:convert';

import 'package:aqim/core/services/local_notifications_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalNotificationsService payload codec', () {
    test('round-trips a typical prayer payload', () {
      const payload = {
        'sound_type': 'sound',
        'title': 'Fajr',
        'summary': 'حان الآن موعد صلاة الفجر',
        'fired_at': '1765432100000',
      };

      final encoded = LocalNotificationsService.encodePayload(payload);
      expect(encoded, isNotNull);

      final decoded = LocalNotificationsService.decodePayload(encoded);
      expect(decoded, equals(payload));
    });

    test('returns null for empty payload', () {
      expect(LocalNotificationsService.encodePayload(const {}), isNull);
    });

    test('returns empty map for null or empty input', () {
      expect(LocalNotificationsService.decodePayload(null), isEmpty);
      expect(LocalNotificationsService.decodePayload(''), isEmpty);
    });

    test('returns empty map for malformed JSON instead of throwing', () {
      expect(LocalNotificationsService.decodePayload('not-json{'), isEmpty);
      // JSON صالح لكن ليس كائناً (قائمة مثلاً)
      expect(
        LocalNotificationsService.decodePayload(jsonEncode(['a', 'b'])),
        isEmpty,
      );
    });

    test('coerces non-string values to strings', () {
      final encoded = jsonEncode({'sound_type': 'bell', 'count': 3});
      final decoded = LocalNotificationsService.decodePayload(encoded);
      expect(decoded['count'], equals('3'));
    });
  });

  group('resolveDarwinAdhanSoundName', () {
    test('iOS keeps the downloaded segment name with extension', () {
      expect(
        LocalNotificationsService.resolveDarwinAdhanSoundName(
          isMacOS: false,
          downloadedSegmentName: 'saqqaf_athan.aiff',
        ),
        equals('saqqaf_athan.aiff'),
      );
    });

    test('iOS falls back to bundled aqsa segment with extension', () {
      expect(
        LocalNotificationsService.resolveDarwinAdhanSoundName(
          isMacOS: false,
          downloadedSegmentName: null,
        ),
        equals('aqsa_athan.aiff'),
      );
    });

    test('macOS strips the extension from a downloaded segment', () {
      expect(
        LocalNotificationsService.resolveDarwinAdhanSoundName(
          isMacOS: true,
          downloadedSegmentName: 'qatami_athan.aiff',
        ),
        equals('qatami_athan'),
      );
    });

    test('macOS falls back to bundled aqsa without extension', () {
      expect(
        LocalNotificationsService.resolveDarwinAdhanSoundName(
          isMacOS: true,
          downloadedSegmentName: null,
        ),
        equals('aqsa_athan'),
      );
    });

    test('macOS strips .aif and .caf variants too', () {
      expect(
        LocalNotificationsService.stripDarwinSoundExtension(
          'baset_athan.aif',
          isMacOS: true,
        ),
        equals('baset_athan'),
      );
      expect(
        LocalNotificationsService.stripDarwinSoundExtension(
          'salah_athan.caf',
          isMacOS: true,
        ),
        equals('salah_athan'),
      );
    });

    test('macOS leaves names without a known audio extension untouched', () {
      expect(
        LocalNotificationsService.stripDarwinSoundExtension(
          'notification',
          isMacOS: true,
        ),
        equals('notification'),
      );
      // امتدادات غير صوتية لا تُجرَّد (تجنب العبث بأسماء غير متوقعة).
      expect(
        LocalNotificationsService.stripDarwinSoundExtension(
          'tone.mp3',
          isMacOS: true,
        ),
        equals('tone.mp3'),
      );
    });
  });

  group('macBundledReciterSoundFile', () {
    test('resolves by catalog index', () {
      expect(
        LocalNotificationsService.macBundledReciterSoundFile(
          selectedIndex: '1',
        ),
        equals('saqqaf_athan.aiff'),
      );
      expect(
        LocalNotificationsService.macBundledReciterSoundFile(
          selectedIndex: '4',
        ),
        equals('qatami_athan.aiff'),
      );
    });

    test('falls back to legacy path index then stored path', () {
      expect(
        LocalNotificationsService.macBundledReciterSoundFile(
          legacyPathIndex: '2',
        ),
        equals('sarihi_athan.aiff'),
      );
      expect(
        LocalNotificationsService.macBundledReciterSoundFile(
          storedPath: 'resource://raw/baset_athan',
        ),
        equals('baset_athan.aiff'),
      );
      // المسار المخزّن بعد التنزيل يحمل اسم المقرئ (m4a كامل).
      expect(
        LocalNotificationsService.macBundledReciterSoundFile(
          storedPath: '/somewhere/Group Containers/x/Sounds/salah_athan.m4a',
        ),
        equals('salah_athan.aiff'),
      );
    });

    test('defaults to aqsa on missing or out-of-range input', () {
      expect(
        LocalNotificationsService.macBundledReciterSoundFile(),
        equals('aqsa_athan.aiff'),
      );
      expect(
        LocalNotificationsService.macBundledReciterSoundFile(
          selectedIndex: '9',
          storedPath: null,
        ),
        equals('aqsa_athan.aiff'),
      );
      expect(
        LocalNotificationsService.macBundledReciterSoundFile(
          selectedIndex: 'garbage',
          storedPath: 'nothing-here',
        ),
        equals('aqsa_athan.aiff'),
      );
    });
  });
}
