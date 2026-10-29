part of '../../../prayers.dart';

extension PrayersNotiUi on PrayersNotificationsCtrl {
  Future<void> playButtonOnTap(List<AdhanData>? adhanData, int i) async {
    final isDownloaded = state.downloadedAdhanData.any(
      (d) => d.index == adhanData![i].index,
    );
    if (isDownloaded) {
      AdhanData? adhan = state.downloadedAdhanData.firstWhere(
        (a) => a.index == adhanData![i].index,
      );
      await state.audioPlayer
          .setAudioSource(AudioSource.file(adhan.adhanPath!))
          .then((_) async => await state.audioPlayer.play());
      log('AdhanPath: ${adhan.adhanPath} index: ${adhanData![i].index}');
    } else {
      // رابط المعاينة مسار نسبي في الكتالوج؛ يُحل حسب المستودع النشط.
      final previewUrl = AdhanSoundsCatalog.resolveUrl(
        adhanData![i].urlPlayAdhan,
      );
      log('urlPlayAdhan: $previewUrl index: ${adhanData[i].index}');
      await state.audioPlayer
          .setAudioSource(AudioSource.uri(Uri.parse(previewUrl)))
          .then((_) async => await state.audioPlayer.play());
    }
  }

  /// اختيار مقرئ من الكتالوج (مدمج أو محمّل) وتخزين مساراته.
  void switchAdhanOnTap(int index) {
    final box = GetStorage('AdhanSounds');
    final downloadedPath = AudioDownloader.downloadedAudioPathFor(index);

    final String regularPath;
    final String fajirPath;
    if (downloadedPath != null) {
      regularPath = downloadedPath;
      final fajir = box.read<String?>('$index$ADHAN_PATH_FAJIR_AUDIO');
      fajirPath = (fajir != null && File(fajir).existsSync())
          ? fajir
          : downloadedPath;
    } else {
      final entry = state.adhanList.length > index
          ? state.adhanList[index]
          : null;
      final fileName = entry?.adhanFileName ?? 'aqsa';
      regularPath = entry?.adhanLocalPath ?? 'resource://raw/${fileName}_athan';
      // iOS/macOS لا يحتويان نسخاً فجرية مدمجة؛ وsarihi له تسمية خاصة في raw.
      final fajirRaw = fileName == 'sarihi'
          ? 'sarihi_athan_fajir'
          : '${fileName}_fajir_athan';
      fajirPath = Platform.isIOS || Platform.isMacOS
          ? regularPath
          : 'resource://raw/$fajirRaw';
    }

    state.selectedAdhanPath.value = regularPath;
    state.selectedAdhanPathFajir.value = fajirPath;

    // تخزين المسارات والفهرس المختار في GetStorage
    box.write(ADHAN_PATH, regularPath);
    box.write(ADHAN_PATH_FAJIR, fajirPath);
    box.write(ADHAN_SELECTED_INDEX, index.toString());

    log(
      'Adhan selected: $index, Path: ${state.selectedAdhanPath.value}',
      name: 'PrayersNotiUi',
    );
    log(
      'Adhan Fajir Path: ${state.selectedAdhanPathFajir.value}',
      name: 'PrayersNotiUi',
    );
  }

  RxBool isAdhanSelectByIndex(int adhanIndex) {
    // selectedAdhanPath ردّي (Rx)؛ قراءته هنا تسجّل تبعية لدى GetX فيعاد
    // بناء عنصر القائمة فور تغيير الاختيار — GetStorage وحده لا يفعّلها.
    final selectedPath = state.selectedAdhanPath.value;
    final storedIndex = state.box.read<String?>(ADHAN_SELECTED_INDEX);
    if (storedIndex != null) {
      return RxBool(storedIndex == adhanIndex.toString());
    }
    // توافق مع البيانات القديمة قبل اشتقاق الفهرس.
    return RxBool(
      state.adhanList.length > adhanIndex &&
          state.adhanList[adhanIndex].adhanLocalPath == selectedPath,
    );
  }

  RxBool isAdhanDownloadedByIndex(int adhanIndex) =>
      (null !=
              state.downloadedAdhanData.firstWhereOrNull(
                (e) => e.index == adhanIndex,
              ))
          .obs;

  RxBool isAdhanPathDownloadedByIndex(int adhanIndex) =>
      (state.selectedAdhanPath.value ==
              state.downloadedAdhanData
                  .firstWhereOrNull((e) => e.index == adhanIndex)
                  ?.adhanPath)
          .obs;

  void onReceiveProgress(int received, int total) {
    if (total != -1) {
      state.progress.value = (received / total);
      state.progressString.value =
          '${(state.progress.value * 100).toStringAsFixed(0)}%';
      log(state.progressString.value);
    }
  }

