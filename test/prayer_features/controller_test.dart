import 'dart:async';

import 'package:aqim/presentation/prayers/features/data/pending_prayer_feature_capabilities.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature_availability.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature_settings.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_id.dart';
import 'package:aqim/presentation/prayers/features/domain/save_prayer_feature_settings.dart';
import 'package:aqim/presentation/prayers/features/presentation/prayer_feature_settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_prayer_feature_capabilities.dart';
import 'fake_prayer_feature_repository.dart';

void main() {
  PrayerFeatureSettingsController create(
    FakePrayerFeatureRepository repository,
    FakePrayerFeatureCapabilities capabilities,
  ) => PrayerFeatureSettingsController(
    repository: repository,
    capabilities: capabilities,
    save: SavePrayerFeatureSettings(repository, capabilities),
  )..onInit();

  test(
    'settings survive controller recreation; reset restores inheritance',
    () async {
      final repo = FakePrayerFeatureRepository();
      final caps = FakePrayerFeatureCapabilities();
      final controller = create(repo, caps);
      await controller.adjustMinutes(PrayerFeature.silence, 5);
      await controller.adjustMinutes(
        PrayerFeature.silence,
        10,
        prayer: PrayerId.fajr,
      );
      await controller.setPrayerIncluded(
        PrayerFeature.silence,
        PrayerId.fajr,
        false,
      );
      await controller.adjustMinutes(PrayerFeature.reminder, 3);
      final restored = create(repo, caps);
      expect(restored.state.settings[PrayerFeature.silence].minutes, 25);
      expect(
        restored.state.settings[PrayerFeature.silence].minutesFor(
          PrayerId.fajr,
        ),
        35,
      );
      expect(
        restored.state.settings[PrayerFeature.silence].includesPrayer(
          PrayerId.fajr,
        ),
        isFalse,
      );
      expect(restored.state.settings[PrayerFeature.reminder].minutes, 13);
      await restored.resetPrayer(PrayerFeature.silence, PrayerId.fajr);
      await restored.adjustMinutes(PrayerFeature.silence, 1);
      expect(
        restored.state.settings[PrayerFeature.silence].minutesFor(
          PrayerId.fajr,
        ),
        26,
      );
      expect(
        restored.state.settings[PrayerFeature.silence].includesPrayer(
          PrayerId.fajr,
        ),
        isTrue,
      );
    },
  );

  test(
    'onSaved fires with previous and next settings only after a saved change',
    () async {
      final repo = FakePrayerFeatureRepository();
      final caps = FakePrayerFeatureCapabilities(
        value: PrayerFeatureAvailability.available,
      );
      final calls = <String>[];
      final controller = PrayerFeatureSettingsController(
        repository: repo,
        capabilities: caps,
        save: SavePrayerFeatureSettings(repo, caps),
        onSaved: (previous, next) async {
          calls.add(
            '${previous[PrayerFeature.reminder].enabled}'
            '>${next[PrayerFeature.reminder].enabled}',
          );
        },
      )..onInit();

      await controller.setEnabled(PrayerFeature.reminder, true);
      expect(calls, ['false>true']);
      await controller.adjustMinutes(PrayerFeature.reminder, 5);
      expect(calls, ['false>true', 'true>true']);
    },
  );

  test('unfinished features stay off but durations can be prepared', () async {
    final repo = FakePrayerFeatureRepository();
    final caps = FakePrayerFeatureCapabilities(
      value: PrayerFeatureAvailability.comingSoon,
    );
    final controller = create(repo, caps);
    for (final feature in PrayerFeature.values) {
      await controller.setEnabled(feature, true);
      expect(controller.isEnabled(feature), isFalse);
      expect(controller.canToggle(feature), isFalse);
    }
    expect(repo.saves, 0);
    await controller.adjustMinutes(PrayerFeature.reminder, 2);
    expect(repo.stored[PrayerFeature.reminder].minutes, 12);
    expect(controller.state.errorKey, isNull);
  });

  test(
    'read failure prevents overwriting saved settings until retry succeeds',
    () async {
      final repo = FakePrayerFeatureRepository()..failRead = true;
      final controller = create(repo, FakePrayerFeatureCapabilities());
      expect(controller.state.loadFailed, isTrue);
      await controller.adjustMinutes(PrayerFeature.silence, 1);
      expect(repo.saves, 0);
      repo.failRead = false;
      controller.reload();
      await controller.adjustMinutes(PrayerFeature.silence, 1);
      expect(repo.stored[PrayerFeature.silence].minutes, 21);
    },
  );

  test('failed writes retain prior state and can be retried', () async {
    final repo = FakePrayerFeatureRepository()..failSave = true;
    final controller = create(repo, FakePrayerFeatureCapabilities());
    await controller.adjustMinutes(PrayerFeature.silence, 1);
    expect(controller.state.settings[PrayerFeature.silence].minutes, 20);
    expect(controller.state.errorKey, 'prayerFeaturesSaveError');
    expect(controller.canEdit, isTrue);
    repo.failSave = false;
    await controller.adjustMinutes(PrayerFeature.silence, 1);
    expect(controller.state.settings[PrayerFeature.silence].minutes, 21);
    expect(controller.state.errorKey, isNull);
  });

  test(
    'pending save blocks competing edits and does not report early success',
    () async {
      final repo = FakePrayerFeatureRepository()
        ..pendingSave = Completer<void>();
      final controller = create(repo, FakePrayerFeatureCapabilities());
      final pending = controller.adjustMinutes(PrayerFeature.silence, 1);
      expect(controller.state.saving, isTrue);
      expect(controller.state.settings[PrayerFeature.silence].minutes, 20);
      await controller.adjustMinutes(PrayerFeature.reminder, 5);
      expect(repo.saves, 1);
      repo.pendingSave!.complete();
      await pending;
      expect(controller.state.settings[PrayerFeature.silence].minutes, 21);
      expect(controller.state.settings[PrayerFeature.reminder].minutes, 10);
    },
  );

  test(
    'bounds clamp safely and unsupported restored flags are not enabled',
    () async {
      final repo = FakePrayerFeatureRepository();
      var settings = PrayerFeatureSettings();
      settings = settings.withPreference(
        PrayerFeature.silence,
        settings[PrayerFeature.silence].copyWith(enabled: true),
      );
      repo.stored = settings;
      final controller = create(
        repo,
        FakePrayerFeatureCapabilities(
          value: PrayerFeatureAvailability.unsupported,
        ),
      );
      expect(controller.isEnabled(PrayerFeature.silence), isFalse);
      await controller.adjustMinutes(PrayerFeature.silence, 500);
      expect(repo.stored[PrayerFeature.silence].minutes, 120);
      expect(repo.stored[PrayerFeature.silence].enabled, isFalse);
      await controller.adjustMinutes(PrayerFeature.reminder, -50);
      expect(repo.stored[PrayerFeature.reminder].minutes, 1);
    },
  );

  test(
    'platform policy never reports native functionality ready in stage 1',
    () {
      for (final platform in ['android', 'ios', 'macos', 'other']) {
        final caps = PendingPrayerFeatureCapabilities(
          isAndroid: platform == 'android',
          isIOS: platform == 'ios',
          isMacOS: platform == 'macos',
        );
        for (final feature in PrayerFeature.values) {
          expect(
            caps.availability(feature),
            isNot(PrayerFeatureAvailability.available),
          );
        }
        expect(
          caps.availability(PrayerFeature.silence),
          platform == 'android'
              ? PrayerFeatureAvailability.comingSoon
              : PrayerFeatureAvailability.unsupported,
        );
      }
    },
  );
}
