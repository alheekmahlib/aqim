part of '../../../prayers.dart';

extension AdhanGetters on AdhanController {
  /// -------- [Getters] ----------

  /// اسم المدينة والدولة بلغة المستخدم (استدعاء واحد فقط للـ API)
  Future<String> get localizedLocation async {
    final storedCity = Location.instance.city;
    final storedCountry = Location.instance.country;
    final pos = Location.instance.position;

    // Offline: لا نجري أي طلب شبكة، ونستخدم المخزون/الكاش فقط.
    if (!InternetConnectionController.instance.isConnected) {
      final hasStored =
          storedCity.trim().isNotEmpty || storedCountry.trim().isNotEmpty;
      if (hasStored) {
        return '$storedCity\n$storedCountry';
      }

      return '$storedCity\n$storedCountry';
    }

    // Online
    if (pos == null) {
      return '$storedCity\n$storedCountry';
    }

    try {
      final result = await NominatimReverseGeocodingService.instance.reverse(
        latitude: pos.latitude,
        longitude: pos.longitude,
        languageCode: Get.locale?.languageCode,
      );

      final cityOk = result.city.trim().isNotEmpty && result.city != 'Unknown';
      final countryOk =
          result.country.trim().isNotEmpty && result.country != 'Unknown';
      if (cityOk && countryOk) return '${result.city}\n${result.country}';
      return '$storedCity\n$storedCountry';
    } catch (_) {
      return '$storedCity\n$storedCountry';
    }
  }

  RxBool get isNoInternetAndDataNotInitialized {
    bool state = false;
    state =
        (!InternetConnectionController.instance.isConnected &&
        PrayerCacheManager.getCachedPrayerData() == null);
    return state.obs;
  }

  /// حالة تحميل بيانات الصلاة
  /// Prayer data loading state
  RxBool get isLoadingPrayerData => state.isLoadingPrayerData;

  /// التحقق من صحة البيانات الشهرية المخزنة
  /// Check if monthly cached data is valid
  bool get isMonthlyDataAvailable {
    final currentLocation = PrayerCacheManager.getStoredLocation();
    return currentLocation != null &&
        MonthlyPrayerCache.isMonthlyDataValid(currentLocation: currentLocation);
  }

  /// الحصول على إحصائيات التخزين
  /// Get cache statistics
  Map<String, dynamic> get cacheStatistics {
    return {
      'monthlyDataAvailable': isMonthlyDataAvailable,
      'dailyDataAvailable': PrayerCacheManager.getCacheStats()['isValid'],
      'isPrayerTimesInitialized': state.isPrayerTimesInitialized.value,
      'isLoadingData': state.isLoadingPrayerData.value,
    };
  }

  // int get adjustment {
  //   if (state.adjustmentIndex.value >= 0 &&
  //       state.adjustmentIndex.value < state.adjustments.length) {
  //     return state.adjustments[state.adjustmentIndex.value].value;
  //   }
  //   return 0;
  // }
  RxInt get currentPrayer {
    if (state.prayerTimes == null) return 0.obs;
    return (state.prayerTimes!.currentPrayer().index - 1).obs;
  }

  int get nextPrayer {
    if (state.prayerTimes == null) return 0;
    return state.prayerTimes!.nextPrayer().index;
  }

  String get getFridayDhuhrName =>
      intl.DateFormat('EEEE').format(state.now) == 'Friday'
      ? 'Friday'
      : 'Dhuhr';

  String get getMaghribName => EventController.instance.hijriNow.hMonth == 9
      ? 'ramadanMaghribName'
      : 'Maghrib';

  PrayerDetail getPrayerDetails({required bool isNextPrayer}) {
    if (state.prayerTimes == null) {
      return PrayerDetail(
        prayerName: '',
        prayerTime: null,
        prayerDisplayTime: '',
      );
    }
    final Prayer currentPrayer = state.prayerTimes!.currentPrayer();
    final Prayer? targetPrayer;

    if (isNextPrayer) {
      if (currentPrayer == Prayer.isha) {
        targetPrayer = Prayer.fajr;
      } else {
        targetPrayer = state.prayerTimes!.nextPrayer();
      }
    } else {
      targetPrayer = currentPrayer;
    }

    DateTime? targetPrayerDateTime = state.prayerTimes!.timeForPrayer(
      targetPrayer,
    );
    if (isNextPrayer &&
        targetPrayer == Prayer.fajr &&
        currentPrayer == Prayer.isha) {
      targetPrayerDateTime = targetPrayerDateTime?.add(const Duration(days: 1));
    }

    return PrayerDetail(
      prayerName: prayerNameFromEnum(targetPrayer).tr,
      prayerTime: targetPrayerDateTime,
      prayerDisplayTime: DateFormatter.formatPrayerTime(targetPrayerDateTime),
    );
  }

