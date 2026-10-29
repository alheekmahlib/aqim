import 'dart:io';

import 'package:aqim/core/services/local_notifications_service.dart';
import 'package:aqim/core/utils/constants/shared_preferences_constants.dart';
import 'package:aqim/presentation/prayers/features/data/custom_adhan_selector.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_reminder_plan.dart';
import 'package:aqim/presentation/prayers/features/domain/local_adhan_audio.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature_settings.dart';
import 'package:aqim/presentation/prayers/features/domain/save_prayer_feature_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'fake_prayer_feature_capabilities.dart';
import 'fake_prayer_feature_repository.dart';

/// اختبارات تفاعل مميزات الصلاة (المرحلة السادسة): مساحات المعرفات،
/// التفعيل المشترك، وسلوك فقدان ملف المؤذن المخصص داخل جدولة مستقبلية.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory suiteDir;

  setUpAll(() async {
    suiteDir = await Directory.systemTemp.createTemp('aqim_integration_');
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => suiteDir.path);
  });

  test('notification id spaces stay disjoint across every feature', () {
    const planner = PrayerReminderPlanner();
    final reminderIds = planner.idsInRange(30).toSet();

    // الأذان والإقامة: كتلة اليوم 20000+day*10 وخانات 0-9.
    final prayerAndIqamaIds = <int>{
      for (var day = 0; day < 30; day++)
        for (var slot = 0; slot < 10; slot++) 20000 + day * 10 + slot,
    };
    // تذكير فتح التطبيق.
    const openAppIds = {21000, 21001, 21002, 21003, 21004};
    // رمضان (سحور/إفطار).
    const ramadanIds = {1000, 1001};

    expect(reminderIds.intersection(prayerAndIqamaIds), isEmpty);
    expect(reminderIds.intersection(openAppIds), isEmpty);
    expect(reminderIds.intersection(ramadanIds), isEmpty);
    expect(reminderIds.first, greaterThanOrEqualTo(21100));
  });

  test(
    'saving all features enabled passes validation and persists together',
    () async {
      final repo = FakePrayerFeatureRepository();
      final caps = FakePrayerFeatureCapabilities();
      final save = SavePrayerFeatureSettings(repo, caps);

      var settings = PrayerFeatureSettings();
      for (final feature in PrayerFeature.values) {
        settings = settings.withPreference(
          feature,
          settings[feature].copyWith(enabled: true),
        );
      }
      await save(settings);

      expect(repo.saves, 1);
      for (final feature in PrayerFeature.values) {
        expect(repo.stored[feature].enabled, isTrue, reason: feature.name);
      }
    },
  );

  test(
    'losing the selected custom muezzin file falls back to the default sound '
    'at scheduling time',
    () async {
      final adhanSounds = GetStorage('AdhanSounds', suiteDir.path);
      await adhanSounds.initStorage;
      final preferences = GetStorage('aqim_integration_prefs', suiteDir.path);
      await preferences.initStorage;

      await adhanSounds.write(ADHAN_SELECTED_INDEX, '3');
      final selector = CustomAdhanSelector(
        adhanSounds: adhanSounds,
        preferences: preferences,
      );
      // اختيار ملف دائم غير موجود فعليًا (حذف داخل جدولة مستقبلية).
      await selector.select(
        const LocalAdhanAudio(
          id: 'missing',
          name: 'مؤذن مفقود',
          duration: Duration(minutes: 2),
          audioPath: '/nonexistent/custom_missing.mp3',
        ),
      );

      // الجدولة ترجع null فيقع التشغيل للمورد المدمج الافتراضي.
      expect(selector.hasActiveAudio(), isFalse);
      expect(
        LocalNotificationsService.selectedAdhanAudioPath(),
        isNull,
        reason: 'missing durable file must not be scheduled',
      );
    },
  );
}
