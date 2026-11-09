import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io' show File, Platform;

import 'package:connectivity_kit/connectivity_kit.dart';
import 'package:dio/dio.dart' as dio show FormData, MultipartFile;
import 'package:either_dart/either.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_info/flutter_app_info.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/error_handling_system.dart';
import '../../../core/services/local_notifications_service.dart';
import '../../../core/utils/constants/api_constants.dart';
import '../data/feedback_media_staging.dart';
import '../data/feedback_queue.dart';
import '../data/models/feedback_model.dart';
import '../data/models/feedback_reply_model.dart';
import '../data/models/feedback_thread.dart';

/// إدارة ميزة الملاحظات (تواصل معنا) بالكامل.
///
/// يحفظ **قائمة tokens** محليًا (كل ملاحظة لها token مستقل خاص بها)،
/// يحمّل كل المحادثات للعرض كقائمة، ويدير المحادثة المفتوحة حاليًا.
/// كل اللوجيك هنا — الشاشات مجرد واجهة تستهلك الـ Rx state.
class FeedbackController extends GetxController {
  static FeedbackController get instance =>
      GetInstance().putOrFind(() => FeedbackController());

  final _box = GetStorage();

  /// مفتاح حفظ قائمة الـ tokens في GetStorage.
  static const _tokensKey = 'feedback_tokens';

  /// آخر id رد رآه المستخدم (للكشف عن الردود الجديدة).
  static const _lastReplyKey = 'feedback_last_reply_id';

  /// اسم التطبيق الثابت المُرسل للـ backend.
  static const String appSource = 'أقم - مكتبة الحكمة';

  // ---------- State ----------
  /// قائمة كل المحادثات (لعرضها كقائمة بطاقات).
  final threads = <FeedbackThread>[].obs;

  /// حالة تحميل القائمة.
  final isLoadingList = false.obs;

  /// فشل تحميل القائمة (tokens موجودة لكن الجلب فشل) — لحالة الخطأ مع retry.
  final loadError = false.obs;

  /// حالة الإرسال من ورقة الإرسال.
  final isSubmitting = false.obs;

  /// المحادثة المفتوحة حاليًا (في شاشة المحادثة).
  final openThread = Rxn<FeedbackThread>();

  /// حالة تحميل المحادثة المفتوحة.
  final isLoadingThread = false.obs;

  /// حالة إرسال رد متابعة.
  final isReplying = false.obs;

  // ---------- state الوسائط ----------
  /// الملفات المختارة محليًا قبل الإرسال.
  final selectedFiles = <File>[].obs;

  /// حالة رفع الوسائط.
  final isUploading = false.obs;

  /// تقدّم الرفع الحالي (0.0 - 1.0).
  final uploadProgress = 0.0.obs;

  /// الحد الأقصى لعدد الملفات لكل رسالة.
  static const int maxFiles = 5;