  RxDouble get getTimeLeftPercentage {
    if (state.prayerTimes == null) return 0.0.obs;
    final Prayer currentPrayer = state.prayerTimes!.currentPrayer();
    final Prayer? nextPrayer;

    if (currentPrayer == Prayer.isha) {
      nextPrayer = Prayer.fajr;
    } else {
      nextPrayer = state.prayerTimes!.nextPrayer();
    }
    DateTime? nextPrayerDateTime = state.prayerTimes!.timeForPrayer(nextPrayer);
    DateTime? currentPrayerDateTime = state.prayerTimes!.timeForPrayer(
      currentPrayer,
    );

    if (nextPrayer == Prayer.fajr && currentPrayer == Prayer.isha) {
      nextPrayerDateTime = nextPrayerDateTime?.add(const Duration(days: 1));
    }
    if (nextPrayerDateTime == null ||
        currentPrayerDateTime == null ||
        nextPrayerDateTime.isBefore(state.now)) {
      return 0.0.obs;
    }

    final totalDuration = nextPrayerDateTime
        .difference(currentPrayerDateTime)
        .inMinutes;
    final elapsedDuration = state.now
        .difference(currentPrayerDateTime)
        .inMinutes;

    double percentage = ((elapsedDuration / totalDuration) * 100)
        .clamp(0, 100)
        .toDouble();
    return percentage.obs;
  }

  /// حساب التقدم من صلاة الفجر إلى صلاة العشاء
  /// Calculate progress from Fajr to Isha prayer
  RxDouble get getPrayerDayProgress {
    final PrayerTimes? prayerTimes = state.prayerTimes;
    final SunnahTimes? sunnahTimes = state.sunnahTimes;

    if (prayerTimes == null || sunnahTimes == null) {
      return 0.0.obs;
    }

    final DateTime fajrTime = prayerTimes.fajr;
    final DateTime lastThirdOfTheNight = sunnahTimes.lastThirdOfTheNight;

    // إذا كان الوقت الحالي قبل الفجر، فالتقدم يكون 0
    if (state.now.isBefore(fajrTime)) {
      return 0.0.obs;
    }

    // إذا كان الوقت الحالي بعد العشاء، فالتقدم يكون 100%
    if (state.now.isAfter(lastThirdOfTheNight)) {
      return 100.0.obs;
    }

    // حساب المدة الإجمالية من الفجر إلى العشاء بالدقائق
    final totalDuration = lastThirdOfTheNight.difference(fajrTime).inMinutes;

    // حساب المدة المنقضية من الفجر حتى الآن بالدقائق
    final elapsedDuration = state.now.difference(fajrTime).inMinutes;

    // تجنب القسمة على صفر
    if (totalDuration <= 0) {
      return 0.0.obs;
    }

    // حساب النسبة المئوية (من 0 إلى 100)
    double percentage = ((elapsedDuration / totalDuration) * 100)
        .clamp(0, 100)
        .toDouble();

    return percentage.obs;
  }

  /// حساب قطع المؤشر (Gauge Segments) بناءً على أوقات الصلوات
  /// Calculate gauge segments based on prayer times
  List<GaugeZone> get getPrayerGaugeSegments {
    final PrayerTimes? prayerTimes = state.prayerTimes;
    final SunnahTimes? sunnahTimes = state.sunnahTimes;

    if (prayerTimes == null || sunnahTimes == null) {
      return [];
    }

    // أوقات الصلوات الخمس (من الفجر إلى العشاء)
    final List<DateTime> prayers = [
      prayerTimes.fajr, // الفجر
      prayerTimes.sunrise, // الشروق
      prayerTimes.dhuhr, // الظهر
      prayerTimes.asr, // العصر
      prayerTimes.maghrib, // المغرب
      prayerTimes.isha, // العشاء
      sunnahTimes.middleOfTheNight, // منتصف الليل
      sunnahTimes.lastThirdOfTheNight, // الثلث الأخير
    ];

    // ألوان مختلفة لكل فترة صلاة
    final List<GaugeAxisGradient> prayerColors = [
      const GaugeAxisGradient(
        colors: [Color(0xff000000), Color(0xff4b4c4f)],
        colorStops: [0.0, 1.0],
      ), // الفجر إلى الشروق - أزرق داكن (فجر)
      const GaugeAxisGradient(
        colors: [Color(0xffB8E0EA), Color(0xff0098EE)],
        colorStops: [0.0, 1.0],
      ), // الشروق إلى الظهر - ذهبي (صباح)
      const GaugeAxisGradient(
        colors: [Color(0xff0098EE), Color(0xffc5deed)],
        colorStops: [0.0, 1.0],
      ), // الظهر إلى العصر - أزرق فاتح (ظهيرة)
      const GaugeAxisGradient(
        colors: [Color(0xfff2dfd9), Color(0xfff8a159)],
        colorStops: [0.0, 1.0],
      ), // العصر إلى المغرب - برتقالي (عصر)
      const GaugeAxisGradient(
        colors: [Color(0xfff8a159), Color(0xff000000)],
        colorStops: [0.0, 1.0],
      ), // المغرب إلى العشاء - بنفسجي (مغرب)
      const GaugeAxisGradient(
        colors: [Color(0xff4b4c4f), Color(0xff000000)],
        colorStops: [0.0, 1.0],
      ), // العشاء إلى منتصف الليل - بنفسجي (عشاء)
      const GaugeAxisGradient(
        colors: [Color(0xff000000), Color(0xff000000)],
        colorStops: [0.0, 1.0],
      ), // العشاء إلى منتصف الليل - بنفسجي (عشاء)
      const GaugeAxisGradient(
        colors: [Color(0xff000000), Color(0xff000000)],
        colorStops: [0.0, 1.0],
      ), // بعد الثلث الاخير بنصف ساعة
    ];

    final DateTime fajrTime = prayers[0];
    final DateTime lastThirdOfTheNight = prayers[7];
    final int totalDuration = lastThirdOfTheNight
        .difference(fajrTime)
        .inMinutes;

    if (totalDuration <= 0) {
      return [];
    }

    List<GaugeZone> segments = [];
    double currentFrom = 0.0;

    // إنشاء segment لكل فترة بين صلاتين متتاليتين
    // Create segment for each period between two consecutive prayers
    for (int i = 0; i < prayers.length - 1; i++) {
      // حساب مدة الفترة بين الصلاة الحالية والتالية بالدقائق
      // Calculate duration between current and next prayer in minutes
      final int prayerDuration = prayers[i + 1]
          .difference(prayers[i])
          .inMinutes;

      // حساب النسبة المئوية لهذه الفترة من إجمالي اليوم
      // Calculate percentage of this period from total day
      final double prayerPercentage = (prayerDuration / totalDuration) * 100;
      final double currentTo = currentFrom + prayerPercentage;

      segments.add(
        GaugeZone(
          from: currentFrom,
          to: currentTo,
          gradient: prayerColors[i],
          cornerRadius: const Radius.circular(8.0),
        ),
      );

      currentFrom = currentTo; // البداية التالية تكون نهاية الحالية
    }

    return segments;
  }

