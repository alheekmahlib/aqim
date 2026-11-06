part of '../../../prayers.dart';

/// تسلسل بيانات أوقات الصلاة للتخزين والاسترداد
/// Prayer times serialization extension for storage and retrieval
extension PrayerTimesSerialization on AdhanState {
  /// تحويل البيانات إلى JSON للتخزين
  /// Convert data to JSON for storage
  Map<String, dynamic> toJson() {
    // بيانات الصلاة غير مهيأة بعد: لا نقرأ حقول late غير مهيأة وإلا انهار التسلسل
    // Uninitialized prayer data: reading the late fields below would throw
    // LateInitializationError, so emit an empty payload instead.
    if (prayerTimes == null || sunnahTimes == null) {
      log('toJson skipped: prayer data not ready yet',
          name: 'PrayerTimesSerialization');
      return {};
    }
    return {
      // أوقات الصلاة الأساسية / Basic prayer times
      'fajr': prayerTimes?.fajr.toIso8601String(),
      'sunrise': prayerTimes?.sunrise.toIso8601String(),
      'dhuhr': prayerTimes?.dhuhr.toIso8601String(),
      'asr': prayerTimes?.asr.toIso8601String(),
      'maghrib': prayerTimes?.maghrib.toIso8601String(),
      'isha': prayerTimes?.isha.toIso8601String(),

      // أوقات السنة / Sunnah times
      'lastThird': sunnahTimes?.lastThirdOfTheNight.toIso8601String(),
      'middleOfTheNight': sunnahTimes?.middleOfTheNight.toIso8601String(),

      // معلومات الموقع / Location information
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,

      // إعدادات الحساب / Calculation settings
      'calculationMethod': calculationMethodString.value,
      'fajrAngle': params.fajrAngle,
      'ishaAngle': params.ishaAngle,
      'ishaInterval': params.ishaInterval,
      'maghribAngle': params.maghribAngle,
      'method': params.method.name,
      'madhab': params.madhab == Madhab.hanafi ? 'hanafi' : 'shafi',
      'highLatitudeRule': params.highLatitudeRule.toString(),
      'isHanafi': isHanafi,
      'autoCalculationMethod': autoCalculationMethod.value,
      'selectedCountry': selectedCountry.value,

      // التعديلات / Adjustments
      'adjustments': adjustments.toJson(),

      // التاريخ والوقت / Date and time
      'calculationDate': DateTime.now().toIso8601String(),
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// استرداد البيانات من JSON
  /// Restore data from JSON
  bool fromJson(Map<String, dynamic> json) {
    try {
      // التحقق من صحة البيانات / Validate data
      if (!_isValidPrayerData(json)) {
        log('Invalid prayer data found', name: 'PrayerTimesSerialization');
        return false;
      }

      // استرداد الإحداثيات / Restore coordinates
      coordinates = Coordinates(
        json['latitude']?.toDouble() ?? 0.0,
        json['longitude']?.toDouble() ?? 0.0,
      );

      // استرداد تاريخ الحساب / Restore calculation date
      dateComponents = DateComponents.from(DateTime.now());

      // استرداد معاملات الحساب / Restore calculation parameters
      final method = CalculationMethod.values.firstWhere(
        (value) => value.name == json['method'],
        orElse: () => CalculationMethod.other,
      );
      final defaults = method.getParameters();
      params = CalculationParameters(
        method: method,
        fajrAngle: json['fajrAngle']?.toDouble() ?? 18.0,
        ishaAngle: json['ishaAngle']?.toDouble(),
        ishaInterval: json['ishaInterval'] ?? 0,
        maghribAngle: json['maghribAngle']?.toDouble(),
        methodAdjustments: defaults.methodAdjustments,
      );

      // استرداد المذهب / Restore madhab
      params.madhab = json['madhab'] == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
      isHanafi = json['isHanafi'] ?? true;

      // استرداد قاعدة خطوط العرض العليا / Restore high latitude rule
      params.highLatitudeRule = HighLatitudeRule.values.firstWhere(
        (rule) => rule.toString() == json['highLatitudeRule'],
        orElse: () => HighLatitudeRule.middle_of_the_night,
      );

      adjustments = OurPrayerAdjustments.fromJson(json['adjustments'] ?? {});
      params.adjustments = adjustments;

      // استرداد الإعدادات / Restore settings
      autoCalculationMethod.value = json['autoCalculationMethod'] ?? true;
      selectedCountry.value = json['selectedCountry'] ?? 'Saudi Arabia';
      calculationMethodString.value = json['calculationMethod'] ?? 'أم القرى';

      // إنشاء أوقات الصلاة / Create prayer times
      prayerTimes = PrayerTimes(coordinates, dateComponents, params);
      sunnahTimes = SunnahTimes(prayerTimes!);

      log('Prayer data restored successfully',
          name: 'PrayerTimesSerialization');
      return true;
    } catch (e) {
      log('Error restoring prayer data: $e', name: 'PrayerTimesSerialization');
      return false;
    }
  }

  /// التحقق من صحة البيانات المخزنة
  /// Validate stored prayer data
  bool _isValidPrayerData(Map<String, dynamic> json) {
    final requiredFields = ['latitude', 'longitude', 'fajrAngle'];

    for (String field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        return false;
      }
    }
    if (json['ishaAngle'] == null && (json['ishaInterval'] ?? 0) <= 0) {
      return false;
    }

    // التحقق من صحة الإحداثيات / Validate coordinates
    final lat = json['latitude']?.toDouble();
    final lng = json['longitude']?.toDouble();

    if (lat == null ||
        lng == null ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      return false;
    }

    return true;
  }
}
