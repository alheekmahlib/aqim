import Flutter
import Foundation

/// قناة إيماءات إيقاف الأذان (المرحلة الرابعة) على iOS:
/// - يستقبل تفضيلَي القلب وزر الصوت وحالة تشغيل التطبيق للأذان.
/// - لا يوجد اعتراض لأزرار الصوت بواجهة عامة على iOS؛ التفضيل يُخزَّن
///   للتماثل ولا يوحي التطبيق بغير ذلك.
class AdhanStopChannel {
  static var flipEnabled = false
  static var volumeEnabled = false
  static var inAppPlaying = false

  static func register(on messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.alheekmah.aqimApp/adhan_stop",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "setStopGestures":
        if let args = call.arguments as? [String: Any] {
          Self.flipEnabled = args["flip"] as? Bool ?? false
          Self.volumeEnabled = args["volume"] as? Bool ?? false
        }
        result(true)
      case "setInAppPlaying":
        if let args = call.arguments as? [String: Any] {
          Self.inAppPlaying = args["playing"] as? Bool ?? false
        }
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
