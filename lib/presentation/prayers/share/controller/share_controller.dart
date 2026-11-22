part of '../../prayers.dart';

class ShareController extends GetxController {
  static ShareController get instance => Get.isRegistered<ShareController>()
      ? Get.find<ShareController>()
      : Get.put(ShareController());

  final ScreenshotController screenshotController = ScreenshotController();
  final RxBool isSaving = false.obs;
  final RxBool isPrinting = false.obs;
  final Rx<DateTime> selectedMonth = DateTime.now().obs;
  Uint8List? imageBytesScreen;

  /// التصميم المختار لبطاقة المشاركة.
  final Rx<ShareCardDesign> selectedDesign = ShareCardDesign.timetable.obs;

  /// نسبة التقدّم الحيّة (0..1) للشريط داخل البطاقة.
  final RxDouble progress = 0.0.obs;

  Timer? _progressTimer;

  AdhanController get adhan => AdhanController.instance;

  @override
  void onInit() {
    super.onInit();
    final saved = GetStorage().read<String>(SHARE_CARD_DESIGN);
    if (saved != null) {
      selectedDesign.value = ShareCardDesign.values.firstWhere(
        (design) => design.name == saved,
        orElse: () => ShareCardDesign.timetable,
      );
    }
  }

  /// تشغيل مؤقّت تحديث شريط التقدّم أثناء فتح ورقة المشاركة.
  /// Starts the progress ticker while the share sheet is open.
  void startProgressTicker() {
    if (_progressTimer != null) return;
    progress.value = progressValue;
    _progressTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      progress.value = progressValue;
    });
  }

  /// إيقاف المؤقّت عند إغلاق الورقة.
  /// Stops the ticker when the sheet closes.
  void stopProgressTicker() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  @override
  void onClose() {
    stopProgressTicker();
    super.onClose();
  }

  /// تغيير التصميم المختار وحفظه في التخزين المحلي.
  /// Change the selected design and persist it locally.
  void selectDesign(ShareCardDesign design) {
    if (selectedDesign.value == design) return;
    selectedDesign.value = design;
    GetStorage().write(SHARE_CARD_DESIGN, design.name);
  }

  /// الصلاة الواجبة القادمة كما تُحسب لبطاقة المشاركة.
  ///
  /// The next obligatory prayer resolved for the share card. It is computed
  /// locally (see `share_next_prayer.dart`) so the card never falls back to
  /// middle of the night / last third of the night.
  ShareNextPrayer? get nextPrayer {
    final times = adhan.state.prayerTimes;
    if (times == null) return null;
    return resolveShareNextPrayer(
      now: DateTime.now(),
      fajr: times.fajr,
      dhuhr: times.dhuhr,
      asr: times.asr,
      maghrib: times.maghrib,
      isha: times.isha,
    );
  }

  // Build display strings using available getters/helpers
  String get nextPrayerName {
    final prayer = nextPrayer;
    if (prayer == null) return '';
    return _prayerDisplayName(prayer.prayer);
  }

  DateTime? get nextPrayerTime => nextPrayer?.time;

  String get formattedNextPrayerTime =>
      DateFormatter.formatPrayerTime(nextPrayerTime);

  /// اسم الصلاة كما يظهر في التطبيق (الجمعة بدل الظهر، ورمضان بدل المغرب).
  /// Prayer label used by the app (Friday instead of Dhuhr, Ramadan Maghrib).
  String _prayerDisplayName(Prayer prayer) {
    switch (prayer) {
      case Prayer.dhuhr:
        return adhan.getFridayDhuhrName.tr;
      case Prayer.maghrib:
        return adhan.getMaghribName.tr;
      default:
        return adhan.prayerNameFromEnum(prayer).tr;
    }
  }

  // Time left as mm:ss or h:mm
  String get timeLeftLabel {
    final prayer = nextPrayer;
    if (prayer == null) return '--';
    final diff = prayer.timeLeft;
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    if (diff == Duration.zero) return '--';
    if (hours <= 0) {
      return '${minutes.toString().padLeft(2, '0')} ${'min'.tr}';
    }
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} ${'h'.tr}';
  }

  // Hijri date text
  String get hijriDateText {
    final h = EventController.instance.hijriNow;
    return '${'${h.hDay}'.convertNumbers(Get.locale!.languageCode)} ${h.getLongMonthName().tr} ${'${h.hYear}'.convertNumbers(Get.locale!.languageCode)}';
  }

  /// اسم اليوم الحالي مترجمًا.
  /// Current weekday name, translated.
  String get weekdayText {
    final hijri = EventController.instance.hijriNow;
    final index = hijri.weekDay() - 1;
    if (index < 0 || index >= weekDaysFullName.length) return '';
    return weekDaysFullName[index].tr;
  }

  /// نسبة التقدّم بين الصلاة السابقة والصلاة القادمة كقيمة بين 0 و 1.
  ///
  /// تُحسب على الصلوات الواجبة فقط، فبعد العشاء يقيس الشريط المسافة من العشاء
  /// حتى فجر الغد (وهي نفس المسافة التي يقيسها الوقت المتبقي).
  ///
  /// Progress between the previous and the next obligatory prayer (0..1).
  double get progressValue => nextPrayer?.progress ?? 0;

  /// كل بيانات بطاقة المشاركة لتغذية أي تصميم.
  /// All share-card data feeding any design.
  ShareCardData get cardData {
    final hijri = EventController.instance.hijriNow;
    final lang = Get.locale?.languageCode ?? 'ar';
    return ShareCardData(
      prayerName: nextPrayerName,
      prayerTime: formattedNextPrayerTime,
      nextPrayerLabel: 'nextPrayer'.tr,
      timeLeftTitle: 'timeLeft'.tr,
      timeLeftValue: timeLeftLabel,
      hijriDate: hijriDateText,
      weekday: weekdayText,
      location: adhan.state.location,
      appName: 'appName'.tr,
      prayerTimesTitle: 'prayerTimesTitle'.tr,
      progress: progressValue,
      prayers: _prayerSlots(lang),
      gradient: adhan.getTimeNowColor(),
      hijriMonth: hijri.hMonth,
    );
  }

  /// أوقات اليوم مع تمييز الصلاة القادمة.
  /// Today's prayer slots with the next prayer highlighted.
  List<SharePrayerSlot> _prayerSlots(String lang) {
    final times = adhan.state.prayerTimes;
    if (times == null) return const [];

    String format(DateTime? time) {
      final text = DateFormatter.formatPrayerTime(time);
      return text.isEmpty ? '--:--' : text.convertNumbers(lang);
    }

    // الصلاة القادمة بالمعرّف (وليس بالاسم) حتى تُضاء بلاطة الفجر بعد العشاء.
    // The next prayer is matched by identity so the Fajr tile lights up after Isha.
    final Prayer upcoming = nextPrayer?.prayer ?? Prayer.fajr;

    return [
      SharePrayerSlot(
        name: _prayerDisplayName(Prayer.fajr),
        time: format(times.fajr),
        isNext: upcoming == Prayer.fajr,
      ),
      SharePrayerSlot(
        name: _prayerDisplayName(Prayer.dhuhr),
        time: format(times.dhuhr),
        isNext: upcoming == Prayer.dhuhr,
      ),
      SharePrayerSlot(
        name: _prayerDisplayName(Prayer.asr),
        time: format(times.asr),
        isNext: upcoming == Prayer.asr,
      ),
      SharePrayerSlot(
        name: _prayerDisplayName(Prayer.maghrib),
        time: format(times.maghrib),
        isNext: upcoming == Prayer.maghrib,
      ),
      SharePrayerSlot(
        name: _prayerDisplayName(Prayer.isha),
        time: format(times.isha),
        isNext: upcoming == Prayer.isha,
      ),
    ];
  }

  /// بناء بطاقة المشاركة بحجمها المنطقي للتصدير.
  /// Builds the share card at its logical export size.
  Widget _buildExportCard(BuildContext context, ShareCardDesign design) {
    final direction = _currentTextDirection();
    return Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: SizedBox(
          width: design.exportWidth,
          height: design.exportHeight,
          child: ShareCardView(design: design, data: cardData),
        ),
      ),
    );
  }

  TextDirection _currentTextDirection() {
    const rtlLangs = {'ar', 'ku', 'ur', 'fa'};
    final lang = Get.locale?.languageCode ?? 'ar';
    return rtlLangs.contains(lang) ? TextDirection.rtl : TextDirection.ltr;
  }

  /// التقاط بطاقة المشاركة بدقة عالية خارج شجرة العرض.
  /// Captures the share card at high resolution off-screen.
  Future<void> createAndShowVerseImage() async {
    try {
      isSaving.value = true;
      final context = Get.context;
      if (context == null) return;

      final design = selectedDesign.value;
      final card = _buildExportCard(context, design);
      final height = design.exportHeight;

      final bytes = await screenshotController.captureFromLongWidget(
        card,
        context: context,
        delay: const Duration(milliseconds: 120),
        pixelRatio: 3,
        constraints: height == null
            ? BoxConstraints(maxWidth: design.exportWidth)
            : BoxConstraints.tight(Size(design.exportWidth, height)),
      );

      if (bytes.isNotEmpty) {
        imageBytesScreen = bytes;
        update();
      }
    } catch (e) {
      log('Error capturing share card image: $e', name: 'ShareController');
    }
  }

  Future<void> shareAsImage() async {
    try {
      isSaving.value = true;

      if (imageBytesScreen != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File(
          '${directory.path}/prayer_share_${DateTime.now().millisecondsSinceEpoch}.png',
        ).create();
        await imagePath.writeAsBytes(imageBytesScreen!);

        final shareText =
            '${'sharePrayerTime'.tr}\n'
            '${'appName'.tr}';

        final params = ShareParams(
          text: shareText,
          files: [XFile(imagePath.path, name: 'prayer_times.png')],
          // subject: 'appName'.tr,
        );

        final result = await SharePlus.instance.share(params);

        if (result.status == ShareResultStatus.success) {
          log('Image shared successfully!');
        } else if (result.status == ShareResultStatus.dismissed) {
          log('Share dismissed by user');
        } else {
          log('Share unavailable or failed');
        }
      }
    } catch (e) {
      log('Error sharing image: $e', name: 'ShareController');
    } finally {
      isSaving.value = false;
    }
  }
}
