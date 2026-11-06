part of 'locations.dart';

class Location {
  static final Location instance = Location._();
  String _city = '';
  String _country = '';
  Position? _position;
  static final GetStorage _storage = GetStorage();

  factory Location() {
    return instance;
  }

  Location._();

  /// Update the coordinates without assigning the previous place's address.
  void updateCoordinates(double latitude, double longitude) {
    updateLocation(
      city: '',
      country: '',
      position: Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
    );
  }

  /// تحديث الموقع وحفظه في التخزين
  /// Update location and save to storage
  void updateLocation({
    required String city,
    required String country,
    required Position position,
  }) {
    _city = city;
    _country = country;
    _position = position;

    // حفظ البيانات في التخزين
    // Save data to storage
    _storage.write(CURRENT_LOCATION, {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'city': city,
      'country': country,
      'timestamp': DateTime.now().toIso8601String(),
    });

    log('Location updated: $city, $country (${position.latitude}, ${position.longitude})',
        name: 'Location');
  }

  /// استرداد الموقع من التخزين عند بدء التطبيق
  /// Restore location from storage on app start
  void restoreFromStorage() {
    try {
      final storedLocation = _storage.read(CURRENT_LOCATION);
      if (storedLocation is Map) {
        final locationMap = Map<String, dynamic>.from(storedLocation);

        _city = (locationMap['city'] ?? '').toString();
        _country = (locationMap['country'] ?? '').toString();

        // استرداد Position إذا كانت البيانات متوفرة
        // Restore Position if data is available
        final lat = locationMap['latitude'];
        final lng = locationMap['longitude'];
        if (lat != null && lng != null) {
          final latDouble =
              lat is num ? lat.toDouble() : double.tryParse('$lat');
          final lngDouble =
              lng is num ? lng.toDouble() : double.tryParse('$lng');
          if (latDouble == null || lngDouble == null) return;

          _position = Position(
            latitude: latDouble,
            longitude: lngDouble,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        }
      }
    } catch (e) {
      log('Error restoring location from storage: $e', name: 'Location');
    }
  }

  String get city => _city;
  String get country => _country;
  Position? get position => _position;
}