  /// حساب قطع المؤشر (Gauge Segments) بناءً على أوقات الصلوات
  /// Calculate gauge segments based on prayer times
  // List<Gradient> get getPrayerGradients {
  //   // ألوان مختلفة لكل فترة صلاة
  //   final List<Gradient> prayerColors = [
  //     const RadialGradient(
  //       colors: [Color(0xff000000), Color(0xff4b4c4f)],
  //     ),
  //     const RadialGradient(
  //       colors: [Color.fromARGB(255, 235, 254, 251), Color(0xff4b4c4f)],
  //     ), // الفجر إلى الشروق - أزرق داكن (فجر)
  //     const RadialGradient(
  //       colors: [Color(0xffB8E0EA), Color(0xff0098EE)],
  //     ), // الشروق إلى الظهر - ذهبي (صباح)
  //     const RadialGradient(
  //       colors: [Color(0xff0098EE), Color(0xffc5deed)],
  //     ), // الظهر إلى العصر - أزرق فاتح (ظهيرة)
  //     const RadialGradient(
  //       colors: [Color(0xfff2dfd9), Color(0xfff8a159)],
  //     ), // العصر إلى المغرب - برتقالي (عصر)
  //     const RadialGradient(
  //       colors: [Color(0xff4b4c4f), Color(0xff000000)],
  //     ), // المغرب إلى العشاء - بنفسجي (مغرب)
  //     const RadialGradient(
  //       colors: [Color(0xff000000), Color(0xff000000)],
  //     ), // العشاء إلى منتصف الليل
  //     const RadialGradient(
  //       colors: [Color(0xff000000), Color(0xff000000)],
  //     ), // منتصف الليل إلى الثلث الأخير
  //   ];

  //   return prayerColors;
  // }

  // /// الحصول على اسم الفترة الحالية للصلاة
  // /// Get current prayer period name
  // String get getCurrentPrayerPeriodName {
  //   final PrayerTimes? prayerTimes = state.prayerTimes;

  //   if (prayerTimes == null) {
  //     return 'غير محدد';
  //   }

  //   if (state.now.isBefore(prayerTimes.fajr)) {
  //     return 'قبل الفجر';
  //   } else if (state.now.isBefore(prayerTimes.sunrise)) {
  //     return 'فترة الفجر';
  //   } else if (state.now.isBefore(prayerTimes.dhuhr)) {
  //     return 'فترة الصباح';
  //   } else if (state.now.isBefore(prayerTimes.asr)) {
  //     return 'فترة الظهيرة';
  //   } else if (state.now.isBefore(prayerTimes.maghrib)) {
  //     return 'فترة العصر';
  //   } else if (state.now.isBefore(prayerTimes.isha)) {
  //     return 'فترة المغرب';
  //   } else {
  //     return 'فترة العشاء';
  //   }
  // }

