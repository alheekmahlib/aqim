import 'dart:async' show TimeoutException;
import 'dart:developer' show log;
import 'dart:io' show Platform;

import 'package:adhan/adhan.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../presentation/prayers/prayers.dart';
import '../utils/constants/extensions/convert_number_extension.dart';
import '../utils/constants/shared_preferences_constants.dart';
import '../utils/helpers/date_formatter.dart';
import 'local_notifications_service.dart';
import 'prayer_countdown_payload.dart';

/// الإشعار الدائم للعدّ التنازلي لوقت الصلاة القادمة والوقت المضى على
/// السابقة — بنفس محتوى البطاقة على المنصتين:
///
/// أندرويد — إشعار ongoing بتخطيط مخصص (RemoteViews) بعدّادَي Chronometer
/// أصليين يحدّثهما النظام كل ثانية: تنازلي حتى القادمة وتصاعدي منذ
/// السابقة (صفر بطارية، ويعمل بعد قتل التطبيق وفي وضع Doze). إعادة
/// النشر بحقول جديدة تحدث لحظة كل حدّ صلاة عبر منبّهات أصلية دقيقة
/// (CountdownNotificationReceiver) حتى لو قُتل التطبيق.
///
/// iOS — Live Activity على شاشة القفل والجزيرة الديناميكية، وعدّاداه
/// يرسلهما النظام ذاتيًا عبر Text(timerInterval:).
///
/// لا تحديثات دورية من التطبيق على أي منصة بين حدود الصلوات.
class PrayerCountdownNotificationService {
  PrayerCountdownNotificationService._();

  static final PrayerCountdownNotificationService instance =
      PrayerCountdownNotificationService._();

  static const String _tag = 'PrayerCountdown';

  /// قناة الطبقة الأصلية: أندرويد (RemoteViews + حدود المنبّهات) وiOS
  /// (Live Activity).
  static const MethodChannel _channel = MethodChannel(
    'com.alheekmah.aqimApp/prayer_countdown',
  );

  /// مهلة استدعاءات القناة الأصلية: في محرك الخلفية (headless) على
  /// أندرويد لا يوجد معالج للقناة، وبدون مهلة يعلّق الاستدعاء للأبد.
  static const Duration _channelTimeout = Duration(seconds: 2);

  /// نافذة الأيام التي تُبنى منها الخانات المطلقة (أمس/اليوم/الغد).
  static const List<int> _dayOffsets = [-1, 0, 1];

  final GetStorage _box = GetStorage();
  bool _refreshing = false;

  bool get _platformSupported => Platform.isAndroid || Platform.isIOS;

  bool get isEnabled =>
      _box.read<bool>(PRAYER_COUNTDOWN_NOTIFICATION_ENABLED) ?? false;

  /// تفعيل/تعطيل الميزة من مفتاح الإعدادات.
  Future<void> setEnabled(bool value) async {
    await _box.write(PRAYER_COUNTDOWN_NOTIFICATION_ENABLED, value);
    if (!value) {
      await disable();
      return;
    }
    // الأذونات شرط العرض؛ نطلبها ونكمل حتى لو رُفضت (يقرر النظام).
    final granted = await LocalNotificationsService.instance
        .requestPermissions();
    if (!granted) {
      log('Notifications permission not granted', name: _tag);
    }
    await refresh();
  }

  /// إخفاء الإشعار/النشاط وإلغاء كل المنبّهات الأصلية المرتبطة به.
  Future<void> disable() async {
    if (_platformSupported) {
      try {
        await _channel.invokeMethod('cancel').timeout(_channelTimeout);
      } catch (e) {
        log('Native cancel failed: $e', name: _tag);
      }
    }
  }

  /// إعادة بناء كاملة: تسليم الحالة الراهنة وحدود الغد للطبقة الأصلية
  /// في استدعاء واحد. تُستدعى عند: التفعيل، تغيّر الأوقات/اللغة، فتح
  /// التطبيق، عبور حدّ صلاة، والمهام الدورية في الخلفية. لا حاجة
  /// لأي استدعاءات بين الحدود — العدّادان أصليان نابضان.
  Future<void> refresh() async {
    if (!isEnabled || !_platformSupported) return;
    if (_refreshing) return;
    _refreshing = true;
    try {
      final state = AdhanController.instance.state;
      if (!state.isPrayerTimesInitialized.value) return;

      final slots = _buildSlots();
      if (slots == null) return;

      final now = DateTime.now();
      final snapshot = computeCountdownSnapshot(slots: slots, now: now);
      final next = snapshot.next;
      if (next == null) return;

      final entries = buildBoundaryEntries(
        slots: slots,
        now: now,
        buildData: _buildDisplayData,
      );
      if (Platform.isIOS) {
        await _syncLiveActivity(snapshot, next, entries);
        return;
      }
      try {
        await _channel
            .invokeMethod('syncBoundaries', {
              'refreshLabel': 'countdownRefresh'.tr,
              'current': _currentDisplayData(snapshot, next).toMap(),
              'entries': entries.map((e) => e.toMap()).toList(),
            })
            .timeout(_channelTimeout);
      } on TimeoutException {
        // محرك الخلفية بلا معالج قناة؛ المنبّهات تبقى من آخر تسليح.
        log('syncBoundaries timed out (headless engine?)', name: _tag);
      } catch (e) {
        log('syncBoundaries failed: $e', name: _tag);
      }
    } catch (e) {
      log('refresh failed: $e', name: _tag);
    } finally {
      _refreshing = false;
    }
  }

