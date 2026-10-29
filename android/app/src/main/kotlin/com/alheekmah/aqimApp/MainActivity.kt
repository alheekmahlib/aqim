package com.alheekmah.aqimApp

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.MediaPlayer
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.alheekmah.aqimApp/raw_audio"
    private val ALARMS_CHANNEL = "com.alheekmah.aqimApp/adhan_alarms"
    private val COUNTDOWN_CHANNEL = "com.alheekmah.aqimApp/prayer_countdown"
    private val SILENCE_CHANNEL = "com.alheekmah.aqimApp/prayer_silence"
    private val ADHAN_STOP_CHANNEL = "com.alheekmah.aqimApp/adhan_stop"
    private val ADHAN_MOTION_CHANNEL = "com.alheekmah.aqimApp/adhan_motion"
    private val ADHAN_ALARM_ACTION = "com.alheekmah.aqimApp.ADAN_ALARM"
    private var mediaPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SILENCE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> {
                    result.success(PrayerSilenceManager.isSupported())
                }
                "hasDndAccess" -> {
                    result.success(PrayerSilenceManager.hasDndAccess(this))
                }
                "requestDndAccess" -> {
                    // لا يُمنح الوصول برمجيًا؛ نفتح شاشة النظام المخصصة.
                    runCatching {
                        startActivity(PrayerSilenceManager.dndAccessSettingsIntent())
                    }
                    result.success(true)
                }
                "syncSilencePeriods" -> {
                    val periods = (call.argument<List<Any?>>("periods") ?: emptyList())
                        .mapNotNull { entry ->
                            val map = entry as? Map<*, *> ?: return@mapNotNull null
                            val start = (map["start"] as? Number)?.toLong() ?: return@mapNotNull null
                            val end = (map["end"] as? Number)?.toLong() ?: return@mapNotNull null
                            if (end > start) start to end else null
                        }
                    PrayerSilenceManager.sync(this, periods)
                    result.success(true)
                }
                "endAndCancelSilence" -> {
                    PrayerSilenceManager.endAndCancel(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ADHAN_STOP_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setStopGestures" -> {
                    val flip = call.argument<Boolean>("flip") ?: false
                    val volume = call.argument<Boolean>("volume") ?: false
                    AdhanStopGestures.setGestures(this, flip, volume)
                    result.success(true)
                }
                "setInAppPlaying" -> {
                    AdhanStopGestures.inAppPlaying =
                        call.argument<Boolean>("playing") ?: false
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, ADHAN_MOTION_CHANNEL)
            .setStreamHandler(AccelerometerStreamHandler(this))

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COUNTDOWN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncBoundaries" -> {
                    val current = call.argument<Map<String, Any?>>("current") ?: emptyMap()
                    val entries = call.argument<List<Map<String, Any?>>>("entries") ?: emptyList()
                    PrayerCountdownNotifier.syncBoundaries(this, current, entries)
                    result.success(true)
                }
                "cancel" -> {
                    PrayerCountdownNotifier.cancel(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRawAudioPath" -> {
                    val fileName = call.argument<String>("fileName")
                    if (fileName != null) {
                        val path = copyRawToCache(fileName)
                        if (path != null) {
                            result.success(path)
                        } else {
                            result.error("ERROR", "Could not copy raw file: $fileName", null)
                        }
                    } else {
                        result.error("ERROR", "File name is null", null)
                    }
                }
                "playRawAudio" -> {
                    val fileName = call.argument<String>("fileName")
                    if (fileName != null) {
                        val success = playRawAudio(fileName)
                        result.success(success)
                    } else {
                        result.error("ERROR", "File name is null", null)
                    }
                }
                "stopAudio" -> {
                    stopAudio()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARMS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAdhanAlarms" -> {
                    val alarms = call.argument<List<Map<String, Any?>>>("alarms") ?: emptyList()
                    scheduleAdhanAlarms(alarms)
                    result.success(true)
                }
                "cancelAdhanAlarms" -> {
                    val ids = call.argument<List<Int>>("ids") ?: emptyList()
                    cancelAdhanAlarms(ids)
                    result.success(true)
                }
                "hasExactAlarmPermission" -> {
                    result.success(hasExactAlarmPermission())
                }
                "stopAdhanPlayback" -> {
                    // التطبيق في الواجهة عند الاستدعاء؛ startService مسموح.
                    // النقر على الإشعار يحذفه (autoCancel)، فنمرر remove=true
                    // حتى لا يعاد نشره بعد توقف الخدمة.
                    startService(
                        Intent(this, AdhanPlaybackService::class.java)
                            .setAction(AdhanPlaybackService.ACTION_STOP)
                            .putExtra(AdhanPlaybackService.EXTRA_REMOVE_ON_STOP, true)
                    )
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ─── إيقاف الأذان بزري الصوت في الواجهة النشطة (المرحلة الرابعة) ───

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        val isVolumeKey = keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
            keyCode == KeyEvent.KEYCODE_VOLUME_DOWN
        if (isVolumeKey &&
            AdhanStopGestures.volumeEnabled(this) &&
            stopAdhanFromVolumeKey()
        ) {
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    /** يوقف جلسة الأذان الجارية فقط (تشغيل التطبيق أو الخدمة) ويرجع true. */
    private fun stopAdhanFromVolumeKey(): Boolean {
        if (AdhanStopGestures.inAppPlaying) {
            // التطبيق يشغّل الأذان داخل الواجهة؛ وجّه الطلب إلى Flutter.
            MethodChannel(
                flutterEngine!!.dartExecutor.binaryMessenger,
                ADHAN_STOP_CHANNEL
            ).invokeMethod("stopFromVolumeKey", null)
            return true
        }
        if (AdhanPlaybackService.isPlaying) {
            startService(
                Intent(this, AdhanPlaybackService::class.java)
                    .setAction(AdhanPlaybackService.ACTION_STOP)
            )
            return true
        }
        return false
    }

    // ─── جدولة أذان المنبة الدقيقة (بالتوازي مع إشعارات FLN) ───

    private fun alarmManager(): AlarmManager =
        getSystemService(Context.ALARM_SERVICE) as AlarmManager

    private fun hasExactAlarmPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            alarmManager().canScheduleExactAlarms()

    private fun alarmPendingIntent(
        id: Int,
        filePath: String?,
        notifId: Int?,
        notifTitle: String?,
        notifText: String?,
        stopLabel: String?
    ): PendingIntent {
        val intent = Intent(this, AdhanAlarmReceiver::class.java)
            .setAction(ADHAN_ALARM_ACTION)
            .putExtra(AdhanPlaybackService.EXTRA_FILE_PATH, filePath)
            .putExtra(AdhanPlaybackService.EXTRA_NOTIF_TITLE, notifTitle)
            .putExtra(AdhanPlaybackService.EXTRA_NOTIF_TEXT, notifText)
            .putExtra(AdhanPlaybackService.EXTRA_STOP_ACTION_LABEL, stopLabel)
        notifId?.let { intent.putExtra(AdhanPlaybackService.EXTRA_NOTIF_ID, it) }
        return PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    private fun scheduleAdhanAlarms(alarms: List<Map<String, Any?>>) {
        val manager = alarmManager()
        val canExact = hasExactAlarmPermission()
        for (alarm in alarms) {
            val id = (alarm["id"] as Number).toInt()
            val triggerAtMillis = (alarm["triggerAtMillis"] as Number).toLong()
            val filePath = alarm["filePath"] as String?
            val notifId = (alarm["notifId"] as? Number)?.toInt()
            val notifTitle = alarm["notifTitle"] as String?
            val notifText = alarm["notifText"] as String?
            val stopLabel = alarm["stopActionLabel"] as String?
            val pendingIntent =
                alarmPendingIntent(id, filePath, notifId, notifTitle, notifText, stopLabel)
            try {
                if (canExact) {
                    manager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                } else {
                    manager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                }
            } catch (e: SecurityException) {
                // سُحب إذن الإنذارات الدقيقة أثناء التشغيل؛ تراجع لجدولة مرنة.
                manager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            }
        }
    }

    private fun cancelAdhanAlarms(ids: List<Int>) {
        val manager = alarmManager()
        for (id in ids) {
            // filterEquals يتجاهل الإضافات؛ نفس المعرف يلغي الإنذار نفسه.
            manager.cancel(alarmPendingIntent(id, null, null, null, null, null))
        }
    }

    // ─── تشغيل موارد raw الخام (للمعاينة داخل التطبيق) ───

    private fun copyRawToCache(fileName: String): String? {
        return try {
            val resourceId = resources.getIdentifier(fileName, "raw", packageName)
            if (resourceId == 0) {
                return null
            }

            val cacheDir = File(cacheDir, "adhan_audio")
            if (!cacheDir.exists()) {
                cacheDir.mkdirs()
            }

            val outputFile = File(cacheDir, "$fileName.wav")
            
            // إذا كان الملف موجوداً بالفعل، أرجع مساره
            if (outputFile.exists()) {
                return outputFile.absolutePath
            }

            resources.openRawResource(resourceId).use { input ->
                FileOutputStream(outputFile).use { output ->
                    input.copyTo(output)
                }
            }

            outputFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun playRawAudio(fileName: String): Boolean {
        return try {
            stopAudio()
            
            val resourceId = resources.getIdentifier(fileName, "raw", packageName)
            if (resourceId == 0) {
                return false
            }

            mediaPlayer = MediaPlayer.create(this, resourceId)
            mediaPlayer?.start()
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun stopAudio() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
    }
}