  RxDouble getTimeLeftForPrayerByIndex(int index) {
    if (index < 0 || index >= prayerNameList.length) {
      throw ArgumentError(
        'Index out of range, must be between 0 and ${prayerNameList.length - 1}.',
      );
    }

    Map<String, dynamic> targetPrayerMap = prayerNameList[index];
    DateTime? targetPrayerDateTime = targetPrayerMap['dateTime'];

    // إذا كانت الصلاة المطلوبة قد مرت اليوم، نضيف يوم واحد لحساب الصلاة القادمة
    if (targetPrayerDateTime != null) {
      targetPrayerDateTime = DateTime(
        state.now.year,
        state.now.month,
        state.now.day,
        targetPrayerDateTime.hour,
        targetPrayerDateTime.minute,
      );
      if (targetPrayerDateTime.isBefore(state.now)) {
        targetPrayerDateTime = targetPrayerDateTime.add(
          const Duration(days: 1),
        );
      }
    }

    if (targetPrayerDateTime == null) {
      return 0.0.obs;
    }

    final totalDuration = targetPrayerDateTime.difference(state.now).inMinutes;
    final fullDayDuration = const Duration(days: 1).inMinutes;

    // حساب النسبة المئوية المتبقية من 0 إلى 100 (كلما قل الوقت المتبقي زادت النسبة المئوية)
    double percentageLeft =
        (((fullDayDuration - totalDuration) / fullDayDuration) * 100)
            .clamp(0, 100)
            .toDouble();
    return percentageLeft.obs;
  }

  /// احسب المدة بين صلاة فائتة والصلاة التالية لها مباشرةً (بدون الاعتماد على الوقت الحالي)
  /// Compute the interval duration between a given prayer (missed) and the immediately next prayer
  /// This does NOT use DateTime.now(); it only uses the two prayer times and wraps to next day when needed.
  Rx<Duration> getDurationBetweenPrayerAndNextByIndex(int index) {
    if (index < 0 || index >= prayerNameList.length) {
      throw ArgumentError(
        'Index out of range, must be between 0 and ${prayerNameList.length - 1}.',
      );
    }

    final Map<String, dynamic> currentPrayerMap = prayerNameList[index];
    final int nextIndex = (index + 1) % prayerNameList.length;
    final Map<String, dynamic> nextPrayerMap = prayerNameList[nextIndex];

    DateTime? currentPrayerDateTime = currentPrayerMap['dateTime'];
    DateTime? nextPrayerDateTime = nextPrayerMap['dateTime'];

    if (currentPrayerDateTime == null || nextPrayerDateTime == null) {
      return Duration.zero.obs;
    }

    // إذا كان موعد الصلاة التالية يسبق موعد الصلاة الحالية أو يساويه، نضيف يومًا للموعد التالي
    // If next prayer's time is before or equal to current's time, move next to the next day
    if (!nextPrayerDateTime.isAfter(currentPrayerDateTime)) {
      nextPrayerDateTime = nextPrayerDateTime.add(const Duration(days: 1));
    }

    final Duration interval = nextPrayerDateTime.difference(
      currentPrayerDateTime,
    );
    return interval.obs;
  }

  /// احسب «نسبة المتبقي» للوصول إلى صلاة معيّنة ضمن الفترة بين الصلاة السابقة وهذه الصلاة.
  /// المنهجية:
  /// - نحدّد موعد «التكرار القادم» للصلاة الهدف بالنسبة للحظة الحالية (`state.now`).
  /// - نحدّد موعد الصلاة السابقة مباشرةً بالنسبة لنفس يوم «الصلاة الهدف» (وقد يكون في اليوم السابق إذا كان وقتها أكبر من وقت الهدف).
  /// - النسبة = (الوقت المتبقي حتى الصلاة الهدف) ÷ (طول الفترة بين السابقة والهدف) × 100.
  RxDouble getIntervalPercentageOfDayBetweenPrayerAndNextByIndex(int index) {
    if (index < 0 || index >= prayerNameList.length) {
      throw ArgumentError(
        'Index out of range, must be between 0 and ${prayerNameList.length - 1}.',
      );
    }

    final Map<String, dynamic> targetPrayerMap = prayerNameList[index];
    final int prevIndex = (index - 1) < 0
        ? (prayerNameList.length - 1)
        : (index - 1);
    final Map<String, dynamic> prevPrayerMap = prayerNameList[prevIndex];

    final DateTime? targetRaw = targetPrayerMap['dateTime'];
    final DateTime? prevRaw = prevPrayerMap['dateTime'];

    if (targetRaw == null || prevRaw == null) {
      return 0.0.obs;
    }

    // نبني مواعيد اليوم/الغد بناءً على اللحظة الحالية
    final DateTime now = state.now;

    // نبني موعد الصلاة الهدف لليوم الحالي
    DateTime target = DateTime(
      now.year,
      now.month,
      now.day,
      targetRaw.hour,
      targetRaw.minute,
      targetRaw.second,
    );

    // نبني موعد الصلاة السابقة لليوم الحالي
    DateTime prev = DateTime(
      now.year,
      now.month,
      now.day,
      prevRaw.hour,
      prevRaw.minute,
      prevRaw.second,
    );

    // نحدد الفترة الزمنية الصحيحة بناءً على الوقت الحالي
    if (now.isAfter(target) || now.isAtSameMomentAs(target)) {
      // الصلاة الهدف مرت اليوم، نأخذها للغد
      target = target.add(const Duration(days: 1));
    }

    if (now.isBefore(prev)) {
      // نحن قبل الصلاة السابقة، فالسابقة والهدف في الأمس واليوم
      prev = prev.subtract(const Duration(days: 1));
    } else {
      // نحن بعد الصلاة السابقة، نتحقق إذا كان الهدف قبل السابقة (مثل: عشاء -> فجر)
      if (targetRaw.hour < prevRaw.hour ||
          (targetRaw.hour == prevRaw.hour &&
              targetRaw.minute <= prevRaw.minute)) {
        // الصلاة الهدف في اليوم التالي بطبيعتها
        target = target.add(const Duration(days: 1));
      }
    }

    final int totalMinutes = target.difference(prev).inMinutes;
    if (totalMinutes <= 0) {
      return 0.0.obs;
    }

    // الوقت المنقضي من الصلاة السابقة حتى الآن
    int elapsedMinutes = now.difference(prev).inMinutes;
    // قصّ القيم لضمان [0, totalMinutes]
    if (elapsedMinutes < 0) elapsedMinutes = 0;
    if (elapsedMinutes > totalMinutes) elapsedMinutes = totalMinutes;

    final double percentage = ((elapsedMinutes / totalMinutes) * 100)
        .clamp(0, 100)
        .toDouble();
    return percentage.obs;
  }

