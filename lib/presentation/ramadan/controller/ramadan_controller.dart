part of '../events.dart';

/// ثوابت التخزين
const _kRamadanStorage = (
  qadaTracker: 'ramadan_qada_tracker',
  quranTracker: 'ramadan_quran_tracker',
  suhoorNotification: 'ramadan_suhoor_notification',
  iftarNotification: 'ramadan_iftar_notification',
  suhoorMinutes: 'ramadan_suhoor_minutes',
  iftarMinutes: 'ramadan_iftar_minutes',
  lastTenNights: 'ramadan_last_ten_notification',
);

/// أنواع إشعارات الصيام
enum _FastingNotificationType {
  suhoor(baseId: 1000, titleKey: 'suhoorReminder', bodyKey: 'timeForSuhoor'),
  iftar(baseId: 1050, titleKey: 'iftarReminder', bodyKey: 'prepareForIftar'),
  lastTen(
    baseId: 1100,
    titleKey: 'lastTenNights',
    bodyKey: 'laylatAlQadrReminder',
  );

  const _FastingNotificationType({
    required this.baseId,
    required this.titleKey,
    required this.bodyKey,
  });

  final int baseId;
  final String titleKey;
  final String bodyKey;
}

/// Controller لإدارة ميزات رمضان
class RamadanController extends GetxController {
  static RamadanController get instance => Get.isRegistered<RamadanController>()
      ? Get.find<RamadanController>()
      : Get.put<RamadanController>(RamadanController());

  final _box = GetStorage();
  late HijriDate hijriNow;

  // القضاء
  final missedDays = <QadaDay>[].obs;
  final fastedDays = <QadaDay>[].obs;

  // الختمات
  final khatmas = <QuranKhatma>[].obs;
  final currentJuz = 0.obs;
  final currentKhatmaId = 0.obs;

  // التنبيهات
  final suhoorEnabled = false.obs;
  final iftarEnabled = false.obs;
  final lastTenNightsEnabled = false.obs;
  final suhoorMinutes = 60.obs;
  final iftarMinutes = 30.obs;

  /// عدد أيام الجدولة حسب المنصة
  int get _scheduleDaysCount => Platform.isIOS ? 5 : 15;

  @override
  void onInit() {
    super.onInit();
    hijriNow = EventController.instance.hijriNow;
    _loadAllData();
  }

  void _loadAllData() {
    _loadQadaData();
    _loadQuranData();
    _loadNotificationSettings();
  }

  // ==================== القضاء ====================

  bool _matchesQadaDay(QadaDay d, int day) =>
      d.day == day && d.month == 9 && d.year == hijriNow.hYear;

  void _loadQadaData() {
    final data = _box.read(_kRamadanStorage.qadaTracker);
    if (data == null) return;
    try {
      final tracker = QadaTracker.fromJson(json.decode(data));
      if (tracker.hijriYear == hijriNow.hYear) {
        missedDays.value = tracker.missedDays;
        fastedDays.value = tracker.fastedDays;
      }
    } catch (_) {}
  }

  void _saveQadaData() {
    final tracker = QadaTracker(
      missedDays: missedDays.toList(),
      fastedDays: fastedDays.toList(),
      hijriYear: hijriNow.hYear,
    );
    _box.write(_kRamadanStorage.qadaTracker, json.encode(tracker.toJson()));
  }

  void toggleQadaDay(int day) {
    final index = missedDays.indexWhere((d) => _matchesQadaDay(d, day));

    if (index != -1) {
      missedDays.removeAt(index);
      fastedDays.removeWhere((d) => _matchesQadaDay(d, day));
    } else {
      missedDays.add(QadaDay(day: day, month: 9, year: hijriNow.hYear));
    }
    _saveQadaData();
    update();
  }

  bool isDayMissed(int day) => missedDays.any((d) => _matchesQadaDay(d, day));
  bool isDayFasted(int day) => fastedDays.any((d) => _matchesQadaDay(d, day));

  void markDayAsFasted(int day) {
    final missed = missedDays.firstWhereOrNull((d) => _matchesQadaDay(d, day));
    if (missed != null && !isDayFasted(day)) {
      fastedDays.add(missed.copyWith(fastedDate: DateTime.now()));
      _saveQadaData();
      update();
    }
  }

  void unmarkDayAsFasted(int day) {
    fastedDays.removeWhere((d) => _matchesQadaDay(d, day));
    _saveQadaData();
    update();
  }

  int get totalMissedDays => missedDays.length;
  int get totalFastedDays => fastedDays.length;
  int get remainingQadaDays => totalMissedDays - totalFastedDays;
  double get qadaProgress =>
      totalMissedDays > 0 ? (totalFastedDays / totalMissedDays) * 100 : 0;

