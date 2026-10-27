import 'dart:convert';

import 'package:aqim/core/utils/constants/api_constants.dart';
import 'package:aqim/presentation/prayers/data/model/adhan_data.dart';
import 'package:aqim/presentation/prayers/prayers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdhanSoundsCatalog', () {
    test('uses remote entries when fetch succeeds', () async {
      final remoteJson = jsonEncode([
        {
          'index': 0,
          'adhanFileName': 'aqsa',
          'adhanLocalPath': 'resource://raw/aqsa_athan',
          'adhanName': 'aqsa',
          'urlPlayAdhan': 'aqsa_athan.m4a',
        },
        {
          'index': 6,
          'adhanFileName': 'new_reciter',
          'adhanName': 'new_reciter',
          'urlAndroidAdhan': 'android/new_athan.wav',
          'urlAndroidFajirAdhan': 'android/new_fajir_athan.wav',
          'urlIosAdhan': 'ios/new.zip',
          'urlPlayAdhan': 'new_athan.m4a',
        },
      ]);

      final entries = await AdhanSoundsCatalog.load(
        fetchRemote: () async => remoteJson,
      );

      expect(entries, hasLength(2));
      // مقرئ بعيد بلا مسار محلي: ليس مدمجاً وروابطه نسبية.
      expect(entries[0].isBundled, isTrue);
      expect(entries[1].isBundled, isFalse);
      expect(entries[1].adhanLocalPath, isNull);
      expect(entries[1].urlAndroidAdhan, 'android/new_athan.wav');
      expect(entries[1].urlAndroidFajirAdhan, 'android/new_fajir_athan.wav');
      expect(entries[1].urlIosAdhan, 'ios/new.zip');
    });

    test('falls back to bundled assets when remote fetch throws', () async {
      final entries = await AdhanSoundsCatalog.load(
        fetchRemote: () async => throw Exception('network down'),
      );

      // النسخة المدمجة: 6 مقرئين، الأقصى مدمج فقط والبقية تحميل عن بعد.
      expect(entries, hasLength(6));
      expect(entries.first.adhanFileName, 'aqsa');
      expect(entries.first.isBundled, isTrue);
      expect(entries.first.urlAndroidAdhan, isNull);
      // حزمة iOS للأقصى متاحة للتحميل التلقائي (أذان كامل أوفلاين).
      expect(entries.first.urlIosAdhan, 'ios/aqsa.zip');
      expect(entries.sublist(1).every((e) => !e.isBundled), isTrue);
      expect(entries[1].urlAndroidAdhan, 'android/saqqaf_athan.wav');
      expect(entries[1].urlIosAdhan, 'ios/saqqaf.zip');
    });

    test(
      'falls back to bundled assets when remote returns null or empty',
      () async {
        for (final remote in [null, '', '[]']) {
          final entries = await AdhanSoundsCatalog.load(
            fetchRemote: () async => remote,
          );
          expect(entries, hasLength(6), reason: 'remote="$remote"');
        }
      },
    );

    test('falls back to bundled assets on malformed remote JSON', () async {
      final entries = await AdhanSoundsCatalog.load(
        fetchRemote: () async => 'not-json{',
      );
      expect(entries, hasLength(6));
    });

    test('resolveUrl builds absolute urls per host', () async {
      const relative = 'android/saqqaf_athan.wav';

      expect(
        AdhanSoundsCatalog.resolveUrl(relative, preferGitlab: false),
        '${ApiConstants.adhanSoundsBaseGithub}/$relative',
      );
      expect(
        AdhanSoundsCatalog.resolveUrl(relative, preferGitlab: true),
        '${ApiConstants.adhanSoundsBaseGitlab}/$relative',
      );
      // الروابط المطلقة تعود كما هي.
      const absolute = 'https://example.com/x.wav';
      expect(AdhanSoundsCatalog.resolveUrl(absolute), absolute);
      expect(AdhanSoundsCatalog.resolveFallbackUrl(absolute), absolute);
    });
  });

  group('AdhanData round trip', () {
    test('preserves new fields and nulls through toJson', () async {
      final remote = AdhanData(
        index: 9,
        adhanFileName: 'remote_reciter',
        adhanLocalPath: null,
        isBundled: false,
        adhanName: 'remote_reciter',
        urlAndroidAdhan: 'android/x.wav',
        urlAndroidFajirAdhan: 'android/x_fajir.wav',
        urlIosAdhan: 'ios/x.zip',
        urlPlayAdhan: 'x.m4a',
      );

      final restored = AdhanData.fromJson(remote.toJson());
      expect(restored.isBundled, isFalse);
      expect(restored.adhanLocalPath, isNull);
      expect(restored.urlAndroidAdhan, 'android/x.wav');
      expect(restored.urlAndroidFajirAdhan, 'android/x_fajir.wav');
      expect(restored.urlIosAdhan, 'ios/x.zip');
      expect(restored.index, 9);
    });

    test(
      'reads legacy field names (urlAndroidAdhanZip/urlIosAdhanZip)',
      () async {
        final legacy = AdhanData.fromJson({
          'index': 0,
          'adhanFileName': 'aqsa',
          'adhanLocalPath': 'resource://raw/aqsa_athan',
          'adhanName': 'aqsa',
          'urlAndroidAdhanZip': 'old/aqsa.zip',
          'urlIosAdhanZip': 'old/aqsa_part.zip',
          'urlPlayAdhan': 'aqsa.m4a',
        });
        expect(legacy.isBundled, isTrue);
        expect(legacy.urlAndroidAdhan, 'old/aqsa.zip');
        expect(legacy.urlIosAdhan, 'old/aqsa_part.zip');
      },
    );
  });
}
