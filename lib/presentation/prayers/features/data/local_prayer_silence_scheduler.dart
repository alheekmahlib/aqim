import 'dart:developer' show log;

import '../domain/prayer_feature_preferences.dart';
import '../domain/prayer_id.dart';
import '../domain/prayer_silence_plan.dart';
import '../domain/prayer_silence_scheduler.dart';

/// محوّل المرحلة الثالثة: يحوّل إعدادات التصميت إلى فترات مدمجة ويسلّمها
/// للطبقة الأصلية (أندرويد) التي تملك القاعدة والجدولة والاستعادة؛ لا
/// يعمل على غير أندرويد فترجعه النافذة صفرًا والربط لا يستدعيه.
/// تعتمد كل التبعيات حقنًا لتظل قابلة للاختبار دون منصة.
class LocalPrayerSilenceScheduler implements PrayerSilenceScheduler {
  LocalPrayerSilenceScheduler({
    required this.iqamaTimeFor,
    required this.daysToSchedule,
    required this.syncPeriods,
    required this.endAndCancel,
    required this.isSupported,
    this.now = DateTime.now,
  });

  /// موعد الإقامة (أذان + إزاحة) بعد dayOffset أيام؛ null إن لم تجهز المواقيت.
  final DateTime? Function(PrayerId prayer, int dayOffset) iqamaTimeFor;
  final int Function() daysToSchedule;

  /// يسلّم الفترات بالميلي ثانية [{start,end}, ...] للقناة الأصلية؛
  /// قائمة فارغة تعني الإنهاء والإلغاء الكامل.
  final Future<void> Function(List<Map<String, int>> periodMillis) syncPeriods;
  final Future<void> Function() endAndCancel;
  final bool Function() isSupported;
  final DateTime Function() now;

  final PrayerSilencePlanner planner = const PrayerSilencePlanner();

  @override
  Future<void> synchronize(PrayerFeaturePreferences preferences) async {
    // غير مدعوم على هذه المنصة: لا قناة أصلية ولا ما يُلغى أصلًا.
    if (!isSupported()) return;
    if (!preferences.enabled) {
      await endAndCancel();
      log(
        'Prayer silence disabled; ended and cancelled',
        name: 'PrayerSilence',
      );
      return;
    }

    final days = daysToSchedule();
    final iqamaTimesByDay = <Map<PrayerId, DateTime?>>[
      for (var day = 0; day < days; day++)
        {
          for (final prayer in PrayerId.values)
            prayer: iqamaTimeFor(prayer, day),
        },
    ];

    final periods = planner.plan(
      preferences: preferences,
      iqamaTimesByDay: iqamaTimesByDay,
      now: now(),
    );

    await syncPeriods([
      for (final period in periods)
        {
          'start': period.start.millisecondsSinceEpoch,
          'end': period.end.millisecondsSinceEpoch,
        },
    ]);
    log(
      'Prayer silence synced with ${periods.length} merged period(s)',
      name: 'PrayerSilence',
    );
  }

  @override
  Future<void> endAndCancelSilence() async {
    if (!isSupported()) return;
    await endAndCancel();
  }
}
