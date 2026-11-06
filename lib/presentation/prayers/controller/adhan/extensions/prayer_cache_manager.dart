part of '../../../prayers.dart';

/// مدير التخزين المؤقت لأوقات الصلاة
/// Prayer times cache manager
class PrayerCacheManager {
  static const String _tag = 'PrayerCacheManager';
  static const String _prayerLocationKey = 'PRAYER_TIME_LOCATION_V2';
  static final GetStorage _storage = GetStorage();

  /// التحقق من صحة البيانات المخزنة
  /// Check if cached data is valid
  static bool isCacheValid({LatLng? currentLocation}) {
    try {
      // التحقق من وجود البيانات الأساسية
      // Check for basic data existence
      final storedDate = _storage.read(PRAYER_TIME_DATE);
      final storedPrayerTimes = _storage.read(PRAYER_TIME);
      final locationForPrayer = _storage.read(_prayerLocationKey);
      final legacyData = locationForPrayer == null && storedPrayerTimes is String
          ? jsonDecode(storedPrayerTimes)
          : null;
      final storedLocation = locationForPrayer ?? legacyData;

      if (storedDate == null || storedPrayerTimes == null) {
        log('Missing basic prayer data', name: _tag);
        return false;
      }

      // التحقق من التاريخ
      // Check date validity
      if (!_isDateValid(storedDate)) {
        log('Date is not current', name: _tag);
        return false;
      }

      // التحقق من الموقع إذا تم توفيره
      // Check location if provided
      if (currentLocation != null &&
          !_isLocationValid(storedLocation, currentLocation)) {
        log('Location has changed significantly', name: _tag);
        return false;
      }

      return true;
    } catch (e) {
      log('Error checking cache validity: $e', name: _tag);
      return false;
    }
  }

  /// التحقق من صحة التاريخ
  /// Check if date is valid (same day)
  static bool _isDateValid(String storedDate) {
    try {
      final lastUpdate = DateTime.parse(storedDate);
      final now = DateTime.now();

      return lastUpdate.year == now.year &&
          lastUpdate.month == now.month &&
          lastUpdate.day == now.day;
    } catch (e) {
      return false;
    }
  }

  /// التحقق من صحة الموقع
  /// Check if location is valid (within threshold)
  static bool _isLocationValid(dynamic storedLocation, LatLng currentLocation) {
    try {
      if (storedLocation is! Map ||
          !storedLocation.containsKey('latitude') ||
          !storedLocation.containsKey('longitude')) {
        return false;
      }

      final locationMap = Map<String, dynamic>.from(storedLocation);

      final storedLat = locationMap['latitude']?.toDouble();
      final storedLng = locationMap['longitude']?.toDouble();

      if (storedLat == null || storedLng == null) {
        return false;
      }

      // التحقق من المسافة (0.01 درجة تقريباً 1 كم)
      // Check distance (0.01 degree ≈ 1km)
      const threshold = 0.01;
      final latDiff = (storedLat - currentLocation.latitude).abs();
      final lngDiff = (storedLng - currentLocation.longitude).abs();

      return latDiff <= threshold && lngDiff <= threshold;
    } catch (e) {
      return false;
    }
  }

  /// الحصول على البيانات المخزنة
  /// Get cached prayer data
  static Map<String, dynamic>? getCachedPrayerData() {
    try {
      final storedData = _storage.read(PRAYER_TIME);
      if (storedData != null) {
        return jsonDecode(storedData) as Map<String, dynamic>;
      }
    } catch (e) {
      log('Error getting cached data: $e', name: _tag);
    }
    return null;
  }

  /// حفظ بيانات الصلاة
  /// Save prayer data to cache
  static void savePrayerData(
      Map<String, dynamic> prayerData, LatLng? location) {
    try {
      final now = DateTime.now();

      // حفظ بيانات الصلاة
      // Save prayer data
      _storage.write(PRAYER_TIME, jsonEncode(prayerData));
      _storage.write(PRAYER_TIME_DATE, now.toIso8601String());

      // حفظ الموقع إذا تم توفيره
      // Save location if provided
      if (location != null) {
        _storage.write(_prayerLocationKey, {
          'latitude': location.latitude,
          'longitude': location.longitude,
        });
        final existing = _storage.read(CURRENT_LOCATION);
        final merged = (existing is Map)
            ? Map<String, dynamic>.from(existing)
            : <String, dynamic>{};

        merged['latitude'] = location.latitude;
        merged['longitude'] = location.longitude;

        _storage.write(CURRENT_LOCATION, merged);
      }

      log('Prayer data saved successfully', name: _tag);
    } catch (e) {
      log('Error saving prayer data: $e', name: _tag);
    }
  }

  /// مسح البيانات المخزنة
  /// Clear cached data
  static void clearCache() {
    try {
      _storage.remove(PRAYER_TIME_DATE);
      _storage.remove(PRAYER_TIME);
      _storage.remove(_prayerLocationKey);
      log('Cache cleared successfully', name: _tag);
    } catch (e) {
      log('Error clearing cache: $e', name: _tag);
    }
  }

  /// الحصول على الموقع المخزن
  /// Get stored location
  static LatLng? getStoredLocation() {
    try {
      final storedLocation = _storage.read(CURRENT_LOCATION);
      if (storedLocation is Map &&
          storedLocation.containsKey('latitude') &&
          storedLocation.containsKey('longitude')) {
        final locationMap = Map<String, dynamic>.from(storedLocation);
        return LatLng(
          locationMap['latitude']?.toDouble() ?? 0.0,
          locationMap['longitude']?.toDouble() ?? 0.0,
        );
      }
    } catch (e) {
      log('Error getting stored location: $e', name: _tag);
    }
    return null;
  }

  /// إحصائيات التخزين المؤقت
  /// Cache statistics
  static Map<String, dynamic> getCacheStats() {
    final storedDate = _storage.read(PRAYER_TIME_DATE);
    final storedLocation = _storage.read(CURRENT_LOCATION);
    final hasPrayerData = _storage.hasData(PRAYER_TIME);

    return {
      'hasData': hasPrayerData,
      'lastUpdate': storedDate,
      'location': storedLocation,
      'isValid': isCacheValid(),
    };
  }
}
