# قسم "تواصل معنا" الجديد (نظام ملاحظات) — خطة التنفيذ

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** استبدال خيار "تواصل معنا" (mailto) في تطبيق أقم بنظام ملاحظات/محادثات متكامل مطابق لتطبيق القرآن، مبنيًا على widgets أقم القائمة.

**Architecture:** ميزة مستقلة في `lib/presentation/feedback/` (controller + models + screens + widgets). كل المنطق في `FeedbackController` (GetX + Rx state، بلا مصادقة — token محلي لكل ملاحظة في GetStorage). الشبكة عبر `ApiClient` القائم + دالة `uploadFile` جديدة. الإشعارات عبر `LocalNotificationsService` القائم، والفحص الخلفي من `_executeBackgroundTask` القائم في `background_services.dart`.

**Tech Stack:** Flutter + GetX 4.7.3 + get_it + Dio (ApiClient) + either_dart + GetStorage + image_picker ^1.2.3 (جديدة) + flutter_local_notifications + flutter_screenutil (360×690) + bot_toast.

**Spec:** `docs/superpowers/specs/2026-08-19-contact-us-feedback-design.md`

## Global Constraints

- المرجع الحرفي للمنطق: `alquranalkareem/lib/presentation/screens/feedback/` — الكود منقول ومكيّف، ليس مُعاد اختراعه.
- `app_source` الثابت المُرسل للخادم: `'أقم - مكتبة الحكمة'`.
- لا `commit` ولا `push` إلا بإذن صريح من المالك (قاعدة AGENTS.md). خطوات Commit أدناه تُنفَّذ فقط بعد إذنه، وإلا تُتخطى مع إبقاء التغييرات staged/متاحة.
- `dart format` على كل ملف جديد/معدل + `flutter analyze` بلا أخطاء جديدة + `flutter_lints` 5.x.
- لا نصوص صلبة داخل الواجهات — كل النصوص مفاتيح ترجمة.
- مفاتيح الترجمة الـ 22 الجديدة (لا توجد أي منها في الملفات حاليًا — تم التحقق): `feedbackSendNote`, `feedbackSubtitle`, `feedbackMessageHint`, `feedbackContactOptional`, `feedbackSentSuccess`, `feedbackSentError`, `feedbackNoNotesYet`, `feedbackReplyHint`, `feedbackReplyTitle`, `feedbackStatusPlanned`, `feedbackStatusInProgress`, `feedbackStatusComplete`, `feedbackAdminRole`, `feedbackYouRole`, `feedbackPickImages`, `feedbackPickVideo`, `feedbackMaxFiles`, `feedbackFileTooLarge`, `feedbackInvalidType`, `feedbackUploading`, `charactersRemaining`, `retry`.
- شاشة القائمة تعنونها بمفتاح `email` الموجود مسبقًا (= "تواصل معنا") — لا مفتاح جديد للعنوان.
- مسار التنقل دائمًا `Get.toNamed` + `Transition.fadeIn` (اتفاقية AppRouter).
- كل الأبعاد بـ flutter_screenutil (`.w/.h/.sp`) والخط `fontFamily: 'cairo'` كما في بقية التطبيق.
- المعرفات لإشعارات الملاحظات: `900000 + (reply.id.hashCode.abs() % 99999)` — بعيدًا عن نطاق إشعارات الصلوات (20000–21000).

---

### Task 1: التبعيات وإعدادات المنصات

**Files:**
- Modify: `pubspec.yaml`
- Modify: `ios/Runner/Info.plist`
- Modify (إن لزم): `macos/Runner/*.entitlements`

**Interfaces:**
- Produces: حزمة `image_picker` متاحة للاستيراد في كل المهام التالية.

- [ ] **Step 1: أضف image_picker إلى pubspec.yaml**

في `dependencies:`، بين `home_widget:` و`huawei_location:` (ترتيب أبجدي):

```yaml
  image_picker: ^1.2.3
```

- [ ] **Step 2: أضف وصف استخدام مكتبة الصور لـ iOS 13 (PHPicker هو 14+)**

في `ios/Runner/Info.plist` داخل dict الجذر الرئيسي `<dict>`، قبل `</dict>` الأخير أضف:

```xml
	<key>NSPhotoLibraryUsageDescription</key>
	<string>لإرفاق صور أو مقاطع فيديو بملاحظاتك عند التواصل معنا.</string>
```

- [ ] **Step 3: تحقق من صلاحية قراءة الملفات المختارة على macOS**

افحص `macos/Runner/DebugProfile.entitlements` و`macos/Runner/Release.entitlements`:

```bash
grep -l "com.apple.security.files.user-selected.read-only" macos/Runner/*.entitlements | wc -l
```

المتوقع: 2. إن نقص ملف، أضف داخل `<dict>` فيه:

```xml
	<key>com.apple.security.files.user-selected.read-only</key>
	<true/>
```

- [ ] **Step 4: نفّذ pub get وتحقق من التحليل**

```bash
flutter pub get && flutter analyze
```

المتوقع: `No issues found!` (أو نفس عدد الملاحظات الموجودة قبل التغيير — لا أخطاء جديدة).

- [ ] **Step 5: Commit (بإذن المالك فقط)**

```bash
git add pubspec.yaml pubspec.lock ios/Runner/Info.plist macos/Runner/*.entitlements
git commit -m "ADD: image_picker dependency for feedback media attachments"
```

---

### Task 2: الـ Models الثلاثة + اختباراتها (TDD)

**Files:**
- Create: `lib/presentation/feedback/data/models/feedback_model.dart`
- Create: `lib/presentation/feedback/data/models/feedback_reply_model.dart`
- Create: `lib/presentation/feedback/data/models/feedback_thread.dart`
- Test: `test/feedback_models_test.dart`

**Interfaces:**
- Produces (تستخدمها المهام 5–10):
  - `FeedbackModel` بحقول: `id, token, message, status, published, appSource, contactEmail, createdAt, updatedAt, mediaUrls` + `fromJson` + `copyWith`.
  - `FeedbackReplyModel` بحقول: `id, feedbackId, authorRole, body, createdAt, mediaUrls` + getter `isAdmin` + `fromJson`.
  - `FeedbackThread` بحقلين: `feedback, replies` + `fromJson` + `copyWith`.

- [ ] **Step 1: اكتب الاختبار الفاشل**

أنشئ `test/feedback_models_test.dart`:

```dart
import 'package:aqim/presentation/feedback/data/models/feedback_model.dart';
import 'package:aqim/presentation/feedback/data/models/feedback_reply_model.dart';
import 'package:aqim/presentation/feedback/data/models/feedback_thread.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedbackModel', () {
    test('يحلل الاستجابة الكاملة مع media_urls ويحوّل id الرقمي إلى نص', () {
      final m = FeedbackModel.fromJson(const {
        'id': 12,
        'token': 'tok-1',
        'message': 'رسالة تجريبية',
        'status': 'in_progress',
        'published': true,
        'app_source': 'أقم - مكتبة الحكمة',
        'contact_email': 'a@b.c',
        'created_at': '2026-08-19T10:00:00Z',
        'updated_at': '2026-08-19T11:00:00Z',
        'media_urls': ['u1', 'u2'],
      });
      expect(m.id, '12');
      expect(m.token, 'tok-1');
      expect(m.status, 'in_progress');
      expect(m.published, isTrue);
      expect(m.contactEmail, 'a@b.c');
      expect(m.mediaUrls, ['u1', 'u2']);
    });

    test('حالات الحافة: يقرأ media بدل media_urls ويطبق الافتراضات', () {
      final m = FeedbackModel.fromJson(const {
        'id': 'x',
        'token': 't',
        'message': 'm',
        'media': ['only-media-key'],
      });
      expect(m.status, 'planned'); // الافتراضي
      expect(m.published, isFalse); // published ليس bool
      expect(m.mediaUrls, ['only-media-key']); // توافق اسم الحقل
      expect(m.createdAt, '');
    });

    test('copyWith يعدل الحقل المطلوب ويبقي الباقي', () {
      final m = FeedbackModel.fromJson(
        const {'id': '1', 'token': 't', 'message': 'm', 'status': 'planned'},
      );
      final c = m.copyWith(status: 'complete');
      expect(c.status, 'complete');
      expect(c.token, 't');
      expect(c.message, 'm');
    });
  });

  group('FeedbackReplyModel', () {
    test('يحلل الرد ويميز المشرف', () {
      final r = FeedbackReplyModel.fromJson(const {
        'id': 5,
        'feedback_id': 1,
        'author_role': 'admin',
        'body': 'رد المشرف',
        'created_at': '2026-08-19T12:00:00Z',
        'media_urls': [],
      });
      expect(r.isAdmin, isTrue);
      expect(r.id, '5');
      expect(r.feedbackId, '1');
    });

    test('الافتراضي مستخدم حين تغيب author_role', () {
      final r = FeedbackReplyModel.fromJson(const {'id': '1'});
      expect(r.authorRole, 'user');
      expect(r.isAdmin, isFalse);
    });
  });

  group('FeedbackThread', () {
    test('يحلل feedback + replies معًا', () {
      final t = FeedbackThread.fromJson(const {
        'feedback': {
          'id': '1',
          'token': 'tok',
          'message': 'الأصل',
          'status': 'planned',
        },
        'replies': [
          {'id': '9', 'author_role': 'admin', 'body': 'رد'},
          'ليست خريطة — تُتجاهل',
        ],
      });
      expect(t.feedback.token, 'tok');
      expect(t.replies.length, 1);
      expect(t.replies.first.isAdmin, isTrue);
    });

    test('غياب feedback لا يرمي — موديل فارغ', () {
      final t = FeedbackThread.fromJson(const {
        'replies': [
          {'id': '9'},
        ],
      });
      expect(t.feedback.token, '');
      expect(t.replies.length, 1);
    });

    test('copyWith يستبدل الردود', () {
      final t = FeedbackThread.fromJson(const {
        'feedback': {'id': '1'},
      });
      final t2 = t.copyWith(
        replies: [FeedbackReplyModel.fromJson(const {'id': '2'})],
      );
      expect(t2.replies.length, 1);
      expect(t2.feedback.id, t.feedback.id);
    });
  });
}
```

