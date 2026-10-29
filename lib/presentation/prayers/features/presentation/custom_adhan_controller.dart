import 'dart:async';
import 'dart:developer' show log;

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;

import '../../prayers.dart';
import '../data/custom_adhan_selector.dart';
import '../data/stored_custom_adhan_repository.dart';
import '../domain/custom_adhan_repository.dart';
import '../domain/local_adhan_audio.dart';

/// متحكم المؤذن المخصص: الاستيراد والمعاينة والاختيار وإعادة التسمية
/// والحذف، مع العودة لآخر مؤذن قياسي صالح وإعادة الجدولة عند تعطيل
/// الميزة أو حذف المختار. فشل الاستيراد لا يغيّر الاختيار السابق.
class CustomAdhanController extends GetxController {
  CustomAdhanController({
    required this.repository,
    required this.selector,
    required this.pickAudioFile,
    required this.reschedule,
    required this.selectStandardAdhan,
    required this.probeForPreview,
  });

  final CustomAdhanRepository repository;
  final CustomAdhanSelector selector;
  final Future<String?> Function() pickAudioFile;
  final Future<void> Function() reschedule;
  final Future<void> Function(int standardIndex) selectStandardAdhan;
  final Future<Duration?> Function(String path) probeForPreview;

  final audios = <LocalAdhanAudio>[].obs;
  final importing = false.obs;
  final errorKey = ''.obs;
  final previewingId = ''.obs;

  String? get activeAudioId =>
      audios.any((audio) => audio.id == selector.activeAudioId)
      ? selector.activeAudioId
      : null;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    try {
      audios.value = await repository.list();
    } catch (error, stack) {
      log('Custom adhan list failed', error: error, stackTrace: stack);
      errorKey.value = 'customAdhanLoadFailed';
    }
  }

  /// استيراد ملف محلي؛ لا يلمس الاختيار الحالي عند الفشل.
  Future<void> importAudio() async {
    if (importing.value) return;
    importing.value = true;
    errorKey.value = '';
    try {
      final source = await pickAudioFile();
      if (source == null) return;
      final baseName = source.split('/').last;
      final name = baseName.contains('.')
          ? baseName.substring(0, baseName.lastIndexOf('.'))
          : baseName;
      await repository.importAudio(sourcePath: source, name: name);
      await load();
    } on CustomAdhanImportException catch (error) {
      errorKey.value = error.messageKey;
    } catch (error, stack) {
      log('Custom adhan import failed', error: error, stackTrace: stack);
      errorKey.value = 'customAdhanImportFailed';
    } finally {
      importing.value = false;
    }
  }

  /// اختيار المؤذن المخصص وتحديث حالة الواجهة وإعادة الجدولة.
  Future<void> select(LocalAdhanAudio audio) async {
    await selector.select(audio);
    final ctrl = PrayersNotificationsCtrl.instance;
    ctrl.state.selectedAdhanPath.value = audio.audioPath;
    ctrl.state.selectedAdhanPathFajir.value = audio.audioPath;
    await reschedule();
  }

  /// حذف مؤذن؛ إن كان المختار فعودة لآخر قياسي صالح ثم إعادة الجدولة.
  Future<void> delete(String id) async {
    final wasActive = selector.activeAudioId == id;
    await repository.delete(id);
    if (wasActive) {
      await fallbackToStandard();
    }
    await load();
  }

  Future<void> rename(String id, String name) async {
    await repository.rename(id, name);
    await load();
  }

  /// العودة لآخر مؤذن قياسي صالح (عند التعطيل أو حذف المختار).
  Future<bool> fallbackToStandard() async {
    if (!selector.hasActiveAudio()) return false;
    final index = selector.lastStandardIndex;
    await selectStandardAdhan(index);
    await selector.clearActive();
    await reschedule();
    return true;
  }

  /// معاينة سريعة عبر مشغّل المعاينات نفسه؛ المدة من الفاحص.
  Future<void> preview(LocalAdhanAudio audio) async {
    if (previewingId.value == audio.id) {
      await _stopPreview();
      return;
    }
    final duration = await probeForPreview(audio.audioPath);
    if (duration == null) {
      errorKey.value = 'customAdhanUnplayable';
      return;
    }
    final player = PrayersNotificationsCtrl.instance.state.audioPlayer;
    await player.stop();
    await player.setFilePath(audio.audioPath);
    previewingId.value = audio.id;
    unawaited(
      player.playerStateStream
          .firstWhere(
            (state) => state.processingState == ProcessingState.completed,
          )
          .then((_) => _stopPreview())
          .catchError((_) {}),
    );
    await player.play();
  }

  Future<void> _stopPreview() async {
    previewingId.value = '';
    try {
      await PrayersNotificationsCtrl.instance.state.audioPlayer.stop();
    } catch (_) {}
  }
}
