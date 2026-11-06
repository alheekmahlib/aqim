part of 'locations.dart';

class NominatimReverseGeocodingService {
  NominatimReverseGeocodingService._();

  static final NominatimReverseGeocodingService instance =
      NominatimReverseGeocodingService._();

  static const String _cacheKey = 'NOMINATIM_REVERSE_CACHE_V1';
  static const String _lastRequestKey = 'NOMINATIM_REVERSE_LAST_REQUEST_MS_V1';

  static const Duration _minRequestInterval = Duration(milliseconds: 1100);

  final GetStorage _box = GetStorage();

  Future<({String city, String country})> reverse({
    required double latitude,
    required double longitude,
    String? languageCode,
  }) async {
    final lang = (languageCode ?? 'en').toLowerCase();
    final cacheId = _buildCacheId(latitude, longitude, lang);

    final cached = _readCache(cacheId);
    if (cached != null) {
      return cached;
    }

    await _respectRateLimit();

    final response =
        await Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        ).get(
          'https://nominatim.openstreetmap.org/reverse',
          queryParameters: {
            'format': 'json',
            'lat': latitude,
            'lon': longitude,
            'addressdetails': '1',
            'accept-language': lang,
          },
          options: Options(
            headers: const {
              'User-Agent': 'Aqim/1.0 (contact: haozo89@gmail.com)',
            },
          ),
        );

    if (response.statusCode != 200 || response.data is! Map) {
      throw LocationException('Nominatim reverse geocoding failed');
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    final address = (data['address'] is Map)
        ? Map<String, dynamic>.from(data['address'] as Map)
        : <String, dynamic>{};

    final city = _pickFirstNonEmpty([
      address['city'],
      address['town'],
      address['village'],
      address['municipality'],
      address['suburb'],
      address['city_district'],
      address['state_district'],
      address['county'],
      address['state'],
    ]);

    final country = _pickFirstNonEmpty([address['country']]);

    final result = (
      city: city.isNotEmpty ? city : 'Unknown',
      country: country.isNotEmpty ? country : 'Unknown',
    );

    _writeCache(cacheId, result);

    return result;
  }

  String _buildCacheId(double lat, double lon, String lang) {
    final roundedLat = _roundTo(lat, 4);
    final roundedLon = _roundTo(lon, 4);
    return '$roundedLat,$roundedLon:$lang';
  }

  double _roundTo(double value, int decimals) {
    final factor = math.pow(10, decimals).toDouble();
    return (value * factor).round() / factor;
  }

  ({String city, String country})? _readCache(String cacheId) {
    final raw = _box.read(_cacheKey);
    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);
    final entry = map[cacheId];
    if (entry is! Map) return null;

    final entryMap = Map<String, dynamic>.from(entry);
    final city = (entryMap['city'] ?? '').toString();
    final country = (entryMap['country'] ?? '').toString();

    if (city.isEmpty && country.isEmpty) return null;
    return (city: city, country: country);
  }

  Future<void> _writeCache(
    String cacheId,
    ({String city, String country}) v,
  ) async {
    final raw = _box.read(_cacheKey);
    final map = (raw is Map)
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    map[cacheId] = {
      'city': v.city,
      'country': v.country,
      'ts': DateTime.now().toIso8601String(),
    };

    await _box.write(_cacheKey, map);
  }

  Future<void> _respectRateLimit() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lastMs = _box.read(_lastRequestKey);

    if (lastMs is int) {
      final elapsed = nowMs - lastMs;
      final waitMs = _minRequestInterval.inMilliseconds - elapsed;
      if (waitMs > 0) {
        await Future.delayed(Duration(milliseconds: waitMs));
      }
    }

    await _box.write(_lastRequestKey, DateTime.now().millisecondsSinceEpoch);
  }

  String _pickFirstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      final s = (v ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }
}
