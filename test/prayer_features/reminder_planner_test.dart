import 'package:aqim/presentation/prayers/features/domain/prayer_feature_preferences.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_id.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_override.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_reminder_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime dayAt(int day, int hour) => DateTime(
    2026,
    10,
    29,
  ).add(Duration(days: day)).add(Duration(hours: hour));

  List<Map<PrayerId, DateTime?>> twoDays() => [
    {
      PrayerId.fajr: dayAt(0, 5),
      PrayerId.dhuhr: dayAt(0, 12),
      PrayerId.asr: dayAt(0, 15),
      PrayerId.maghrib: dayAt(0, 18),
      PrayerId.isha: dayAt(0, 20),
    },
    {
      PrayerId.fajr: dayAt(1, 5),
      PrayerId.dhuhr: dayAt(1, 12),
      PrayerId.asr: dayAt(1, 15),
      PrayerId.maghrib: dayAt(1, 18),
      PrayerId.isha: dayAt(1, 20),
    },
  ];

  test('disabled preference plans nothing', () {
    final plans = const PrayerReminderPlanner().plan(
      preferences: PrayerFeaturePreferences(enabled: false, minutes: 10),
      prayerTimesByDay: twoDays(),
      now: dayAt(0, 0),
    );
    expect(plans, isEmpty);
  });

  test('plans every prayer at adhan minus minutes and skips past moments', () {
    // الآن 04:56 بتوقيت اليوم الأول: تذكير الفجر (05:00 - 10) مضى، والباقي لا.
    final plans = const PrayerReminderPlanner().plan(
      preferences: PrayerFeaturePreferences(enabled: true, minutes: 10),
      prayerTimesByDay: twoDays(),
      now: DateTime(2026, 10, 29, 4, 56),
    );

    expect(
      plans.where((r) => r.prayer == PrayerId.fajr && r.time.day == 29),
      isEmpty,
      reason: 'today fajr reminder (04:50) is already past',
    );

    final total = plans.length;
    expect(total, 9); // 10 صلوات في يومين ناقص فجر اليوم الماضي.

    final fajrTomorrow = plans.firstWhere((r) => r.prayer == PrayerId.fajr);
    expect(
      fajrTomorrow.time,
      dayAt(1, 5).subtract(const Duration(minutes: 10)),
    );
    expect(fajrTomorrow.minutesBeforePrayer, 10);
    expect(fajrTomorrow.id, 21100 + 1 * 10 + PrayerId.fajr.index);
  });

  test('per-prayer exclusion and custom minutes are honored', () {
    final preferences = PrayerFeaturePreferences(
      enabled: true,
      minutes: 10,
      overrides: const {
        PrayerId.asr: PrayerOverride(enabled: false),
        PrayerId.maghrib: PrayerOverride(enabled: true, minutes: 25),
      },
    );
    final plans = const PrayerReminderPlanner().plan(
      preferences: preferences,
      prayerTimesByDay: twoDays(),
      now: dayAt(0, 0),
    );

    expect(plans.where((r) => r.prayer == PrayerId.asr), isEmpty);
    final maghrib = plans.firstWhere((r) => r.prayer == PrayerId.maghrib);
    expect(maghrib.minutesBeforePrayer, 25);
    expect(maghrib.time, dayAt(0, 18).subtract(const Duration(minutes: 25)));
    expect(plans.length, 8); // 10 - (عصران مستثنيان).
  });

  test('ids never collide with adhan, iqama or open-app ranges', () {
    const planner = PrayerReminderPlanner();
    final ids = planner.idsInRange(10).toSet();
    expect(ids.length, 50);
    expect(ids.first, 21100);
    expect(ids.last, 21100 + 9 * 10 + 4);
    for (final id in ids) {
      expect(
        id >= 20000 && id < 21100,
        isFalse,
        reason: 'overlap with prayer/iqama block: $id',
      );
    }
  });
}
