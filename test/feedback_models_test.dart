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
      final m = FeedbackModel.fromJson(const {
        'id': '1',
        'token': 't',
        'message': 'm',
        'status': 'planned',
      });
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
        replies: [
          FeedbackReplyModel.fromJson(const {'id': '2'}),
        ],
      );
      expect(t2.replies.length, 1);
      expect(t2.feedback.id, t.feedback.id);
    });
  });
}