  // ==================== الختمات ====================

  void _loadQuranData() {
    final data = _box.read(_kRamadanStorage.quranTracker);
    if (data == null) {
      _startNewKhatma();
      return;
    }
    try {
      final tracker = QuranTracker.fromJson(json.decode(data));
      khatmas.value = tracker.khatmas;
      currentKhatmaId.value = tracker.currentKhatmaId;
      _updateCurrentJuz();
    } catch (_) {
      _startNewKhatma();
    }
  }

  void _saveQuranData() {
    final tracker = QuranTracker(
      khatmas: khatmas.toList(),
      currentKhatmaId: currentKhatmaId.value,
    );
    _box.write(_kRamadanStorage.quranTracker, json.encode(tracker.toJson()));
  }

  void _updateCurrentJuz() {
    currentJuz.value =
        khatmas
            .firstWhereOrNull((k) => k.id == currentKhatmaId.value)
            ?.completedJuz ??
        0;
  }

  void _startNewKhatma() {
    final newId = khatmas.isEmpty ? 1 : khatmas.last.id + 1;
    khatmas.add(
      QuranKhatma(
        id: newId,
        completedJuz: 0,
        startDate: DateTime.now(),
        hijriYear: hijriNow.hYear,
        hijriMonth: hijriNow.hMonth,
      ),
    );
    currentKhatmaId.value = newId;
    currentJuz.value = 0;
    _saveQuranData();
  }

  void _updateKhatma(int Function(int current) transform) {
    final index = khatmas.indexWhere((k) => k.id == currentKhatmaId.value);
    if (index == -1) return;

    final current = khatmas[index];
    final newJuz = transform(current.completedJuz).clamp(0, 30);
    if (newJuz == current.completedJuz) return;

    final updated = current.copyWith(
      completedJuz: newJuz,
      completionDate: newJuz >= 30 ? DateTime.now() : null,
    );
    khatmas[index] = updated;
    currentJuz.value = newJuz;

    if (updated.isCompleted) _startNewKhatma();
    _saveQuranData();
    update();
  }

  void incrementJuz() => _updateKhatma((c) => c + 1);
  void decrementJuz() => _updateKhatma((c) => c - 1);

  void resetQuranData() {
    _box.remove(_kRamadanStorage.quranTracker);
    khatmas.clear();
    _startNewKhatma();
    update();
  }

  int get completedKhatmasCount => khatmas.where((k) => k.isCompleted).length;
  double get khatmaProgress => (currentJuz.value / 30) * 100;

  // ==================== التنبيهات ====================

  void _loadNotificationSettings() {
    suhoorEnabled.value =
        _box.read(_kRamadanStorage.suhoorNotification) ?? false;
    iftarEnabled.value = _box.read(_kRamadanStorage.iftarNotification) ?? false;
    lastTenNightsEnabled.value =
        _box.read(_kRamadanStorage.lastTenNights) ?? false;
    suhoorMinutes.value = _box.read(_kRamadanStorage.suhoorMinutes) ?? 60;
    iftarMinutes.value = _box.read(_kRamadanStorage.iftarMinutes) ?? 30;
  }

  /// ينتظر اكتمال الجدولة/الإلغاء كي يعكس مؤشر تحميل المفتاح المدة الفعلية.
  Future<void> _toggleNotification(
    RxBool state,
    String storageKey,
    Future<void> Function() schedule,
    Future<void> Function() cancel,
    bool value,
  ) async {
    state.value = value;
    _box.write(storageKey, value);
    final operation = value ? schedule() : cancel();
    update();
    await operation;
  }

  Future<void> toggleSuhoorNotification(bool value) => _toggleNotification(
    suhoorEnabled,
    _kRamadanStorage.suhoorNotification,
    _scheduleSuhoorNotification,
    () => _cancelNotifications(_FastingNotificationType.suhoor),
    value,
  );

  Future<void> toggleIftarNotification(bool value) => _toggleNotification(
    iftarEnabled,
    _kRamadanStorage.iftarNotification,
    _scheduleIftarNotification,
    () => _cancelNotifications(_FastingNotificationType.iftar),
    value,
  );

  Future<void> toggleLastTenNightsNotification(bool value) =>
      _toggleNotification(
        lastTenNightsEnabled,
        _kRamadanStorage.lastTenNights,
        _scheduleLastTenNightsNotification,
        () => _cancelNotifications(_FastingNotificationType.lastTen),
        value,
      );

