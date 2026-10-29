import 'dart:developer' show log;

import 'package:get/get.dart';

import '../domain/prayer_feature_preferences.dart';
import '../domain/prayer_id.dart';
import '../domain/prayer_reminder_plan.dart';
import '../domain/prayer_reminder_scheduler.dart';

/// محوّل المرحلة الثانية: يجدول إشعارات تذكير قصيرة قبل الصلاة بصوت
/// التنبيه الموجود (bell)، مستقلة عن صوت الأذان والإقامة، ووسمها بنوع
/// prayer_reminder ليفتح النقر شاشة الصلاة دون تشغيل الأذان.
/// تعتمد كل التبعيات حقنًا لتظل قابلة للاختبار دون منصة.
class LocalPrayerReminderScheduler implements PrayerReminderScheduler {
  LocalPrayerReminderScheduler({
    required this.prayerTimeFor,
    required this.daysToSchedule,
    required this.maxDaysToCancel,
    required this.schedule,
    required this.cancel,
    this.now = DateTime.now,
  });

  final DateTime? Function(PrayerId prayer, int dayOffset) prayerTimeFor;
  final int Function() daysToSchedule;
  final int Function() maxDaysToCancel;
  final Future<void> Function({
    required int id,
    required DateTime time,
    required String title,
    required String summary,
    required String body,
    required Map<String, String?> payload,
  })
  schedule;
  final Future<void> Function(int id) cancel;
  final DateTime Function() now;

  final PrayerReminderPlanner planner = const PrayerReminderPlanner();

  @override
  Future<void> synchronize(PrayerFeaturePreferences preferences) async {
    await cancelReminders();
    if (!preferences.enabled) {
      log('Prayer reminders disabled; cancelled all', name: 'PrayerReminders');
      return;
    }

    final days = daysToSchedule();
    final prayerTimesByDay = <Map<PrayerId, DateTime?>>[
      for (var day = 0; day < days; day++)
        {
          for (final prayer in PrayerId.values)
            prayer: prayerTimeFor(prayer, day),
        },
    ];

    final reminders = planner.plan(
      preferences: preferences,
      prayerTimesByDay: prayerTimesByDay,
      now: now(),
    );

    for (final reminder in reminders) {
      final prayerName = _prayerLabelKey(reminder.prayer).tr;
      await schedule(
        id: reminder.id,
        time: reminder.time,
        title: 'prayerReminderTitle'.tr,
        summary: prayerName,
        body: 'prayerReminderBody'.trParams({
          'minutes': '${reminder.minutesBeforePrayer}',
          'prayer': prayerName,
        }),
        payload: {
          'type': 'prayer_reminder',
          'sound_type': 'bell',
          'prayer': reminder.prayer.name,
        },
      );
    }
    log(
      'Scheduled ${reminders.length} prayer reminders over $days day(s)',
      name: 'PrayerReminders',
    );
  }

  @override
  Future<void> cancelReminders() async {
    for (final id in planner.idsInRange(maxDaysToCancel())) {
      await cancel(id);
    }
  }

  /// مفاتيح ترجمة أسماء الصلوات مطابقة لمفاتيح التطبيق القائمة.
  String _prayerLabelKey(PrayerId prayer) => switch (prayer) {
    PrayerId.fajr => 'Fajr',
    PrayerId.dhuhr => 'Dhuhr',
    PrayerId.asr => 'Asr',
    PrayerId.maghrib => 'Maghrib',
    PrayerId.isha => 'Isha',
  };
}