  /// أنواع الصور المسموحة + حد حجمها (10MB).
  static const Set<String> _allowedImageExts = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
  };
  static const int _maxImageBytes = 10 * 1024 * 1024;

  /// أنواع الفيديو المسموحة + حد حجمها (50MB).
  static const Set<String> _allowedVideoExts = {'mp4', 'webm', 'mov'};
  static const int _maxVideoBytes = 50 * 1024 * 1024;

  // ---------- Lifecycle ----------
  /// علامة نتيجة "أُدخلت الطابور": token/id فارغ تتحقق منه الواجهات
  /// لعرض رسالة الانتظار بدل رسالة النجاح الفوري.
  static const FeedbackModel _queuedModel = FeedbackModel(
    id: '',
    token: '',
    message: '',
    status: 'queued',
    published: false,
    createdAt: '',
    updatedAt: '',
  );
  static const FeedbackReplyModel _queuedReply = FeedbackReplyModel(
    id: '',
    feedbackId: '',
    authorRole: 'user',
    body: '',
    createdAt: '',
  );

  /// اشتراك أحداث الطابور لتحديث القائمة عند وصول إرسال مؤجَّل.
  StreamSubscription<QueueEvent>? _queueSubscription;

  @override
  void onInit() {
    super.onInit();
    _loadTokens();
    loadAllThreads();
    checkForNewReplies();
    _listenToQueue();
  }

  @override
  void onClose() {
    _queueSubscription?.cancel();
    super.onClose();
  }

  /// عند نجاح إرسال مؤجَّل في الخلفية: حدّث القائمة والمحادثة المفتوحة.
  void _listenToQueue() {
    if (!Get.isRegistered<TaskQueueService>()) return;
    _queueSubscription = Get.find<TaskQueueService>().events.listen((event) {
      if (event is! QueueTaskSucceeded) return;
      final type = event.task.type;
      if (type != FeedbackQueue.submitType && type != FeedbackQueue.replyType) {
        return;
      }
      loadAllThreads();
      final token = event.task.payload['token']?.toString();
      final open = openThread.value?.feedback.token;
      if (token != null && token.isNotEmpty && token == open) {
        openConversation(token);
      }
    });
  }

  /// يضمن تحميل القائمة عند فتح شاشة الملاحظات (ولو بعد hot restart).
  Future<void> ensureLoaded() async {
    if (isLoadingList.value) return;
    await loadAllThreads();
  }

  // ---------- Tokens ----------
  final _tokens = <String>[].obs;
  List<String> get tokens => _tokens.toList();
  bool get hasFeedback => _tokens.isNotEmpty;

  void _loadTokens() {
    final raw = _box.read<List<dynamic>>(_tokensKey) ?? [];
    _tokens.value = raw.map((e) => e.toString()).toList();
  }

  void _saveTokens() {
    _box.write(_tokensKey, _tokens.toList());
  }

  /// يضيف token جديدًا (بدون تكرار) ويحفظ القائمة.
  void _addToken(String token) {
    if (token.isEmpty) return;
    if (!_tokens.contains(token)) {
      _tokens.insert(0, token); // الأحدث أولًا
      _saveTokens();
    }
  }

  // ---------- قائمة الملاحظات ----------

  /// يحمّل كل المحادثات للـ tokens المحفوظة لعرضها كقائمة بطاقات.
  Future<void> loadAllThreads() async {
    _loadTokens();
    if (_tokens.isEmpty) {
      threads.clear();
      return;
    }
    isLoadingList.value = true;
    loadError.value = false;
    try {
      final loaded = <FeedbackThread>[];
      var anyFailed = false;
      final results = await Future.wait(_tokens.map((t) => _fetchThread(t)));
      for (final r in results) {
        r.fold((_) => anyFailed = true, (thread) => loaded.add(thread));
      }
      loaded.sort(
        (a, b) => b.feedback.createdAt.compareTo(a.feedback.createdAt),
      );
      threads.value = loaded;
      // فشل كل الجلب وبلا نتائج → حالة خطأ (زر إعادة محاولة في القائمة).
      if (loaded.isEmpty && anyFailed) loadError.value = true;
    } finally {
      isLoadingList.value = false;
    }
  }

  /// جلب محادثة واحدة بالـ token (داخلي).
  Future<Either<Failure, FeedbackThread>> _fetchThread(String token) async {
    try {
      final endpoint =
          '${ApiConstants.feedbackApiUrl}${ApiConstants.feedbackEndpoint}/$token';
      final result = await ApiClient().request(
        endpoint: endpoint,
        method: HttpMethod.get,
        printResponse: false,
      );
      return await result.fold((f) => Left(f), (data) {
        final map = _asMap(data);
        if (map == null) return Left(DataSource.DEFAULT.getFailure());
        return Right(FeedbackThread.fromJson(map));
      });
    } catch (e) {
      log('_fetchThread error: $e', name: 'FeedbackController');
      return Left(DataSource.DEFAULT.getFailure());
    }
  }

  // ---------- الإرسال ----------

  /// إرسال ملاحظة جديدة من ورقة الإرسال. يحفظ الـ token ويُحدّث القائمة.
  Future<Either<Failure, FeedbackModel>> submitFeedback(
    String msg, {
    String? email,
    BuildContext? context,
  }) async {
    final trimmed = msg.trim();
    if (trimmed.isEmpty || trimmed.length > 8000) {
      return Left(Failure(400, 'feedbackMessageHint'));
    }

    isSubmitting.value = true;
    try {
      // اجمع معلومات الجهاز قبل أي await (سياق الواجهة لا يُستخدم عبر الفجوات).
      final userMeta = _collectUserMeta(context);

      // دون اتصال: أدخل الطابور مباشرة بدل الفشل (الوسائط تُرحَّل
      // إلى مجلد دائم لتُرفع لاحقًا).
      if (!_isOnline) {
        return await _enqueueSubmit(
          trimmed: trimmed,
          email: email,
          userMeta: userMeta,
        );
      }

      // ارفع الوسائط المختارة أولاً (إن وُجدت) واحصل على روابطها.
      final mediaUrls = await _uploadAllFiles();
      if (mediaUrls == null) {
        // فشل الرفع (اتصال متذبذب غالبًا) — أسقط للطابور بدل إظهار خطأ.
        return await _enqueueSubmit(
          trimmed: trimmed,
          email: email,
          userMeta: userMeta,
        );
      }

      final body = <String, dynamic>{
        'message': trimmed,
        'app_source': appSource,
      };
      if (email != null && email.trim().isNotEmpty) {
        body['contact_email'] = email.trim();
      }
      body['user_meta'] = userMeta;
      if (mediaUrls.isNotEmpty) {
        body['media_urls'] = mediaUrls;
      }

      const endpoint =
          '${ApiConstants.feedbackApiUrl}${ApiConstants.feedbackEndpoint}';

      final result = await ApiClient().request(
        endpoint: endpoint,
        method: HttpMethod.post,
        data: body,
        printResponse: false,
      );

      // فشل شبكي/خادم → الطابور (الروابط رُفعت بالفعل فتُعاد كما هي)؛
      // أما 4xx فهي أخطاء حقيقية تُعرض للمستخدم ولا تستحق إعادة محاولة.
      final failure = result.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) {
        if (_isQueueableFailure(failure)) {
          return await _enqueueSubmit(
            trimmed: trimmed,
            email: email,
            userMeta: userMeta,
            mediaUrls: mediaUrls,
          );
        }
        return Left(failure);
      }

      final map = _asMap(result.right);
      if (map == null) return Left(DataSource.DEFAULT.getFailure());
      final token = map['token']?.toString();
      final dataField = map['data'];
      final feedbackMap = dataField is Map
          ? Map<String, dynamic>.from(dataField)
          : null;
      if (feedbackMap == null) return Left(DataSource.DEFAULT.getFailure());
      final model = FeedbackModel.fromJson(feedbackMap);
      final finalToken = (token != null && token.isNotEmpty)
          ? token
          : model.token;
      if (finalToken.isNotEmpty) {
        _addToken(finalToken);
      }
      clearFiles(); // افرغ القائمة بعد النجاح
      return Right(model);
    } catch (e) {
      log('submitFeedback error: $e', name: 'FeedbackController');
      return Left(DataSource.DEFAULT.getFailure());
    } finally {
      isSubmitting.value = false;
    }
  }

  // ---------- الطابور دون اتصال ----------

  /// هل يوجد اتصال الآن؟ (بحسب خدمة المراقبة المسجَّلة في main).
  bool get _isOnline =>
      Get.isRegistered<ConnectionService>() &&
      Get.find<ConnectionService>().currentStatus.isOnline;

  /// هل الفشل شبكي/خادم يستحق الدخول في الطابور؟
  /// في نظام أخطاء هذا التطبيق الأكواد السالبة/الصفرية أخطاء عميل
  /// شبكية، و5xx أخطاء خادم عابرة — أما 4xx فلا تنجح بإعادة المحاولة.
  bool _isQueueableFailure(Failure failure) =>
      failure.code <= 0 || failure.code >= 500;

  /// يضيف ملاحظة جديدة إلى الطابور ويعيد علامة queued.
  ///
  /// [mediaUrls] لروابط رُفعت بالفعل (فشل POST بعد نجاح الرفع)، وإلا
  /// تُرحَّل الملفات المختارة إلى مجلد دائم ليرفعها المعالج لاحقًا.
  Future<Either<Failure, FeedbackModel>> _enqueueSubmit({
    required String trimmed,
    String? email,
    Map<String, dynamic>? userMeta,
    List<String> mediaUrls = const [],
  }) async {
    final staged = selectedFiles.isNotEmpty && mediaUrls.isEmpty
        ? await FeedbackMediaStaging.stage(selectedFiles)
        : const <String>[];
    await Get.find<TaskQueueService>().enqueue(
      type: FeedbackQueue.submitType,
      payload: <String, dynamic>{
        'message': trimmed,
        'app_source': appSource,
        'user_meta': userMeta ?? <String, dynamic>{},
        if (email != null && email.trim().isNotEmpty)
          'contact_email': email.trim(),
        if (mediaUrls.isNotEmpty) 'media_urls': mediaUrls,
        if (staged.isNotEmpty) FeedbackMediaStaging.payloadKey: staged,
      },
    );
    clearFiles();
    return const Right(_queuedModel);
  }

  /// يضيف رد متابعة إلى الطابور ويعيد علامة queued.
  Future<Either<Failure, FeedbackReplyModel>> _enqueueReply({
    required String token,
    required String body,
    List<String> mediaUrls = const [],
  }) async {
    if (body.isEmpty && selectedFiles.isEmpty && mediaUrls.isEmpty) {
      return Left(Failure(400, 'feedbackReplyHint'));
    }
    final staged = selectedFiles.isNotEmpty && mediaUrls.isEmpty
        ? await FeedbackMediaStaging.stage(selectedFiles)
        : const <String>[];
    await Get.find<TaskQueueService>().enqueue(
      type: FeedbackQueue.replyType,
      payload: <String, dynamic>{
        'token': token,
        'body': body,
        if (mediaUrls.isNotEmpty) 'media_urls': mediaUrls,
        if (staged.isNotEmpty) FeedbackMediaStaging.payloadKey: staged,
      },
    );
    clearFiles();
    return const Right(_queuedReply);
  }

  // ---------- المحادثة المفتوحة ----------

  /// فتح محادثة للعرض في شاشة المحادثة.
  Future<void> openConversation(String token) async {
    isLoadingThread.value = true;
    openThread.value = null;
    try {
      final result = await _fetchThread(token);
      result.fold((_) => null, (t) {
        openThread.value = t;
        _markThreadSeen(t);
      });
    } finally {
      isLoadingThread.value = false;
    }
  }

  /// إرسال رد متابعة في المحادثة المفتوحة.
  /// يقبل وسائط فقط (دون نص) — النص مطلوب فقط إن لم تكن هناك وسائط.
  Future<Either<Failure, FeedbackReplyModel>> sendReply(String body) async {
    final token = openThread.value?.feedback.token;
    if (token == null || token.isEmpty) {
      return Left(Failure(404, 'feedbackNoNotesYet'));
    }
    final trimmed = body.trim();

    isReplying.value = true;
    try {
      // دون اتصال: رد نصي/بوسائط مرحَّلة يدخل الطابور بدل الفشل.
      if (!_isOnline) {
        return await _enqueueReply(token: token, body: trimmed);
      }

      // ارفع الوسائط المختارة أولاً (إن وُجدت).
      final mediaUrls = await _uploadAllFiles();
      if (mediaUrls == null) {
        // اتصال متذبذب — أسقط للطابور بدل إظهار خطأ.
        return await _enqueueReply(token: token, body: trimmed);
      }
      // النص مطلوب فقط إن لم تكن هناك وسائط.
      if (trimmed.isEmpty && mediaUrls.isEmpty) {
        return Left(Failure(400, 'feedbackReplyHint'));
      }

      final endpoint =
          '${ApiConstants.feedbackApiUrl}${ApiConstants.feedbackEndpoint}/$token${ApiConstants.feedbackReplySuffix}';
      final payload = <String, dynamic>{'body': trimmed};
      if (mediaUrls.isNotEmpty) {
        payload['media_urls'] = mediaUrls;
      }
      final result = await ApiClient().request(
        endpoint: endpoint,
        method: HttpMethod.post,
        data: payload,
        printResponse: false,
      );

      // فشل شبكي/خادم → الطابور؛ أما 4xx فأخطاء حقيقية تُعرض للمستخدم.
      final failure = result.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) {
        if (_isQueueableFailure(failure)) {
          return await _enqueueReply(
            token: token,
            body: trimmed,
            mediaUrls: mediaUrls,
          );
        }
        return Left(failure);
      }

      final map = _asMap(result.right);
      final replyMap = map == null
          ? null
          : (map['data'] is Map
                ? Map<String, dynamic>.from(map['data'])
                : null);
      if (replyMap == null) return Left(DataSource.DEFAULT.getFailure());
      final reply = FeedbackReplyModel.fromJson(replyMap);
      // أضف الرد محليًا للمحادثة المفتوحة + للقائمة.
      final current = openThread.value;
      if (current != null) {
        final updated = current.copyWith(replies: [...current.replies, reply]);
        openThread.value = updated;
        _upsertThreadInList(updated);
      }
      return Right(reply);
    } catch (e) {
      log('sendReply error: $e', name: 'FeedbackController');
      return Left(DataSource.DEFAULT.getFailure());
    } finally {
      isReplying.value = false;
    }
  }

  /// يحدّث/يضيف محادثة في قائمة [threads].
  void _upsertThreadInList(FeedbackThread updated) {
    final idx = threads.indexWhere(
      (t) => t.feedback.token == updated.feedback.token,
    );
    if (idx >= 0) {
      final list = threads.toList();
      list[idx] = updated;
      threads.value = list;
    } else {
      threads.insert(0, updated);
    }
  }

  // ---------- اختيار ورفع الوسائط ----------

  /// يفتح حوار اختيار الصور (متعددة). يعمل على كل المنصات بما فيها macOS.
  ///
  /// يستخدم `file_picker` لأن `image_picker` لا تدعم سطح المكتب.
  /// يتحقق من النوع والحجم والحد الأقصى.
  Future<String?> pickImages() async {
    if (selectedFiles.length >= maxFiles) return 'feedback_max_files';

    try {
      // منذ file_picker v13: pickFiles تُرجع List<PlatformFile> مباشرة
      // (قائمة فارغة عند الإلغاء) والاختيار المتعدد هو السلوك الافتراضي.
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isEmpty) return null; // ألغى المستخدم

      for (final pf in files) {
        if (selectedFiles.length >= maxFiles) break;
        final path = pf.path;
        if (path == null || path.isEmpty) continue;
        final ext = _extension(path);

        if (!_allowedImageExts.contains(ext)) {
          return 'feedback_invalid_type';
        }
        if ((pf.lengthSync() ?? 0) > _maxImageBytes) {
          return 'feedback_file_too_large';
        }
        selectedFiles.add(File(path));
      }
      return null; // نجاح
    } catch (e) {
      log('pickImages error: $e', name: 'FeedbackController');
      return 'feedback_invalid_type';
    }
  }

  /// يفتح حوار اختيار فيديو واحد. يعمل على كل المنصات بما فيها macOS.
  Future<String?> pickVideo() async {
    if (selectedFiles.length >= maxFiles) return 'feedback_max_files';

    try {
      // pickFile (جديد في v13) لاختيار ملف واحد — تُرجع null عند الإلغاء.
      final pf = await FilePicker.pickFile(type: FileType.video);
      if (pf == null) return null; // ألغى المستخدم

      final path = pf.path;
      if (path == null || path.isEmpty) return null;
      final ext = _extension(path);

      if (!_allowedVideoExts.contains(ext)) {
        return 'feedback_invalid_type';
      }
      if ((pf.lengthSync() ?? 0) > _maxVideoBytes) {
        return 'feedback_file_too_large';
      }
      selectedFiles.add(File(path));
      return null; // نجاح
    } catch (e) {
      log('pickVideo error: $e', name: 'FeedbackController');
      return 'feedback_invalid_type';
    }
  }

  /// يزيل ملفًا من القائمة المختارة بالـ index.
  void removeFileAt(int index) {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles.removeAt(index);
    }
  }

  /// يفرّغ قائمة الملفات المختارة (بعد الإرسال أو الإلغاء).
  void clearFiles() {
    selectedFiles.clear();
    uploadProgress.value = 0.0;
  }

  /// هل الملف فيديو؟ (حسب الامتداد).
  bool isVideoFile(File file) {
    return _allowedVideoExts.contains(_extension(file.path));
  }

  /// يرفع كل الملفات المختارة عبر [ApiClient.uploadFile].
  ///
  /// يُرجع قائمة الروابط عند النجاح، أو `null` عند الفشل.
  Future<List<String>?> _uploadAllFiles() async {
    if (selectedFiles.isEmpty) return const [];

    isUploading.value = true;
    uploadProgress.value = 0.0;
    final urls = <String>[];
    const endpoint =
        '${ApiConstants.feedbackApiUrl}${ApiConstants.feedbackUploadEndpoint}';

    try {
      for (var i = 0; i < selectedFiles.length; i++) {
        final file = selectedFiles[i];
        final fileName = file.path.split('/').last;
        final formField = await dio.MultipartFile.fromFile(
          file.path,
          filename: fileName,
        );
        final formData = dio.FormData.fromMap({'file': formField});

        final result = await ApiClient().uploadFile(
          endpoint: endpoint,
          data: formData,
          onSendProgress: (sent, total) {
            if (total > 0) {
              final fileFraction = (i + (sent / total)) / selectedFiles.length;
              uploadProgress.value = fileFraction.clamp(0.0, 1.0);
            }
          },
          printResponse: false,
        );

        if (result.isLeft) {
          log(
            'upload failed: ${result.left.message}',
            name: 'FeedbackController',
          );
          uploadProgress.value = 0.0;
          return null;
        }
        final data = result.right;
        final url = data is Map ? data['url']?.toString() : null;
        if (url == null || url.isEmpty) {
          uploadProgress.value = 0.0;
          return null;
        }
        urls.add(url);
      }
      uploadProgress.value = 1.0;
      return urls;
    } catch (e) {
      log('_uploadAllFiles error: $e', name: 'FeedbackController');
      uploadProgress.value = 0.0;
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }

  // ---------- الإشعارات عند وصول رد جديد ----------

  /// يفحص كل المحادثات للكشف عن ردود مشرف جديدة ويطلق إشعارًا فوريًا لكل رد.
  Future<void> checkForNewReplies() async {
    await checkNewRepliesBackground(box: _box);
  }

  /// نسخة ثابتة مستقلة للاستدعاء من الخلفية ([BGServices]).
  ///
  /// لا تعتمد على Rx state ولا ترجمات GetX ولا تحتاج لإنشاء controller.
  /// تقرأ الـ tokens مباشرة من GetStorage (المُهيّأ في أي isolate).
  @pragma('vm:entry-point')
  static Future<void> checkNewRepliesBackground({GetStorage? box}) async {
    final storage = box ?? GetStorage();
    try {
      final raw = storage.read<List<dynamic>>(_tokensKey) ?? [];
      final tokens = raw.map((e) => e.toString()).toList();
      if (tokens.isEmpty) return;

      final lastSeen = storage.read<int>(_lastReplyKey) ?? 0;
      int newMax = lastSeen;
      for (final token in tokens) {
        final result = await _fetchThreadStatic(token);
        if (result.isLeft) continue;
        final thread = result.right;
        final adminReplies = thread.replies.where((r) => r.isAdmin);
        for (final reply in adminReplies) {
          final idInt = _replyIdAsInt(reply.id);
          if (idInt > lastSeen) {
            final title = _trStatic(
              'feedbackReplyTitle',
              fallback: 'رد المشرف',
            );
            await LocalNotificationsService.instance.showNotification(
              // نطاق 900000+ بعيد عن إشعارات الصلوات (20000–21000).
              id: 900000 + (reply.id.hashCode.abs() % 99999),
              title: title,
              body: reply.body,
              soundType: 'bell',
              payload: {
                'type': 'feedback_reply',
                'feedback_token': token,
                'reply_id': reply.id,
                'title': title,
              },
            );
            if (idInt > newMax) newMax = idInt;
          }
        }
      }
      if (newMax > lastSeen) {
        storage.write(_lastReplyKey, newMax);
      }
    } catch (e) {
      log('checkNewRepliesBackground error: $e', name: 'FeedbackController');
    }
  }

  /// جلب محادثة واحدة (نسخة ثابتة للخلفية).
  static Future<Either<Failure, FeedbackThread>> _fetchThreadStatic(
    String token,
  ) async {
    try {
      final endpoint =
          '${ApiConstants.feedbackApiUrl}${ApiConstants.feedbackEndpoint}/$token';
      final result = await ApiClient().request(
        endpoint: endpoint,
        method: HttpMethod.get,
        printResponse: false,
      );
      return await result.fold((f) => Left(f), (data) {
        final map = _asMapStatic(data);
        if (map == null) return Left(DataSource.DEFAULT.getFailure());
        return Right(FeedbackThread.fromJson(map));
      });
    } catch (e) {
      log('_fetchThreadStatic error: $e', name: 'FeedbackController');
      return Left(DataSource.DEFAULT.getFailure());
    }
  }

  /// ترجمة آمنة للخلفية: ترجع القيمة المُترجمة إن وُجدت، وإلا fallback.
  static String _trStatic(String key, {required String fallback}) {
    try {
      final translated = key.tr;
      return translated == key ? fallback : translated;
    } catch (_) {
      return fallback;
    }
  }

  static int _replyIdAsInt(String id) => int.tryParse(id) ?? id.hashCode;

  void _markThreadSeen(FeedbackThread t) {
    if (t.replies.isEmpty) return;
    final lastSeen = _box.read<int>(_lastReplyKey) ?? 0;
    final maxInThread = t.replies
        .map((r) => _replyIdAsInt(r.id))
        .fold(lastSeen, (a, b) => a > b ? a : b);
    if (maxInThread > lastSeen) {
      _box.write(_lastReplyKey, maxInThread);
    }
  }

  // ---------- Helpers ----------

  /// يجمع معلومات الجهاز تلقائيًا (بدون سؤال المستخدم).
  Map<String, dynamic> _collectUserMeta(BuildContext? context) {
    String appVersion = '';
    String osName = '';
    String osVersion = '';
    if (context != null) {
      try {
        final info = AppInfo.of(context);
        appVersion = '${info.package.versionWithoutBuild}';
        osName = info.platform.operatingSystem;
        osVersion = info.platform.operatingSystemVersion;
      } catch (_) {}
    }
    if (appVersion.isEmpty) appVersion = 'unknown';
    if (osName.isEmpty) osName = Platform.operatingSystem;
    if (osVersion.isEmpty) osVersion = Platform.operatingSystemVersion;

    return {
      'platform': Platform.operatingSystem, // android | ios | macos
      'app_version': appVersion,
      'device_model': '',
      'os_version': osVersion,
      'language': Get.locale?.languageCode ?? 'ar',
      'os_name': osName,
    };
  }

  Map<String, dynamic>? _asMap(dynamic data) => _asMapStatic(data);

  static Map<String, dynamic>? _asMapStatic(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }
}
