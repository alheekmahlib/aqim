import 'dart:developer' show log;
import 'dart:io' show Platform;

import 'package:flutter/services.dart' show MethodChannel;

/// يخزّن حالة وصول «عدم الإزعاج» (Do Not Disturb access) وحالة دعم المنصة
/// للقراءة المتزامنة؛ الفحص الفعلي غير متزامن فتُحدَّث النسخة المخبأة عند
/// التسجيل وعند فتح إعدادات الصلاة. القواعد المملوكة تتطلب أندرويد 10+.
class PrayerSilenceAccess {
  PrayerSilenceAccess({
    Future<bool> Function()? readPlatformSupported,
    Future<bool> Function()? readPlatformAccess,
    Future<void> Function()? openPlatformSettings,
  }) : _readPlatformSupported = readPlatformSupported ?? _channelIsSupported,
       _readPlatformAccess = readPlatformAccess ?? _channelHasAccess,
       _openPlatformSettings = openPlatformSettings ?? _channelOpenSettings;

  static const MethodChannel _channel = MethodChannel(
    'com.alheekmah.aqimApp/prayer_silence',
  );

  final Future<bool> Function() _readPlatformSupported;
  final Future<bool> Function() _readPlatformAccess;
  final Future<void> Function() _openPlatformSettings;
  bool _supported = false;
  bool _granted = false;
  bool _refreshing = false;

  bool get supported => _supported;
  bool get granted => _granted;

  /// فتح شاشة إعدادات وصول عدم الإزعاج في النظام (لا يُمنح برمجيًا).
  Future<void> openSettings() => _openPlatformSettings();

  Future<void> refresh() async {
    if (!Platform.isAndroid) {
      _supported = false;
      _granted = false;
      return;
    }
    if (_refreshing) return;
    _refreshing = true;
    try {
      _supported = await _readPlatformSupported();
      _granted = _supported && await _readPlatformAccess();
    } catch (e) {
      log('DND access check failed: $e', name: 'PrayerSilenceAccess');
    } finally {
      _refreshing = false;
    }
  }

  static Future<bool> _channelIsSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (e) {
      log('isSupported failed: $e', name: 'PrayerSilenceAccess');
      return false;
    }
  }

  static Future<bool> _channelHasAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasDndAccess') ?? false;
    } catch (e) {
      log('hasDndAccess failed: $e', name: 'PrayerSilenceAccess');
      return false;
    }
  }

  static Future<void> _channelOpenSettings() async {
    try {
      await _channel.invokeMethod<void>('requestDndAccess');
    } catch (e) {
      log('requestDndAccess failed: $e', name: 'PrayerSilenceAccess');
    }
  }
}
