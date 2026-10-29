import 'dart:developer' show log;

import '../domain/adhan_playback_control.dart';
import 'in_app_adhan_session.dart';

/// محوّل المرحلة الرابعة: يوقف جلسة الأذان الحالية أينما كانت تُشغَّل —
/// خدمة أندرويد الأمامية ومشغّل الأذان داخل التطبيق — دون المساس
/// بمعاينات الأصوات ولا بصلواتٍ قادمة. الاستدعاء المتكرر آمن.
class LocalAdhanPlaybackControl implements AdhanPlaybackControl {
  LocalAdhanPlaybackControl({
    required this.stopNativeService,
    required this.stopInAppPlayer,
  });

  final Future<void> Function() stopNativeService;
  final Future<void> Function() stopInAppPlayer;

  @override
  Future<void> stopCurrentAdhan() async {
    await InAppAdhanSession.instance.end();
    for (final stop in [stopNativeService, stopInAppPlayer]) {
      try {
        await stop();
      } catch (error, stack) {
        log(
          'Adhan stop step failed',
          error: error,
          stackTrace: stack,
          name: 'AdhanPlaybackControl',
        );
      }
    }
  }
}
