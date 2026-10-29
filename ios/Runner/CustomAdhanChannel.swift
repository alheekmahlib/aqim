import AVFoundation
import Flutter
import Foundation

/// قناة المؤذن المخصص (المرحلة الخامسة) على iOS:
/// - prepareNotificationCopy: يصدّر نسخة WAV أحادية 44.1kHz بطول ≤30 ثانية
///   (حد UNNotificationSound) إلى Library/Sounds ويعيد مسارها؛ فشل التحويل
///   يرمى ليُفشل الاستيراد كاملًا ولا يتغير الاختيار السابق.
/// - removeNotificationCopy: حذف نسخة الإشعار (أفضل-جهد).
class CustomAdhanChannel {
  static let maxSeconds = 29.5

  static func register(on messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.alheekmah.aqimApp/custom_adhan",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "prepareNotificationCopy":
        let args = call.arguments as? [String: Any]
        let source = args?["source"] as? String ?? ""
        let id = args?["id"] as? String ?? ""
        if source.isEmpty || id.isEmpty {
          result(FlutterError(code: "BAD_ARGS", message: "missing source/id", details: nil))
          return
        }
        DispatchQueue.global(qos: .userInitiated).async {
          do {
            let path = try Self.exportTrimmedWav(source: source, id: id)
            DispatchQueue.main.async { result(path) }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "CONVERSION_FAILED", message: "\(error)", details: nil))
            }
          }
        }
      case "removeNotificationCopy":
        let args = call.arguments as? [String: Any]
        let filename = args?["filename"] as? String ?? ""
        Self.removeCopy(filename: filename)
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// يقرأ الملف المصدر بأي صيغة قابلة للفك ويكتب WAV أحادي Int16 حتى
  /// maxSeconds عبر AVAudioConverter.
  static func exportTrimmedWav(source: String, id: String) throws -> String {
    let sourceUrl = URL(fileURLWithPath: source)
    let reading = try AVAudioFile(forReading: sourceUrl)
    let sourceFormat = reading.processingFormat

    guard
      let outputFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 44_100,
        channels: 1,
        interleaved: true
      )
    else {
      throw NSError(domain: "CustomAdhan", code: -1)
    }

    let soundsDir = soundsDirectory()
    let outputUrl = soundsDir.appendingPathComponent("custom_\(id).wav")
    try? FileManager.default.removeItem(at: outputUrl)

    let writing = try AVAudioFile(forWriting: outputUrl, settings: outputFormat.settings)
    guard
      let converter = AVAudioConverter(
        from: sourceFormat,
        to: outputFormat
      )
    else {
      throw NSError(domain: "CustomAdhan", code: -2)
    }

    let maxFrames = AVAudioFramePosition(outputFormat.sampleRate * maxSeconds)
    var convertedFrames: AVAudioFramePosition = 0
    let inCapacity = AVAudioFrameCount(4096)
    let outCapacity = AVAudioFrameCount(8192)

    while convertedFrames < maxFrames {
      let inBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: inCapacity)!
      let outBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outCapacity)!

      var conversionError: NSError?
      var fed = false
      let status = converter.convert(
        to: outBuffer,
        error: &conversionError
      ) { _, inputStatus in
        if fed {
          inputStatus.pointee = .noDataNow
          return nil
        }
        do {
          try reading.read(into: inBuffer)
        } catch {
          inputStatus.pointee = .endOfStream
          return nil
        }
        if inBuffer.frameLength == 0 {
          inputStatus.pointee = .endOfStream
          return nil
        }
        fed = true
        inputStatus.pointee = .haveData
        return inBuffer
      }

      if let conversionError {
        throw conversionError
      }
      if outBuffer.frameLength > 0 {
        try writing.write(from: outBuffer)
        convertedFrames += AVAudioFramePosition(outBuffer.frameLength)
      }
      if status == .endOfStream || (fed && inBuffer.frameLength == 0) {
        break
      }
      if status == .error {
        throw NSError(domain: "CustomAdhan", code: -3)
      }
    }

    return outputUrl.path
  }

  static func removeCopy(filename: String) {
    guard !filename.isEmpty else { return }
    let url = soundsDirectory().appendingPathComponent(filename)
    try? FileManager.default.removeItem(at: url)
  }

  private static func soundsDirectory() -> URL {
    let library = FileManager.default.urls(
      for: .libraryDirectory,
      in: .userDomainMask
    ).first!
    let dir = library.appendingPathComponent("Sounds", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
  }
}
