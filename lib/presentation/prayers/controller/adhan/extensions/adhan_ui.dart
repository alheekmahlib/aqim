part of '../../../prayers.dart';

extension AdhanUi on AdhanController {
  /// -------- [OnTaps] ----------

  Future<void> hanafiOnTap(bool value) async {
    // تفعيل المذهب الحنفي وإلغاء تفعيل الشافعي - Activate Hanafi madhab and deactivate Shafi'i
    state.isHanafi = value;
    state.box.write(SHAFI, state.isHanafi);
    state.isLoadingPrayerData.value = true;
    await initializeStoredAdhan(forceUpdate: true);
  }

  Future<void> adjustPrayerTime(int index, {bool isAdding = true}) async {
    log("Before adjustment: ${prayerNameList[index]['adjustment']}");
    state.adjustments.addAdjustment(
      prayerNameList[index]['sharedAdjustment'],
      isAdding ? 1 : -1,
    );

    log("After adjustment: ${prayerNameList[index]['adjustment']}");
    state.box.remove(PRAYER_TIME_DATE);
    state.box.remove(PRAYER_TIME);
    state.isLoadingPrayerData.value = true;
    await initializeStoredAdhan(forceUpdate: true);
  }

  Future<void> switchAutoCalculation(bool value) async {
    state.autoCalculationMethod.value = value;
    // sl<NotificationController>().initializeNotification();
    state.box.write(AUTO_CALCULATION, value);
    state.isLoadingPrayerData.value = true;
    // await ضروري كي يعكس مؤشر تحميل المفتاح المدة الفعلية لإعادة الحساب
    await initializeStoredAdhan(forceUpdate: true);
  }

  Future<void> notificationOptionsOnTap(int i, int prayerIndex) async {
    await PrayersNotificationsCtrl.instance.scheduleDailyNotificationsForPrayer(
      prayerIndex,
      prayerNameList[prayerIndex]['title'],
      notificationOptions[i]['title'],
    );
    // await NotifyHelper().scheduledNotification(
    //   reminderId: 99999,
    //   title: 'Fajr'.tr,
    //   summary: 'وقت صلاة الفجر',
    //   body: 'fajrBody'.tr,
    //   isRepeats: false,
    //   time: DateTime.now().add(const Duration(seconds: 10)),
    //   payload: {'sound_type': 'sound'},
    // );
    update(['change_notification']);
  }

  /// تعديل إزاحة الإقامة لصلاة معينة بخطوة iqamaOffsetStep.
  Future<void> adjustIqamaOffset(int index, {bool isAdding = true}) async {
    if (!IqamaOffsets.hasIqama(index)) return;
    state.iqamaOffsets.adjustByIndex(
      index,
      isAdding ? iqamaOffsetStep : -iqamaOffsetStep,
    );
    update(['init_athan']);
    // تحديث إشعارات الإقامة إن كانت مفعلة (نافذة قصيرة — عملية رخيصة).
    if (state.iqamaNotificationsEnabled.value) {
      try {
        await PrayersNotificationsCtrl.instance.scheduleIqamaNotifications();
      } catch (e) {
        log('Failed to refresh iqama notifications: $e', name: 'AdhanUi');
      }
    }
  }

  /// تفعيل/تعطيل إشعارات الإقامة. التبديل يغيّر ميزانية خانات iOS
  /// فيلزم إعادة جدولة كاملة لاشعارات الأذان.
  Future<void> toggleIqamaNotifications(bool value) async {
    state.iqamaNotificationsEnabled.value = value;
    state.box.write(IQAMA_NOTIFICATIONS_ENABLED, value);
    await PrayersNotificationsCtrl.instance.reschedulePrayers();
    update(['init_athan']);
  }

  /// إظهار/إخفاء وقت الإقامة في قائمة الصلوات (لا يؤثر على الإشعارات).
  void toggleShowIqamaTimes(bool value) {
    state.showIqamaTimes.value = value;
    state.box.write(SHOW_IQAMA_TIMES, value);
    update(['init_athan']);
  }

  /// تفعيل/تعطيل الإشعار الدائم بالعدّ التنازلي للصلاة القادمة.
  /// يطلب أذونات الإشعارات عند التفعيل ويبني/يلغي الإشعار والمنبّهات.
  Future<void> togglePrayerCountdownNotification(bool value) async {
    state.prayerCountdownEnabled.value = value;
    state.box.write(PRAYER_COUNTDOWN_NOTIFICATION_ENABLED, value);
    await PrayerCountdownNotificationService.instance.setEnabled(value);
    update(['init_athan']);
  }
}
