part of '../../../prayers.dart';

const int _kPrayerNotificationsBaseId = 20000;
const int _kPrayerNotificationsDayStride = 10;
const int _kPrayerOpenAppReminderBaseId = 21000;
const String _kLegacyPrayerNotificationsCancelledFlag =
    'legacy_prayer_notifications_cancelled_v2';

/// علم GetStorage يوثق وجود تذكيرات مجدولة فعليًا؛ يمنع تكرار الإلغاء
/// الدوري للميزة المعطلة دون حاجة.
const String _kPrayerRemindersScheduledFlag = 'prayer_reminders_scheduled';

/// علم GetStorage يوثق وجود فترات تصميت مجدولة فعليًا.
const String _kPrayerSilenceScheduledFlag = 'prayer_silence_scheduled';

/// خانات الإقامة داخل كتلة اليوم (الصلوات 0-4 والإقامة 5-9).
const int _kIqamaSlotOffset = 5;

/// سياسة جدولة الأذان والإقامة ضمن حد iOS البالغ 64 إشعارًا محجوزًا.
/// iOS يُبقي أقرب 64 إشعارًا زمنيًا ويحذف الباقي بصمت، لذا تُدار الخانات صراحة.
class IqamaSchedulePolicy {
  static const int iOSPendingNotificationsLimit = 64;

  /// خانات محجوزة لمنشورات الخادم وإشعارات أخرى خارج نطاق الصلوات.
  static const int reservedSlots = 4;

  /// نافذة الإقامة على iOS: اليوم + الغد فقط (تتجدد مع كل تشغيل/مهمة خلفية).
  static const int iOSIqamaWindowDays = 2;

  /// نافذة تذكير ما قبل الصلاة على iOS: اليوم + الغد (10 خانات).
  static const int iOSReminderWindowDays = 2;

  /// أقصى عدد أيام جدولة أذان على iOS (كما كان قبل الميزانية الديناميكية).
  static const int iOSAdhanMaxDays = 10;

  /// الحد الأدنى للأفق حتى مع اشتداد الضغط على الخانات.
  static const int minAdhanDays = 2;

  /// عدد أيام جدولة الأذان على iOS وفق الخانات المتاحة.
  static int adhanDaysForIOS({
    required int enabledAdhanCount,
    required bool iqamaEnabled,
    required bool ramadanActive,
    bool remindersEnabled = false,
  }) {
    if (enabledAdhanCount <= 0) return minAdhanDays;
    const adhanCount = 5;
    final iqamaSlots = iqamaEnabled ? iOSIqamaWindowDays * adhanCount : 0;
    // رمضان: 3 أنواع × 5 أيام على iOS في أسوأ الأحوال.
    final ramadanSlots = ramadanActive ? 15 : 0;
    const openAppReminders = 5;
    final reminderSlots = remindersEnabled
        ? iOSReminderWindowDays * adhanCount
        : 0;
    final available =
        iOSPendingNotificationsLimit -
        reservedSlots -
        iqamaSlots -
        ramadanSlots -
        openAppReminders -
        reminderSlots;
    return (available ~/ enabledAdhanCount).clamp(
      minAdhanDays,
      iOSAdhanMaxDays,
    );
  }

  /// عدد أيام جدولة الإقامة: نافذة قصيرة متجددة على iOS وكامل الأفق فيما عداها.
  static int iqamaDaysToSchedule() {
    return Platform.isIOS ? iOSIqamaWindowDays : _daysToSchedule();
  }

  /// نافذة تذكير ما قبل الصلاة: اليوم + الغد على iOS (ضمن الميزانية)،
  /// وكامل أفق المنصة فيما عداها — تتجدد مع كل تشغيل ومهمة دورية.
  static int reminderDaysToSchedule() {
    return Platform.isIOS ? iOSReminderWindowDays : _daysToSchedule();
  }

  /// أقصى مدى للإلغاء: الأفق الديناميكي قد يتقلص بعد جدولة أوسع سابقًا،
  /// فيُلغى دائمًا على أقصى مدى ممكن لكل منصة.
  static int maxReminderDaysToCancel() => _maxDaysToCancel();
}

