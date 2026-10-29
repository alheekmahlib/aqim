import 'dart:io' show File;

import 'package:get_storage/get_storage.dart';

import '../../../../core/utils/constants/shared_preferences_constants.dart';
import '../domain/local_adhan_audio.dart';

/// يكتب اختيار المؤذن المخصص في مفاتيح أصوات الأذان القائمة (نفس مسار
/// الفجر وغيره في الإصدار الأول) بفهرس محجوز، ويوثق آخر فهرس قياسي صالح
/// للعودة إليه عند التعطيل أو الحذف. الجدولة وإعادة النشر مسؤولية
/// المتحكم لا هذه الكتابة النقية.
class CustomAdhanSelector {
  const CustomAdhanSelector({
    required this.adhanSounds,
    required this.preferences,
  });

  static const int customIndex = 1000;
  static const String activeIdKey = 'custom_adhan_active_id';
  static const String lastStandardIndexKey = 'custom_adhan_last_standard_index';

  final GetStorage adhanSounds;
  final GetStorage preferences;

  String? get activeAudioId => preferences.read<String?>(activeIdKey);

  int get lastStandardIndex => preferences.read<int>(lastStandardIndexKey) ?? 0;

  bool hasActiveAudio() {
    final id = activeAudioId;
    if (id == null) return false;
    final path = adhanSounds.read<String?>('$customIndex$ADHAN_PATH_AUDIO');
    return path != null && File(path).existsSync();
  }

  /// يكتب مسارات الصوت المخصص للمفاتيح القياسية، ويوثق آخر مؤذن قياسي
  /// كان مختارًا إن كان الاختيار الحالي قياسيًا.
  Future<void> select(LocalAdhanAudio audio) async {
    final currentIndex =
        int.tryParse(adhanSounds.read<String?>(ADHAN_SELECTED_INDEX) ?? '') ??
        0;
    if (currentIndex != customIndex && currentIndex >= 0) {
      await preferences.write(lastStandardIndexKey, currentIndex);
    }

    await adhanSounds.write(ADHAN_SELECTED_INDEX, '$customIndex');
    await adhanSounds.write(ADHAN_PATH, audio.audioPath);
    await adhanSounds.write(ADHAN_PATH_FAJIR, audio.audioPath);
    await adhanSounds.write('$customIndex$ADHAN_PATH_AUDIO', audio.audioPath);
    await adhanSounds.write(
      '$customIndex$ADHAN_PATH_FAJIR_AUDIO',
      audio.audioPath,
    );
    final sound = audio.notificationSoundPath;
    if (sound != null && sound.isNotEmpty) {
      await adhanSounds.write('$customIndex$ADHAN_PATH_SEGMENT_AUDIO', sound);
    } else {
      await adhanSounds.remove('$customIndex$ADHAN_PATH_SEGMENT_AUDIO');
    }
    await preferences.write(activeIdKey, audio.id);
  }

  /// يمسح أثر الاختيار المخصص دون لمس المؤذنين القياسيين.
  Future<void> clearActive() async {
    await preferences.remove(activeIdKey);
    await adhanSounds.remove('$customIndex$ADHAN_PATH_AUDIO');
    await adhanSounds.remove('$customIndex$ADHAN_PATH_FAJIR_AUDIO');
    await adhanSounds.remove('$customIndex$ADHAN_PATH_SEGMENT_AUDIO');
  }
}