- [ ] **Step 2: شغّل الاختبار وتحقق من فشله**

```bash
flutter test test/feedback_models_test.dart
```

المتوقع: فشل تجميع (Compilation failed) — الملفات غير موجودة.

- [ ] **Step 3: أنشئ الموديلات**

`lib/presentation/feedback/data/models/feedback_model.dart`:

```dart
/// نموذج الملاحظة المُرسلة من المستخدم.
///
/// يطابق استجابة `data` في `POST /feedback` وحقل `feedback` في `GET /feedback/{token}`.
class FeedbackModel {
  final String id;
  final String token;
  final String message;
  final String status; // planned | in_progress | complete
  final bool published;
  final String? appSource;
  final String? contactEmail;
  final String createdAt;
  final String updatedAt;
  final List<String> mediaUrls;

  const FeedbackModel({
    required this.id,
    required this.token,
    required this.message,
    required this.status,
    required this.published,
    this.appSource,
    this.contactEmail,
    required this.createdAt,
    required this.updatedAt,
    this.mediaUrls = const [],
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: '${json['id'] ?? ''}',
      token: '${json['token'] ?? ''}',
      message: '${json['message'] ?? ''}',
      status: '${json['status'] ?? 'planned'}',
      published: json['published'] is bool ? json['published'] as bool : false,
      appSource: json['app_source']?.toString(),
      contactEmail: json['contact_email']?.toString(),
      createdAt: '${json['created_at'] ?? ''}',
      updatedAt: '${json['updated_at'] ?? ''}',
      mediaUrls: _readUrls(json),
    );
  }

  /// يقرأ قائمة الروابط من `media_urls` أو `media` (للتوافق مع كلا الاسمين).
  static List<String> _readUrls(Map<String, dynamic> json) {
    final raw = json['media_urls'] ?? json['media'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  FeedbackModel copyWith({
    String? id,
    String? token,
    String? message,
    String? status,
    bool? published,
    String? appSource,
    String? contactEmail,
    String? createdAt,
    String? updatedAt,
    List<String>? mediaUrls,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      token: token ?? this.token,
      message: message ?? this.message,
      status: status ?? this.status,
      published: published ?? this.published,
      appSource: appSource ?? this.appSource,
      contactEmail: contactEmail ?? this.contactEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mediaUrls: mediaUrls ?? this.mediaUrls,
    );
  }
}
```

`lib/presentation/feedback/data/models/feedback_reply_model.dart`:

```dart
/// نموذج رد واحد في محادثة الملاحظة.
///
/// يطابق عناصر مصفوفة `replies` في `GET /feedback/{token}`
/// وحقل `data` في `POST /feedback/{token}/reply`.
class FeedbackReplyModel {
  final String id;
  final String feedbackId;
  final String authorRole; // admin | user
  final String body;
  final String createdAt;
  final List<String> mediaUrls;

  const FeedbackReplyModel({
    required this.id,
    required this.feedbackId,
    required this.authorRole,
    required this.body,
    required this.createdAt,
    this.mediaUrls = const [],
  });

  /// هل الكاتب مشرف؟
  bool get isAdmin => authorRole == 'admin';

  factory FeedbackReplyModel.fromJson(Map<String, dynamic> json) {
    final raw = json['media_urls'] ?? json['media'];
    final List<String> urls = raw is List
        ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const [];
    return FeedbackReplyModel(
      id: '${json['id'] ?? ''}',
      feedbackId: '${json['feedback_id'] ?? ''}',
      authorRole: '${json['author_role'] ?? 'user'}',
      body: '${json['body'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
      mediaUrls: urls,
    );
  }
}
```

`lib/presentation/feedback/data/models/feedback_thread.dart`:

```dart
import 'feedback_model.dart';
import 'feedback_reply_model.dart';

/// محادثة الملاحظة كاملة: الرسالة الأصلية + قائمة الردود.
///
/// يطابق استجابة `GET /feedback/{token}` بالكامل.
class FeedbackThread {
  final FeedbackModel feedback;
  final List<FeedbackReplyModel> replies;

  const FeedbackThread({required this.feedback, required this.replies});

  factory FeedbackThread.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'];
    final replies = <FeedbackReplyModel>[];
    if (rawReplies is List) {
      for (final item in rawReplies) {
        if (item is Map<String, dynamic>) {
          replies.add(FeedbackReplyModel.fromJson(item));
        }
      }
    }
    final feedbackJson = json['feedback'];
    return FeedbackThread(
      feedback: FeedbackModel.fromJson(
        feedbackJson is Map<String, dynamic>
            ? feedbackJson
            : const <String, dynamic>{},
      ),
      replies: replies,
    );
  }

  FeedbackThread copyWith({
    FeedbackModel? feedback,
    List<FeedbackReplyModel>? replies,
  }) {
    return FeedbackThread(
      feedback: feedback ?? this.feedback,
      replies: replies ?? this.replies,
    );
  }
}
```

- [ ] **Step 4: شغّل الاختبار وتحقق من نجاحه**

```bash
flutter test test/feedback_models_test.dart
```

المتوقع: `All tests passed!`

- [ ] **Step 5: dart format ثم Commit (بإذن المالك فقط)**

```bash
dart format lib/presentation/feedback/data test/feedback_models_test.dart
git add lib/presentation/feedback test/feedback_models_test.dart
git commit -m "ADD: feedback models (feedback, reply, thread) with tests"
```

---

### Task 3: طبقة API — الثوابت ورفع الملفات

**Files:**
- Modify: `lib/core/utils/constants/api_constants.dart:23-24` (بعد `ourAppsUrl`)
- Modify: `lib/core/services/api_client.dart` (بعد دالة `request` قبل `_requestFallback`)

**Interfaces:**
- Consumes: `ApiClient._dio`, `ErrorHandler`, `DataSource` (موجودة).
- Produces: `ApiConstants.feedbackApiUrl`, `ApiConstants.feedbackEndpoint`, `ApiConstants.feedbackReplySuffix`, `ApiConstants.feedbackUploadEndpoint` + `ApiClient.uploadFile({required String endpoint, required FormData data, Map<String, String>? headers, void Function(int sent, int total)? onSendProgress, bool? printResponse})` → `Future<Either<Failure, dynamic>>`.

- [ ] **Step 1: أضف الثوابت في api_constants.dart**

بعد سطر `ourAppsUrl` مباشرة:

```dart
  /// Feedback API — نطاق مستقل عن baseUrl (يُمرَّر URL كامل في ApiClient.request).
  static const String feedbackApiUrl = 'https://vexaltech.dev/api/feedback';
  static const String feedbackEndpoint =
      '/feedback'; // POST إنشاء + GET /feedback/{token}
  static const String feedbackReplySuffix =
      '/reply'; // POST /feedback/{token}/reply
  static const String feedbackUploadEndpoint = '/upload'; // POST رفع وسائط
```

- [ ] **Step 2: أضف uploadFile إلى api_client.dart**

بعد نهاية دالة `request` وقبل `_requestFallback` (نفس نمط المرجع حرفيًا):

```dart
  /// رفع ملف عبر `multipart/form-data` (لرفع وسائط الملاحظات إلى R2).
  ///
  /// يُرجع `Either<Failure, dynamic>` كالعادة — الرابط يكون في `response.data['url']`.
  /// Dio يتجاهل baseUrl عند تمرير URL مطلق في [endpoint].
  Future<Either<Failure, dynamic>> uploadFile({
    required String endpoint,
    required FormData data,
    Map<String, String>? headers,
    void Function(int sent, int total)? onSendProgress,
    bool? printResponse = false,
  }) async {
    try {
      final Response response = await _dio.post(
        endpoint,
        data: data,
        options: Options(headers: headers),
        onSendProgress: onSendProgress,
      );
      if (printResponse!) {
        log('Upload response received: ${response.data}', name: 'ApiClient');
      }
      return Right(response.data);
    } on DioException catch (e) {
      log(
        'Upload DioException: ${e.message}, Status Code: ${e.response?.statusCode}',
        name: 'ApiClient',
      );
      return Left(ErrorHandler.handle(e).failure);
    } catch (e) {
      log('Upload error: $e', name: 'ApiClient');
      return Left(DataSource.DEFAULT.getFailure());
    }
  }
```

- [ ] **Step 3: تحقق**

```bash
dart format lib/core/utils/constants/api_constants.dart lib/core/services/api_client.dart && flutter analyze
```

المتوقع: لا أخطاء. (لا اختبار وحدة — الغلاف رفيع فوق Dio والتحقق الفعلي يحدث بالتكامل في المهمة 5.)

- [ ] **Step 4: Commit (بإذن المالك فقط)**

```bash
git add lib/core/utils/constants/api_constants.dart lib/core/services/api_client.dart
git commit -m "ADD: feedback API constants and multipart upload in ApiClient"
```

---

### Task 4: مفاتيح الترجمة (11 لغة)

**Files:**
- Modify: `assets/locales/ar.json`, `en.json`, `bn.json`, `es.json`, `fil.json`, `id.json`, `ku.json`, `ms.json`, `so.json`, `tr.json`, `ur.json`

**Interfaces:**
- Produces: المفاتيح الـ 22 المذكورة في Global Constraints، قابلة للاستخدام فورًا عبر `'key'.tr`.

- [ ] **Step 1: شغّل سكربت الإضافة (يحقن المفاتيح قبل `}` الأخير ويتحقق من صلاحية JSON)**

أنشئ ملفًا مؤقتًا `/tmp/add_feedback_keys.py` بالمحتوى التالي ثم شغّله `python3 /tmp/add_feedback_keys.py` من جذر المستودع:

```python
import json

T = {
 'ar': {
  'feedbackSendNote': 'إرسال الملاحظة',
  'feedbackSubtitle': 'شاركنا ملاحظتك أو أبلغ عن مشكلة',
  'feedbackMessageHint': 'اكتب ملاحظتك هنا...',
  'feedbackContactOptional': 'بريد إلكتروني للتواصل (اختياري)',
  'feedbackSentSuccess': 'تم إرسال ملاحظتك بنجاح',
  'feedbackSentError': 'تعذّر إرسال الملاحظة، حاول مرة أخرى',
  'feedbackNoNotesYet': 'لا توجد ملاحظات بعد',
  'feedbackReplyHint': 'اكتب متابعة على ملاحظتك...',
  'feedbackReplyTitle': 'رد المشرف',
  'feedbackStatusPlanned': 'مُخطّط',
  'feedbackStatusInProgress': 'قيد التنفيذ',
  'feedbackStatusComplete': 'مكتمل',
  'feedbackAdminRole': 'المشرف',
  'feedbackYouRole': 'أنا',
  'feedbackPickImages': 'صور',
  'feedbackPickVideo': 'فيديو',
  'feedbackMaxFiles': 'الحد الأقصى 5 ملفات',
  'feedbackFileTooLarge': 'حجم الملف كبير جداً',
  'feedbackInvalidType': 'نوع الملف غير مدعوم',
  'feedbackUploading': 'جارٍ الرفع',
  'charactersRemaining': 'حرفاً متبقياً',
  'retry': 'إعادة المحاولة',
 },
 'en': {
  'feedbackSendNote': 'Send Feedback',
  'feedbackSubtitle': 'Share your feedback or report an issue',
  'feedbackMessageHint': 'Write your feedback here...',
  'feedbackContactOptional': 'Contact email (optional)',
  'feedbackSentSuccess': 'Your feedback was sent successfully',
  'feedbackSentError': 'Could not send feedback, please try again',
  'feedbackNoNotesYet': 'No feedback yet',
  'feedbackReplyHint': 'Write a follow-up on your feedback...',
  'feedbackReplyTitle': 'Admin Reply',
  'feedbackStatusPlanned': 'Planned',
  'feedbackStatusInProgress': 'In Progress',
  'feedbackStatusComplete': 'Complete',
  'feedbackAdminRole': 'Admin',
  'feedbackYouRole': 'Me',
  'feedbackPickImages': 'Photos',
  'feedbackPickVideo': 'Video',
  'feedbackMaxFiles': 'Maximum 5 files',
  'feedbackFileTooLarge': 'File is too large',
  'feedbackInvalidType': 'Unsupported file type',
  'feedbackUploading': 'Uploading',
  'charactersRemaining': 'characters remaining',
  'retry': 'Retry',
 },
 'bn': {
  'feedbackSendNote': 'মন্তব্য পাঠান',
  'feedbackSubtitle': 'আপনার মতামত জানান বা সমস্যা রিপোর্ট করুন',
  'feedbackMessageHint': 'এখানে আপনার মন্তব্য লিখুন...',
  'feedbackContactOptional': 'যোগাযোগের ইমেইল (ঐচ্ছিক)',
  'feedbackSentSuccess': 'আপনার মন্তব্য সফলভাবে পাঠানো হয়েছে',
  'feedbackSentError': 'মন্তব্য পাঠানো যায়নি, আবার চেষ্টা করুন',
  'feedbackNoNotesYet': 'এখনও কোনো মন্তব্য নেই',
  'feedbackReplyHint': 'আপনার মন্তব্যের উত্তর লিখুন...',
  'feedbackReplyTitle': 'অ্যাডমিনের উত্তর',
  'feedbackStatusPlanned': 'পরিকল্পিত',
  'feedbackStatusInProgress': 'চলমান',
  'feedbackStatusComplete': 'সম্পন্ন',
  'feedbackAdminRole': 'অ্যাডমিন',
  'feedbackYouRole': 'আমি',
  'feedbackPickImages': 'ছবি',
  'feedbackPickVideo': 'ভিডিও',
  'feedbackMaxFiles': 'সর্বোচ্চ ৫টি ফাইল',
  'feedbackFileTooLarge': 'ফাইলটি অনেক বড়',
  'feedbackInvalidType': 'অসমর্থিত ফাইল',
  'feedbackUploading': 'আপলোড হচ্ছে',
  'charactersRemaining': 'অক্ষর বাকি',
  'retry': 'আবার চেষ্টা করুন',
 },
 'es': {
  'feedbackSendNote': 'Enviar comentario',
  'feedbackSubtitle': 'Comparte tu comentario o informa de un problema',
  'feedbackMessageHint': 'Escribe tu comentario aquí...',
  'feedbackContactOptional': 'Correo de contacto (opcional)',
  'feedbackSentSuccess': 'Tu comentario se envió correctamente',
  'feedbackSentError': 'No se pudo enviar el comentario, inténtalo de nuevo',
  'feedbackNoNotesYet': 'Aún no hay comentarios',
  'feedbackReplyHint': 'Escribe un seguimiento de tu comentario...',
  'feedbackReplyTitle': 'Respuesta del administrador',
  'feedbackStatusPlanned': 'Planificado',
  'feedbackStatusInProgress': 'En curso',
  'feedbackStatusComplete': 'Completado',
  'feedbackAdminRole': 'Administrador',
  'feedbackYouRole': 'Yo',
  'feedbackPickImages': 'Fotos',
  'feedbackPickVideo': 'Vídeo',
  'feedbackMaxFiles': 'Máximo 5 archivos',
  'feedbackFileTooLarge': 'El archivo es demasiado grande',
  'feedbackInvalidType': 'Tipo de archivo no compatible',
  'feedbackUploading': 'Subiendo',
  'charactersRemaining': 'caracteres restantes',
  'retry': 'Reintentar',
 },
 'fil': {
  'feedbackSendNote': 'Magpadala ng puna',
  'feedbackSubtitle': 'Ibahagi ang iyong puna o mag-ulat ng problema',
  'feedbackMessageHint': 'Isulat ang iyong puna dito...',
  'feedbackContactOptional': 'Email para sa kontak (opsyonal)',
  'feedbackSentSuccess': 'Matagumpay na naipadala ang iyong puna',
  'feedbackSentError': 'Hindi mapadala ang puna, subukan muli',
  'feedbackNoNotesYet': 'Wala pang puna',
  'feedbackReplyHint': 'Sumulat ng karugtong ng iyong puna...',
  'feedbackReplyTitle': 'Sagot ng Admin',
  'feedbackStatusPlanned': 'Naka-plano',
  'feedbackStatusInProgress': 'Isinasagawa',
  'feedbackStatusComplete': 'Tapos na',
  'feedbackAdminRole': 'Admin',
  'feedbackYouRole': 'Ako',
  'feedbackPickImages': 'Mga Larawan',
  'feedbackPickVideo': 'Video',
  'feedbackMaxFiles': 'Hanggang 5 file',
  'feedbackFileTooLarge': 'Masyadong malaki ang file',
  'feedbackInvalidType': 'Hindi suportadong uri ng file',
  'feedbackUploading': 'Nag-a-upload',
  'charactersRemaining': 'natitirang karakter',
  'retry': 'Subukan muli',
 },
 'id': {
  'feedbackSendNote': 'Kirim Masukan',
  'feedbackSubtitle': 'Bagikan masukan Anda atau laporkan masalah',
  'feedbackMessageHint': 'Tulis masukan Anda di sini...',
  'feedbackContactOptional': 'Email kontak (opsional)',
  'feedbackSentSuccess': 'Masukan Anda berhasil dikirim',
  'feedbackSentError': 'Gagal mengirim masukan, coba lagi',
  'feedbackNoNotesYet': 'Belum ada masukan',
  'feedbackReplyHint': 'Tulis tindak lanjut masukan Anda...',
  'feedbackReplyTitle': 'Balasan Admin',
  'feedbackStatusPlanned': 'Direncanakan',
  'feedbackStatusInProgress': 'Sedang dikerjakan',
  'feedbackStatusComplete': 'Selesai',
  'feedbackAdminRole': 'Admin',
  'feedbackYouRole': 'Saya',
  'feedbackPickImages': 'Foto',
  'feedbackPickVideo': 'Video',
  'feedbackMaxFiles': 'Maksimal 5 file',
  'feedbackFileTooLarge': 'File terlalu besar',
  'feedbackInvalidType': 'Jenis file tidak didukung',
  'feedbackUploading': 'Mengunggah',
  'charactersRemaining': 'karakter tersisa',
  'retry': 'Coba lagi',
 },
 'ku': {
  'feedbackSendNote': 'ناردنی تێبینیەکە',
  'feedbackSubtitle': 'تێبینیەکەت پێ بڵێ یان کێشەیەک ڕاپۆرت بکە',
  'feedbackMessageHint': 'تێبینیەکەت لێرە بنووسە...',
  'feedbackContactOptional': 'ئیمەیڵ بۆ پەیوەندی (ئارەزوومەندانە)',
  'feedbackSentSuccess': 'تێبینیەکەت بە سەرکەوتوویی نێردرا',
  'feedbackSentError': 'نەتوانرا تێبینیەکە بنێردرێت، دووبارە هەوڵ بدەوە',
  'feedbackNoNotesYet': 'هێشتا هیچ تێبینییەک نییە',
  'feedbackReplyHint': 'بەدواداچوونێک بۆ تێبینیەکەت بنووسە...',
  'feedbackReplyTitle': 'وەڵامی بەڕێوەبەر',
  'feedbackStatusPlanned': 'پلان بۆ داڕێژراو',
  'feedbackStatusInProgress': 'لە جێبەجێکردندایە',
  'feedbackStatusComplete': 'تەواو بوو',
  'feedbackAdminRole': 'بەڕێوەبەر',
  'feedbackYouRole': 'من',
  'feedbackPickImages': 'وێنەکان',
  'feedbackPickVideo': 'ڤیدیۆ',
  'feedbackMaxFiles': 'زۆرترین ٥ فایل',
  'feedbackFileTooLarge': 'قەبارەی فایل زۆر گەورەیە',
  'feedbackInvalidType': 'جۆری فایل پشتگیری نەکراوە',
  'feedbackUploading': 'بارکردن',
  'charactersRemaining': 'پیتەی ماوە',
  'retry': 'دووبارە هەوڵ بدەوە',
 },
 'ms': {
  'feedbackSendNote': 'Hantar Maklum Balas',
  'feedbackSubtitle': 'Kongsi maklum balas anda atau laporkan masalah',
  'feedbackMessageHint': 'Tulis maklum balas anda di sini...',
  'feedbackContactOptional': 'E-mel untuk dihubungi (pilihan)',
  'feedbackSentSuccess': 'Maklum balas anda berjaya dihantar',
  'feedbackSentError': 'Gagal menghantar maklum balas, cuba lagi',
  'feedbackNoNotesYet': 'Belum ada maklum balas',
  'feedbackReplyHint': 'Tulis susulan maklum balas anda...',
  'feedbackReplyTitle': 'Balasan Admin',
  'feedbackStatusPlanned': 'Dirancang',
  'feedbackStatusInProgress': 'Sedang Dijalankan',
  'feedbackStatusComplete': 'Selesai',
  'feedbackAdminRole': 'Admin',
  'feedbackYouRole': 'Saya',
  'feedbackPickImages': 'Gambar',
  'feedbackPickVideo': 'Video',
  'feedbackMaxFiles': 'Maksimum 5 fail',
  'feedbackFileTooLarge': 'Fail terlalu besar',
  'feedbackInvalidType': 'Jenis fail tidak disokong',
  'feedbackUploading': 'Memuat naik',
  'charactersRemaining': 'aksara berbaki',
  'retry': 'Cuba semula',
 },
 'so': {
  'feedbackSendNote': 'Soo dir faallo',
  'feedbackSubtitle': 'La wadaag faalladaada ama warbi xaalad',
  'feedbackMessageHint': 'Qor faalladaada halkan...',
  'feedbackContactOptional': 'Iimeel la xiriir (ikhtiyaari)',
  'feedbackSentSuccess': 'Faalladaada si guul leh ayaa loo diray',
  'feedbackSentError': 'Lama diri karin faallo, isku day mar kale',
  'feedbackNoNotesYet': 'Wali faallo ma jirto',
  'feedbackReplyHint': 'Qor raac faalladaada...',
  'feedbackReplyTitle': 'Jawaabta Maamulaha',
  'feedbackStatusPlanned': 'La qorsheeyay',
  'feedbackStatusInProgress': 'Wii socdaa',
  'feedbackStatusComplete': 'La dhammeeyay',
  'feedbackAdminRole': 'Maamule',
  'feedbackYouRole': 'Aniga',
  'feedbackPickImages': 'Sawiro',
  'feedbackPickVideo': 'Muuqaal',
  'feedbackMaxFiles': 'Ugu badan 5 fayl',
  'feedbackFileTooLarge': 'Faylka aad u weyn',
  'feedbackInvalidType': 'Nooca faylkaan lama taageerin',
  'feedbackUploading': 'Wuu soo gudbeynayaa',
  'charactersRemaining': 'xarfo hadhay',
  'retry': 'Mar kale isku day',
 },
 'tr': {
  'feedbackSendNote': 'Geri Bildirim Gönder',
  'feedbackSubtitle': 'Görüşlerini paylaş veya bir sorunu bildir',
  'feedbackMessageHint': 'Geri bildirimini buraya yaz...',
  'feedbackContactOptional': 'İletişim e-postası (isteğe bağlı)',
  'feedbackSentSuccess': 'Geri bildirimin başarıyla gönderildi',
  'feedbackSentError': 'Geri bildirim gönderilemedi, tekrar dene',
  'feedbackNoNotesYet': 'Henüz geri bildirim yok',
  'feedbackReplyHint': 'Geri bildirimine bir devam mesajı yaz...',
  'feedbackReplyTitle': 'Yönetici Yanıtı',
  'feedbackStatusPlanned': 'Planlandı',
  'feedbackStatusInProgress': 'Devam Ediyor',
  'feedbackStatusComplete': 'Tamamlandı',
  'feedbackAdminRole': 'Yönetici',
  'feedbackYouRole': 'Ben',
  'feedbackPickImages': 'Fotoğraflar',
  'feedbackPickVideo': 'Video',
  'feedbackMaxFiles': 'En fazla 5 dosya',
  'feedbackFileTooLarge': 'Dosya çok büyük',
  'feedbackInvalidType': 'Desteklenmeyen dosya türü',
  'feedbackUploading': 'Yükleniyor',
  'charactersRemaining': 'karakter kaldı',
  'retry': 'Tekrar Dene',
 },
 'ur': {
  'feedbackSendNote': 'رائے بھیجیں',
  'feedbackSubtitle': 'اپنی رائے شیئر کریں یا مسئلہ کی اطلاع دیں',
  'feedbackMessageHint': 'اپنی رائے یہاں لکھیں...',
  'feedbackContactOptional': 'رابطے کا ای میل (اختیاری)',
  'feedbackSentSuccess': 'آپ کی رائے کامیابی سے بھیج دی گئی',
  'feedbackSentError': 'رائے نہیں بھیجی جا سکی، دوبارہ کوشش کریں',
  'feedbackNoNotesYet': 'ابھی کوئی رائے نہیں',
  'feedbackReplyHint': 'اپنی رائے پر تفصیل لکھیں...',
  'feedbackReplyTitle': 'ایڈمن کا جواب',
  'feedbackStatusPlanned': 'منصوبہ بند',
  'feedbackStatusInProgress': 'جاری ہے',
  'feedbackStatusComplete': 'مکمل',
  'feedbackAdminRole': 'ایڈمن',
  'feedbackYouRole': 'میں',
  'feedbackPickImages': 'تصاویر',
  'feedbackPickVideo': 'ویڈیو',
  'feedbackMaxFiles': 'زیادہ سے زیادہ 5 فائلیں',
  'feedbackFileTooLarge': 'فائل بہت بڑی ہے',
  'feedbackInvalidType': 'غیر معاون فائل کی قسم',
  'feedbackUploading': 'اپ لوڈ ہو رہی ہے',
  'charactersRemaining': 'حروف باقی',
  'retry': 'دوبارہ کوشش کریں',
 },
}

for lang, vals in T.items():
    path = f'assets/locales/{lang}.json'
    with open(path, encoding='utf-8') as f:
        s = f.read().rstrip()
    assert s.endswith('}'), f'{path}: unexpected tail'
    s = s[:-1].rstrip()
    if s and not s.endswith(','):
        s += ','
    entries = []
    for k, v in vals.items():
        if f'"{k}"' in s:
            print(f'{lang}: SKIP existing {k}')
            continue
        entries.append(f'  "{k}": {json.dumps(v, ensure_ascii=False)}')
        entries.append(
            f'  "@{k}": {{\n    "description": "{k}",\n'
            f'    "type": "text",\n    "placeholders": {{}}\n  }}'
        )
    s += '\n' + ',\n'.join(entries) + '\n}'
    with open(path, 'w', encoding='utf-8') as f:
        f.write(s)
    json.loads(open(path, encoding='utf-8').read())  # تحقق صلاحية
    print(f'{lang}: OK')
```

