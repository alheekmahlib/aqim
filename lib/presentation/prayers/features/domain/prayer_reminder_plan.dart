import 'prayer_feature_preferences.dart';
import 'prayer_id.dart';

/// تذكير واحد مخطَّط قبل الصلاة؛ معرفه مستقل عن معرفات الأذان والإقامة.
class PlannedPrayerReminder {
  const PlannedPrayerReminder({
    required this.prayer,
    required this.id,
    required this.time,
    required this.minutesBeforePrayer,
  });

  final PrayerId prayer;
  final int id;
  final DateTime time;
  final int minutesBeforePrayer;
}

/// يشتق تذكيرات ما قبل الصلاة من مواقيت الأيام القادمة:
/// معرفات ثابتة (baseId + day*stride + فهرس الصلاة)، وتجاوز للمواعيد
/// الماضية، واحترام التخصيص والاستثناء لكل صلاة على حدة.
class PrayerReminderPlanner {
  const PrayerReminderPlanner({this.baseId = 21100, this.dayStride = 10});

  /// نطاق معرفات التذكير 21100 فأعلى؛ لا تصادم مع الأذان (20000-20299)
  /// ولا الإقامة ولا تذكير فتح التطبيق (21000-21004) ولا رمضان (100x).
  final int baseId;
  final int dayStride;

  List<PlannedPrayerReminder> plan({
    required PrayerFeaturePreferences preferences,
    required List<Map<PrayerId, DateTime?>> prayerTimesByDay,
    required DateTime now,
  }) {
    if (!preferences.enabled) return const [];
    final reminders = <PlannedPrayerReminder>[];
    for (var day = 0; day < prayerTimesByDay.length; day++) {
      for (final prayer in PrayerId.values) {
        if (!preferences.isEnabledFor(prayer)) continue;
        final minutes = preferences.minutesFor(prayer);
        if (minutes == null) continue;
        final prayerTime = prayerTimesByDay[day][prayer];
        if (prayerTime == null) continue;
        final time = prayerTime.subtract(Duration(minutes: minutes));
        if (!time.isAfter(now)) continue;
        reminders.add(
          PlannedPrayerReminder(
            prayer: prayer,
            id: idFor(prayer: prayer, day: day),
            time: time,
            minutesBeforePrayer: minutes,
          ),
        );
      }
    }
    return reminders;
  }

  int idFor({required PrayerId prayer, required int day}) =>
      baseId + day * dayStride + prayer.index;

  /// كل المعرفات الممكنة ضمن نطاق الأيام المعطى — للإلغاء الشامل للميزة.
  Iterable<int> idsInRange(int days) sync* {
    for (var day = 0; day < days; day++) {
      for (final prayer in PrayerId.values) {
        yield idFor(prayer: prayer, day: day);
      }
    }
  }
}