int _prayerKeyFromIndex(int prayerIndex) {
  switch (prayerIndex) {
    case 0:
      return 0; // Fajr
    case 2:
      return 1; // Dhuhr
    case 3:
      return 2; // Asr
    case 4:
      return 3; // Maghrib
    case 5:
      return 4; // Isha
    default:
      throw ArgumentError.value(prayerIndex, 'prayerIndex', 'Unsupported');
  }
}

int _scheduledPrayerNotificationId({required int prayerKey, required int day}) {
  return _kPrayerNotificationsBaseId +
      (day * _kPrayerNotificationsDayStride) +
      prayerKey;
}

int _scheduledIqamaNotificationId({required int prayerKey, required int day}) {
  return _kPrayerNotificationsBaseId +
      (day * _kPrayerNotificationsDayStride) +
      _kIqamaSlotOffset +
      prayerKey;
}

int _openAppReminderIdForPrayer(int prayerKey) {
  return _kPrayerOpenAppReminderBaseId + prayerKey;
}

/// عدد الأذان المفعلة حاليًا (نوع إشعار غير nothing للصلوات الخمس).
int _enabledAdhanNotificationCount() {
  final adhanStorage = GetStorage('AdhanSounds');
  const prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  int count = 0;
  for (final name in prayerNames) {
    final type = adhanStorage.read<String?>('scheduledAdhan_$name');
    if (type != null && type != 'nothing') count++;
  }
  return count;
}

/// هل إشعارات الصيام (السحور/الإفطار/العشر الأواخر) مفعلة في رمضان حاليًا؟
bool _isRamadanNotificationsActive() {
  try {
    final ramadan = RamadanController.instance;
    final inRamadan = ramadan.hijriNow.hMonth == 9;
    if (!inRamadan) return false;
    return ramadan.suhoorEnabled.value ||
        ramadan.iftarEnabled.value ||
        ramadan.lastTenNightsEnabled.value;
  } catch (_) {
    return false;
  }
}

int _daysToSchedule() {
  if (Platform.isAndroid) return 30;
  if (Platform.isMacOS) return 10;
  // iOS: أفق ديناميكي ضمن ميزانية الـ 64 إشعارًا.
  return IqamaSchedulePolicy.adhanDaysForIOS(
    enabledAdhanCount: _enabledAdhanNotificationCount(),
    iqamaEnabled:
        AdhanController.instance.state.iqamaNotificationsEnabled.value,
    ramadanActive: _isRamadanNotificationsActive(),
    remindersEnabled: _prayerRemindersEnabled(),
  );
}

/// هل تذكير ما قبل الصلاة مفعّل في إعدادات المميزات؟ (قراءة مباشرة من
/// التخزين لتعمل في عزل الخلفية أيضًا دون الاعتماد على حقن GetX.)
bool _prayerRemindersEnabled() {
  try {
    return StoredPrayerFeatureSettings(
      GetStorage(),
    ).read()[PrayerFeature.reminder].enabled;
  } catch (_) {
    return false;
  }
}

/// موعد أذان الصلاة بعد dayOffset أيام من اليوم؛ null إن لم تجهز المواقيت.
DateTime? _reminderPrayerTime(PrayerId prayer, int dayOffset) {
  final athanCtrl = AdhanController.instance;
  if (athanCtrl.state.prayerTimes == null) return null;
  final dateComponents = DateComponents.from(
    DateTime.now().add(Duration(days: dayOffset)),
  );
  final prayerTimes = PrayerTimes(
    athanCtrl.state.coordinates,
    dateComponents,
    athanCtrl.state.params,
  );
  final adhanPrayer = switch (prayer) {
    PrayerId.fajr => Prayer.fajr,
    PrayerId.dhuhr => Prayer.dhuhr,
    PrayerId.asr => Prayer.asr,
    PrayerId.maghrib => Prayer.maghrib,
    PrayerId.isha => Prayer.isha,
  };
  return prayerTimes.timeForPrayer(adhanPrayer);
}

