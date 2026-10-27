import 'dart:io' show Directory, File, FileSystemException;

import 'package:aqim/presentation/feedback/controller/feedback_controller.dart';
import 'package:aqim/presentation/feedback/data/feedback_media_staging.dart';
import 'package:aqim/presentation/feedback/data/feedback_queue.dart';
import 'package:connectivity_kit/connectivity_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// سلوك طابور الملاحظات دون اتصال:
/// - إرسال ملاحظة دون اتصال يعيد علامة queued ويدخل المهمة في الطابور.
/// - ترحيل الوسائط إلى مجلد دائم ثم تنظيفها بعد الانتهاء.
/// - كنس الإقلاع يمسح المجلدات اليتيمة ويبقي ما تشير إليه مهمة قائمة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late _MemoryQueueStore store;
  late TaskQueueService queue;

  setUp(() async {
    Get.reset();
    tempRoot = await Directory.systemTemp.createTemp('feedback_queue_test');

    // path_provider + GetStorage يعتمدان قناة المنصة — نحاكيها بمجلد مؤقت.
    const pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          return tempRoot.path;
        });

    await GetStorage.init();
    await GetStorage().remove('feedback_tokens');

    // خدمة اتصال بلا تهيئة = offline (الحالة الافتراضية قبل init).
    final connection = ConnectionService();
    Get.put(connection, permanent: true);

    store = _MemoryQueueStore();
    queue = TaskQueueService(connectionService: connection, store: store);
    await queue.init();
    Get.put(queue, permanent: true);
  });

  tearDown(() async {
    Get.reset();
    try {
      await tempRoot.delete(recursive: true);
    } on FileSystemException {
      // تجاهل — قد يكون مُمسحًا.
    }
  });

  test('إرسال ملاحظة دون اتصال يعيد علامة queued ويضيف مهمة للطابور', () async {
    final c = FeedbackController.instance;
    final result = await c.submitFeedback('ملاحظة تجريبية');

    expect(result.isLeft, isFalse, reason: 'لا خطأ متوقع دون اتصال');
    final model = result.right;
    expect(model.token, isEmpty, reason: 'token فارغ = أُدخلت الطابور');
    expect(model.status, 'queued');

    expect(queue.pendingTasks, hasLength(1));
    final task = queue.pendingTasks.single;
    expect(task.type, FeedbackQueue.submitType);
    expect(task.payload['message'], 'ملاحظة تجريبية');
    expect(task.payload['app_source'], FeedbackController.appSource);
    // لم يصل شيء للخادم → لا token محفوظ بعد.
    expect(GetStorage().read<List<dynamic>>('feedback_tokens'), isNull);
  });

  test('stage تنقل الملف إلى مجلد دائم وcleanup تحذفه مع مجلده', () async {
    final cacheDir = await Directory('${tempRoot.path}/cache').create();
    final src = File('${cacheDir.path}/shot.png');
    await src.writeAsBytes(List.filled(8, 0));

    final staged = await FeedbackMediaStaging.stage([src]);
    expect(staged, hasLength(1));
    expect(
      await File(staged.single).exists(),
      isTrue,
      reason: 'الملف موجود في المسار الدائم',
    );
    expect(await src.exists(), isFalse, reason: 'الأصل رُحِّل لا نُسخ');
    expect(
      staged.single,
      contains('feedback_queue_media'),
      reason: 'داخل مجلد الترحيل الخاص',
    );

    await FeedbackMediaStaging.cleanup(staged);
    expect(await File(staged.single).exists(), isFalse);
    expect(
      await File(staged.single).parent.exists(),
      isFalse,
      reason: 'المجلد الفارغ يُحذف معه',
    );
  });

  test('sweepOrphans يمسح المجلدات اليتيمة ويبقي ما تشير إليه مهمة', () async {
    final root = Directory('${tempRoot.path}/feedback_queue_media');

    final referencedDir = Directory('${root.path}/1000');
    await referencedDir.create(recursive: true);
    final referencedFile = File('${referencedDir.path}/a.png');
    await referencedFile.writeAsBytes(List.filled(4, 0));

    final orphanDir = Directory('${root.path}/2000');
    await orphanDir.create(recursive: true);
    await File('${orphanDir.path}/b.png').writeAsBytes(List.filled(4, 0));

    await queue.enqueue(
      type: FeedbackQueue.submitType,
      payload: {
        'message': 'x',
        FeedbackMediaStaging.payloadKey: [referencedFile.path],
      },
    );

    await FeedbackMediaStaging.sweepOrphans(queue);

    expect(
      referencedDir.existsSync(),
      isTrue,
      reason: 'المجلد المشدود لمهمة قائمة يبقى',
    );
    expect(orphanDir.existsSync(), isFalse, reason: 'المجلد اليتيم يُمسح');
  });
}

/// مخزن طابور في الذاكرة — يحقق [QueueStore] دون shared_preferences.
class _MemoryQueueStore implements QueueStore {
  final List<QueuedTask> _tasks = [];

  @override
  Future<List<QueuedTask>> load() async => List.of(_tasks);

  @override
  Future<void> save(List<QueuedTask> tasks) async {
    _tasks
      ..clear()
      ..addAll(tasks);
  }
}
