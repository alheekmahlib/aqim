import 'package:adhan/adhan.dart';

/// نتيجة تحديد الصلاة الواجبة القادمة لبطاقة المشاركة.
///
/// The outcome of resolving the next obligatory prayer for the share card.
///
/// هذه النتيجة مستقلة تمامًا عن `getTimeLeftForNextPrayer` في وحدة الأدان:
/// فهي تتخطّى منتصف الليل والثلث الأخير (وكذلك الشروق) لأن بطاقة المشاركة
/// تتحدث عن الصلوات الواجبة فقط.
class ShareNextPrayer {
  /// الصلاة الواجبة القادمة (فجر، ظهر، عصر، مغرب، عشاء).
  final Prayer prayer;

  /// موعد الصلاة القادمة (قد يكون في الغد بعد العشاء).
  final DateTime time;

  /// الصلاة الواجبة التي سبقت القادمة.
  final Prayer previousPrayer;

  /// موعد الصلاة السابقة.
  final DateTime previousTime;

  /// الوقت المتبقي حتى الصلاة القادمة.
  final Duration timeLeft;

  /// نسبة الوقت المنقضي بين الصلاة السابقة والقادمة (0..1).
  final double progress;

  const ShareNextPrayer({
    required this.prayer,
    required this.time,
    required this.previousPrayer,
    required this.previousTime,
    required this.timeLeft,
    required this.progress,
  });
}

/// يحسب الصلاة الواجبة القادمة (الفجر، الظهر، العصر، المغرب، العشاء) والوقت
/// المتبقي لها، اعتمادًا على أوقات اليوم والوقت الحالي.
///
/// Resolves the next obligatory prayer and the time left until it.
///
/// ملاحظات:
/// - بعد العشاء تكون الصلاة القادمة هي **فجر الغد** ( rollover ل يوم كامل).
/// - قبل الفجر (بعد منتصف الليل) تكون الصلاة القادمة هي **فجر اليوم**.
/// - تُعاد أوقات اليوم على تاريخ اللحظة الحالية حتى لا تتأثر النتيجة بتقادم
///   الأوقات المحسوبة في اليوم السابق.
ShareNextPrayer resolveShareNextPrayer({
  required DateTime now,
  required DateTime fajr,
  required DateTime dhuhr,
  required DateTime asr,
  required DateTime maghrib,
  required DateTime isha,
}) {
  DateTime onToday(DateTime time) =>
      DateTime(now.year, now.month, now.day, time.hour, time.minute);

  final List<({Prayer prayer, DateTime time})> slots =
      <({Prayer prayer, DateTime time})>[
        (prayer: Prayer.fajr, time: onToday(fajr)),
        (prayer: Prayer.dhuhr, time: onToday(dhuhr)),
        (prayer: Prayer.asr, time: onToday(asr)),
        (prayer: Prayer.maghrib, time: onToday(maghrib)),
        (prayer: Prayer.isha, time: onToday(isha)),
      ];

  int nextIndex = -1;
  for (int i = 0; i < slots.length; i++) {
    if (slots[i].time.isAfter(now)) {
      nextIndex = i;
      break;
    }
  }

  Prayer nextPrayer;
  DateTime nextTime;
  Prayer previousPrayer;
  DateTime previousTime;

  if (nextIndex == -1) {
    // بعد العشاء: القادمة هي فجر الغد، والسابقة هي عشاء اليوم.
    nextPrayer = Prayer.fajr;
    nextTime = slots.first.time.add(const Duration(days: 1));
    previousPrayer = Prayer.isha;
    previousTime = slots.last.time;
  } else if (nextIndex == 0) {
    // قبل فجر اليوم: القادمة هي فجر اليوم، والسابقة هي عشاء الأمس.
    nextPrayer = Prayer.fajr;
    nextTime = slots.first.time;
    previousPrayer = Prayer.isha;
    previousTime = slots.last.time.subtract(const Duration(days: 1));
  } else {
    nextPrayer = slots[nextIndex].prayer;
    nextTime = slots[nextIndex].time;
    previousPrayer = slots[nextIndex - 1].prayer;
    previousTime = slots[nextIndex - 1].time;
  }

  final int intervalMinutes = nextTime.difference(previousTime).inMinutes;
  final int elapsedMinutes = now.difference(previousTime).inMinutes;
  final double progress = intervalMinutes <= 0
      ? 0
      : (elapsedMinutes / intervalMinutes).clamp(0.0, 1.0);

  return ShareNextPrayer(
    prayer: nextPrayer,
    time: nextTime,
    previousPrayer: previousPrayer,
    previousTime: previousTime,
    timeLeft: nextTime.difference(now),
    progress: progress,
  );
}