LocalPrayerReminderScheduler _reminderScheduler() =>
    LocalPrayerReminderScheduler(
      prayerTimeFor: _reminderPrayerTime,
      daysToSchedule: IqamaSchedulePolicy.reminderDaysToSchedule,
      maxDaysToCancel: IqamaSchedulePolicy.maxReminderDaysToCancel,
      schedule:
          ({
            required id,
            required time,
            required title,
            required summary,
            required body,
            required payload,
          }) => NotifyHelper().scheduledNotification(
            reminderId: id,
            title: title,
            summary: summary,
            body: body,
            isRepeats: false,
            time: time,
            payload: payload,
          ),
      cancel: NotifyHelper().cancelNotification,
    );

/// موعد إقامة الصلاة (أذان + إزاحة) بعد dayOffset أيام؛ مستقل عن تفعيل
/// إشعارات الإقامة، وnull إن لم تجهز المواقيت.
DateTime? _silenceIqamaTime(PrayerId prayer, int dayOffset) {
  final athanCtrl = AdhanController.instance;
  final adhan = _reminderPrayerTime(prayer, dayOffset);
  if (adhan == null) return null;
  final prayerIndex = switch (prayer) {
    PrayerId.fajr => 0,
    PrayerId.dhuhr => 2,
    PrayerId.asr => 3,
    PrayerId.maghrib => 4,
    PrayerId.isha => 5,
  };
  return adhan.add(athanCtrl.state.iqamaOffsets.durationByIndex(prayerIndex));
}

const MethodChannel _silenceChannel = MethodChannel(
  'com.alheekmah.aqimApp/prayer_silence',
);

LocalPrayerSilenceScheduler _silenceScheduler() => LocalPrayerSilenceScheduler(
  iqamaTimeFor: _silenceIqamaTime,
  daysToSchedule: _daysToSchedule,
  isSupported: () => Platform.isAndroid,
  syncPeriods: (periods) =>
      _silenceChannel.invokeMethod('syncSilencePeriods', {'periods': periods}),
  endAndCancel: () => _silenceChannel.invokeMethod('endAndCancelSilence'),
);

/// أقصى مدى للإلغاء: الأفق الديناميكي قد يتقلص بعد جدولة أوسع سابقًا،
/// فيُلغى دائمًا على أقصى مدى ممكن لكل منصة.
int _maxDaysToCancel() => Platform.isAndroid ? 30 : 10;

Future<void> _cancelLegacyPrayerNotificationsForPrayerIndex(
  int prayerIndex,
) async {
  // النظام القديم كان يعتمد: baseId ثم +5 لكل يوم.
  final dayLength = Platform.isAndroid ? 61 : 10;
  for (int i = 0; i < dayLength; i++) {
    final legacyBaseId = prayerIndex + (5 * i);
    await NotifyHelper().cancelNotification(legacyBaseId);

    // في بعض الإصدارات كان iOS يرسل "الأذان الكامل" عبر عدة إشعارات متتالية.
    if (Platform.isIOS) {
      for (int offset = 1; offset <= 6; offset++) {
        await NotifyHelper().cancelNotification(legacyBaseId + offset);
      }
    }
  }

  // تذكير "افتح التطبيق" في النظام القديم كان: 1000 + (baseId + 5*n)
  // (نبدأ من 1 لتجنب المساس بـ 1000/1001 الخاصين برمضان).
  for (int n = 1; n <= dayLength; n++) {
    await NotifyHelper().cancelNotification(1000 + prayerIndex + (5 * n));
  }
}

Future<void> _cancelLegacyPrayerNotificationsIfNeeded() async {
  final storage = GetStorage();
  final alreadyCancelled =
      storage.read<bool>(_kLegacyPrayerNotificationsCancelledFlag) ?? false;
  if (alreadyCancelled) return;

  const prayerIndexes = <int>[0, 2, 3, 4, 5];
  for (final prayerIndex in prayerIndexes) {
    await _cancelLegacyPrayerNotificationsForPrayerIndex(prayerIndex);
  }

  await storage.write(_kLegacyPrayerNotificationsCancelledFlag, true);
  log(
    'Legacy prayer notification IDs cancelled (migration)',
    name: 'ScheduleDailyExtension',
  );
}

