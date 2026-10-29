import 'dart:io' show Platform;

import 'in_app_adhan_session.dart';

/// يزامن تفضيلا إيقاف الأذان (القلب/زر الصوت) نحو المنصة:
/// أندرويد تقرأهما خدمة التشغيل والواجهة النشطة، وiOS تقرأهما لجلسة
/// التشغيل داخل التطبيق. غير المدعوم لا يُرسَل.
class LocalAdhanStopGestures {
  const LocalAdhanStopGestures({
    required this.flipEnabled,
    required this.volumeEnabled,
  });

  final bool flipEnabled;
  final bool volumeEnabled;

  Future<void> synchronize() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await adhanStopChannel.invokeMethod<void>('setStopGestures', {
      'flip': flipEnabled,
      'volume': volumeEnabled,
    });
  }
}
