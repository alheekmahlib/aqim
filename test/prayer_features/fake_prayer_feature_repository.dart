import 'dart:async';

import 'package:aqim/presentation/prayers/features/domain/prayer_feature_settings.dart';
import 'package:aqim/presentation/prayers/features/domain/prayer_feature_settings_repository.dart';

class FakePrayerFeatureRepository implements PrayerFeatureSettingsRepository {
  PrayerFeatureSettings stored = PrayerFeatureSettings();
  bool failRead = false;
  bool failSave = false;
  int saves = 0;
  Completer<void>? pendingSave;

  @override
  PrayerFeatureSettings read() {
    if (failRead) throw StateError('read failed');
    return stored;
  }

  @override
  Future<void> save(PrayerFeatureSettings settings) async {
    saves++;
    if (pendingSave != null) await pendingSave!.future;
    if (failSave) throw StateError('save failed');
    stored = settings;
  }
}