  Rx<Duration> getDurationLeftForPrayerByIndex(int index) {
    if (index < 0 || index >= prayerNameList.length) {
      throw ArgumentError(
        'Index out of range, must be between 0 and ${prayerNameList.length - 1}.',
      );
    }

    Map<String, dynamic> targetPrayerMap = prayerNameList[index];
    DateTime? targetPrayerDateTime = targetPrayerMap['dateTime'];

    // إذا كانت الصلاة المطلوبة قد مرت اليوم، نضيف يوم واحد لحساب الصلاة القادمة
    if (targetPrayerDateTime != null) {
      targetPrayerDateTime = DateTime(
        state.now.year,
        state.now.month,
        state.now.day,
        targetPrayerDateTime.hour,
        targetPrayerDateTime.minute,
      );
      if (targetPrayerDateTime.isBefore(state.now)) {
        targetPrayerDateTime = targetPrayerDateTime.add(
          const Duration(days: 1),
        );
      }
    }

    if (targetPrayerDateTime == null) {
      return Duration.zero.obs;
    }

    final durationLeft = targetPrayerDateTime.difference(state.now);
    return durationLeft.obs;
  }

  Duration get getTimeLeftForNextPrayer {
    // نستخدم getCurrentPrayerByDateTime للحصول على الفترة الحالية (0-7)
    // بما في ذلك منتصف الليل (6) والثلث الأخير (7)
    final int currentPrayerIndex = getCurrentPrayerByDateTime();

    // تحديد index الصلاة القادمة
    final int nextPrayerIndex = (currentPrayerIndex) > 7
        ? 0
        : (currentPrayerIndex);

    // الحصول على وقت الصلاة القادمة من prayerNameList
    final Map<String, dynamic> nextPrayerMap = prayerNameList[nextPrayerIndex];
    DateTime? nextPrayerDateTime = nextPrayerMap['dateTime'];

    if (nextPrayerDateTime == null) {
      return Duration.zero;
    }

    // بناء وقت الصلاة لليوم الحالي
    nextPrayerDateTime = DateTime(
      state.now.year,
      state.now.month,
      state.now.day,
      nextPrayerDateTime.hour,
      nextPrayerDateTime.minute,
    );

    // معالجة الحالات الليلية
    // إذا كانت الصلاة القادمة هي الفجر (index 0) ونحن في فترة الليل
    if (nextPrayerIndex == 0 && currentPrayerIndex >= 5) {
      // نحن بعد المغرب، الفجر في اليوم التالي
      nextPrayerDateTime = nextPrayerDateTime.add(const Duration(days: 1));
    }
    // إذا كانت الصلاة القادمة منتصف الليل أو الثلث الأخير وهي بعد منتصف الليل الفلكي
    else if ((nextPrayerIndex == 6 || nextPrayerIndex == 7) &&
        nextPrayerDateTime.hour < 12 &&
        state.now.hour >= 12) {
      // الوقت الليلي في الصباح الباكر (بعد 12 AM)
      nextPrayerDateTime = nextPrayerDateTime.add(const Duration(days: 1));
    }

    // التحقق النهائي - إذا كان الوقت قد مر
    if (nextPrayerDateTime.isBefore(state.now)) {
      nextPrayerDateTime = nextPrayerDateTime.add(const Duration(days: 1));
    }

    return nextPrayerDateTime.difference(state.now);
  }

