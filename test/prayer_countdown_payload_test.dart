import 'package:aqim/core/services/prayer_countdown_payload.dart';
import 'package:flutter_test/flutter_test.dart';

/// بناء خانات يوم واحد بأوقات اصطناعية؛ تُعاد الفهارس بترتيب
/// prayerNameList (فجر 0 .. ثلث أخير 7).
CountdownSlot _slot(int index, DateTime at) =>
    CountdownSlot(index: index, at: at);

DateTime _day(int day, int hour, [int minute = 0]) =>
    DateTime(2026, 9, day, hour, minute);

/// سيناريو نموذجي: ليلة 8/9 سبتمبر مع خانات الليل فجر اليوم التالي.
List<CountdownSlot> _typicalDays() => [
  // أمس (7 سبتمبر): الصلوات الخمس والشروق
  _slot(0, _day(7, 4, 30)), // فجر أمس
  _slot(1, _day(7, 6, 0)), // شروق أمس
  _slot(2, _day(7, 12, 10)), // ظهر أمس
  _slot(3, _day(7, 15, 40)), // عصر أمس
  _slot(4, _day(7, 18, 20)), // مغرب أمس
  _slot(5, _day(7, 19, 50)), // عشاء أمس
  _slot(6, _day(7, 23, 25)), // منتصف ليل أمس (الليل الفلكي لأمس)
  _slot(7, _day(8, 1, 35)), // ثلث أخير (بعد منتصف الليل)
  // اليوم (8 سبتمبر)
  _slot(0, _day(8, 4, 32)), // فجر اليوم
  _slot(1, _day(8, 6, 2)),
  _slot(2, _day(8, 12, 9)),
  _slot(3, _day(8, 15, 39)),
  _slot(4, _day(8, 18, 19)),
  _slot(5, _day(8, 19, 49)),
  _slot(6, _day(8, 23, 24)),
  _slot(7, _day(9, 1, 34)),
  // الغد (9 سبتمبر)
  _slot(0, _day(9, 4, 31)),
  _slot(1, _day(9, 6, 1)),
  _slot(2, _day(9, 12, 8)),
  _slot(3, _day(9, 15, 38)),
  _slot(4, _day(9, 18, 18)),
  _slot(5, _day(9, 19, 48)),
  _slot(6, _day(9, 23, 23)),
];

CountdownDisplayData _data(CountdownSlot justStarted, CountdownSlot next) =>
    CountdownDisplayData(
      nextLabel: 'التالية',
      nextName: 'ن${next.index}',
      nextTime: '12:00',
      nextAt: next.at,
      elapsedLabel: 'مضى',
      prevName: 'س${justStarted.index}',
      prevAt: justStarted.at,
    );

