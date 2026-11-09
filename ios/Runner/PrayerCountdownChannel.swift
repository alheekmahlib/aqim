//
//  PrayerCountdownChannel.swift
//  Runner
//
//  جسر MethodChannel لإشعار العدّ التنازلي الدائم — فرع iOS:
//  ينشئ/يحدّث Live Activity على شاشة القفل والجزيرة الديناميكية.
//  العدّادان (تنازلي حتى الصلاة القادمة وتصاعدي منذ السابقة) يرسمهما
//  النظام عبر Text(timerInterval:) فلا تحديثات دورية مطلوبة بين الحدود.
//

import ActivityKit
import Flutter
import Foundation

/// سمات النشاط المشتركة مع الامتداد (نسخة مطابقة حقلًا بحقل موجودة في
/// prayer_widgetExtension/PrayerLiveActivity.swift — Codable يتطلب التطابق).
struct PrayerCountdownAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var nextName: String
    var nextAt: Date
    var nextTimeText: String
    var prevName: String
    var prevAt: Date
    var nextLabel: String?
    var refreshLabel: String?
  }

  /// نصوص ثابتة مترجمة تمرَّر عند الإنشاء (تتغير فقط مع تغير اللغة).
  var nextLabel: String
  var elapsedLabel: String
}

// ملاحظة توفر: واجهات ActivityContent وupdate(_:) تتطلب iOS 16.2،
// فيُبوّب كل شيء خلف @available(iOS 16.2, *)؛ iOS 16.1 تحديدًا نادر
// جدًا بحلول 2026 فلا يُدعم لهذه الميزة (يرجع الجسر نجاحًا صامتًا).
@available(iOS 16.2, *)
enum PrayerCountdownLiveActivityController {

  static func sync(
    nextName: String, nextAt: Date, nextTimeText: String,
    prevName: String, prevAt: Date,
    nextLabel: String, elapsedLabel: String, refreshLabel: String
  ) async {
    let authInfo = ActivityAuthorizationInfo()
    NSLog("PrayerCountdown: sync - areActivitiesEnabled=\(authInfo.areActivitiesEnabled)")
    let attributes = PrayerCountdownAttributes(
      nextLabel: nextLabel,
      elapsedLabel: elapsedLabel
    )
    let state = PrayerCountdownAttributes.ContentState(
      nextName: nextName,
      nextAt: nextAt,
      nextTimeText: nextTimeText,
      prevName: prevName,
      prevAt: prevAt,
      nextLabel: nextLabel,
      refreshLabel: refreshLabel
    )
    let content = ActivityContent(state: state, staleDate: nextAt)

    let existing = Activity<PrayerCountdownAttributes>.activities
    // سمات النشاط (ومنها الوسم «الصلاة القادمة/الوقت القادم») ثابتة بعد
    // الإنشاء؛ إن تغيّر الوسم — كعبور من صلاةٍ إلى شروقٍ أو ليلٍ — نُنهي
    // النشاط وننشئه من جديد بدل تحديث الحالة فقط.
    if let activity = existing.first,
       activity.content.state.nextAt > Date(),
       activity.attributes.nextLabel == attributes.nextLabel {
      await activity.update(content)
      NSLog("PrayerCountdown: updated existing activity id=\(activity.id)")
      return
    }
    for stale in existing {
      await stale.end(content, dismissalPolicy: .immediate)
    }
    do {
      let activity = try Activity.request(
        attributes: attributes,
        content: content,
        pushType: nil
      )
      NSLog("PrayerCountdown: activity created id=\(activity.id)")
    } catch {
      NSLog("PrayerCountdown: activity request failed: \(error)")
    }
  }

  static func cancelAll() async {
    for activity in Activity<PrayerCountdownAttributes>.activities {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
  }
}

/// يسجّل قناة com.alheekmah.aqimApp/prayer_countdown على المحرك الضمني.
enum PrayerCountdownChannel {
  static let name = "com.alheekmah.aqimApp/prayer_countdown"

  static func register(on messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any]
      switch call.method {
      case "syncActivity":
        guard let args = args else {
          result(FlutterError(code: "ARGS", message: "missing arguments", details: nil))
          return
        }
        guard #available(iOS 16.2, *) else {
          // دون iOS 16.2 لا يوجد Live Activity؛ نجيب نجاحًا صامتًا.
          result(true)
          return
        }
        // Dart يرسل مليثوانات منذ الحقبة؛ Date يتوقع ثوانٍ — بدون القسمة
        // يقفز التاريخ ~56 ألف عام للأمام فيظهر العدّ بمئات ملايين الساعات.
        let nextAt = Date(timeIntervalSince1970: ((args["nextAtMillis"] as? NSNumber)?.doubleValue ?? 0) / 1000.0)
        let prevAt = Date(timeIntervalSince1970: ((args["prevAtMillis"] as? NSNumber)?.doubleValue ?? 0) / 1000.0)
        UserDefaults.standard.set(args["entries"] as? [[String: Any]] ?? [], forKey: "prayerCountdownBoundaries")
        Task {
          await PrayerCountdownLiveActivityController.sync(
            nextName: args["nextName"] as? String ?? "",
            nextAt: nextAt,
            nextTimeText: args["nextTimeText"] as? String ?? "",
            prevName: args["prevName"] as? String ?? "",
            prevAt: prevAt,
            nextLabel: args["nextLabel"] as? String ?? "",
            elapsedLabel: args["elapsedLabel"] as? String ?? "",
            refreshLabel: args["refreshLabel"] as? String ?? "Refresh"
          )
        }
        result(true)
      case "cancel":
        guard #available(iOS 16.2, *) else {
          result(true)
          return
        }
        UserDefaults.standard.removeObject(forKey: "prayerCountdownBoundaries")
        Task {
          await PrayerCountdownLiveActivityController.cancelAll()
        }
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