ملاحظة عن الخطوة السابقة: السكربت يتخطى أي مفتاح موجود مسبقًا (طباعة SKIP) بدل تكراره، ويتحقق أن الملف الناتج JSON صالح.

- [ ] **Step 2: تحقق من العدّ في كل ملف**

```bash
for f in assets/locales/*.json; do echo "$f: $(grep -c '"feedbackSendNote"\|"retry"' $f)"; done
```

المتوقع: كل ملف يطبع 2 على الأقل (feedbackSendNote + retry موجودان). و`python3 -c "import json;[json.load(open(f,encoding='utf-8')) for f in __import__('glob').glob('assets/locales/*.json')]"` لا يرمي خطأ.

- [ ] **Step 3: Commit (بإذن المالك فقط)**

```bash
git add assets/locales
git commit -m "ADD: feedback translation keys across all 11 locales"
```

---

### Task 5: FeedbackController + تسجيله في DI

**Files:**
- Create: `lib/presentation/feedback/controller/feedback_controller.dart`
- Modify: `lib/core/services/services_locator.dart:76-77` (بعد تسجيل OurAppsController)

**Interfaces:**
- Consumes: `ApiClient.request/uploadFile`, `ApiConstants.*` (المهمة 3)، الموديلات (المهمة 2)، `LocalNotificationsService.showNotification`.
- Produces (للمهام 6–9): كل ما يلي على `FeedbackController.instance`:
  - State: `threads` (RxList<FeedbackThread>)، `isLoadingList`، `loadError`، `isSubmitting`، `openThread` (Rxn<FeedbackThread>)، `isLoadingThread`، `isReplying`، `selectedFiles` (RxList<File>)، `isUploading`، `uploadProgress`.
  - Getters: `hasFeedback`، `static const int maxFiles = 5`.
  - دوال: `ensureLoaded()`، `loadAllThreads()`، `submitFeedback(String, {String? email, BuildContext? context})` → `Either<Failure, FeedbackModel>`، `openConversation(String token)`، `sendReply(String body)` → `Either<Failure, FeedbackReplyModel>`، `pickImages()/pickVideo()` → `Future<String?>` (مفتاح خطأ أو null)، `removeFileAt(int)`، `clearFiles()`، `isVideoFile(File)`، `checkForNewReplies()`، `static checkNewRepliesBackground()`.

- [ ] **Step 1: أنشئ الكنترولر**

`lib/presentation/feedback/controller/feedback_controller.dart` (منقول من المرجع مع هذه التكييفات: appSource أقم، الإشعار عبر LocalNotificationsService بمعرّف آمن، اسم النسخة الخلفية `checkNewRepliesBackground`، platform يشمل macOS):