  /// تغيّرت لغة الواجهة: النصوص مخبأة سلفًا فلا بد من إعادة بنائها.
  Future<void> onLocaleChanged() async {
    await refresh();
  }

  // ─── iOS: Live Activity ───

  Future<void> _syncLiveActivity(
    CountdownSnapshot snapshot,
    CountdownSlot next,
    List<CountdownBoundaryEntry> entries,
  ) async {
    final data = _currentDisplayData(snapshot, next);
    try {
      await _channel
          .invokeMethod('syncActivity', {
            'nextName': data.nextName,
            'nextAtMillis': data.nextAt.millisecondsSinceEpoch,
            'nextTimeText': data.nextTime,
            'prevName': data.prevName,
            'prevAtMillis': data.prevAt?.millisecondsSinceEpoch,
            'nextLabel': data.nextLabel,
            'elapsedLabel': data.elapsedLabel,
            'entries': entries.map((e) => e.toMap()).toList(),
            'refreshLabel': 'countdownRefresh'.tr,
          })
          .timeout(_channelTimeout);
    } on TimeoutException {
      log('syncActivity timed out', name: _tag);
    } catch (e) {
      log('syncActivity failed: $e', name: _tag);
    }
  }

  // ─── بناء بيانات العرض ───

  /// «الصلاة القادمة» للصلوات الخمس، و«الوقت القادم» لبقية الخانات
  /// (الشروق ومنتصف الليل والثلث الأخير ليست صلوات).
  String _nextLabelFor(int slotIndex) => isPrayerSlot(slotIndex)
      ? 'countdownNextLabel'.tr
      : 'countdownNextEventLabel'.tr;

  CountdownDisplayData _currentDisplayData(
    CountdownSnapshot snapshot,
    CountdownSlot next,
  ) {
    final prev = snapshot.prev;
    return CountdownDisplayData(
      nextLabel: _nextLabelFor(next.index),
      nextName: _slotTitle(next.index),
      nextTime: _formatTime(next.at),
      nextAt: next.at,
      elapsedLabel: 'countdownElapsedLabel'.tr,
      prevName: prev == null ? _slotTitle(next.index) : _slotTitle(prev.index),
      prevAt: prev?.at,
    );
  }

  /// بيانات العرض بعد حدّ [justStarted]: القادمة تصبح [next] والعدّاد
  /// التصاعدي يبدأ من صفر منذ لحظة الحدّ.
  CountdownDisplayData _buildDisplayData(
    CountdownSlot justStarted,
    CountdownSlot next,
  ) {
    return CountdownDisplayData(
      nextLabel: _nextLabelFor(next.index),
      nextName: _slotTitle(next.index),
      nextTime: _formatTime(next.at),
      nextAt: next.at,
      elapsedLabel: 'countdownElapsedLabel'.tr,
      prevName: _slotTitle(justStarted.index),
      prevAt: justStarted.at,
    );
  }

  // ─── بناء الخانات المطلقة ───

  /// يبني 24 خانة مطلقة (أمس/اليوم/الغد × 8 خانات) بأوقات حساب أذان
  /// نفسه (إحداثيات ومعايير الحالة)، أو null إن لم تتهيأ البيانات.
  List<CountdownSlot>? _buildSlots() {
    try {
      final state = AdhanController.instance.state;
      final slots = <CountdownSlot>[];
      final today = DateTime.now();
      for (final offset in _dayOffsets) {
        final day = today.add(Duration(days: offset));
        final times = PrayerTimes(
          state.coordinates,
          DateComponents(day.year, day.month, day.day),
          state.params,
        );
        final sunnah = SunnahTimes(times);
        final dayTimes = [
          times.fajr,
          times.sunrise,
          times.dhuhr,
          times.asr,
          times.maghrib,
          times.isha,
          sunnah.middleOfTheNight,
          sunnah.lastThirdOfTheNight,
        ];
        for (var i = 0; i < dayTimes.length; i++) {
          slots.add(CountdownSlot(index: i, at: dayTimes[i]));
        }
      }
      return normalizeSlots(slots);
    } catch (e) {
      log('buildSlots failed: $e', name: _tag);
      return null;
    }
  }

  // ─── النصوص المترجمة ───

  static const List<String> _fallbackTitles = [
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
    'middleOfTheNight',
    'lastThirdOfTheNight',
  ];

  String _slotTitle(int index) {
    try {
      final list = AdhanController.instance.prayerNameList;
      if (list.isNotEmpty && index < list.length) {
        return '${list[index]['title']!}'.tr;
      }
    } catch (_) {}
    return _fallbackTitles[index].tr;
  }

  String _formatTime(DateTime at) =>
      DateFormatter.formatPrayerTime(at).convertNumbersToCurrentLang();
}
