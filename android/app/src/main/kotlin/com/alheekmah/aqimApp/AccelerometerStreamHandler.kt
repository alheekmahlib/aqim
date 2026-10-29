package com.alheekmah.aqimApp

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * بث قراءات محور z للتسارع إلى Flutter أثناء الاشتراك فقط:
 * يُستخدم لكشف القلب أثناء تشغيل الأذان داخل التطبيق. المستقبِل
 * يُسجَّل عند onListen ويُفك عند onCancel فلا مستمعين خارج الجلسة.
 */
class AccelerometerStreamHandler(
    private val context: Context
) : EventChannel.StreamHandler {

    private var sensorManager: SensorManager? = null
    private var listener: SensorEventListener? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val manager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensor = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        if (sensor == null) {
            events.error("NO_SENSOR", "Accelerometer unavailable", null)
            return
        }
        val motionListener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val payload = mapOf(
                    "z" to event.values[2].toDouble(),
                    "at" to System.currentTimeMillis()
                )
                // EventSink يُستدعى من الخيط الرئيسي فقط.
                mainHandler.post { events.success(payload) }
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }
        manager.registerListener(
            motionListener,
            sensor,
            SensorManager.SENSOR_DELAY_NORMAL
        )
        sensorManager = manager
        listener = motionListener
    }

    override fun onCancel(arguments: Any?) {
        listener?.let { sensorManager?.unregisterListener(it) }
        listener = null
        sensorManager = null
    }
}