extension ScheduleDailyExtension on PrayersNotificationsCtrl {
  Future<void> scheduleDailyNotificationsForPrayer(
    int prayerIndex,
    String prayerName,
    String notificationType,
  ) async {
    final athanCtrl = AdhanController.instance;
    if ('nothing' == notificationType) {
      GetStorage('AdhanSounds').remove('scheduledAdhan_$prayerName');
      log('منبة صلاة $prayerName removed', name: 'ScheduleDailyExtension');
      return cancelPrayerNotificationsForAllDay(prayerIndex);
    }
    GetStorage(
      'AdhanSounds',
    ).write('scheduledAdhan_$prayerName', notificationType);

    if (athanCtrl.state.prayerTimes == null ||
        athanCtrl.state.sunnahTimes == null) {
      return;
    }

    final prayerKey = _prayerKeyFromIndex(prayerIndex);
    final daysToSchedule = _daysToSchedule();

    DateTime? lastPrayerTime;
    final now = DateTime.now();

    for (int day = 0; day < daysToSchedule; day++) {
      DateComponents dateComponents = DateComponents.from(
        DateTime.now().add(Duration(days: day)),
      );

      PrayerTimes prayerTimes = PrayerTimes(
        athanCtrl.state.coordinates,
        dateComponents,
        athanCtrl.state.params,
      );

      late final DateTime prayerTime;
      Prayer selectedPrayer;
      String selectedBody;

      switch (prayerIndex) {
        case 0:
          selectedPrayer = Prayer.fajr;
          prayerTime = prayerTimes.fajr;
          selectedBody = 'fajrBody';
          break;
        case 2:
          selectedPrayer = Prayer.dhuhr;
          prayerTime = prayerTimes.dhuhr;
          selectedBody = 'dhuhrBody';
          break;
        case 3:
          selectedPrayer = Prayer.asr;
          prayerTime = prayerTimes.asr;
          selectedBody = 'asrBody';
          break;
        case 4:
          selectedPrayer = Prayer.maghrib;
          prayerTime = prayerTimes.maghrib;
          selectedBody = 'maghribBody';
          break;
        case 5:
          selectedPrayer = Prayer.isha;
          prayerTime = prayerTimes.isha;
          selectedBody = 'ishaBody';
          break;
        default:
          return;
      }

      // لا تُجدول إشعارًا بوقتٍ ماضٍ. إذا كانت صلاة اليوم قد فاتت، انتقل لليوم التالي.
      if (prayerTime.isBefore(now)) {
        log(
          'Skip past prayer time for ${athanCtrl.prayerNameFromEnum(selectedPrayer).tr}: $prayerTime',
          name: 'ScheduleDailyExtension',
        );
        continue;
      }

      final notificationId = _scheduledPrayerNotificationId(
        prayerKey: prayerKey,
        day: day,
      );

      /// this code is for full athan on ios
      // if (Platform.isIOS) {
      //   for (int i = 1; i <= 6; i++) {
      //     DateTime nextNotificationTime =
      //         prayerTime.add(Duration(seconds: 30 * i));
      //     await NotifyHelper().scheduledNotification(
      //       notificationId + i,
      //       athanCtrl.prayerNameFromEnum(selectedPrayer).tr,
      //       'وقت صلاة ${athanCtrl.prayerNameFromEnum(selectedPrayer).tr}',
      //       'حان الآن موعد صلاة ${athanCtrl.prayerNameFromEnum(selectedPrayer).tr}',
      //       false,
      //       time: nextNotificationTime,
      //       payload: {'sound_type': notificationType},
      //       soundIndex: i + 1,
      //     );
      //   }
      // } else {
      await NotifyHelper().scheduledNotification(
        reminderId: notificationId,
        title: athanCtrl.prayerNameFromEnum(selectedPrayer).tr,
        summary:
            '${'timeForPrayer'.tr} ${athanCtrl.prayerNameFromEnum(selectedPrayer).tr}',
        body: selectedBody.tr,
        isRepeats: false,
        time: prayerTime,
        payload: {'sound_type': notificationType},
        soundIndex: 1,
      );
      // }

      log(
        'تم جدولة صلاة ${athanCtrl.prayerNameFromEnum(selectedPrayer).tr}',
        name: 'ScheduleDailyExtension',
      );
      log('notificationId: $notificationId', name: 'ScheduleDailyExtension');
      // log('موعد صلاة ${DateFormatter.formatPrayerTime(prayerTime).tr}');

      lastPrayerTime = prayerTime;
    }

    if (lastPrayerTime != null) {
      DateTime reminderTime = lastPrayerTime.add(const Duration(minutes: 5));
      await NotifyHelper().scheduledNotification(
        reminderId: _openAppReminderIdForPrayer(prayerKey),
        title: 'reminder'.tr,
        summary: 'openAppReminderTitle'.tr,
        body: 'openAppReminderBody'.tr,
        isRepeats: false,
        time: reminderTime,
        payload: {'sound_type': 'bell'},
      );

      log('تم جدولة تذكير بعد آخر صلاة بـ ٥ دقائق');
      // log('موعد التذكير ${DateFormatter.formatPrayerTime(reminderTime)}');
    }
  }

