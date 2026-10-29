import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';

import '../domain/prayer_feature.dart';
import '../domain/prayer_feature_availability.dart';
import '../domain/prayer_feature_capabilities.dart';
import '../domain/prayer_feature_preferences.dart';
import '../domain/prayer_feature_settings.dart';
import '../domain/prayer_feature_settings_repository.dart';
import '../domain/prayer_id.dart';
import '../domain/prayer_override.dart';
import '../domain/save_prayer_feature_settings.dart';
import 'prayer_feature_settings_state.dart';

class PrayerFeatureSettingsController extends GetxController {
  PrayerFeatureSettingsController({
    required this.repository,
    required this.capabilities,
    required this.save,
    this.refreshAvailability,
    this.onSaved,
  });

  final PrayerFeatureSettingsRepository repository;
  final PrayerFeatureCapabilities capabilities;
  final SavePrayerFeatureSettings save;

  /// يجدّد حالة الإتاحة غير المتزامنة (مثل إذن الإشعارات) عند فتح
  /// الإعدادات؛ تُحدَّث الواجهة فور اكتمال التحديث.
  final Future<void> Function()? refreshAvailability;

  /// أثر جانبي بعد نجاح الحفظ فقط (مزامنة جدولة التذكيرات)؛ فشله لا
  /// يُرجع الإعداد المحفوظ.
  final Future<void> Function(
    PrayerFeatureSettings previous,
    PrayerFeatureSettings next,
  )?
  onSaved;

  PrayerFeatureSettingsState _state = PrayerFeatureSettingsState(
    settings: PrayerFeatureSettings(),
  );
  PrayerFeatureSettingsState get state => _state;
  bool get canEdit => !_state.saving && !_state.loadFailed;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  PrayerFeatureAvailability availability(PrayerFeature feature) =>
      capabilities.availability(feature);

  bool canToggle(PrayerFeature feature) =>
      canEdit && availability(feature) == PrayerFeatureAvailability.available;

  bool isEnabled(PrayerFeature feature) =>
      _state.settings[feature].enabled &&
      availability(feature) == PrayerFeatureAvailability.available;

  void reload() {
    if (_state.saving) return;
    unawaited(_refreshAvailabilityThenUpdate());
    try {
      var loaded = repository.read();
      // Never display or later persist enabled flags for unfinished features,
      // e.g. after restoring settings from a different build/platform.
      for (final feature in PrayerFeature.values) {
        if (availability(feature) != PrayerFeatureAvailability.available) {
          loaded = loaded.withPreference(
            feature,
            loaded[feature].copyWith(enabled: false),
          );
        }
      }
      _state = PrayerFeatureSettingsState(settings: loaded);
    } catch (error, stack) {
      log(
        'Could not read prayer feature settings',
        error: error,
        stackTrace: stack,
      );
      _state = PrayerFeatureSettingsState(
        settings: _state.settings,
        loadFailed: true,
        errorKey: 'prayerFeaturesLoadError',
      );
    }
    update();
  }

  Future<void> _refreshAvailabilityThenUpdate() async {
    final refresh = refreshAvailability;
    if (refresh == null) return;
    try {
      await refresh();
    } catch (error, stack) {
      log(
        'Could not refresh feature availability',
        error: error,
        stackTrace: stack,
      );
    }
    if (!isClosed) update();
  }

  Future<void> setEnabled(PrayerFeature feature, bool enabled) async {
    if (!canEdit) return;
    if (enabled && !canToggle(feature)) {
      _state = PrayerFeatureSettingsState(
        settings: _state.settings,
        errorKey: 'prayerFeaturesUnavailable',
      );
      update();
      return;
    }
    await _change(feature, _state.settings[feature].copyWith(enabled: enabled));
  }

  Future<void> adjustMinutes(
    PrayerFeature feature,
    int delta, {
    PrayerId? prayer,
  }) async {
    if (!canEdit || !feature.hasTiming) return;
    final current = _state.settings[feature];
    final oldMinutes = prayer == null
        ? current.minutes!
        : current.minutesFor(prayer)!;
    final minutes = (oldMinutes + delta).clamp(1, feature.maxMinutes!);
    if (minutes == oldMinutes) return;
    final next = prayer == null
        ? current.copyWith(minutes: minutes)
        : current.withOverride(
            prayer,
            PrayerOverride(
              enabled: current.includesPrayer(prayer),
              minutes: minutes,
            ),
          );
    await _change(feature, next);
  }

  Future<void> setPrayerIncluded(
    PrayerFeature feature,
    PrayerId prayer,
    bool included,
  ) async {
    if (!canEdit || !feature.hasTiming) return;
    final current = _state.settings[feature];
    await _change(
      feature,
      current.withOverride(
        prayer,
        PrayerOverride(
          enabled: included,
          minutes: current.overrides[prayer]?.minutes,
        ),
      ),
    );
  }

  /// Removes both the exclusion and the custom duration for this prayer.
  Future<void> resetPrayer(PrayerFeature feature, PrayerId prayer) async {
    if (!canEdit || !feature.hasTiming) return;
    await _change(feature, _state.settings[feature].withOverride(prayer, null));
  }

  Future<void> _change(
    PrayerFeature feature,
    PrayerFeaturePreferences preference,
  ) async {
    if (!canEdit) return;
    final previous = _state.settings;
    final next = previous.withPreference(feature, preference);
    _state = PrayerFeatureSettingsState(settings: previous, saving: true);
    update();
    var saved = false;
    try {
      await save(next);
      _state = PrayerFeatureSettingsState(settings: next);
      saved = true;
    } catch (error, stack) {
      log(
        'Could not save prayer feature settings',
        error: error,
        stackTrace: stack,
      );
      _state = PrayerFeatureSettingsState(
        settings: previous,
        errorKey: 'prayerFeaturesSaveError',
      );
    }
    if (saved && onSaved != null) {
      try {
        await onSaved!(previous, next);
      } catch (error, stack) {
        log(
          'Prayer feature settings saved but side effects failed',
          error: error,
          stackTrace: stack,
        );
      }
    }
    if (!isClosed) update();
  }
}