  void updateSuhoorMinutes(int minutes) {
    suhoorMinutes.value = minutes;
    _box.write(_kRamadanStorage.suhoorMinutes, minutes);
    if (suhoorEnabled.value) _scheduleSuhoorNotification();
    update();
  }

  void updateIftarMinutes(int minutes) {
    iftarMinutes.value = minutes;
    _box.write(_kRamadanStorage.iftarMinutes, minutes);
    if (iftarEnabled.value) _scheduleIftarNotification();
    update();
  }

  /// إلغاء إشعارات نوع معين
  Future<void> _cancelNotifications(_FastingNotificationType type) async {
    for (int i = 0; i < _scheduleDaysCount; i++) {
      await NotifyHelper().cancelNotification(type.baseId + i);
    }
    log('${type.name} notifications cancelled');
  }

  /// جدولة إشعار صيام
  Future<void> _scheduleFastingNotification({
    required _FastingNotificationType type,
    required DateTime Function(PrayerTimes) getTime,
    bool Function(HijriDate)? shouldSchedule,
  }) async {
    try {
      final adhanCtrl = AdhanController.instance;
      if (adhanCtrl.state.prayerTimes == null) return;

      final now = DateTime.now();

      for (int day = 0; day < _scheduleDaysCount; day++) {
        final targetDate = now.add(Duration(days: day));

        // التحقق من شرط الجدولة (للعشر الأواخر مثلاً)
        if (shouldSchedule != null) {
          final hijriDate = HijriDate.now().addDays(day);
          if (!shouldSchedule(hijriDate)) continue;
        }

        final prayerTimes = PrayerTimes(
          adhanCtrl.state.coordinates,
          DateComponents.from(targetDate),
          adhanCtrl.state.params,
        );

        final notificationTime = getTime(prayerTimes);
        if (notificationTime.isBefore(now)) continue;

        await NotifyHelper().scheduledNotification(
          reminderId: type.baseId + day,
          title: type.titleKey.tr,
          summary: 'fastingReminder'.tr,
          body: type.bodyKey.tr,
          isRepeats: false,
          time: notificationTime,
          payload: {'sound_type': 'bell'},
        );
        log(
          '${type.name} #${type.baseId + day} scheduled at $notificationTime',
        );
      }
    } catch (e) {
      log('Error scheduling ${type.name}: $e');
    }
  }

  Future<void> _scheduleSuhoorNotification() => _scheduleFastingNotification(
    type: _FastingNotificationType.suhoor,
    getTime: (pt) => pt.fajr.subtract(Duration(minutes: suhoorMinutes.value)),
  );

  Future<void> _scheduleIftarNotification() => _scheduleFastingNotification(
    type: _FastingNotificationType.iftar,
    getTime: (pt) => pt.maghrib.subtract(Duration(minutes: iftarMinutes.value)),
  );

  Future<void> _scheduleLastTenNightsNotification() =>
      _scheduleFastingNotification(
        type: _FastingNotificationType.lastTen,
        getTime: (pt) => pt.maghrib.subtract(const Duration(hours: 1)),
        shouldSchedule: (hijri) =>
            hijri.hMonth == 9 && hijri.hDay >= 21 && hijri.hDay.isOdd,
      );

  /// إعادة جدولة جميع تنبيهات الصيام
  Future<void> rescheduleFastingNotifications() async {
    log('Rescheduling fasting notifications...', name: 'RamadanController');

    // إلغاء جميع الإشعارات
    await Future.wait([
      _cancelNotifications(_FastingNotificationType.suhoor),
      _cancelNotifications(_FastingNotificationType.iftar),
      _cancelNotifications(_FastingNotificationType.lastTen),
    ]);

    // إعادة الجدولة
    final futures = <Future<void>>[];
    if (suhoorEnabled.value) {
      futures.add(_scheduleSuhoorNotification());
    }
    if (iftarEnabled.value) {
      futures.add(_scheduleIftarNotification());
    }
    if (lastTenNightsEnabled.value) {
      futures.add(_scheduleLastTenNightsNotification());
    }
    await Future.wait(futures);

    log('Fasting notifications rescheduled', name: 'RamadanController');
  }

  // ==================== المساعدات ====================

  bool get isRamadan => hijriNow.hMonth == 9;
  bool get isLastTenDays => isRamadan && hijriNow.hDay >= 21;
  bool get isOddNight => isLastTenDays && hijriNow.hDay.isOdd;
  int get ramadanDaysCount => hijriNow.getDaysInMonth(hijriNow.hYear, 9);

  void refreshHijriDate() {
    hijriNow = EventController.instance.hijriNow;
    update();
  }
}
