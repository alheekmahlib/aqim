import 'dart:io' show Directory, File, Platform;

import 'package:get_storage/get_storage.dart';

import '../domain/custom_adhan_repository.dart';
import '../domain/local_adhan_audio.dart';

/// استثناءات الاستيراد المعروفة لعرضها برسائل مترجمة.
class CustomAdhanImportException implements Exception {
  const CustomAdhanImportException(this.messageKey);

  /// مفتاح الترجمة لسبب الفشل (صيغة غير مدعومة / ملف غير قابل للتشغيل /
  /// فشل تجهيز نسخة الإشعار).
  final String messageKey;

  @override
  String toString() => messageKey;
}

/// مستودع المؤذنين المحليين: نسخ دائمة داخل مجلد التطبيق (لا تُشغَّل من
/// مسار المصدر أبدًا)، فهرس في GetStorage، فحص قابلية تشغيل قبل اعتماد
/// الملف، وتجهيز نسخة إشعار iOS (اختياري عبر حقن). المعطوب يُقلَّع من
/// الفهرس تلقائيًا عند القراءة.
class StoredCustomAdhanRepository implements CustomAdhanRepository {
  StoredCustomAdhanRepository({
    required this.baseDirectory,
    required this.storage,
    required this.probeDuration,
    required this.prepareNotificationCopy,
    required this.removeNotificationCopy,
  });

  static const indexKey = 'custom_adhan_sounds_v1';
  static const supportedExtensions = ['mp3', 'm4a', 'wav'];

  final Future<Directory> Function() baseDirectory;
  final GetStorage storage;
  final Future<Duration?> Function(String path) probeDuration;
  final Future<String?> Function(String sourcePath, String id)
  prepareNotificationCopy;
  final Future<void> Function(String notificationSoundPath)
  removeNotificationCopy;

  @override
  Future<List<LocalAdhanAudio>> list() async {
    final entries = _readEntries();
    final valid = <Map<String, dynamic>>[];
    final audios = <LocalAdhanAudio>[];
    for (final entry in entries) {
      final audio = _audioFromEntry(entry);
      if (audio == null) {
        // تلف: الملف الدائم مفقود؛ نظّف نسخة الإشعار إن وجدت.
        final sound = entry['notificationSoundPath'] as String?;
        if (sound != null && sound.isNotEmpty) {
          await removeNotificationCopy(sound);
        }
        continue;
      }
      valid.add(entry);
      audios.add(audio);
    }
    if (valid.length != entries.length) {
      await storage.write(indexKey, valid);
    }
    return audios;
  }

  @override
  Future<LocalAdhanAudio> importAudio({
    required String sourcePath,
    required String name,
  }) async {
    final extension = sourcePath.split('.').last.toLowerCase();
    if (!supportedExtensions.contains(extension)) {
      throw const CustomAdhanImportException('customAdhanUnsupportedFormat');
    }

    // فحص قابلية التشغيل قبل اعتماد الملف.
    final duration = await probeDuration(sourcePath);
    if (duration == null || duration.inMilliseconds <= 0) {
      throw const CustomAdhanImportException('customAdhanUnplayable');
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final dir = await baseDirectory();
    await dir.create(recursive: true);
    final durablePath =
        '${dir.path}${Platform.pathSeparator}'
        'custom_$id.$extension';
    await File(sourcePath).copy(durablePath);

    String? notificationSoundPath;
    try {
      notificationSoundPath = await prepareNotificationCopy(durablePath, id);
    } catch (_) {
      await File(durablePath).delete().catchError((_) => File(durablePath));
      throw const CustomAdhanImportException('customAdhanConversionFailed');
    }

    final audio = LocalAdhanAudio(
      id: id,
      name: name.trim().isEmpty ? 'مؤذن مخصص' : name.trim(),
      duration: duration,
      audioPath: durablePath,
      notificationSoundPath: notificationSoundPath,
    );
    final entries = _readEntries()
      ..add({
        'id': audio.id,
        'name': audio.name,
        'durationMs': audio.duration.inMilliseconds,
        'audioPath': audio.audioPath,
        'notificationSoundPath': audio.notificationSoundPath,
      });
    await storage.write(indexKey, entries);
    return audio;
  }

  @override
  Future<void> rename(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final entries = _readEntries();
    for (final entry in entries) {
      if (entry['id'] == id) {
        entry['name'] = trimmed;
        break;
      }
    }
    await storage.write(indexKey, entries);
  }

  @override
  Future<void> delete(String id) async {
    final entries = _readEntries();
    final kept = <Map<String, dynamic>>[];
    for (final entry in entries) {
      if (entry['id'] == id) {
        final audio = _audioFromEntry(entry);
        if (audio != null) {
          await File(
            audio.audioPath,
          ).delete().catchError((_) => File(audio.audioPath));
          final sound = audio.notificationSoundPath;
          if (sound != null && sound.isNotEmpty) {
            await removeNotificationCopy(sound);
          }
        }
      } else {
        kept.add(entry);
      }
    }
    await storage.write(indexKey, kept);
  }

  List<Map<String, dynamic>> _readEntries() {
    final raw = storage.read<List<dynamic>>(indexKey) ?? const [];
    return [
      for (final entry in raw)
        if (entry is Map<dynamic, dynamic>) Map<String, dynamic>.from(entry),
    ];
  }

  LocalAdhanAudio? _audioFromEntry(Map<String, dynamic> entry) {
    final path = entry['audioPath'] as String?;
    if (path == null || !File(path).existsSync()) return null;
    return LocalAdhanAudio(
      id: entry['id'] as String? ?? '',
      name: entry['name'] as String? ?? '',
      duration: Duration(milliseconds: entry['durationMs'] as int? ?? 0),
      audioPath: path,
      notificationSoundPath: entry['notificationSoundPath'] as String?,
    );
  }
}