  DateTime get getTimeLeftForHomeWidgetNextPrayer {
    if (state.prayerTimes == null) {
      return state.now.add(const Duration(hours: 1));
    }
    final Prayer nextPrayer = state.prayerTimes!.nextPrayer();
    final DateTime? nextPrayerDateTime = state.prayerTimes!.timeForPrayer(
      nextPrayer,
    );
    if (nextPrayerDateTime == null || nextPrayerDateTime.isBefore(state.now)) {
      return state.now.add(const Duration(hours: 1));
    }
    return nextPrayerDateTime;
  }

  /// دالة لمعرفة رقم الصلاة السابقة بدون استدعاء update
  /// Function to get the previous prayer index without calling update.
  int getPreviousPrayerByDateTime() {
    final currentPrayerIndex = getCurrentPrayerByDateTime();
    return (currentPrayerIndex - 1) < 0 ? 7 : (currentPrayerIndex - 1);
  }

  /// دالة لمعرفة رقم الصلاة القادمة بدون استدعاء update
  /// Function to get the next prayer index without calling update.
  RxInt getNextPrayerByDateTime() {
    final currentPrayerIndex = getCurrentPrayerByDateTime();
    return ((currentPrayerIndex + 1) > 7 ? 0 : (currentPrayerIndex + 1)).obs;
  }

  PrayerDetail get getNextPrayerDetail => getPrayerDetails(isNextPrayer: true);

