import 'dart:async';
import 'dart:developer' show log;
import 'dart:io' show Platform;

import 'package:flutter/services.dart'
    show EventChannel, MethodChannel, MissingPluginException;

import 'face_down_detector.dart';

/// قناة الإيماءات المشتركة (أندرويد/iOS): تفضيلات الإيقاف وحالة التشغيل
/// داخل التطبيق وطلب الإيقاف من زر الصوت.
const MethodChannel _stopChannel = MethodChannel(
  'com.alheekmah.aqimApp/adhan_stop',
);

/// بث قراءات التسارع أثناء الاستماع فقط (يسلّح المنصة المستقبل عند
/// الاشتراك ويوقفه عند الإلغاء).
const EventChannel _motionChannel = EventChannel(
  'com.alheekmah.aqimApp/adhan_motion',
);

/// يمتلك حالة «جلسة الأذان داخل التطبيق» فقط:
/// - يخبر المنصة ببدء التشغيل/انتهائه (لزر الصوت في الواجهة النشطة).
/// - يسليح كاشف القلب النقي أثناء التشغيل وحده إن كانت الميزة مفعلة،
///   ويفكّه عند الانتهاء أو الإيقاف (تنظيف مضمون).
/// المستمعون لا يعملون خارج جلسة أذان فعلية.
class InAppAdhanSession {
  InAppAdhanSession._();

  static final InAppAdhanSession instance = InAppAdhanSession._();

  StreamSubscription<dynamic>? _motionSubscription;
  final FaceDownDetector _faceDownDetector = FaceDownDetector();
  bool _active = false;
  bool Function() _flipEnabled = () => false;
  Future<void> Function()? _onStopRequested;

  /// تهيئة الروابط: تفضيل القلب الحالي ومسار الإيقاف الموحد.
  void configure({
    required bool Function() flipEnabled,
    required Future<void> Function() onStopRequested,
  }) {
    _flipEnabled = flipEnabled;
    _onStopRequested = onStopRequested;
  }

  bool get isActive => _active;

  /// تُستدعى قبل تشغيل الأذان داخل التطبيق مباشرة.
  Future<void> begin() async {
    if (_active) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    _active = true;
    _faceDownDetector.reset();
    _notifyNative(playing: true);
    if (!_flipEnabled()) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    _motionSubscription = _motionChannel.receiveBroadcastStream().listen(
      _onMotionSample,
      onError: (Object error) {
        log('Motion stream error: $error', name: 'InAppAdhanSession');
      },
    );
  }

  /// تُستدعى عند انتهاء التشغيل بأي مسار (اكتمال، إغلاق، إيقاف موحد).
  Future<void> end() async {
    if (!_active) return;
    _active = false;
    await _motionSubscription?.cancel();
    _motionSubscription = null;
    _notifyNative(playing: false);
  }

  /// طلب إيقاف من المنصة (زر الصوت في الواجهة النشطة على أندرويد).
  Future<void> handleNativeStopRequest() async {
    final stop = _onStopRequested;
    if (stop == null) return;
    await stop();
  }

  void _onMotionSample(dynamic event) {
    if (event is! Map) return;
    final z = (event['z'] as num?)?.toDouble();
    final at = event['at'] as int?;
    if (z == null || at == null) return;
    final shouldStop = _faceDownDetector.offer(
      AccelerometerSample(z: z, at: DateTime.fromMillisecondsSinceEpoch(at)),
    );
    if (shouldStop) {
      handleNativeStopRequest();
    }
  }

  void _notifyNative({required bool playing}) {
    _stopChannel
        .invokeMethod<void>('setInAppPlaying', {'playing': playing})
        .catchError((Object error) {
          log('setInAppPlaying failed: $error', name: 'InAppAdhanSession');
          return null;
        });
  }
}

/// يسجَّل من الربط لاستقبال طلبات المنصة على قناة الإيقاف.
class AdhanStopChannelHandler {
  const AdhanStopChannelHandler({required this.onStopFromVolumeKey});

  final Future<void> Function() onStopFromVolumeKey;

  void register() {
    _stopChannel.setMethodCallHandler((call) async {
      if (call.method == 'stopFromVolumeKey') {
        await onStopFromVolumeKey();
        return null;
      }
      throw MissingPluginException(call.method);
    });
  }
}

/// مرجع عام لاسم القناة يشاركه محوّل مزامنة التفضيلات.
MethodChannel get adhanStopChannel => _stopChannel;
