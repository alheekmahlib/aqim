import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ضروري لوضع Implicit Engine: لا يضبط FlutterAppDelegate نفسه كمفوض
    // لمركز الإشعارات تلقائياً، وبغير هذا السطر لا تصل نقرات الإشعارات
    // إلى flutter_local_notifications إطلاقاً (FlutterAppDelegate يمرر
    // الأحداث للإضافات المسجلة عبر addApplicationDelegate).
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // قناة إشعار العدّ التنازلي الدائم (iOS: إنشاء/تحديث/إنهاء Live Activity)
    PrayerCountdownChannel.register(on: engineBridge.applicationRegistrar.messenger())
    // إيماءات إيقاف الأذان وبث التسارع داخل التطبيق (المرحلة الرابعة)
    let messenger = engineBridge.applicationRegistrar.messenger()
    AdhanStopChannel.register(on: messenger)
    FlutterEventChannel(
      name: "com.alheekmah.aqimApp/adhan_motion",
      binaryMessenger: messenger
    ).setStreamHandler(AdhanMotionStreamHandler())
    // المؤذن المخصص: تجهيز نسخة إشعار iOS متوافقة (المرحلة الخامسة)
    CustomAdhanChannel.register(on: messenger)
  }
}
