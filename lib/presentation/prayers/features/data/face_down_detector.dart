import 'dart:developer' show log;

/// قراءة مستشعر التسارع النقية: (z بالـ m/s²، اللحظة).
class AccelerometerSample {
  const AccelerometerSample({required this.z, required this.at});

  final double z;
  final DateTime at;
}

/// كاشف «الشاشة لأسفل» بالإجماع على انتقال لا حالة:
/// يلزم رؤية الشاشة للأعلى أولًا ثم انقلاب مستقر نحو الأسفل للمدة
/// المحددة؛ الجهاز المقلوب قبل بدء الأذان لا يوقفه لغياب الانتقال.
class FaceDownDetector {
  FaceDownDetector({
    this.threshold = 7.0,
    this.stability = const Duration(milliseconds: 1200),
  });

  final double threshold;
  final Duration stability;

  bool _sawFaceUp = false;
  DateTime? _faceDownSince;

  /// يُغذّى بكل قراءة؛ يرجع true مرة واحدة عند اكتمال الانقلاب المستقر.
  bool offer(AccelerometerSample sample) {
    if (sample.z > threshold) {
      _sawFaceUp = true;
      _faceDownSince = null;
      return false;
    }
    if (sample.z < -threshold) {
      final since = _faceDownSince;
      if (!_sawFaceUp) return false;
      if (since == null) {
        _faceDownSince = sample.at;
        return false;
      }
      if (sample.at.difference(since) >= stability) {
        _faceDownSince = null;
        _sawFaceUp = false; // أعِد التسليح؛ التوقف مرة واحدة لكل انقلاب.
        log('Face-down flip detected', name: 'FaceDownDetector');
        return true;
      }
      return false;
    }
    // المنطقة الرمادية بين الحدين: لا تراكم استقرار.
    _faceDownSince = null;
    return false;
  }

  void reset() {
    _sawFaceUp = false;
    _faceDownSince = null;
  }
}