  LinearGradient getTimeNowColor() {
    // Guard: أرجع لوناً افتراضياً عند عدم توفر البيانات لتفادي Null crash
    if (state.prayerTimes == null) {
      return const LinearGradient(
        colors: [Color(0xff0a0f29), Color(0xff081e37)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    DateTime sunrise = state.prayerTimes!.sunrise;
    DateTime dhuhr = state.prayerTimes!.dhuhr;
    DateTime maghrib = state.prayerTimes!.maghrib;

    if (state.now.isAfter(sunrise.subtract(const Duration(minutes: 10))) &&
        state.now.isBefore(sunrise.add(const Duration(minutes: 30)))) {
      return const LinearGradient(
        colors: [Color(0xffbababa), Color(0xff081e37)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (state.now.isAfter(sunrise.add(const Duration(minutes: 30))) &&
        state.now.isBefore(dhuhr.subtract(const Duration(hours: 1)))) {
      return const LinearGradient(
        colors: [Color(0xffB8E0EA), Color(0xff0098EE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (state.now.isAfter(dhuhr.subtract(const Duration(hours: 1))) &&
        state.now.isBefore(maghrib.subtract(const Duration(hours: 1)))) {
      return const LinearGradient(
        colors: [Color(0xffB8E0EA), Color(0xff0098EE)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (state.now.isAfter(maghrib.subtract(const Duration(hours: 1))) &&
        state.now.isBefore(maghrib.add(const Duration(minutes: 20)))) {
      return const LinearGradient(
        colors: [Color(0xffF17148), Color(0xffCF4B6D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (state.now.isAfter(maghrib.add(const Duration(minutes: 20))) ||
        state.now.isBefore(sunrise.subtract(const Duration(minutes: 10)))) {
      return const LinearGradient(
        colors: [Color(0xff0a0f29), Color(0xff081e37)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      state.backgroundColor.value = const Color(0xffbababa);
      return const LinearGradient(
        colors: [Color(0xffbababa), Color(0xff232323)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  /// دالة لمعرفة أوقات النهي عن الصلاة
  /// Function to get prayer prohibition times
  ///
  /// ملاحظة: هذا الـ getter يُقرأ داخل مرحلة بناء الواجهة، لذا يجب أن يبقى
  /// نقيًا (بدون استدعاء update)؛ التحديث الدوري تديره updateProgressBar.
  /// Note: this getter is read during widget build, so it must stay pure
  /// (no update calls); periodic refresh is driven by updateProgressBar.
  bool get prohibitionTimesBool {
    if (state.prayerTimes == null) {
      state.prohibitionTimesIndex.value = -1;
      return false;
    }
    PrayerTimes dateTime = state.prayerTimes!;

    // 1- من طلوع الفجر الصادق حتى تطلع الشمس (أو من بعد صلاة الفجر)
    // From true dawn until sunrise (or from after Fajr prayer)
    if (state.now.isAfter(dateTime.fajr) &&
        state.now.isBefore(dateTime.sunrise)) {
      state.prohibitionTimesIndex.value = 0;
      return true;
    }
    // 5- حين يقوم قائم الظهيرة وتتوسط الشمس كبد السماء قبل الزوال (5-10 دقائق قبل الظهر)
    // When the sun is at its zenith before midday (5-10 minutes before Dhuhr)
    else if (state.now.isAfter(
          dateTime.dhuhr.subtract(const Duration(minutes: 10)),
        ) &&
        state.now.isBefore(dateTime.dhuhr)) {
      state.prohibitionTimesIndex.value = 1;
      return true;
    }
    // 3- من بعد صلاة العصر حتى تميل إلى الغروب
    // From after Asr prayer until the sun starts to set
    else if (state.now.isAfter(dateTime.asr) &&
        state.now.isBefore(
          dateTime.maghrib.subtract(const Duration(minutes: 15)),
        )) {
      state.prohibitionTimesIndex.value = 2;
      return true;
    } else {
      state.prohibitionTimesIndex.value = -1; // لا يوجد وقت نهي
      return false;
    }
  }

  void get getShared {
    state.isHanafi = state.box.read(SHAFI) ?? true;
    state.highLatitudeRuleIndex.value = state.box.read(HIGH_LATITUDE_RULE) ?? 0;
    state.autoCalculationMethod.value =
        state.box.read(AUTO_CALCULATION) ?? true;
    state.selectedCountry.value = state.box.read<String>(PRAYER_CALCULATION_COUNTRY) ??
        (PrayerCacheManager.getCachedPrayerData()?['selectedCountry'] as String?) ??
        'Saudi Arabia';
    state.iqamaOffsets = IqamaOffsets.fromGetStorage();
    state.iqamaNotificationsEnabled.value =
        state.box.read(IQAMA_NOTIFICATIONS_ENABLED) ?? false;
    state.showIqamaTimes.value = state.box.read(SHOW_IQAMA_TIMES) ?? true;
    state.prayerCountdownEnabled.value =
        state.box.read(PRAYER_COUNTDOWN_NOTIFICATION_ENABLED) ?? false;
    // state.adjustments[0].value = state.box.read(ADJUSTMENT_FAJR) ?? 0;
    // state.adjustments[1].value = state.box.read(ADJUSTMENT_DHUHR) ?? 0;
    // state.adjustments[2].value = state.box.read(ADJUSTMENT_ASR) ?? 0;
    // state.adjustments[3].value = state.box.read(ADJUSTMENT_MAGHRIB) ?? 0;
    // state.adjustments[4].value = state.box.read(ADJUSTMENT_ISHA) ?? 0;
    // state.adjustments[5].value = state.box.read(ADJUSTMENT_THIRD) ?? 0;
    // state.adjustments[6].value = state.box.read(ADJUSTMENT_MIDNIGHT) ?? 0;
    // state.adjustments[7].value = state.box.read(ADJUSTMENT_SUNRISE) ?? 0;
  }

  Duration get getDelayUntilNextIsha {
    if (state.prayerTimes == null) {
      return const Duration(hours: 1);
    }
    DateTime nextIsha = state.prayerTimes!.isha;

    // If today's Isha time is already passed, schedule for tomorrow
    if (state.now.isAfter(nextIsha)) {
      nextIsha = nextIsha.add(const Duration(minutes: 15));
    }

    return nextIsha.difference(state.now);
  }

  Madhab getMadhab(bool madhab) {
    if (madhab) {
      return Madhab.shafi;
    } else {
      return Madhab.hanafi;
    }
  }

  Future<HighLatitudeRule> getHighLatitudeRule(int index) async {
    // إذا كانت الحالة المطلوبة مفعلة بالفعل، لا نفعل شيئًا
    if (index == 0) {
      state.middleOfTheNight.value = true;
      state.seventhOfTheNight.value = false;
      state.twilightAngle.value = false;
      state.box.write(HIGH_LATITUDE_RULE, 0);
      log('HighLatitudeRule set to middleOfTheNight', name: 'AdhanGetters');
    } else if (index == 1) {
      state.middleOfTheNight.value = false;
      state.seventhOfTheNight.value = true;
      state.twilightAngle.value = false;
      state.box.write(HIGH_LATITUDE_RULE, 1);
      log('HighLatitudeRule set to seventhOfTheNight', name: 'AdhanGetters');
    } else if (index == 2) {
      state.middleOfTheNight.value = false;
      state.seventhOfTheNight.value = false;
      state.twilightAngle.value = true;
      state.box.write(HIGH_LATITUDE_RULE, 2);
      log('HighLatitudeRule set to twilightAngle', name: 'AdhanGetters');
    } else {
      log('No change in HighLatitudeRule', name: 'AdhanGetters');
      return getHighLatitudeRuleFromIndex(
        index,
      ); // نرجع القيمة الحالية دون تغيير
    }
    state.highLatitudeRuleIndex.value = index;
    // إشعار GetBuilder(id: 'init_athan') في شيت الإعدادات — بدونه لا تتحدث
    // المفاتيح حتى إغلاق الشيت وفتحه من جديد.
    update(['init_athan']);
    return getHighLatitudeRuleFromIndex(index);
  }

  HighLatitudeRule getHighLatitudeRuleFromIndex(int index) {
    switch (index) {
      case 0:
        return HighLatitudeRule.middle_of_the_night;
      case 1:
        return HighLatitudeRule.seventh_of_the_night;
      case 2:
        return HighLatitudeRule.twilight_angle;
      default:
        return HighLatitudeRule.middle_of_the_night; // القيمة الافتراضية
    }
  }

  int get currentPrayerIndex => getCurrentPrayerByDateTime();

  int getCurrentPrayerByDateTime() {
    final prayer = state.prayerTimes;
    final sunnah = state.sunnahTimes;

    if (prayer == null || sunnah == null) {
      return 0;
    }

    int value = 0;

    // log('Current time: ${state.now}');

    // log('Fajr time: ${prayer!.fajr}');

    // log('lastThirdOfTheNight: ${sunnah.lastThirdOfTheNight}');

    // log('middleOfTheNight: ${sunnah.middleOfTheNight}');

    if (state.now.isBefore(prayer.fajr)) {
      log('Time is before Fajr');

      // تحديد التاريخ الصحيح لأوقات منتصف الليل والثلث الأخير

      DateTime adjustedMiddleOfNight;

      DateTime adjustedLastThirdOfNight;

      // إذا كان وقت منتصف الليل قبل الساعة 12 (في اليوم السابق)

      if (sunnah.middleOfTheNight.hour >= 18) {
        // منتصف الليل في اليوم السابق

        adjustedMiddleOfNight = DateTime(
          state.now.year,
          state.now.month,
          state.now.day - 1,
          sunnah.middleOfTheNight.hour,
          sunnah.middleOfTheNight.minute,
          sunnah.middleOfTheNight.second,
        );
      } else {
        // منتصف الليل في نفس اليوم

        adjustedMiddleOfNight = DateTime(
          state.now.year,
          state.now.month,
          state.now.day,
          sunnah.middleOfTheNight.hour,
          sunnah.middleOfTheNight.minute,
          sunnah.middleOfTheNight.second,
        );
      }

      // إذا كان وقت الثلث الأخير قبل الساعة 12 (في اليوم السابق)

      if (sunnah.lastThirdOfTheNight.hour >= 18) {
        // الثلث الأخير في اليوم السابق

        adjustedLastThirdOfNight = DateTime(
          state.now.year,
          state.now.month,
          state.now.day - 1,
          sunnah.lastThirdOfTheNight.hour,
          sunnah.lastThirdOfTheNight.minute,
          sunnah.lastThirdOfTheNight.second,
        );
      } else {
        // الثلث الأخير في نفس اليوم

        adjustedLastThirdOfNight = DateTime(
          state.now.year,
          state.now.month,
          state.now.day,
          sunnah.lastThirdOfTheNight.hour,
          sunnah.lastThirdOfTheNight.minute,
          sunnah.lastThirdOfTheNight.second,
        );
      }

      // log('Adjusted middleOfTheNight: $adjustedMiddleOfNight');

      // log('Adjusted lastThirdOfTheNight: $adjustedLastThirdOfNight');

      // إذا كان الوقت بعد الثلث الأخير من الليل وقبل الفجر، ننتقل للفجر

      if (state.now.isAfter(adjustedLastThirdOfNight)) {
        // log('Time is after lastThirdOfTheNight - returning 0 (Fajr)');

        value = 0; // fajr - بعد الثلث الأخير ننتقل للفجر
      } else if (state.now.isAfter(adjustedMiddleOfNight)) {
        // log('Time is after middleOfTheNight - returning 7 (LastThird)');

        value =
            7; // lastQuarterOfNight - بعد منتصف الليل مباشرة ننتقل للثلث الأخير
      } else {
        // log('Time is before middleOfTheNight - returning 6');

        value = 6; // midnightTime (فترة ما قبل منتصف الليل)
      }
    } else if (state.now.isBefore(prayer.sunrise)) {
      value = 1; // sunrise
    } else if (state.now.isBefore(prayer.dhuhr)) {
      value = 2; // dhuhr
    } else if (state.now.isBefore(prayer.asr)) {
      value = 3; // asr
    } else if (state.now.isBefore(prayer.maghrib)) {
      value = 4; //maghrib
    } else if (state.now.isBefore(prayer.isha)) {
      value = 5; // isha
    } else if (state.now.isBefore(sunnah.middleOfTheNight)) {
      value = 6; // midnightTime
    } else if (state.now.isBefore(sunnah.lastThirdOfTheNight)) {
      value = 7; // lastQuarterOfNight
    } else {
      // إذا كان الوقت بعد الثلث الأخير من الليل، ننتقل للفجر

      value = 0; // fajr - بعد الثلث الأخير ننتقل للفجر
    }

    return value;
  }

  Future<String> getPrayerTime(int prayerIndex, DateTime prayerTime) async {
    try {
      DateTime adjustedPrayerTime = prayerTime;
      return await DateFormatter.justTime(adjustedPrayerTime);
    } catch (e) {
      return '';
    }
  }

  int getPrayerNotificationIndexForPrayer(String prayerName) {
    String notiType =
        GetStorage('AdhanSounds').read('scheduledAdhan_$prayerName') ??
        'nothing';
    if ('nothing' == notiType) {
      return 0;
    } else if ('silent' == notiType) {
      return 1;
    } else if ('bell' == notiType) {
      return 2;
    } else if ('sound' == notiType) {
      return 3;
    } else {
      return 0;
    }
  }
}
