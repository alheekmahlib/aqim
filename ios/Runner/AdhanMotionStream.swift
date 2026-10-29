import CoreMotion
import Flutter
import Foundation

/// بث قراءات محور z للتسارع (m/s²) إلى Flutter أثناء الاشتراك فقط:
/// يُستخدم لكشف القلب أثناء تشغيل الأذان داخل التطبيق على iOS.
/// يبدأ التحديث عند onListen ويتوقف عند onCancel فلا مستمعين خارج الجلسة.
class AdhanMotionStreamHandler: NSObject, FlutterStreamHandler {
  private let motion = CMMotionManager()
  private var sink: FlutterEventSink?

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    guard motion.isAccelerometerAvailable else {
      events(FlutterError(code: "NO_SENSOR", message: "Accelerometer unavailable", details: nil))
      return nil
    }
    sink = events
    // 5 قراءات في الثانية تكفي لكشف انقلاب مستقر ~1.2 ثانية.
    motion.accelerometerUpdateInterval = 1.0 / 5.0
    motion.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
      guard let self, let data else { return }
      // CMAcceleration بوحدة g؛ تُحوَّل إلى m/s² لمطابقة العتبات.
      let payload: [String: Any] = [
        "z": data.acceleration.z * 9.81,
        "at": Int(Date().timeIntervalSince1970 * 1000),
      ]
      self.sink?(payload)
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    motion.stopAccelerometerUpdates()
    sink = nil
    return nil
  }
}
