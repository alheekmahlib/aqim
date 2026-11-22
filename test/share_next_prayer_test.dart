import 'package:adhan/adhan.dart';
import 'package:aqim/presentation/prayers/share/share_next_prayer.dart';
import 'package:flutter_test/flutter_test.dart';

/// أوقات يوم ثابتة للاختبار.
final DateTime _day = DateTime(2026, 11, 21);

final DateTime _fajr = DateTime(2026, 11, 21, 5, 12);
final DateTime _dhuhr = DateTime(2026, 11, 21, 12, 45);
final DateTime _asr = DateTime(2026, 11, 21, 15, 58);
final DateTime _maghrib = DateTime(2026, 11, 21, 18, 20);
final DateTime _isha = DateTime(2026, 11, 21, 19, 52);

ShareNextPrayer resolveAt(DateTime now) {
  return resolveShareNextPrayer(
    now: now,
    fajr: _fajr,
    dhuhr: _dhuhr,
    asr: _asr,
    maghrib: _maghrib,
    isha: _isha,
  );
}

void main() {
  group('resolveShareNextPrayer', () {
    test('بعد العشاء تكون الصلاة القادمة هي فجر الغد', () {
      final result = resolveAt(DateTime(2026, 11, 21, 22, 0));

      expect(result.prayer, Prayer.fajr);
      expect(result.time, DateTime(2026, 11, 22, 5, 12));
      expect(result.timeLeft, const Duration(hours: 7, minutes: 12));
      expect(result.previousPrayer, Prayer.isha);
      expect(result.previousTime, _isha);
    });

    test('لا يستهدف منتصف الليل ولا الثلث الأخير بعد العشاء', () {
      final result = resolveAt(DateTime(2026, 11, 21, 23, 30));

      expect(result.prayer, Prayer.fajr);
      expect(result.timeLeft.inHours, greaterThanOrEqualTo(5));
    });

    test('قبل الفجر (بعد منتصف الليل) تكون القادمة فجر اليوم', () {
      final result = resolveAt(DateTime(2026, 11, 21, 0, 30));

      expect(result.prayer, Prayer.fajr);
      expect(result.time, _fajr);
      expect(result.timeLeft, const Duration(hours: 4, minutes: 42));
      expect(result.previousPrayer, Prayer.isha);
      expect(result.previousTime, DateTime(2026, 11, 20, 19, 52));
    });

    test('بعد الفجر مباشرة تكون القادمة الظهر (الشروق ليس صلاة واجبة)', () {
      final result = resolveAt(DateTime(2026, 11, 21, 6, 30));

      expect(result.prayer, Prayer.dhuhr);
      expect(result.time, _dhuhr);
      expect(result.previousPrayer, Prayer.fajr);
      expect(result.previousTime, _fajr);
    });

    test('بين الظهر والعصر تكون القادمة العصر', () {
      final result = resolveAt(DateTime(2026, 11, 21, 13, 30));

      expect(result.prayer, Prayer.asr);
      expect(result.time, _asr);
      expect(result.previousPrayer, Prayer.dhuhr);
    });

    test('بين العصر والمغرب تكون القادمة المغرب', () {
      final result = resolveAt(DateTime(2026, 11, 21, 16, 30));

      expect(result.prayer, Prayer.maghrib);
      expect(result.time, _maghrib);
    });

    test('بين المغرب والعشاء تكون القادمة العشاء', () {
      final result = resolveAt(DateTime(2026, 11, 21, 19, 0));

      expect(result.prayer, Prayer.isha);
      expect(result.time, _isha);
      expect(result.previousPrayer, Prayer.maghrib);
    });

    test('عند دخول وقت العشاء تنتقل البطاقة إلى فجر الغد', () {
      final result = resolveAt(_isha);

      expect(result.prayer, Prayer.fajr);
      expect(result.time, DateTime(2026, 11, 22, 5, 12));
    });

    test('نسبة التقدّم تقيس المسافة بين الصلاة السابقة والقادمة', () {
      final afterIsha = resolveAt(DateTime(2026, 11, 21, 22, 0));
      // 128 دقيقة من العشاء حتى منتصف الليل الآمن، من أصل 560 دقيقة.
      expect(afterIsha.progress, closeTo(128 / 560, 0.001));

      final beforeFajr = resolveAt(DateTime(2026, 11, 21, 0, 30));
      // 278 دقيقة من عشاء الأمس حتى الآن، من أصل 560 دقيقة.
      expect(beforeFajr.progress, closeTo(278 / 560, 0.001));

      final afterDhuhr = resolveAt(DateTime(2026, 11, 21, 13, 30));
      expect(afterDhuhr.progress, closeTo(45 / 193, 0.001));
    });

    test('أوقات قديمة (ليست لتاريخ اليوم) تُعاد على تاريخ اللحظة', () {
      final stale = resolveShareNextPrayer(
        now: DateTime(2026, 11, 21, 22, 0),
        fajr: DateTime(2026, 11, 20, 5, 12),
        dhuhr: DateTime(2026, 11, 20, 12, 45),
        asr: DateTime(2026, 11, 20, 15, 58),
        maghrib: DateTime(2026, 11, 20, 18, 20),
        isha: DateTime(2026, 11, 20, 19, 52),
      );

      expect(stale.prayer, Prayer.fajr);
      expect(stale.time, DateTime(2026, 11, 22, 5, 12));
    });

    test('الوقت المتبقي لا يكون سالبًا في أي وقت من اليوم', () {
      for (int minutes = 0; minutes < 24 * 60; minutes += 7) {
        final now = _day.add(Duration(minutes: minutes));
        final result = resolveAt(now);
        expect(result.timeLeft.isNegative, isFalse, reason: '$now');
        expect(result.progress, inInclusiveRange(0.0, 1.0), reason: '$now');
      }
    });
  });
}