  Future<void> onNotificationActionReceived(
    LocalReceivedNotification receivedAction,
  ) async {
    if (DateTime.now().isBefore(
      (receivedAction.displayedDate ?? DateTime.now()).add(
        const Duration(minutes: 5),
      ),
    )) {
      // تسليم منظم: نقر الإشعار يعني تولّي التطبيق التشغيل داخل الواجهة؛
      // نوقف خدمة التشغيل الأمامية أولاً حتى لا يتراكب صوتان.
      await AdhanAlarmsScheduler.stopPlayback();
      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.only(top: 8.0, right: 8.0, left: 8.0),
          margin: const EdgeInsets.only(right: 8.0, left: 8.0),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border.all(
              width: 1,
              color: Theme.of(Get.context!).colorScheme.primary,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: Theme.of(Get.context!).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox().customSvgWithColor(
                      SvgPath.svgCloseCarve,
                      width: 120,
                      color: Theme.of(Get.context!).colorScheme.inversePrimary,
                    ),
                    Container(
                      width: 70,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          Get.context!,
                        ).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                PrayerDetails(
                  prayerNameTranslated: receivedAction.title,
                  prayerSummary: receivedAction.summary,
                  payload: receivedAction.payload,
                ),
              ],
            ),
          ),
        ),
        isScrollControlled: true,
      ).then((_) async {
        await state.adhanPlayer.stop();
        await InAppAdhanSession.instance.end();
      });
      await playAudio(receivedAction.id, receivedAction.title);
    }
  }

  Future<void> playAudio(int? id, String? title) async {
    final box = GetStorage('AdhanSounds');
    // مفاتيح المقرئ *المختار* — وليس آخر مقرئ حُمّل.
    final String athanIndex =
        box.read<String?>(ADHAN_SELECTED_INDEX) ??
        box.read<String?>(ADHAN_PATH_INDEX) ??
        '0';
    String? audioPath = box.read<String?>('$athanIndex$ADHAN_PATH_AUDIO');
    String? audioFajirPath = box.read<String?>(
      '$athanIndex$ADHAN_PATH_FAJIR_AUDIO',
    );

    // أذان الفجر له نسخته الخاصة؛ يُكشف من العنوان (المعرفات الحالية لا
    // تعود 0 أبداً، والفجر هو الوحيد الذي يمرر عنوانه هنا).
    final bool isFajr = id == 0 || (title != null && title == 'Fajr'.tr);

    log(
      'Audio paths: audioPath=$audioPath, audioFajirPath=$audioFajirPath, '
      'id=$id, isFajr=$isFajr',
      name: 'NotifyHelper',
    );

    // تحديد مسار الصوت المناسب (فجر أو عادي)
    final String? targetPath = isFajr ? audioFajirPath : audioPath;

    // التحقق من وجود الملف المُحمّل
    if (targetPath != null && File(targetPath).existsSync()) {
      try {
        log('Playing downloaded audio: $targetPath', name: 'NotifyHelper');
        await state.adhanPlayer.setAudioSource(AudioSource.file(targetPath));
        await state.adhanPlayer.play();
        return;
      } catch (e, stack) {
        log(
          'Error playing downloaded audio: $e',
          error: e,
          stackTrace: stack,
          name: 'NotifyHelper',
        );
      }
    }

    // على Android، استخدم ملفات raw المحلية عبر MethodChannel
    if (Platform.isAndroid) {
      try {
        // قراءة المسار المحدد للأذان من التخزين
        final String selectedPath = isFajr
            ? (GetStorage('AdhanSounds').read<String?>(ADHAN_PATH_FAJIR) ??
                  'resource://raw/aqsa_fajir_athan')
            : (GetStorage('AdhanSounds').read<String?>(ADHAN_PATH) ??
                  'resource://raw/aqsa_athan');

        // استخراج اسم الملف من المسار
        final String fileName = selectedPath.replaceFirst(
          'resource://raw/',
          '',
        );

        log('Getting raw audio path for: $fileName', name: 'NotifyHelper');

        // استخدام MethodChannel للحصول على مسار الملف من raw
        const channel = MethodChannel('com.alheekmah.aqimApp/raw_audio');
        final String? rawPath = await channel.invokeMethod<String>(
          'getRawAudioPath',
          {'fileName': fileName},
        );

        if (rawPath != null && File(rawPath).existsSync()) {
          log('Playing raw audio from: $rawPath', name: 'NotifyHelper');
          await state.adhanPlayer.setAudioSource(AudioSource.file(rawPath));
          await state.adhanPlayer.play();
          return;
        }
      } catch (e, stack) {
        log(
          'Error playing raw audio via MethodChannel: $e',
          error: e,
          stackTrace: stack,
          name: 'NotifyHelper',
        );
      }
    }

    // إذا لم يكن الملف متوفراً، جرّب الملف الآخر كـ fallback
    final String? fallbackPath = isFajr ? audioPath : audioFajirPath;
    if (fallbackPath != null && File(fallbackPath).existsSync()) {
      try {
        log('Playing fallback audio: $fallbackPath', name: 'NotifyHelper');
        await state.adhanPlayer.setAudioSource(AudioSource.file(fallbackPath));
        await state.adhanPlayer.play();
        return;
      } catch (e, stack) {
        log(
          'Error playing fallback audio: $e',
          error: e,
          stackTrace: stack,
          name: 'NotifyHelper',
        );
      }
    }

    // الحل الأخير: بث الأذان الكامل (m4a) من الكتالوج — يغطي الافتراضي
    // غير المحمّل على iOS/macOS (أندرويد مغطى بموارد raw أعلاه).
    final entry = state.adhanList.firstWhereOrNull(
      (e) => e.index == int.tryParse(athanIndex),
    );
    if (entry?.urlPlayAdhan != null) {
      try {
        final streamUrl = AdhanSoundsCatalog.resolveUrl(entry!.urlPlayAdhan);
        log('Streaming full adhan: $streamUrl', name: 'NotifyHelper');
        await state.adhanPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(streamUrl)),
        );
        await state.adhanPlayer.play();
        return;
      } catch (e, stack) {
        log(
          'Error streaming adhan: $e',
          error: e,
          stackTrace: stack,
          name: 'NotifyHelper',
        );
      }
    }

    log('No audio file available to play', name: 'NotifyHelper');
  }
}
