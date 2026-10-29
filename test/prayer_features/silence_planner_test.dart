import 'package:aqim/presentation/prayers/features/domain/prayer_feature_preferences.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_id.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_override.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_silence_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime at(int day, int hour) =>
      DateTime(2026, 10, 29).add(Duration(days: day, hours: hour));

  // مواقيد يومين نمطية: فجر/ظهر/عصر/مغرب/عشاء.
  Map<PrayerId, DateTime?> typicalDay(int day) => {
    PrayerId.fajr: at(day, 5),
    PrayerId.dhuhr: at(day, 12),
    PrayerId.asr: at(day, 15),
    PrayerId.maghrib: at(day, 18),
    PrayerId.isha: at(day, 20),
  };

  test('disabled preference plans nothing', () {
    final periods = const PrayerSilencePlanner().plan(
      preferences: PrayerFeaturePreferences(enabled: false, minutes: 20),
      iqamaTimesByDay: [typicalDay(0)],
      now: at(0, 0),
    );
    expect(periods, isEmpty);
  });

  test('periods start at iqama and end after the configured minutes', () {
    final periods = const PrayerSilencePlanner().plan(
      preferences: PrayerFeaturePreferences(enabled: true, minutes: 20),
      iqamaTimesByDay: [typicalDay(0)],
      now: at(0, 0),
    );
    expect(periods, hasLength(5));
    expect(periods.first.start, at(0, 5));
    expect(periods.first.end, at(0, 5).add(const Duration(minutes: 20)));
    expect(periods.last.start, at(0, 20));
  });

  test('touching periods merge keeping the latest end', () {
    // مغرب 18:00 + 120 دقيقة = 20:00 لحظة إقامة العشاء → ملاصقة: دمج.
    final periods = const PrayerSilencePlanner().plan(
      preferences: PrayerFeaturePreferences(enabled: true, minutes: 120),
      iqamaTimesByDay: [typicalDay(0)],
      now: at(0, 0),
    );
    // فجر 05→07، ظهر 12→14، عصر 15→17 (تتداخل مع 14؟ لا: 15>14) —
    // مغرب+عشاء مدموجان 18→22.
    expect(periods, hasLength(4));
    final merged = periods.last;
    expect(merged.start, at(0, 18));
    expect(merged.end, at(0, 22));
  });

  test('cross-day overlap merges into one period ending next day', () {
    // عشاء اليوم بمدة 540 دقيقة (تخصيص) → 05:00 غدًا == إقامة فجر الغد؛
    // فجر الغد بمدة 20 دقيقة يلاصق نهايته فيندمجان حتى 05:20.
    final periods = const PrayerSilencePlanner().plan(
      preferences: PrayerFeaturePreferences(
        enabled: true,
        minutes: 20,
        overrides: const {PrayerId.isha: PrayerOverride(minutes: 540)},
      ),
      // اليوم الثاني يقتصر على الفجر ليختبر الدمج العابر لحد اليوم.
      iqamaTimesByDay: [
        typicalDay(0),
        {PrayerId.fajr: at(1, 5)},
      ],
      now: at(0, 0),
    );
    expect(periods, hasLength(5));
    final mergedIsha = periods.last;
    expect(mergedIsha.start, at(0, 20));
    expect(mergedIsha.end, at(1, 5).add(const Duration(minutes: 20)));
  });

  test('excluded prayers and past periods are skipped', () {
    final periods = const PrayerSilencePlanner().plan(
      preferences: PrayerFeaturePreferences(
        enabled: true,
        minutes: 20,
        overrides: const {PrayerId.asr: PrayerOverride(enabled: false)},
      ),
      iqamaTimesByDay: [typicalDay(0)],
      now: at(0, 16), // بعد الفجر والظهر وبعد العصر المستثنى.
    );
    expect(periods, hasLength(2)); // المغرب والعشاء فقط.
    expect(periods.first.start, at(0, 18));
  });

  test('per-prayer duration override wins over the global minutes', () {
    final periods = const PrayerSilencePlanner().plan(
      preferences: PrayerFeaturePreferences(
        enabled: true,
        minutes: 20,
        overrides: const {PrayerId.maghrib: PrayerOverride(minutes: 45)},
      ),
      iqamaTimesByDay: [typicalDay(0)],
      now: at(0, 0),
    );
    final maghrib = periods.firstWhere((p) => p.start == at(0, 18));
    expect(maghrib.end, at(0, 18).add(const Duration(minutes: 45)));
  });

  test('period already running keeps its end though start passed', () {
    final periods = const PrayerSilencePlanner().plan(
      preferences: PrayerFeaturePreferences(enabled: true, minutes: 60),
      iqamaTimesByDay: [typicalDay(0)],
      now: at(0, 20), // لحظة إقامة العشاء.
    );
    final isha = periods.single;
    expect(isha.start, at(0, 20));
    expect(isha.end, at(0, 21));
  });
}
