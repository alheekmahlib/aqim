package com.alheekmah.aqimApp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import java.io.File

/**
 * خدمة أمامية (mediaPlayback) تشغّل الأذان كاملاً عند وقت الصلاة.
 * مصدر الصوت: ملف محمّل من الكتالوج إن وُجد، وإلا المورد الخام الافتراضي.
 *
 * إشعار الخدمة يُدمج في إشعار الصلاة نفسه (نفس المعرف والقناة الصامتة)،
 * فيظهر إشعار واحد فقط كما في iOS/macOS، تُضاف له أثناء التشغيل أزرار
 * الإيقاف فقط.
 */
class AdhanPlaybackService : Service() {

    companion object {
        const val EXTRA_FILE_PATH = "filePath"

        /** عتبة محور z للشاشة للأعلى/الأسفل (m/s²) ومدة الاستقرار. */
        const val FACE_UP_THRESHOLD = 7.0f
        const val FLIP_STABILITY_MS = 1200L

        /** هل الخدمة تشغّل الأذان الآن؟ (زر الصوت في الواجهة النشطة). */
        @Volatile
        var isPlaying: Boolean = false
            private set

        /// بيانات إشعار الصلاة المدمج فيه، تُمرَّر من Flutter وقت الجدولة.
        const val EXTRA_NOTIF_ID = "notifId"
        const val EXTRA_NOTIF_TITLE = "notifTitle"
        const val EXTRA_NOTIF_TEXT = "notifText"
        const val EXTRA_STOP_ACTION_LABEL = "stopActionLabel"

        /// true = حذف الإشعار عند التوقف (تسليم التشغيل للتطبيق عند النقر).
        const val EXTRA_REMOVE_ON_STOP = "removeOnStop"
        const val ACTION_STOP = "com.alheekmah.aqimApp.ACTION_STOP_ADHAN"

        /// نفس قناة إشعارات الأذان الصامتة في flutter_local_notifications.
        const val CHANNEL_ID = "prayers_silent"
        const val NOTIFICATION_ID = 30001

        /** المورد الخام الافتراضي عند غياب ملف محمّل (الأقصى). */
        const val DEFAULT_RAW_NAME = "aqsa_athan"

        /** احتياط إن لم تصل بيانات الإشعار (إنذارات قديمة مثلاً). */
        const val FALLBACK_TITLE = "الأذان"
        const val FALLBACK_STOP = "إيقاف"
    }

    private var mediaPlayer: MediaPlayer? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var audioManager: AudioManager? = null
    private var sensorManager: SensorManager? = null
    private var sensorListener: SensorEventListener? = null
    private var sawFaceUp = false
    private var faceDownSince = 0L

    override fun onBind(intent: Intent?): IBinder? = null

