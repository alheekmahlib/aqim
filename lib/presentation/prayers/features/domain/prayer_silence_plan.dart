import 'prayer_feature_preferences.dart';
import 'prayer_id.dart';

/// فترة تصميت واحدة: تبدأ عند الإقامة وتنتهي بعد المدة المحددة.
class PlannedSilencePeriod {
  const PlannedSilencePeriod({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool covers(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);
}

/// يشتق فترات التصميت من مواقيت الإقامة (أذان + إزاحة، تحسب خارجيًا
/// باستقلال عن تفعيل إشعار الإقامة)، مع احترام التخصيص والاستثناء لكل
/// صلاة، ودمج الفترات المتداخلة أو المتلاصقة حتى آخر نهاية.
class PrayerSilencePlanner {
  const PrayerSilencePlanner();

  List<PlannedSilencePeriod> plan({
    required PrayerFeaturePreferences preferences,
    required List<Map<PrayerId, DateTime?>> iqamaTimesByDay,
    required DateTime now,
  }) {
    if (!preferences.enabled) return const [];
    final periods = <PlannedSilencePeriod>[];
    for (var day = 0; day < iqamaTimesByDay.length; day++) {
      for (final prayer in PrayerId.values) {
        if (!preferences.isEnabledFor(prayer)) continue;
        final minutes = preferences.minutesFor(prayer);
        if (minutes == null) continue;
        final iqamaTime = iqamaTimesByDay[day][prayer];
        if (iqamaTime == null) continue;
        final end = iqamaTime.add(Duration(minutes: minutes));
        if (!end.isAfter(now)) continue;
        periods.add(
          PlannedSilencePeriod(
            start: iqamaTime.isBefore(now) ? now : iqamaTime,
            end: end,
          ),
        );
      }
    }
    return merge(periods);
  }

  /// دمج الفترات المتداخلة أو المتلاصقة؛ النهاية الأبقى تنتصر.
  List<PlannedSilencePeriod> merge(List<PlannedSilencePeriod> periods) {
    if (periods.length < 2) return periods;
    final sorted = [...periods]..sort((a, b) => a.start.compareTo(b.start));
    final merged = <PlannedSilencePeriod>[sorted.first];
    for (final period in sorted.skip(1)) {
      final last = merged.last;
      if (!period.start.isAfter(last.end)) {
        merged[merged.length - 1] = PlannedSilencePeriod(
          start: last.start,
          end: period.end.isAfter(last.end) ? period.end : last.end,
        );
      } else {
        merged.add(period);
      }
    }
    return merged;
  }
}
