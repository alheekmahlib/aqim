import 'dart:io';

import 'package:aqim/core/utils/constants/shared_preferences_constants.dart';
import 'package:aqim/presentation/prayers/features/data/custom_adhan_selector.dart';
import 'package:aqim/presentation/prayers/features/domain/local_adhan_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  late Directory suiteDir;
  late GetStorage adhanSounds;
  late GetStorage preferences;
  late CustomAdhanSelector selector;
  late LocalAdhanAudio audio;

  // mock يبقى طوال المجموعة: تدفقات GetStorage المؤجلة تكتب بعد انتهاء
  // الاختبار الفردي فلا يصح إزالته في tearDown لكل اختبار.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    suiteDir = await Directory.systemTemp.createTemp(
      'aqim_custom_adhan_selector_',
    );
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => suiteDir.path);
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    adhanSounds = GetStorage('selectorAdhanTest$stamp', suiteDir.path);
    preferences = GetStorage('selectorPrefsTest$stamp', suiteDir.path);
    await adhanSounds.initStorage;
    await preferences.initStorage;
    selector = CustomAdhanSelector(
      adhanSounds: adhanSounds,
      preferences: preferences,
    );
    audio = const LocalAdhanAudio(
      id: '42',
      name: 'مؤذن',
      duration: Duration(minutes: 2),
      audioPath: '/tmp/custom_42.mp3',
      notificationSoundPath: '/tmp/Library/Sounds/custom_42.wav',
    );
  });

  test(
    'select writes standard keys, segments and records last standard',
    () async {
      await adhanSounds.write(ADHAN_SELECTED_INDEX, '3');
      await selector.select(audio);

      expect(
        adhanSounds.read(ADHAN_SELECTED_INDEX),
        '${CustomAdhanSelector.customIndex}',
      );
      expect(adhanSounds.read(ADHAN_PATH), audio.audioPath);
      expect(adhanSounds.read(ADHAN_PATH_FAJIR), audio.audioPath);
      expect(
        adhanSounds.read('${CustomAdhanSelector.customIndex}$ADHAN_PATH_AUDIO'),
        audio.audioPath,
      );
      expect(
        adhanSounds.read(
          '${CustomAdhanSelector.customIndex}$ADHAN_PATH_SEGMENT_AUDIO',
        ),
        audio.notificationSoundPath,
      );
      expect(preferences.read(CustomAdhanSelector.activeIdKey), '42');
      // آخر مؤذن قياسي (فهرس 3) وُثّق للعودة.
      expect(selector.lastStandardIndex, 3);
      expect(selector.hasActiveAudio(), isFalse); // الملف غير موجود فعليًا.
    },
  );

  test('clearActive removes custom traces only', () async {
    await selector.select(audio);
    await selector.clearActive();

    expect(selector.activeAudioId, isNull);
    expect(
      adhanSounds.read('${CustomAdhanSelector.customIndex}$ADHAN_PATH_AUDIO'),
      isNull,
    );
    expect(
      adhanSounds.read(
        '${CustomAdhanSelector.customIndex}$ADHAN_PATH_SEGMENT_AUDIO',
      ),
      isNull,
    );
    // المفاتيح العامة لا تُمسح؛ إعادتها مسؤولية العودة للقياسي.
    expect(adhanSounds.read(ADHAN_PATH), audio.audioPath);
  });
}
