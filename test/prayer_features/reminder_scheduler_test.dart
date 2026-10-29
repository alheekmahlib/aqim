import 'dart:ui' show Locale;

import 'package:aqim/presentation/prayers/features/data/local_prayer_reminder_scheduler.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature_preferences.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_id.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_reminder_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'feature_test_translations.dart';

class _RecordingSchedulerDeps {
  _RecordingSchedulerDeps({
    this.days = 1,
    this.maxDays = 1,
    this.day0 = const {},
  });

  final int days;
  final int maxDays;
  final Map<PrayerId, DateTime> day0;

  final scheduledIds = <int>[];
  final scheduledPayloads = <Map<String, String?>>[];
  final cancelledIds = <int>[];

  LocalPrayerReminderScheduler build() => LocalPrayerReminderScheduler(
    prayerTimeFor: (prayer, dayOffset) => dayOffset == 0 ? day0[prayer] : null,
    daysToSchedule: () => days,
    maxDaysToCancel: () => maxDays,
    // وقت ثابت قبل مواقيت اليوم الاختبارية بفارق كافٍ.
    now: () => DateTime(2026, 10, 29, 0),
    schedule:
        ({
          required id,
          required time,
          required title,
          required summary,
          required body,
          required payload,
        }) async {
          scheduledIds.add(id);
          scheduledPayloads.add(payload);
        },
    cancel: (id) async => cancelledIds.add(id),
  );
}

void main() {
  setUpAll(() async {
    Get.addTranslations(FeatureTestTranslations().keys);
    Get.updateLocale(const Locale('en'));
  });

  final day0 = {
    PrayerId.fajr: DateTime(2026, 10, 29, 5),
    PrayerId.dhuhr: DateTime(2026, 10, 29, 12),
    PrayerId.asr: DateTime(2026, 10, 29, 15),
    PrayerId.maghrib: DateTime(2026, 10, 29, 18),
    PrayerId.isha: DateTime(2026, 10, 29, 20),
  };

  test(
    'synchronize schedules bell notifications typed prayer_reminder',
    () async {
      final deps = _RecordingSchedulerDeps(day0: day0, days: 1, maxDays: 1);
      await deps.build().synchronize(
        PrayerFeaturePreferences(enabled: true, minutes: 10),
      );

      expect(deps.scheduledIds, hasLength(5));
      // يبدأ بالتنظيف الكامل لنطاقه ثم الجدولة.
      expect(
        deps.cancelledIds,
        const PrayerReminderPlanner().idsInRange(1).toList(),
      );
      for (final payload in deps.scheduledPayloads) {
        expect(payload['type'], 'prayer_reminder');
        expect(payload['sound_type'], 'bell');
        expect(payload['prayer'], isNotNull);
      }
    },
  );

  test('disabled preference only cancels existing reminders', () async {
    final deps = _RecordingSchedulerDeps(day0: day0, days: 1, maxDays: 1);
    await deps.build().synchronize(
      PrayerFeaturePreferences(enabled: false, minutes: 10),
    );

    expect(deps.scheduledIds, isEmpty);
    expect(deps.cancelledIds, isNotEmpty);
  });

  test('reminder ids stay clear of the prayer notification blocks', () async {
    final deps = _RecordingSchedulerDeps(day0: day0, days: 1, maxDays: 1);
    await deps.build().synchronize(
      PrayerFeaturePreferences(enabled: true, minutes: 10),
    );
    for (final id in deps.scheduledIds) {
      expect(
        id < 20000 || id >= 21100,
        isTrue,
        reason: 'reminder id leaked into legacy range: $id',
      );
    }
  });
}