void main() {
  group('isPrayerSlot', () {
    test('الصلوات الخمس فقط؛ الشروق والليل ليسا صلوات', () {
      for (final i in [0, 2, 3, 4, 5]) {
        expect(isPrayerSlot(i), isTrue, reason: 'index $i صلاة');
      }
      for (final i in [1, 6, 7]) {
        expect(isPrayerSlot(i), isFalse, reason: 'index $i ليس صلاة');
      }
    });
  });

  group('normalizeSlots', () {
    test('يرتب الخانات زمنيًا ويدمج المتطابقات', () {
      final slots = normalizeSlots([
        _slot(2, _day(8, 12)),
        _slot(0, _day(8, 4)),
        _slot(1, _day(8, 6)),
        _slot(3, _day(8, 12)), // نفس لحظة الظهر — يبقى الأخير
      ]);
      expect(slots.map((s) => s.index), [0, 1, 3]);
    });
  });

  group('computeCountdownSnapshot', () {
    test('ظهيرة عادية: القادم العصر والسابق الظهر والمنقضي دقيقتان', () {
      final snapshot = computeCountdownSnapshot(
        slots: normalizeSlots(_typicalDays()),
        now: _day(8, 12, 11),
      );
      expect(snapshot.next?.index, 3); // العصر
      expect(snapshot.prev?.index, 2); // الظهر
      expect(snapshot.elapsed.inMinutes, 2);
    });

    test('قبل الفجر فجرًا: السابق ثلث الليل الأخير والقادم فجر اليوم', () {
      final snapshot = computeCountdownSnapshot(
        slots: normalizeSlots(_typicalDays()),
        now: _day(8, 2),
      );
      expect(snapshot.prev?.index, 7); // ثلث الليل الأخير
      expect(snapshot.next?.index, 0); // فجر اليوم
      expect(snapshot.next?.at.day, 8);
      expect(snapshot.elapsed.inHours, closeTo(0, 1));
    });

    test('بعد العشاء: القادم منتصف الليل والسابق العشاء', () {
      final snapshot = computeCountdownSnapshot(
        slots: normalizeSlots(_typicalDays()),
        now: _day(8, 21),
      );
      expect(snapshot.next?.index, 6); // منتصف الليل
      expect(snapshot.prev?.index, 5); // العشاء
    });

    test('لحظة الحدّ بعينها تُحتسب سابقة لا قادمة', () {
      final snapshot = computeCountdownSnapshot(
        slots: normalizeSlots(_typicalDays()),
        now: _day(8, 15, 39),
      );
      expect(snapshot.prev?.index, 3); // العصر نفسه
      expect(snapshot.next?.index, 4); // المغرب
      expect(snapshot.elapsed, Duration.zero);
    });

    test('قائمة فارغة: لقطة بلا خانات', () {
      final snapshot = computeCountdownSnapshot(
        slots: const [],
        now: _day(8, 12),
      );
      expect(snapshot.next, isNull);
      expect(snapshot.prev, isNull);
      expect(snapshot.elapsed, Duration.zero);
    });
  });

  group('buildBoundaryEntries', () {
    test('يبني حدًا لكل خانة قادمة ولها تالية، ببيانات العرض المهيكلة', () {
      final slots = normalizeSlots(_typicalDays());
      final entries = buildBoundaryEntries(
        slots: slots,
        now: _day(8, 8),
        buildData: _data,
      );

      // أول خانة قادمة بعد 8 صباحًا: الظهر (2)؛ حدودها حتى ما قبل الأخير.
      expect(entries.first.at, _day(8, 12, 9));
      // بيانات الحدّ: «التي بدأت» الظهر والقادمة العصر.
      expect(entries.first.data.prevName, 'س2');
      expect(entries.first.data.nextName, 'ن3');
      expect(entries.first.data.nextAt, _day(8, 15, 39));
      expect(entries.first.data.prevAt, _day(8, 12, 9));

      // آخر خانة (منتصف ليل الغد) لا حدّ لها — لا تالية لها في النافذة.
      expect(entries.last.at, _day(9, 19, 48));
      expect(entries.any((e) => e.at == _day(9, 23, 23)), isFalse);
    });

    test('toMap يحمل لحظة الحدّ وكل حقول العرض', () {
      final slots = normalizeSlots([
        _slot(0, _day(8, 4, 30)),
        _slot(1, _day(8, 6)),
      ]);
      final entries = buildBoundaryEntries(
        slots: slots,
        now: _day(8, 3),
        buildData: _data,
      );
      expect(entries, hasLength(1));
      final map = entries.first.toMap();
      expect(map['at'], _day(8, 4, 30).millisecondsSinceEpoch);
      expect(map['nextLabel'], 'التالية');
      expect(map['nextName'], 'ن1');
      expect(map['nextTime'], '12:00');
      expect(map['nextAt'], _day(8, 6).millisecondsSinceEpoch);
      expect(map['elapsedLabel'], 'مضى');
      expect(map['prevName'], 'س0');
      expect(map['prevAt'], _day(8, 4, 30).millisecondsSinceEpoch);
    });
  });
}
