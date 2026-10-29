import 'dart:io';

import 'package:aqim/presentation/prayers/features/data/stored_custom_adhan_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  late Directory suiteDir;
  late Directory tempDir;
  late GetStorage storage;

  Future<StoredCustomAdhanRepository> build({
    Future<Duration?> Function(String path)? probe,
    Future<String?> Function(String sourcePath, String id)? prepare,
    Future<void> Function(String path)? removeSound,
  }) async {
    final dir = Directory('${tempDir.path}/custom_adhan');
    return StoredCustomAdhanRepository(
      baseDirectory: () async => dir,
      storage: storage,
      probeDuration: probe ?? ((path) async => const Duration(seconds: 90)),
      prepareNotificationCopy:
          prepare ??
          ((sourcePath, id) async => 'Library/Sounds/custom_$id.wav'),
      removeNotificationCopy: removeSound ?? ((_) async {}),
    );
  }

  Future<File> sourceFile(String name, {String content = 'x'}) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  // mock يبقى طوال المجموعة: تدفقات GetStorage المؤجلة تكتب بعد انتهاء
  // الاختبار الفردي فلا يصح إزالته في tearDown لكل اختبار.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    suiteDir = await Directory.systemTemp.createTemp('custom_adhan_suite');
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => suiteDir.path);
  });

  setUp(() async {
    tempDir = Directory(
      '${suiteDir.path}/${DateTime.now().microsecondsSinceEpoch}',
    );
    await tempDir.create(recursive: true);
    storage = GetStorage(
      'customAdhanTest${DateTime.now().microsecondsSinceEpoch}',
      tempDir.path,
    );
    await storage.initStorage;
  });

  tearDown(() async {
    tempDir.deleteSync(recursive: true);
  });

  test('import probes, copies durably and records the entry', () async {
    final repo = await build();
    final source = await sourceFile('my_adhan.mp3');

    final audio = await repo.importAudio(
      sourcePath: source.path,
      name: 'مؤذن الحي',
    );

    expect(audio.duration, const Duration(seconds: 90));
    expect(File(audio.audioPath).existsSync(), isTrue);
    expect(audio.audioPath, contains('custom_adhan'));
    expect(audio.audioPath, isNot(source.path));
    expect(audio.notificationSoundPath, contains('custom_'));
    expect((await repo.list()).map((a) => a.id), [audio.id]);

    // النسخة الدائمة تبقى بعد حذف المصدر.
    await source.delete();
    expect(File(audio.audioPath).existsSync(), isTrue);
    expect((await repo.list()), hasLength(1));
  });

  test(
    'rejects unsupported formats and unplayable files without any change',
    () async {
      final repo = await build();
      final txt = await sourceFile('notes.txt');

      await expectLater(
        repo.importAudio(sourcePath: txt.path, name: 'x'),
        throwsA(isA<CustomAdhanImportException>()),
      );

      final broken = await sourceFile('broken.mp3');
      final probingRepo = await build(
        probe: (_) async => null, // غير قابل للتشغيل
      );
      await expectLater(
        probingRepo.importAudio(sourcePath: broken.path, name: 'x'),
        throwsA(isA<CustomAdhanImportException>()),
      );
      expect(await probingRepo.list(), isEmpty);
      expect(Directory('${tempDir.path}/custom_adhan').existsSync(), isFalse);
    },
  );

  test(
    'conversion failure cleans the durable copy and fails the import',
    () async {
      final repo = await build(
        prepare: (sourcePath, id) async => throw StateError('boom'),
      );
      final source = await sourceFile('voice.m4a');

      await expectLater(
        repo.importAudio(sourcePath: source.path, name: 'x'),
        throwsA(isA<CustomAdhanImportException>()),
      );
      expect(Directory('${tempDir.path}/custom_adhan').listSync(), isEmpty);
      expect(await repo.list(), isEmpty);
    },
  );

  test(
    'list prunes corrupted entries and cleans their notification copies',
    () async {
      final repo = await build();
      final source = await sourceFile('a.wav');
      final audio = await repo.importAudio(sourcePath: source.path, name: 'a');

      await File(audio.audioPath).delete();
      final removed = <String>[];
      final pruningRepo = await build(
        removeSound: (path) async => removed.add(path),
      );

      expect(await pruningRepo.list(), isEmpty);
      expect(removed, [audio.notificationSoundPath]);
    },
  );

  test('rename updates the name; delete removes files and copies', () async {
    final repo = await build();
    final source = await sourceFile('b.mp3');
    final audio = await repo.importAudio(sourcePath: source.path, name: 'b');
    final durableCopy = File(audio.audioPath);

    await repo.rename(audio.id, 'new name');
    final renamed = (await repo.list()).single;
    expect(renamed.name, 'new name');

    final removed = <String>[];
    final deletingRepo = await build(
      removeSound: (path) async => removed.add(path),
    );
    await deletingRepo.delete(audio.id);
    expect(await deletingRepo.list(), isEmpty);
    expect(durableCopy.existsSync(), isFalse);
    expect(removed, [audio.notificationSoundPath]);
  });
}