```dart
import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io' show File, Platform;

import 'package:dio/dio.dart' as dio show FormData, MultipartFile;
import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_info/flutter_app_info.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/error_handling_system.dart';
import '../../../core/services/local_notifications_service.dart';
import '../../../core/utils/constants/api_constants.dart';
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
  @override
  void onInit() {
    super.onInit();
    _loadTokens();
    loadAllThreads();
    checkForNewReplies();
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
      return result.fold((f) => Left(f), (data) {
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
      final mediaUrls = await _uploadAllFiles();
      if (mediaUrls == null) {
        return Left(Failure(500, 'feedbackUploading'));
      }

      final body = <String, dynamic>{
        'message': trimmed,
        'app_source': appSource,
      };
      if (email != null && email.trim().isNotEmpty) {
        body['contact_email'] = email.trim();
      }
      body['user_meta'] = _collectUserMeta(context);
      if (mediaUrls.isNotEmpty) {
        body['media_urls'] = mediaUrls;
      }

      final endpoint =
          '${ApiConstants.feedbackApiUrl}${ApiConstants.feedbackEndpoint}';

      final result = await ApiClient().request(
        endpoint: endpoint,
        method: HttpMethod.post,
        data: body,
        printResponse: false,
      );

      return result.fold((failure) => Left(failure), (data) {
        final map = _asMap(data);
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
        clearFiles();
        return Right(model);
      });
    } catch (e) {
      log('submitFeedback error: $e', name: 'FeedbackController');
      return Left(DataSource.DEFAULT.getFailure());
    } finally {
      isSubmitting.value = false;
    }
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
      final mediaUrls = await _uploadAllFiles();
      if (mediaUrls == null) {
        return Left(Failure(500, 'feedbackUploading'));
      }
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

      return result.fold((failure) => Left(failure), (data) {
        final map = _asMap(data);
        final replyMap = map == null
            ? null
            : (map['data'] is Map
                  ? Map<String, dynamic>.from(map['data'])
                  : null);
        if (replyMap == null) return Left(DataSource.DEFAULT.getFailure());
        final reply = FeedbackReplyModel.fromJson(replyMap);
        final current = openThread.value;
        if (current != null) {
          final updated = current.copyWith(
            replies: [...current.replies, reply],
          );
          openThread.value = updated;
          _upsertThreadInList(updated);
        }
        return Right(reply);
      });
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

  /// يفتح المعرض لاختيار صور متعددة. يتحقق من النوع والحجم والحد الأقصى.
  Future<String?> pickImages() async {
    final remaining = maxFiles - selectedFiles.length;
    if (remaining <= 0) return 'feedbackMaxFiles';

    final picker = ImagePicker();
    try {
      final results = await picker.pickMultiImage(
        limit: remaining,
        imageQuality: 85,
      );
      if (results.isEmpty) return null; // ألغى المستخدم

      for (final x in results) {
        if (selectedFiles.length >= maxFiles) break;
        final file = File(x.path);
        final ext = _extension(x.path);
        final size = await file.length();

        if (!_allowedImageExts.contains(ext)) {
          return 'feedbackInvalidType';
        }
        if (size > _maxImageBytes) {
          return 'feedbackFileTooLarge';
        }
        selectedFiles.add(file);
      }
      return null; // نجاح
    } catch (e) {
      log('pickImages error: $e', name: 'FeedbackController');
      return 'feedbackInvalidType';
    }
  }

  /// يفتح المعرض لاختيار فيديو واحد. يتحقق من النوع والحجم.
  Future<String?> pickVideo() async {
    if (selectedFiles.length >= maxFiles) return 'feedbackMaxFiles';

    final picker = ImagePicker();
    try {
      final x = await picker.pickVideo(source: ImageSource.gallery);
      if (x == null) return null; // ألغى المستخدم

      final file = File(x.path);
      final ext = _extension(x.path);
      final size = await file.length();

      if (!_allowedVideoExts.contains(ext)) {
        return 'feedbackInvalidType';
      }
      if (size > _maxVideoBytes) {
        return 'feedbackFileTooLarge';
      }
      selectedFiles.add(file);
      return null; // نجاح
    } catch (e) {
      log('pickVideo error: $e', name: 'FeedbackController');
      return 'feedbackInvalidType';
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
    final endpoint =
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
              final fileFraction =
                  (i + (sent / total)) / selectedFiles.length;
              uploadProgress.value = fileFraction.clamp(0.0, 1.0);
            }
          },
          printResponse: false,
        );

        if (result.isLeft) {
          log('upload failed: ${result.left.message}', name: 'FeedbackController');
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
            final title = _trStatic('feedbackReplyTitle', fallback: 'رد المشرف');
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
      return result.fold((f) => Left(f), (data) {
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
```

- [ ] **Step 2: سجّله في services_locator.dart**

بعد كتلة `OurAppsController` أضف:

```dart
    sl.registerLazySingleton<FeedbackController>(() =>
        Get.put<FeedbackController>(FeedbackController(), permanent: true));
```

وفي أعلى الملف مع الاستيرادات:

```dart
import '../../presentation/feedback/controller/feedback_controller.dart';
```

- [ ] **Step 3: تحقق**

```bash
dart format lib/presentation/feedback lib/core/services/services_locator.dart && flutter analyze
```

المتوقع: لا أخطاء.

- [ ] **Step 4: Commit (بإذن المالك فقط)**

```bash
git add lib/presentation/feedback lib/core/services/services_locator.dart
git commit -m "ADD: FeedbackController with tokens, threads, media upload and reply checks"
```

---

### Task 6: معرض الوسائط (FeedbackMediaGallery)

**Files:**
- Create: `lib/presentation/feedback/widgets/feedback_media_gallery.dart`

**Interfaces:**
- Consumes: لا شيء من المهام السابقة (widget مستقل).
- Produces: `FeedbackMediaGallery({required List<String> urls})` — تستخدمه شاشة المحادثة (المهمة 9) داخل فقاعات الردود.
- **انحراف مقصود عن المرجع:** الفيديو يُفتح خارجيًا عبر `url_launcher` (لا حزمة video_player). الصور داخل التطبيق بـ `InteractiveViewer`.

- [ ] **Step 1: أنشئ الـ widget**

```dart
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

/// معرض وسائط رسالة الملاحظة (صور + فيديو) — يُعرض داخل فقاعة المحادثة.
///
/// الصور تُعرض ملء الشاشة بتكبير داخل التطبيق،
/// والفيديو يُفتح بالمشغل الخارجي (قرار التصميم — بلا video_player).
class FeedbackMediaGallery extends StatelessWidget {
  const FeedbackMediaGallery({super.key, required this.urls});

  /// قائمة روابط الوسائط.
  final List<String> urls;

  bool _isVideo(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.mp4') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov');
  }

  Future<void> _openVideoExternally(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        log('No external video player found', name: 'FeedbackMediaGallery');
      }
    } catch (e) {
      log('openVideo error: $e', name: 'FeedbackMediaGallery');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: urls.map((url) => _mediaThumb(context, url)).toList(),
    );
  }

  Widget _mediaThumb(BuildContext context, String url) {
    final isVideo = _isVideo(url);
    return GestureDetector(
      onTap: () {
        if (isVideo) {
          _openVideoExternally(url);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _FullScreenImage(url: url),
            ),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: SizedBox(
          width: 120.w,
          height: 120.w,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.1),
                    child: Center(
                      child: SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) => ColoredBox(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),
              if (isVideo)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 36.sp,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// عارض الصورة ملء الشاشة مع تكبير/تصغير.
class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Image.network(
              url,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 30.w,
                    height: 30.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stack) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: تحقق**

```bash
dart format lib/presentation/feedback/widgets/feedback_media_gallery.dart && flutter analyze
```

المتوقع: لا أخطاء.

- [ ] **Step 3: Commit (بإذن المالك فقط)**

```bash
git add lib/presentation/feedback/widgets/feedback_media_gallery.dart
git commit -m "ADD: feedback media gallery with in-app image viewer, external video"
```

---

### Task 7: ورقة الإرسال (FeedbackSendSheet)

**Files:**
- Create: `lib/presentation/feedback/widgets/feedback_send_sheet.dart`

**Interfaces:**
- Consumes: `FeedbackController` (المهمة 5)، `customBottomSheet`، `ContainerButtonWidget`، `showCustomErrorSnackBar`.
- Produces: `FeedbackSendSheet` — تُفتح من الزر العائم في شاشة القائمة (المهمة 8) هكذا: `const SizedBox().customBottomSheet(textTitle: 'feedbackSendNote', child: const FeedbackSendSheet())`. عند نجاح الإرسال تفتح المحادثة الجديدة عبر `Get.toNamed(AppRouter.feedbackConversation)`.

- [ ] **Step 1: أضف ثابتي المسار في app_router.dart (نصوص فقط — الشاشات تُسجَّل في المهمتين 8 و9)**

في `lib/core/utils/helpers/app_router.dart`، بعد `teachingPrayer` أضف:

```dart
  static const String feedback = '/feedback';
  static const String feedbackConversation = '/feedbackConversation';
```

(لا تستورد الشاشات ولا تضيف GetPage الآن — سيحدث في المهام التالية ليبقى التحليل أخضر في كل مهمة.)

- [ ] **Step 2: أنشئ الورقة**

```dart
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import '../../../core/utils/constants/extensions/custom_error_snack_bar.dart';
import '../../../core/utils/helpers/app_router.dart';
import '../../../core/widgets/container_button_widget.dart';
import '../controller/feedback_controller.dart';

/// ورقة إرسال ملاحظة جديدة (تُفتح عبر customBottomSheet).
///
/// كل اللوجيك في [FeedbackController] — الورقة تدير TextEditingControllers
/// المحلية فقط (تنظيف عند الإغلاق).
class FeedbackSendSheet extends StatefulWidget {
  const FeedbackSendSheet({super.key});

  @override
  State<FeedbackSendSheet> createState() => _FeedbackSendSheetState();
}

class _FeedbackSendSheetState extends State<FeedbackSendSheet> {
  final FeedbackController _c = FeedbackController.instance;
  final TextEditingController _messageCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final ValueNotifier<int> _charCount = ValueNotifier<int>(0);

  static const int _maxChars = 8000;

