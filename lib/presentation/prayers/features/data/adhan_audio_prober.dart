import 'dart:io' show File;

import 'package:just_audio/just_audio.dart';

/// فحص قابلية تشغيل ملف صوتي عبر just_audio نفسه: يعيد المدة عند النجاح
/// وnull عند أي فشل (ملف تالف أو صيغة غير قابلة للفك).
class AdhanAudioProber {
  const AdhanAudioProber();

  Future<Duration?> probe(String path) async {
    if (!File(path).existsSync()) return null;
    final player = AudioPlayer();
    try {
      await player.setAudioSource(AudioSource.file(path));
      return player.duration;
    } catch (_) {
      return null;
    } finally {
      await player.dispose();
    }
  }
}
