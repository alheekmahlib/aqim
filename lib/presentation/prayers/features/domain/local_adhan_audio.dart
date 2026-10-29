class LocalAdhanAudio {
  const LocalAdhanAudio({
    required this.id,
    required this.name,
    required this.duration,
    required this.audioPath,
    this.notificationSoundPath,
  });

  final String id;
  final String name;
  final Duration duration;
  final String audioPath;
  final String? notificationSoundPath;
}