    /// معرف إشعار الصلاة المدمج؛ يُتذكر لإعادة نشره/إزالته عند التوقف.
    private var activeNotifId: Int = NOTIFICATION_ID
    private var lastTitle: String? = null
    private var lastText: String? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            // زر الإيقاف: يتوقف الصوت ويبقى الإشعار (قابلاً للمسح)؛ أما
            // طلب التطبيق (تسليم التشغيل عند نقر الإشعار) فيحذفه.
            val remove = intent.getBooleanExtra(EXTRA_REMOVE_ON_STOP, false)
            stopAdhan(removeOnStop = remove)
            return START_NOT_STICKY
        }

        val notifId = intent?.getIntExtra(EXTRA_NOTIF_ID, NOTIFICATION_ID)
            ?: NOTIFICATION_ID
        activeNotifId = notifId
        lastTitle = intent?.getStringExtra(EXTRA_NOTIF_TITLE)
        lastText = intent?.getStringExtra(EXTRA_NOTIF_TEXT)
        startForegroundWithType(
            notifId,
            lastTitle,
            lastText,
            intent?.getStringExtra(EXTRA_STOP_ACTION_LABEL)
        )
        playAdhan(intent?.getStringExtra(EXTRA_FILE_PATH))
        return START_NOT_STICKY
    }

    private fun startForegroundWithType(
        notifId: Int,
        title: String?,
        text: String?,
        stopLabel: String?
    ) {
        val notification = buildNotification(title, text, stopLabel, ongoing = true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                notifId,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(notifId, notification)
        }
    }

    private fun buildNotification(
        title: String?,
        text: String?,
        stopLabel: String?,
        ongoing: Boolean
    ): Notification {
        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // القناة الصامتة نفسها التي أنشأتها FLN؛ إن لم توجد ننشئها دفاعياً.
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    title ?: FALLBACK_TITLE,
                    NotificationManager.IMPORTANCE_LOW
                ).apply { setSound(null, null) }
            )
        }

        val openAppIntent = PendingIntent.getActivity(
            this,
            0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE
        )

        val builder = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title ?: FALLBACK_TITLE)
            .setContentText(text ?: "")
            .setContentIntent(openAppIntent)
            .setCategory(Notification.CATEGORY_SERVICE)

        if (ongoing) {
            // أثناء التشغيل: مثبت مع زر إيقاف.
            val stopIntent = PendingIntent.getService(
                this,
                0,
                Intent(this, AdhanPlaybackService::class.java).setAction(ACTION_STOP),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            builder.setOngoing(true).addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(this, android.R.drawable.ic_media_pause),
                    stopLabel ?: FALLBACK_STOP,
                    stopIntent
                ).build()
            )
        } else {
            // بعد التشغيل: نسخة عادية قابلة للمسح (ongoing يمنع المسح).
            builder.setAutoCancel(true)
        }

        return builder.build()
    }

    private fun playAdhan(filePath: String?) {
        try {
            // حرس دفاعي: حتى لو بدأت الخدمة من مسار آخر، الصامت/الاهتزاز
            // يمنعان التشغيل؛ stopAdhan يعيد نشر الإشعار قابلاً للمسح.
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (audioManager.ringerMode != AudioManager.RINGER_MODE_NORMAL) {
                stopAdhan()
                return
            }

            if (!requestAudioFocus()) {
                stopSelf()
                return
            }

            val player = if (!filePath.isNullOrEmpty() && File(filePath).exists()) {
                MediaPlayer().apply {
                    setDataSource(filePath)
                    prepare()
                }
            } else {
                val resourceId =
                    resources.getIdentifier(DEFAULT_RAW_NAME, "raw", packageName)
                if (resourceId == 0) {
                    stopSelf()
                    return
                }
                MediaPlayer.create(this, resourceId)
            }

            player.setOnCompletionListener { stopAdhan() }
            player.setOnErrorListener { _, _, _ ->
                stopAdhan()
                true
            }
            mediaPlayer = player
            isPlaying = true
            player.start()
            armFlipDetection()
        } catch (e: Exception) {
            e.printStackTrace()
            stopAdhan()
        }
    }

    /**
     * كشف القلب داخل الخدمة الأمامية أثناء التشغيل فقط:
     * انتقال من الشاشة للأعلى إلى الأسفل مستقرًا ~1.2 ثانية؛ الجهاز
     * المقلوب قبل البدء لا يوقفه لغياب الانتقال. المستمع يُفك دائمًا
     * مع التوقف.
     */
    private fun armFlipDetection() {
        if (!AdhanStopGestures.flipEnabled(this)) return
        val manager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensor = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) ?: return
        sawFaceUp = false
        faceDownSince = 0L
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val z = event.values[2]
                if (z > FACE_UP_THRESHOLD) {
                    sawFaceUp = true
                    faceDownSince = 0L
                } else if (z < -FACE_UP_THRESHOLD) {
                    if (!sawFaceUp) return
                    val now = System.currentTimeMillis()
                    if (faceDownSince == 0L) {
                        faceDownSince = now
                    } else if (now - faceDownSince >= FLIP_STABILITY_MS) {
                        faceDownSince = 0L
                        sawFaceUp = false
                        stopAdhan()
                    }
                } else {
                    faceDownSince = 0L
                }
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }
        manager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_NORMAL)
        sensorManager = manager
        sensorListener = listener
    }

    private fun disarmFlipDetection() {
        sensorListener?.let { sensorManager?.unregisterListener(it) }
        sensorListener = null
        sensorManager = null
    }

    private fun requestAudioFocus(): Boolean {
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()
        val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(attributes)
            .build()
        audioFocusRequest = request
        return audioManager?.requestAudioFocus(request) ==
            AudioManager.AUDIOFOCUS_REQUEST_GRANTED
    }

    /**
     * [removeOnStop]: true عند تسليم التشغيل للتطبيق (نقر الإشعار وحده
     * يحذفه عبر autoCancel فلا نعيد نشره). عند زر الإيقاف أو الاكتمال
     * الطبيعي يُعاد نشر الإشعار نسخةً عادية قابلة للمسح — لأن علم
     * ongoing الملتصق به أثناء الخدمة يمنع مسحه نهائياً.
     */
    private fun stopAdhan(removeOnStop: Boolean = false) {
        isPlaying = false
        disarmFlipDetection()
        try {
            mediaPlayer?.let {
                // تفريغ المستمعين قبل stop/release يمنع تحذير
                // "mediaplayer went away with unhandled events".
                it.setOnCompletionListener(null)
                it.setOnErrorListener(null)
                if (it.isPlaying) it.stop()
                it.release()
            }
        } catch (_: Exception) {
        }
        mediaPlayer = null

        audioFocusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
        audioFocusRequest = null

        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (removeOnStop) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            manager.cancel(activeNotifId)
        } else {
            stopForeground(STOP_FOREGROUND_DETACH)
            manager.notify(
                activeNotifId,
                buildNotification(lastTitle, lastText, null, ongoing = false)
            )
        }
        stopSelf()
    }

    override fun onDestroy() {
        stopAdhan()
        super.onDestroy()
    }
}
