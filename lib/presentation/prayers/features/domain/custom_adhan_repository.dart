import 'local_adhan_audio.dart';

/// Stage 5 owns durable copies; source paths must never become playback paths.
/// Selection and rescheduling belong to a use case, not this file repository.
abstract interface class CustomAdhanRepository {
  Future<List<LocalAdhanAudio>> list();
  Future<LocalAdhanAudio> importAudio({
    required String sourcePath,
    required String name,
  });
  Future<void> rename(String id, String name);
  Future<void> delete(String id);
}
