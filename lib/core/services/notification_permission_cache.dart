import 'dart:developer' show log;

import 'local_notifications_service.dart';

/// يخزّن حالة إذن الإشعانات للقراءة المتزامنة؛ الفحص الفعلي غير متزامن
/// فتُحدَّث النسخة المخبأة عند التسجيل وبعد كل طلب إذن أو فتح للإعدادات،
/// وتقرأه سياسات توفّر المميزات دون حجب بناء الواجهة.
class NotificationPermissionCache {
  NotificationPermissionCache({Future<bool> Function()? readPlatformPermission})
    : _readPlatformPermission =
          readPlatformPermission ??
          LocalNotificationsService.instance.hasNotificationsPermission;

  final Future<bool> Function() _readPlatformPermission;
  bool _granted = false;
  bool _refreshing = false;

  bool get granted => _granted;

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      _granted = await _readPlatformPermission();
    } catch (e) {
      log('Permission check failed: $e', name: 'NotificationPermission');
    } finally {
      _refreshing = false;
    }
  }
}