  @override
  void initState() {
    super.initState();
    _messageCtrl.addListener(() => _charCount.value = _messageCtrl.text.length);
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _emailCtrl.dispose();
    _charCount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final result = await _c.submitFeedback(
      _messageCtrl.text,
      email: _emailCtrl.text,
      context: context,
    );
    if (!mounted) return;
    result.fold(
      (failure) => context.showCustomErrorSnackBar('feedbackSentError'.tr),
      (model) {
        _messageCtrl.clear();
        _emailCtrl.clear();
        // أغلق الورقة (route الخاص بـ showModalBottomSheet).
        Navigator.of(context).pop();
        context.showCustomErrorSnackBar(
          'feedbackSentSuccess'.tr,
          isDone: true,
        );
        _c.loadAllThreads();
        // افتح محادثة الملاحظة الجديدة مباشرة إن توفر token.
        if (model.token.isNotEmpty) {
          _c.openConversation(model.token);
          Get.toNamed(AppRouter.feedbackConversation);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'feedbackSubtitle'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.inversePrimary.withValues(alpha: 0.7),
              fontFamily: 'cairo',
              fontSize: 13.sp,
            ),
          ),
          Gap(12.h),
          _messageField(context),
          ValueListenableBuilder<int>(
            valueListenable: _charCount,
            builder: (context, used, _) {
              final remaining = _maxChars - used;
              return Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  '$remaining ${'charactersRemaining'.tr}',
                  style: TextStyle(
                    color: colorScheme.inversePrimary.withValues(alpha: 0.6),
                    fontFamily: 'cairo',
                    fontSize: 11.sp,
                  ),
                ),
              );
            },
          ),
          Gap(12.h),
          _emailField(context),
          Gap(12.h),
          _mediaSection(context),
          Gap(16.h),
          ValueListenableBuilder<int>(
            valueListenable: _charCount,
            builder: (context, used, _) {
              final hasText = used > 0;
              return Obx(() {
                final busy = _c.isSubmitting.value;
                final uploading = _c.isUploading.value;
                final hasFiles = _c.selectedFiles.isNotEmpty;
                final enabled = (hasText || hasFiles) && !busy && !uploading;
                return Opacity(
                  opacity: enabled ? 1.0 : 0.5,
                  child: ContainerButtonWidget(
                    onPressed: enabled ? _submit : null,
                    title: 'feedbackSendNote'.tr,
                    isLoading: busy,
                    icon: Icons.send,
                    height: 48,
                    backgroundColor: colorScheme.primary,
                  ),
                );
              });
            },
          ),
          Gap(16.h),
        ],
      ),
    );
  }

  Widget _mediaSection(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return Obx(() {
      final files = _c.selectedFiles;
      final uploading = _c.isUploading.value;
      final progress = _c.uploadProgress.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _pickerButton(
                context: context,
                icon: Icons.add_photo_alternate_outlined,
                label: 'feedbackPickImages',
                onPressed: uploading ? null : () => _pickImages(context),
              ),
              Gap(8.w),
              _pickerButton(
                context: context,
                icon: Icons.videocam_outlined,
                label: 'feedbackPickVideo',
                onPressed: uploading ? null : () => _pickVideo(context),
              ),
              const Spacer(),
              Text(
                '${files.length}/${FeedbackController.maxFiles}',
                style: TextStyle(
                  color: colorScheme.inversePrimary.withValues(alpha: 0.6),
                  fontFamily: 'cairo',
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          if (uploading) ...[
            Gap(8.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6.h,
                backgroundColor: colorScheme.surface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ),
              ),
            ),
            Gap(4.h),
            Text(
              '${'feedbackUploading'.tr} ${(progress * 100).toInt()}%',
              style: TextStyle(
                color: colorScheme.inversePrimary.withValues(alpha: 0.6),
                fontFamily: 'cairo',
                fontSize: 11.sp,
              ),
            ),
          ],
          if (files.isNotEmpty) ...[
            Gap(8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: List.generate(files.length, (i) {
                return _thumb(context, files[i], i);
              }),
            ),
          ],
        ],
      );
    });
  }

  Widget _pickerButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final colorScheme = context.theme.colorScheme;
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1.0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18.sp, color: colorScheme.primary),
              Gap(4.w),
              Text(
                label.tr,
                style: TextStyle(
                  color: colorScheme.inversePrimary,
                  fontFamily: 'cairo',
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// مصغّرة ملف واحد مع زر إزالة وشارة نوع.
  Widget _thumb(BuildContext context, File file, int index) {
    final isVideo = _c.isVideoFile(file);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: SizedBox(
            width: 72.w,
            height: 72.w,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(file, fit: BoxFit.cover),
                if (isVideo)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _c.removeFileAt(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 14.sp),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages(BuildContext context) async {
    final err = await _c.pickImages();
    if (err != null && context.mounted) {
      context.showCustomErrorSnackBar(err.tr);
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    final err = await _c.pickVideo();
    if (err != null && context.mounted) {
      context.showCustomErrorSnackBar(err.tr);
    }
  }

  /// زخرفة الحقول الموحدة: حدود بحواف 16 بلون السطح (نمط ورقة البحث القائمة).
  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    Widget? icon,
  }) {
    final colorScheme = context.theme.colorScheme;
    return InputDecoration(
      counterText: '',
      hintText: hint,
      hintStyle: TextStyle(
        color: colorScheme.inversePrimary.withValues(alpha: 0.5),
        fontFamily: 'cairo',
        fontSize: 15.sp,
      ),
      icon: icon,
      filled: true,
      fillColor: colorScheme.surface.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: colorScheme.surface),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: colorScheme.surface),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
    );
  }

  Widget _messageField(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return TextField(
      controller: _messageCtrl,
      maxLines: 8,
      minLines: 5,
      maxLength: _maxChars,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      style: TextStyle(
        color: colorScheme.inversePrimary,
        fontFamily: 'cairo',
        fontSize: 15.sp,
      ),
      decoration: _fieldDecoration(context, hint: 'feedbackMessageHint'.tr),
    );
  }

  Widget _emailField(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return TextField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      style: TextStyle(
        color: colorScheme.inversePrimary,
        fontFamily: 'cairo',
        fontSize: 15.sp,
      ),
      decoration: _fieldDecoration(
        context,
        hint: 'feedbackContactOptional'.tr,
        icon: Icon(
          Icons.email_outlined,
          size: 20.sp,
          color: colorScheme.surface,
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: تحقق**

```bash
dart format lib/presentation/feedback/widgets/feedback_send_sheet.dart lib/core/utils/helpers/app_router.dart && flutter analyze
```

المتوقع: لا أخطاء. (استخدام `context` بعد await محروس بـ `if (!mounted) return;` قبل كل استعمال.)

- [ ] **Step 4: Commit (بإذن المالك فقط)**

```bash
git add lib/presentation/feedback/widgets/feedback_send_sheet.dart lib/core/utils/helpers/app_router.dart
git commit -m "ADD: feedback send bottom sheet with media picker and progress"
```

---

### Task 8: شاشة القائمة + المسار + نقطة الدخول

**Files:**
- Create: `lib/presentation/feedback/screens/feedback_thread_screen.dart`
- Modify: `lib/core/utils/helpers/app_router.dart`
- Modify: `lib/presentation/about_app/user_options.dart:53-56`
- Delete: `lib/core/utils/constants/extensions/contact_us_extension.dart`

**Interfaces:**
- Consumes: `FeedbackController` (المهمة 5)، `FeedbackSendSheet` (المهمة 7)، `AppBarWidget`، `ContainerButtonWidget`، `customBottomSheet`.
- Produces: `FeedbackThreadScreen` + المساران `AppRouter.feedback = '/feedback'` و`AppRouter.feedbackConversation = '/feedbackConversation'` (المسار الثاني تستهلكه المهمتان 7 و9).

- [ ] **Step 1: أنشئ شاشة القائمة**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import '../../../core/utils/constants/extensions/bottom_sheet_extension.dart';
import '../../../core/utils/helpers/app_router.dart';
import '../../../core/widgets/app_bar_widget.dart';
import '../../../core/widgets/container_button_widget.dart';
import '../controller/feedback_controller.dart';
import '../data/models/feedback_thread.dart';
import '../widgets/feedback_send_sheet.dart';

/// شاشة "تواصل معنا": قائمة بطاقات الملاحظات السابقة + زر لإرسال ملاحظة جديدة.
///
/// كل اللوجيك في [FeedbackController] — هذه الشاشة مجرد واجهة.
class FeedbackThreadScreen extends StatelessWidget {
  const FeedbackThreadScreen({super.key});

  FeedbackController get _c => FeedbackController.instance;

  @override
  Widget build(BuildContext context) {
    // تأكد من تحميل القائمة عند الفتح (يشمل بعد hot restart).
    WidgetsBinding.instance.addPostFrameCallback((_) => _c.ensureLoaded());
    final colorScheme = context.theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSendSheet(),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        icon: const Icon(Icons.add),
        label: Text(
          'feedbackSendNote'.tr,
          style: TextStyle(
            color: colorScheme.primary,
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const AppBarWidget(withBackButton: true),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'email'.tr,
                style: TextStyle(
                  color: colorScheme.inversePrimary,
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (_c.isLoadingList.value && _c.threads.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_c.loadError.value && _c.threads.isEmpty) {
                  return _errorState();
                }
                if (!_c.hasFeedback || _c.threads.isEmpty) {
                  return _emptyState(context);
                }
                return RefreshIndicator(
                  onRefresh: _c.loadAllThreads,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16.w,
                      8.h,
                      16.w,
                      96.h,
                    ), // مساحة للـ FAB
                    itemCount: _c.threads.length,
                    separatorBuilder: (_, __) => Gap(10.h),
                    itemBuilder: (context, index) {
                      final thread = _c.threads[index];
                      return _FeedbackCard(
                        thread: thread,
                        onTap: () => _openConversation(thread),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// يفتح شاشة المحادثة للبطاقة المضغوطة.
  void _openConversation(FeedbackThread thread) {
    Get.toNamed(AppRouter.feedbackConversation)?.then((_) {
      // أعد تحميل القائمة عند العودة (قد تكون أضفت ردًا).
      _c.loadAllThreads();
    });
    _c.openConversation(thread.feedback.token);
  }

  /// يفتح ورقة الإرسال.
  void _openSendSheet() {
    const SizedBox().customBottomSheet(
      textTitle: 'feedbackSendNote',
      child: const FeedbackSendSheet(),
    );
  }

  /// فشل جلب القائمة مع وجود ملاحظات محفوظة → إعادة محاولة.
  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48.sp),
          Gap(12.h),
          TextButton(
            onPressed: () => _c.loadAllThreads(),
            child: Text('retry'.tr),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.email_outlined,
              size: 72.sp,
              color: colorScheme.surface.withValues(alpha: 0.4),
            ),
            Gap(16.h),
            Text(
              'feedbackNoNotesYet'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.inversePrimary.withValues(alpha: 0.7),
                fontFamily: 'cairo',
                fontSize: 16.sp,
              ),
            ),
            Gap(20.h),
            ContainerButtonWidget(
              onPressed: _openSendSheet,
              title: 'feedbackSendNote'.tr,
              icon: Icons.add,
              width: 200.w,
              height: 46,
              backgroundColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة ملاحظة واحدة في القائمة.
class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.thread, required this.onTap});
  final FeedbackThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final f = thread.feedback;
    final (label, color) = _statusStyle(f.status);
    final adminCount = thread.replies.where((r) => r.isAdmin).length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (adminCount > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14.sp,
                          color: colorScheme.inversePrimary.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        Gap(4.w),
                        Text(
                          '$adminCount',
                          style: TextStyle(
                            color: colorScheme.inversePrimary.withValues(
                              alpha: 0.6,
                            ),
                            fontFamily: 'cairo',
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Gap(8.h),
              Text(
                f.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.inversePrimary,
                  fontFamily: 'cairo',
                  fontSize: 15.sp,
                ),
              ),
              Gap(6.h),
              Text(
                _formatDate(f.createdAt),
                style: TextStyle(
                  color: colorScheme.inversePrimary.withValues(alpha: 0.5),
                  fontFamily: 'cairo',
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _statusStyle(String status) {
    switch (status) {
      case 'in_progress':
        return ('feedbackStatusInProgress'.tr, Colors.amber.shade700);
      case 'complete':
        return ('feedbackStatusComplete'.tr, Colors.green.shade700);
      case 'planned':
      default:
        return ('feedbackStatusPlanned'.tr, Colors.blue.shade700);
    }
  }

  /// yyyy/MM/dd محليًا، أو النص الخام عند فشل التحليل.
  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${d.year}/${two(d.month)}/${two(d.day)}';
    } catch (_) {
      return iso;
    }
  }
}
```

- [ ] **Step 2: سجّل مسار شاشة القائمة في app_router.dart**

(الثابتان أُضيفا في المهمة 7 — هنا الاستيراد وGetPage لشاشة القائمة فقط؛ مسار المحادثة يُسجَّل في المهمة 9 بعد إنشاء شاشتها ليبقى التحليل أخضر.)

أضف الاستيراد:

```dart
import '../../../presentation/feedback/screens/feedback_thread_screen.dart';
```

أضف داخل `pages`:

```dart
    GetPage(
      name: feedback,
      page: () => const FeedbackThreadScreen(),
      transition: Transition.fadeIn,
    ),
```

- [ ] **Step 3: استبدل نقطة الدخول في user_options.dart واحذف الامتداد القديم**

في `user_options.dart`: احذف سطر الاستيراد `import '/core/utils/constants/extensions/contact_us_extension.dart';` وأضف `import '/core/utils/helpers/app_router.dart';`، ثم استبدل:

```dart
              onTap: () => contactUs(
                context: context,
              ),
```

بـ:

```dart
              onTap: () => Get.toNamed(AppRouter.feedback),
```

ثم احذف الملف القديم (غير مستخدم في أي مكان آخر — تم التحقق):

```bash
rm lib/core/utils/constants/extensions/contact_us_extension.dart
```

- [ ] **Step 4: تحقق**

```bash
dart format lib/presentation/feedback lib/core/utils/helpers/app_router.dart lib/presentation/about_app/user_options.dart && flutter analyze
```

المتوقع: لا أخطاء — المهمة 8 مكتفية ذاتيًا (مسار المحادثة لم يُسجَّل بعد، وهذا مقصود حتى المهمة 9).

- [ ] **Step 5: Commit (بإذن المالك فقط)**

```bash
git add lib/presentation/feedback/screens/feedback_thread_screen.dart lib/core/utils/helpers/app_router.dart lib/presentation/about_app/user_options.dart
git rm lib/core/utils/constants/extensions/contact_us_extension.dart
git commit -m "ADD: feedback thread screen, routes; REPLACE contact-us mailto entry"
```

---

### Task 9: شاشة المحادثة + نقر الإشعار + الفحص الخلفي

**Files:**
- Create: `lib/presentation/feedback/screens/feedback_conversation_screen.dart`
- Modify: `lib/core/services/notifications_helper.dart:52-66` (`_handleNotificationTap`)
- Modify: `lib/core/services/background_services.dart:131-141` (داخل `_executeBackgroundTask`)

**Interfaces:**
- Consumes: `FeedbackController.openThread/openConversation/sendReply/selectedFiles/...` (المهمة 5)، `FeedbackMediaGallery` (المهمة 6)، `AppRouter.feedbackConversation` (المهمة 8)، `FeedbackController.checkNewRepliesBackground()` (المهمة 5).
- Produces: ميزة مكتملة التشغيل: رد المشرف يطلق إشعارًا من الخلفية، والنقر عليه يفتح المحادثة.

- [ ] **Step 1: أنشئ شاشة المحادثة**

StatefulWidget (تملك `TextEditingController` شريط الرد وتتخلص منه — تحسين عن المرجع):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import '../../../core/utils/constants/extensions/custom_error_snack_bar.dart';
import '../../../core/widgets/app_bar_widget.dart';
import '../controller/feedback_controller.dart';
import '../data/models/feedback_reply_model.dart';
import '../widgets/feedback_media_gallery.dart';

/// شاشة المحادثة الواحدة: الرسالة الأصلية + الردود (مشرف/مستخدم) + شريط الرد.
///
/// تستهلك [FeedbackController.openThread] — لا تملك state إلا حقل الرد.
class FeedbackConversationScreen extends StatefulWidget {
  const FeedbackConversationScreen({super.key});

  @override
  State<FeedbackConversationScreen> createState() =>
      _FeedbackConversationScreenState();
}

class _FeedbackConversationScreenState
    extends State<FeedbackConversationScreen> {
  final FeedbackController _c = FeedbackController.instance;
  final TextEditingController _replyCtrl = TextEditingController();

  @override
  void dispose() {
    _replyCtrl.dispose();
    _c.clearFiles();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final canSend =
        _replyCtrl.text.trim().isNotEmpty || _c.selectedFiles.isNotEmpty;
    if (!canSend) return;
    final result = await _c.sendReply(_replyCtrl.text);
    if (!mounted) return;
    result.fold(
      (failure) => context.showCustomErrorSnackBar('feedbackSentError'.tr),
      (_) {
        _replyCtrl.clear();
        _c.clearFiles();
      },
    );
  }

  Future<void> _pickImages() async {
    final err = await _c.pickImages();
    if (err != null && mounted) context.showCustomErrorSnackBar(err.tr);
  }

  Future<void> _pickVideo() async {
    final err = await _c.pickVideo();
    if (err != null && mounted) context.showCustomErrorSnackBar(err.tr);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      body: SafeArea(
        child: Column(
          children: [
            const AppBarWidget(withBackButton: true),
            Expanded(
              child: Obx(() {
                if (_c.isLoadingThread.value && _c.openThread.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final thread = _c.openThread.value;
                if (thread == null) {
                  return _errorState();
                }
                return Column(
                  children: [
                    _statusChip(thread.feedback.status),
                    Expanded(
                      child: _conversation(
                        thread.feedback.message,
                        thread.replies,
                        thread.feedback.mediaUrls,
                      ),
                    ),
                    _replyBar(context),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final (label, color) = _statusStyle(status);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Chip(
          label: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'cairo',
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
          backgroundColor: color,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  (String, Color) _statusStyle(String status) {
    switch (status) {
      case 'in_progress':
        return ('feedbackStatusInProgress'.tr, Colors.amber.shade700);
      case 'complete':
        return ('feedbackStatusComplete'.tr, Colors.green.shade700);
      case 'planned':
      default:
        return ('feedbackStatusPlanned'.tr, Colors.blue.shade700);
    }
  }

  Widget _conversation(
    String originalMessage,
    List<FeedbackReplyModel> replies,
    List<String> originalMediaUrls,
  ) {
    final items = <_ChatItem>[
      _ChatItem(
        body: originalMessage,
        isAdmin: false,
        createdAt: '',
        isOriginal: true,
        mediaUrls: originalMediaUrls,
      ),
      ...replies.map(
        (r) => _ChatItem(
          body: r.body,
          isAdmin: r.isAdmin,
          createdAt: r.createdAt,
          mediaUrls: r.mediaUrls,
        ),
      ),
    ];
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      itemCount: items.length,
      itemBuilder: (context, index) => _ChatBubble(item: items[index]),
    );
  }

  Widget _replyBar(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.08),
        border: Border(
          top: BorderSide(color: colorScheme.surface.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // مصغّرات المرفقات المختارة للرد.
          Obx(() {
            final files = _c.selectedFiles;
            if (files.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: List.generate(files.length, (i) {
                  final isVideo = _c.isVideoFile(files[i]);
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: SizedBox(
                          width: 48.w,
                          height: 48.w,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(files[i], fit: BoxFit.cover),
                              if (isVideo)
                                Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 22.sp,
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _c.removeFileAt(i),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyCtrl,
                  minLines: 1,
                  maxLines: 4,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  style: TextStyle(
                    color: colorScheme.inversePrimary,
                    fontFamily: 'cairo',
                    fontSize: 15.sp,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    hintText: 'feedbackReplyHint'.tr,
                    hintStyle: TextStyle(
                      color: colorScheme.inversePrimary.withValues(
                        alpha: 0.5,
                      ),
                      fontFamily: 'cairo',
                      fontSize: 15.sp,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surface.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Gap(4.w),
              Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _c.isReplying.value ? null : _pickImages,
                      icon: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: colorScheme.primary,
                        size: 22.sp,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: _c.isReplying.value ? null : _pickVideo,
                      icon: Icon(
                        Icons.videocam_outlined,
                        color: colorScheme.primary,
                        size: 22.sp,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Gap(4.w),
              Obx(
                () => IconButton(
                  onPressed: _c.isReplying.value ? null : _sendReply,
                  icon: _c.isReplying.value
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: colorScheme.primary,
                          size: 24.sp,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: TextButton(
        onPressed: () => _c.loadAllThreads(),
        child: Text('retry'.tr),
      ),
    );
  }
}

class _ChatItem {
  final String body;
  final bool isAdmin;
  final String createdAt;
  final bool isOriginal;
  final List<String> mediaUrls;
  const _ChatItem({
    required this.body,
    required this.isAdmin,
    required this.createdAt,
    this.isOriginal = false,
    this.mediaUrls = const [],
  });
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.item});
  final _ChatItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final align = item.isAdmin
        ? AlignmentDirectional.centerStart
        : AlignmentDirectional.centerEnd;
    final bg = item.isAdmin
        ? colorScheme.surface.withValues(alpha: 0.2)
        : colorScheme.primary.withValues(alpha: 0.1);
    final roleLabel = item.isAdmin
        ? 'feedbackAdminRole'.tr
        : 'feedbackYouRole'.tr;
    final time = item.createdAt.isEmpty ? '' : _formatTime(item.createdAt);

    return Align(
      alignment: align,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        constraints: BoxConstraints(maxWidth: 280.w),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              roleLabel,
              style: TextStyle(
                color: colorScheme.inversePrimary.withValues(alpha: 0.6),
                fontFamily: 'cairo',
                fontWeight: FontWeight.bold,
                fontSize: 11.sp,
              ),
            ),
            Gap(4.h),
            if (item.body.isNotEmpty)
              Text(
                item.body,
                style: TextStyle(
                  color: colorScheme.inversePrimary,
                  fontFamily: 'cairo',
                  fontSize: 15.sp,
                ),
                textAlign: TextAlign.start,
              ),
            if (item.mediaUrls.isNotEmpty) ...[
              Gap(6.h),
              FeedbackMediaGallery(urls: item.mediaUrls),
            ],
            if (time.isNotEmpty) ...[
              Gap(4.h),
              Text(
                time,
                style: TextStyle(
                  color: colorScheme.inversePrimary.withValues(alpha: 0.5),
                  fontFamily: 'cairo',
                  fontSize: 10.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final local = dt.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(local.hour)}:${two(local.minute)}';
    } catch (_) {
      return '';
    }
  }
}
```

- [ ] **Step 2: سجّل مسار المحادثة في app_router.dart**

أضف الاستيراد:

```dart
import '../../../presentation/feedback/screens/feedback_conversation_screen.dart';
```

أضف داخل `pages` (بعد GetPage الخاص بـ feedback):

```dart
    GetPage(
      name: feedbackConversation,
      page: () => const FeedbackConversationScreen(),
      transition: Transition.fadeIn,
    ),
```

- [ ] **Step 3: وسّع معالج نقر الإشعار في notifications_helper.dart**

في `_handleNotificationTap`، قبل فحص قائمة الصلوات، أضف التفرع على نوع الملاحظات (مع الاستيرادين في أعلى الملف):

```dart
import '../../presentation/feedback/controller/feedback_controller.dart';
import '../utils/helpers/app_router.dart';
```

وداخل الدالة، أول سطر بعد الـ log:

```dart
    // إشعار رد مشرف على ملاحظة → افتح المحادثة مباشرة.
    if (notification.payload['type'] == 'feedback_reply') {
      final token = notification.payload['feedback_token'];
      if (token != null && token.isNotEmpty) {
        await FeedbackController.instance.openConversation(token);
        Get.toNamed(AppRouter.feedbackConversation);
      }
      return;
    }
```

- [ ] **Step 4: اربط الفحص الخلفي في background_services.dart**

أضف الاستيراد:

```dart
import '../../presentation/feedback/controller/feedback_controller.dart';
```

وداخل `_executeBackgroundTask` بعد `await PrayerBackgroundManager.executePeriodicTasks();` مباشرة:

```dart
      // فحص ردود المشرف على ملاحظات المستخدم (مثل تطبيق القرآن).
      try {
        await FeedbackController.checkNewRepliesBackground();
      } catch (e) {
        log('feedback replies check failed: $e', name: 'Background service');
      }
```

- [ ] **Step 5: تحقق نهائي للتحليل والتنسيق**

```bash
dart format lib/presentation/feedback lib/core/services/notifications_helper.dart lib/core/services/background_services.dart lib/core/utils/helpers/app_router.dart && flutter analyze
```

المتوقع: لا أخطاء (مهام 8+9 مكتملتان الآن معًا).

- [ ] **Step 6: Commit (بإذن المالك فقط)**

```bash
git add lib/presentation/feedback lib/core/services/notifications_helper.dart lib/core/services/background_services.dart
git commit -m "ADD: feedback conversation screen, notification tap routing, background reply check"
```

---

### Task 10: اختبارات الواجهة + التحقق النهائي

**Files:**
- Test: `test/feedback_screens_test.dart`

**Interfaces:**
- Consumes: `FeedbackThreadScreen`، `FeedbackSendSheet`، `ContainerButtonWidget` (المهام 5–8).
- Produces: تغطية اختبار لحالة الفراغ وفتح ورقة الإرسال وتعطل زر الإرسال الفارغ.

- [ ] **Step 1: اكتب الاختبار**

`test/feedback_screens_test.dart` (نفس بيئة `our_apps_screen_back_button_test.dart` — بلا شبكة: الـ tokens فارغة فلا يصدر أي طلب):

```dart
import 'dart:io' show Directory;

import 'package:aqim/core/widgets/container_button_widget.dart';
import 'package:aqim/presentation/feedback/controller/feedback_controller.dart';
import 'package:aqim/presentation/feedback/screens/feedback_thread_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// شاشة الملاحظات: حالة الفراغ + فتح ورقة الإرسال من الزر العائم
/// + تعطّل زر الإرسال دون نص أو مرفقات.
/// بلا tokens محفوظة لا يصدر أي طلب شبكة — الاختبار محلي بالكامل.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();

    // GetStorage يعتمد path_provider — نحاكي قناته ب مجلد مؤقت.
    const pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          return Directory.systemTemp.path;
        });

    await GetStorage.init();
    await GetStorage().remove('feedback_tokens');
    Get.put(FeedbackController(), permanent: true);
  });

  testWidgets('empty state renders, sheet opens, submit disabled', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (_, child) => GetMaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const FeedbackThreadScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1) حالة الفراغ: المفتاح يظهر كنص لأن الترجمات غير مسجلة في الاختبار.
    expect(find.text('feedbackNoNotesYet'), findsOneWidget);

    // 2) فتح ورقة الإرسال من الزر العائم.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // 3) حقلا الرسالة والبريد ظاهران.
    expect(find.byType(TextField), findsNWidgets(2));

    // 4) زر الإرسال داخل الورقة (الأخير — الأول لزر حالة الفراغ) معطّل.
    final sheetButton = tester
        .widget<ContainerButtonWidget>(
          find.byType(ContainerButtonWidget).last,
        );
    expect(sheetButton.onPressed, isNull);
  });
}
```

- [ ] **Step 2: شغّل الاختبارات كلها**

```bash
flutter test test/feedback_models_test.dart test/feedback_screens_test.dart
```

المتوقع: `All tests passed!`

- [ ] **Step 3: مجموعة الاختبارات الكاملة + التحليل النهائي**

```bash
flutter analyze && flutter test
```

المتوقع: لا أخطاء تحليل، وكل الاختبارات (القديمة والجديدة) ناجحة. إن فشل اختبار قائم غير ذي صلة بهذه التغييرات، وثّق الفشل بمخرجاته ولا "تصلحه" خارج النطاق.

- [ ] **Step 4: تحقق يدوي مقترح (على جهاز/محاكي)**

1. الإعدادات → عن التطبيق → تواصل معنا → تفتح شاشة الملاحظات (لا البريد).
2. أرسل ملاحظة نصية → snackbar نجاح → تفتح المحادثة وتظهر فقاعتها.
3. من لوحة feedback_system ردّ كمشرف → يصل إشعار (الفحص الخلفي كل ≤20 دقيقة، كما يعمل الفحص عند فتح شاشة الملاحظات) → انقر الإشعار → تفتح المحادثة على الرد.
4. أرفق صورة وفيديو في ملاحظة → ترفع بشريط تقدم → تظهر في المحادثة؛ الصورة تفتح داخلية والفيديو خارجيًا.

- [ ] **Step 5: Commit (بإذن المالك فقط)**

```bash
git add test/feedback_screens_test.dart
git commit -m "ADD: widget tests for feedback thread screen and send sheet"
```

---

## ملاحظات للمُنفّذ

- مسار عمل مرجعي إضافي عند أي غموض: `alquranalkareem/lib/presentation/screens/feedback/` — المنطق منقول منه حرفيًا تقريبًا، والفروق موثقة أعلى كل كتلة كود.
- `ContainerButtonWidget.title` لا يترجم تلقائيًا — مرّر دائمًا `'key'.tr` وليس المفتاح.
- الورقة تُغلق بـ `Navigator.of(context).pop()` (route الخاص بـ showModalBottomSheet) وليس شرط `Get.isBottomSheetOpen` (خاص بـ GetX sheets فقط).
- لا تلمس `LocalNotificationsService` — `showNotification` يحافظ على معالج النقر القائم تلقائيًا عبر `_onTap ?? (_) {}`.