  // Future<void> fullAthanForIos(
  //     LocalReceivedNotification receivedNotification) async {
  //   if (Platform.isIOS) {
  //     for (int i = 1; i <= 6; i++) {
  //       DateTime nextNotificationTime =
  //           DateTime.now().add(Duration(seconds: 30 * i));
  //       await NotifyHelper().scheduledNotification(
  //           reminderId: receivedNotification.id + i + 1,
  //           title: receivedNotification.title,
  //           summary: receivedNotification.summary,
  //           body: receivedNotification.body,
  //           isRepeats: false,
  //           time: nextNotificationTime,
  //           payload: receivedNotification.payload,
  //           soundIndex: i + 1);
  //     }
  //   }
  // }

  /// جدولة إشعارات الإقامة عند وقت الإقامة تمامًا لكل صلاة.
  /// iOS: نافذة اليوم+الغد فقط ضمن ميزانية الـ 64 (تتجدد مع كل تشغيل)؛
  /// أندرويد/macOS: كامل الأفق.
  Future<void> scheduleIqamaNotifications() async {
    final athanCtrl = AdhanController.instance;
    if (!athanCtrl.state.iqamaNotificationsEnabled.value) return;
    if (athanCtrl.state.prayerTimes == null ||
        athanCtrl.state.sunnahTimes == null) {
      return;
    }

    await cancelAllIqamaNotifications();

    final days = IqamaSchedulePolicy.iqamaDaysToSchedule();
    final now = DateTime.now();
    final iqamaOffsets = athanCtrl.state.iqamaOffsets;

    for (int day = 0; day < days; day++) {
      final dateComponents = DateComponents.from(
        DateTime.now().add(Duration(days: day)),
      );

      final prayerTimes = PrayerTimes(
        athanCtrl.state.coordinates,
        dateComponents,
        athanCtrl.state.params,
      );

      const prayerEntries = <({int prayerIndex, Prayer prayer})>[
        (prayerIndex: 0, prayer: Prayer.fajr),
        (prayerIndex: 2, prayer: Prayer.dhuhr),
        (prayerIndex: 3, prayer: Prayer.asr),
        (prayerIndex: 4, prayer: Prayer.maghrib),
        (prayerIndex: 5, prayer: Prayer.isha),
      ];

      for (final entry in prayerEntries) {
        final adhanTime = prayerTimes.timeForPrayer(entry.prayer);
        if (adhanTime == null) continue;
        final iqamaTime = adhanTime.add(
          iqamaOffsets.durationByIndex(entry.prayerIndex),
        );

        // لا تُجدول إقامة بوقتٍ ماضٍ.
        if (iqamaTime.isBefore(now)) continue;

        final prayerKey = _prayerKeyFromIndex(entry.prayerIndex);
        final notificationId = _scheduledIqamaNotificationId(
          prayerKey: prayerKey,
          day: day,
        );
        final prayerName = athanCtrl.prayerNameFromEnum(entry.prayer).tr;

        await NotifyHelper().scheduledNotification(
          reminderId: notificationId,
          title: 'iqama'.tr,
          summary: '${'timeForIqama'.tr} $prayerName',
          body: '',
          isRepeats: false,
          time: iqamaTime,
          payload: {'sound_type': 'bell'},
        );

        log(
          'تم جدولة إقامة $prayerName ($day): $iqamaTime',
          name: 'ScheduleDailyExtension',
        );
      }
    }
  }

