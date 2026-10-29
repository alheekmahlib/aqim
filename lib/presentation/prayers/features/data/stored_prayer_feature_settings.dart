import 'package:get_storage/get_storage.dart';

import '../domain/prayer_feature_settings.dart';
import '../domain/prayer_feature_settings_repository.dart';
import 'prayer_feature_settings_codec.dart';

class StoredPrayerFeatureSettings implements PrayerFeatureSettingsRepository {
  const StoredPrayerFeatureSettings(
    this._storage, {
    this._codec = const PrayerFeatureSettingsCodec(),
  });

  static const storageKey = 'prayer_features_settings_v1';
  final GetStorage _storage;
  final PrayerFeatureSettingsCodec _codec;

  @override
  PrayerFeatureSettings read() => _codec.decode(_storage.read(storageKey));

  @override
  Future<void> save(PrayerFeatureSettings settings) async {
    final previous = _storage.read<Object?>(storageKey);
    try {
      await _storage.write(storageKey, _codec.encode(settings));
    } catch (_) {
      // GetStorage updates its in-memory value before attempting persistence.
      _storage.writeInMemory(storageKey, previous);
      rethrow;
    }
  }
}
