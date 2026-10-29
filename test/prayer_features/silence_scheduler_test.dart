import 'package:aqim/presentation/prayers/features/data/local_prayer_silence_scheduler.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature_preferences.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_id.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingSilenceDeps {
  _RecordingSilenceDeps({this.supported = true});

  final bool supported;
  final syncedPeriods = <List<Map<String, int>>>[];
  int endAndCancelCalls = 0;

  final iqamaTimes = <PrayerId, DateTime>{
    PrayerId.fajr: DateTime(2026, 10, 29, 5),
    PrayerId.dhuhr: DateTime(2026, 10, 29, 12),
    PrayerId.asr: DateTime(2026, 10, 29, 15),
    PrayerId.maghrib: DateTime(2026, 10, 29, 18),
    PrayerId.isha: DateTime(2026, 10, 29, 20),
  };

  LocalPrayerSilenceScheduler build() => LocalPrayerSilenceScheduler(
    iqamaTimeFor: (prayer, dayOffset) =>
        dayOffset == 0 ? iqamaTimes[prayer] : null,
    daysToSchedule: () => 1,
    isSupported: () => supported,
    syncPeriods: (periods) async => syncedPeriods.add(periods),
    endAndCancel: () async => endAndCancelCalls++,
    now: () => DateTime(2026, 10, 29, 0),
  );
}

void main() {
  test('synchronize hands merged period millis to the native layer', () async {
    final deps = _RecordingSilenceDeps();
    await deps.build().synchronize(
      PrayerFeaturePreferences(enabled: true, minutes: 20),
    );

    expect(deps.syncedPeriods, hasLength(1));
    final periods = deps.syncedPeriods.single;
    expect(periods, hasLength(5));
    expect(
      periods.first['start'],
      DateTime(2026, 10, 29, 5).millisecondsSinceEpoch,
    );
    expect(
      periods.first['end'],
      DateTime(2026, 10, 29, 5, 20).millisecondsSinceEpoch,
    );
    expect(deps.endAndCancelCalls, 0);
  });

  test('disabled preference ends and cancels native scheduling', () async {
    final deps = _RecordingSilenceDeps();
    await deps.build().synchronize(
      PrayerFeaturePreferences(enabled: false, minutes: 20),
    );
    expect(deps.syncedPeriods, isEmpty);
    expect(deps.endAndCancelCalls, 1);
  });

  test(
    'unsupported platform is a silent no-op without channel calls',
    () async {
      final deps = _RecordingSilenceDeps(supported: false);
      final scheduler = deps.build();
      await scheduler.synchronize(
        PrayerFeaturePreferences(enabled: true, minutes: 20),
      );
      await scheduler.endAndCancelSilence();
      expect(deps.syncedPeriods, isEmpty);
      expect(deps.endAndCancelCalls, 0);
    },
  );
}