  /// إلغاء جميع إشعارات الإقامة (خانات 5-9 في كل كتلة يوم).
  Future<void> cancelAllIqamaNotifications() async {
    final daysToCancel = _maxDaysToCancel();
    for (int day = 0; day < daysToCancel; day++) {
      for (int prayerKey = 0; prayerKey < 5; prayerKey++) {
        await NotifyHelper().cancelNotification(
          _scheduledIqamaNotificationId(prayerKey: prayerKey, day: day),
        );
      }
    }
    log('تم إلغاء جميع إشعارات الإقامة.', name: 'ScheduleDailyExtension');
  }

  Future<void> reschedulePrayers() async {
    log(
      'إعادة جدولة إشعارات الصلوات اليومية...',
      name: 'ScheduleDailyExtension',
    );

    // تنظيف IDs القديمة مرة واحدة بعد التحديث لتفادي الإشعارات المكررة.
    await _cancelLegacyPrayerNotificationsIfNeeded();
    final adhanStorage = GetStorage('AdhanSounds');
    const prayers = <({int index, String name})>[
      (index: 0, name: 'Fajr'),
      (index: 2, name: 'Dhuhr'),
      (index: 3, name: 'Asr'),
      (index: 4, name: 'Maghrib'),
      (index: 5, name: 'Isha'),
    ];

    await cancelAllPrayerNotifications();

    for (final prayer in prayers) {
      final prayerName = prayer.name;
      final String? notificationType = adhanStorage.read(
        'scheduledAdhan_$prayerName',
      );
      log('notification: $notificationType', name: 'ScheduleDailyExtension');

      if (notificationType != null && notificationType != 'nothing') {
        await PrayersNotificationsCtrl.instance
            .scheduleDailyNotificationsForPrayer(
              prayer.index,
              prayerName,
              notificationType,
            );
      }
    }

    // إشعارات الإقامة: تُجدول إن كانت مفعلة (وتُلغى إن كانت معطلة).
    if (AdhanController.instance.state.iqamaNotificationsEnabled.value) {
      await scheduleIqamaNotifications();
    } else {
      await cancelAllIqamaNotifications();
    }

    // تذكيرات ما قبل الصلاة (المرحلة الثانية): مزامنة مع الإعدادات الحالية.
    await synchronizePrayerReminders();

    // فترات التصميت (المرحلة الثالثة): مزامنة مع الإعدادات والإقامات.
    await synchronizePrayerSilence();

    // إعادة جدولة إشعارات الصيام (السحور/الإفطار/العشر الأواخر)
    await RamadanController.instance.rescheduleFastingNotifications();
  }

  /// مزامنة تذكيرات ما قبل الصلاة مع إعدادات المميزات الحالية:
  /// إلغاء شامل ثم جدولة النافذة النشطة؛ لا تفعل شيئًا متى كانت الميزة
  /// معطلة دون تذكيرات سابقة (يمنع الإلغاء الدوري عبثًا).
  Future<void> synchronizePrayerReminders() async {
    try {
      final preferences = StoredPrayerFeatureSettings(
        GetStorage(),
      ).read()[PrayerFeature.reminder];
      final storage = GetStorage();
      final previouslyScheduled =
          storage.read<bool>(_kPrayerRemindersScheduledFlag) ?? false;
      if (!preferences.enabled && !previouslyScheduled) return;

      await _reminderScheduler().synchronize(preferences);
      await storage.write(_kPrayerRemindersScheduledFlag, preferences.enabled);
    } catch (e) {
      log('Prayer reminders sync failed: $e', name: 'ScheduleDailyExtension');
    }
  }

