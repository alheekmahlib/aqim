import 'dart:developer' show log;

import 'package:get/get.dart';

import '../domain/prayer_feature_preferences.dart';
import '../domain/prayer_id.dart';
import '../domain/prayer_reminder_plan.dart';
import '../domain/prayer_reminder_scheduler.dart';

/// يجدول تذكيرًا قبل الصلاة بصوتها المدمج، مستقلًا عن صوت الأذان والإقامة.
/// يختار محوّل الإشعارات الصوت من prayer على أندرويد وآيفون والماك.
/// الوسم prayer_reminder يفتح شاشة الصلاة دون تشغيل الأذان.
/// تعتمد كل التبعيات حقنًا لتظل قابلة للاختبار دون منصة.
class LocalPrayerReminderScheduler implements PrayerReminderScheduler {
  LocalPrayerReminderScheduler({
    required this.prayerTimeFor,
    required this.daysToSchedule,
    required this.maxDaysToCancel,
    required this.schedule,
    required this.cancel,
    this.now = DateTime.now,
    this.yieldBetweenOps = _defaultYield,
    this.pendingIds,
  });

  final DateTime? Function(PrayerId prayer, int dayOffset) prayerTimeFor;
  final int Function() daysToSchedule;
  final int Function() maxDaysToCancel;

  /// يُستدعى بين عمليات الجدولة والإلغاء لإتاحة الـ UI thread للإطارات.
  final Future<void> Function() yieldBetweenOps;

  /// معرفات الإشعارات المؤجلة حاليًا؛ لإلغاء الفارق فقط. null (أو غيابها)
  /// يعني التراجع للإلغاء الشامل للنطاق.
  final Future<Set<int>?> Function()? pendingIds;
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

  static Future<void> _defaultYield() => Future<void>.delayed(Duration.zero);

  @override
  Future<void> synchronize(PrayerFeaturePreferences preferences) async {
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
    final plannedIds = reminders.map((reminder) => reminder.id).toSet();

    // ابنِ أولًا فوق المعرفات الحالية ثم قلّم ما خرج عن الخطة؛ لا مسح شامل
    // يسبق الجدولة كي لا تنشأ نافذة بلا تذكيرات إن قُطعت العملية.
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
      await yieldBetweenOps();
    }

    // إلغاء الفارق فقط: ما خرج عن الخطة وهو مؤجل فعلاً (وإن تعذرت قراءة
    // المؤجلات نُلغي النطاق كاملًا كما كان).
    final pending = await pendingIds?.call();
    for (final id in planner.idsInRange(maxDaysToCancel())) {
      if (plannedIds.contains(id)) continue;
      if (pending != null && !pending.contains(id)) continue;
      await cancel(id);
      await yieldBetweenOps();
    }

    log(
      preferences.enabled
          ? 'Scheduled ${reminders.length} prayer reminders over $days day(s)'
          : 'Prayer reminders disabled; cancelled all',
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
