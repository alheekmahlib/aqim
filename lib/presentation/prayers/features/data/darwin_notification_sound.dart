import 'dart:io' show Platform;

import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException, PlatformException;

/// تجهيز نسخة إشعار الأذان المخصص على داروين:
/// - iOS: يصدّر عبر الطبقة الأصلية نسخة WAV أحادية ≤30 ثانية إلى
///   Library/Sounds (قيد UNNotificationSound) ويعيد مسارها؛ فشل التصدير
///   يرمي ليفشل الاستيراد كاملًا.
/// - macOS: النظام لا يقرأ أصوات الإشعار إلا من حزمة التطبيق فيُرجع null
///   (الأذان الكامل داخل التطبيق يعمل، والإشعار يبقى بالصوت المدمج).
class DarwinNotificationSound {
  const DarwinNotificationSound();

  static const MethodChannel _channel = MethodChannel(
    'com.alheekmah.aqimApp/custom_adhan',
  );

  Future<String?> prepare({
    required String sourcePath,
    required String id,
  }) async {
    if (!Platform.isIOS) return null;
    try {
      return await _channel.invokeMethod<String>('prepareNotificationCopy', {
        'source': sourcePath,
        'id': id,
      });
    } on PlatformException {
      // فشل التحويل: يستمر كاستثناء صريح يوقف اعتماد الملف.
      rethrow;
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> remove(String notificationSoundPath) async {
    if (!Platform.isIOS) return;
    final filename = notificationSoundPath.split('/').last;
    try {
      await _channel.invokeMethod<void>('removeNotificationCopy', {
        'filename': filename,
      });
    } catch (_) {
      // حذف نسخة الإشعار أفضل-جهد.
    }
  }
}