  /// إلغاء جميع تذكيرات ما قبل الصلاة (معرفات الميزة وحدها).
  Future<void> cancelAllPrayerReminders() async {
    await _reminderScheduler().cancelReminders();
    await GetStorage().write(_kPrayerRemindersScheduledFlag, false);
    log('تم إلغاء جميع تذكيرات ما قبل الصلاة.', name: 'ScheduleDailyExtension');
  }

  /// مزامنة فترات التصميت مع إعدادات المميزات الحالية؛ لا تنفذ شيئًا
  /// على غير أندرويد، ولا تكرر الإلغاء متى كانت الميزة معطلة بلا جدولة.
  Future<void> synchronizePrayerSilence() async {
    try {
      final preferences = StoredPrayerFeatureSettings(
        GetStorage(),
      ).read()[PrayerFeature.silence];
      final storage = GetStorage();
      final previouslyScheduled =
          storage.read<bool>(_kPrayerSilenceScheduledFlag) ?? false;
      if (!preferences.enabled && !previouslyScheduled) return;

      await _silenceScheduler().synchronize(preferences);
      await storage.write(_kPrayerSilenceScheduledFlag, preferences.enabled);
    } catch (e) {
      log('Prayer silence sync failed: $e', name: 'ScheduleDailyExtension');
    }
  }

  /// إنهاء فترة التصميت النشطة وإلغاء جدولتها (تعطيل الميزة مثلًا).
  Future<void> endAndCancelPrayerSilence() async {
    try {
      await _silenceScheduler().endAndCancelSilence();
      await GetStorage().write(_kPrayerSilenceScheduledFlag, false);
    } catch (e) {
      log('Prayer silence cancel failed: $e', name: 'ScheduleDailyExtension');
    }
  }

  Future<void> cancelAllPrayerNotifications() async {
    const prayerIndexes = <int>[0, 2, 3, 4, 5];

    // تنظيف الجداول القديمة (مرة واحدة) لتفادي تداخل الإصدارات.
    await _cancelLegacyPrayerNotificationsIfNeeded();

    final daysToCancel = _maxDaysToCancel();
    for (int day = 0; day < daysToCancel; day++) {
      for (final prayerIndex in prayerIndexes) {
        final prayerKey = _prayerKeyFromIndex(prayerIndex);
        final id = _scheduledPrayerNotificationId(
          prayerKey: prayerKey,
          day: day,
        );
        await NotifyHelper().cancelNotification(id);
      }
    }

    for (int prayerKey = 0; prayerKey < 5; prayerKey++) {
      await NotifyHelper().cancelNotification(
        _openAppReminderIdForPrayer(prayerKey),
      );
    }

    // تشمل إشعارات الإقامة (خانات 5-9 في كل كتلة يوم).
    await cancelAllIqamaNotifications();

    // تشمل تذكيرات ما قبل الصلاة (معرفات 21100 فأعلى).
    await cancelAllPrayerReminders();

    log('تم إلغاء جميع إشعارات الصلاة.', name: 'ScheduleDailyExtension');
  }

  Future<void> cancelPrayerNotificationsForAllDay(
    int prayerNotificationId,
  ) async {
    final originalPrayerIndex = prayerNotificationId;

    // تنظيف من النظام القديم.
    await _cancelLegacyPrayerNotificationsForPrayerIndex(originalPrayerIndex);

    final prayerKey = _prayerKeyFromIndex(originalPrayerIndex);
    final daysToCancel = _maxDaysToCancel();
    for (int day = 0; day < daysToCancel; day++) {
      final id = _scheduledPrayerNotificationId(prayerKey: prayerKey, day: day);
      await NotifyHelper().cancelNotification(id);
    }
    await NotifyHelper().cancelNotification(
      _openAppReminderIdForPrayer(prayerKey),
    );

    log(
      'تم إلغاء جميع إشعارات صلاة $originalPrayerIndex.',
      name: 'ScheduleDailyExtension',
    );
  }

  /// إلغاء IDs القديمة مرة واحدة بعد التحديث.
  Future<void> cancelLegacyPrayerNotificationsIfNeeded() async {
    await _cancelLegacyPrayerNotificationsIfNeeded();
  }
}
