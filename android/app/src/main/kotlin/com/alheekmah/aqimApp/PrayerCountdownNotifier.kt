package com.alheekmah.aqimApp

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

/// بيانات عرض إشعار العدّ التنازلي — نفس حقول بطاقة iOS حرفيًا.
/// النصوص مترجمة سلفًا من Dart؛ هنا تُعرض كما هي.
data class PrayerCountdownData(
    val nextLabel: String,
    val nextName: String,
    val nextTime: String,
    val nextAtMillis: Long,
    val elapsedLabel: String,
    val prevName: String,
    val prevAtMillis: Long
) {
    fun toJson(): JSONObject = JSONObject()
        .put("nextLabel", nextLabel)
        .put("nextName", nextName)
        .put("nextTime", nextTime)
        .put("nextAt", nextAtMillis)
        .put("elapsedLabel", elapsedLabel)
        .put("prevName", prevName)
        .put("prevAt", prevAtMillis)

    companion object {
        fun fromJson(o: JSONObject): PrayerCountdownData = PrayerCountdownData(
            nextLabel = o.optString("nextLabel"),
            nextName = o.optString("nextName"),
            nextTime = o.optString("nextTime"),
            nextAtMillis = o.optLong("nextAt", System.currentTimeMillis()),
            elapsedLabel = o.optString("elapsedLabel"),
            prevName = o.optString("prevName"),
            prevAtMillis = o.optLong("prevAt", System.currentTimeMillis())
        )
    }
}

/**
 * يدير إشعار العدّ الدائم للصلاة القادمة على مستوى أندرويد الأصلي.
 *
 * الإشعار بتخطيط مخصص (RemoteViews) بعدّادَي Chronometer أصليين يحدّثهما
 * النظام كل ثانية — تنازلي حتى الصلاة القادمة وتصاعدي منذ السابقة —
 * كبطاقة Live Activity في iOS تمامًا: صفر بطارية، ويعمل بعد قتل التطبيق
 * وفي وضع Doze بلا أي خدمة أمامية. كل ما نفعله هنا هو إعادة النشر
 * بحقول جديدة لحظة كل حدّ صلاة (نصوص جاهزة تمرَّر من Dart وتُخزَّن)،
 * وتسليح منبّه الحدّ التالي.
 */
object PrayerCountdownNotifier {

    /// نفس قناة flutter السابقة (أهمية منخفضة؛ بلا صوت).
    const val CHANNEL_ID = "prayer_countdown"
    const val NOTIFICATION_ID = 19000

    const val ACTION_BOUNDARY = "com.alheekmah.aqimApp.PRAYER_COUNTDOWN_BOUNDARY"
    const val ACTION_REFRESH = "com.alheekmah.aqimApp.PRAYER_COUNTDOWN_REFRESH"
    const val EXTRA_INDEX = "index"

    /// معرّف ثابت للمنبّه المسلّح الوحيد في أي لحظة.
    private const val ALARM_REQUEST_CODE = 4242

    private const val PREFS = "prayer_countdown"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_CURRENT = "current"
    private const val KEY_ENTRIES = "entries"
    private const val KEY_REFRESH_LABEL = "refresh_label"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    // ─── واجهة القناة (تُستدعى من MainActivity) ───

    /** يستقبل الحالة الراهنة والحدود الجاهزة من Dart: يخزّنها، ينشر
     *  الراهنة، ويسلّح الحدّ القادم. */
    fun syncBoundaries(context: Context, current: Map<String, Any?>, entries: List<Map<String, Any?>>, refreshLabel: String) {
        val currentJson = mapToJson(current)
        val entriesJson = JSONArray()
        for (entry in entries) {
            entriesJson.put(mapToJson(entry))
        }
        prefs(context).edit()
            .putBoolean(KEY_ENABLED, true)
            .putString(KEY_CURRENT, currentJson.toString())
            .putString(KEY_ENTRIES, entriesJson.toString())
            .putString(KEY_REFRESH_LABEL, refreshLabel)
            .apply()

        post(context, PrayerCountdownData.fromJson(currentJson))
        armNext(context)
    }

    /** إلغاء كامل: إخفاء الإشعار وإطفاء المنبّه ومسح الحالة. */
    fun cancel(context: Context) {
        prefs(context).edit().clear().apply()
        alarmManager(context).cancel(boundaryPendingIntent(context))
        notificationManager(context).cancel(NOTIFICATION_ID)
    }

    /** استلام حدّ صلاة: انشر بيانات الحدّ ثم سلّح التالي. */
    fun onBoundary(context: Context, index: Int) {
        val entries = readEntries(context) ?: return
        if (entries.optJSONObject(index) == null) return
        // A delayed alarm must show the latest elapsed boundary, not its old index.
        onSystemEvent(context)
    }

    /** حدث نظام (إقلاع/وقت/منطقة/تاريخ/لغة): إعادة نشر وتسليح إن كانت
     *  الميزة مفعلة. الأوقات المخزونة قد تتقادم بعد تغيير المنطقة
     *  الزمنية؛ يصحّحها أول تشغيل قادم لـ Dart. */
    fun onSystemEvent(context: Context) {
        if (!prefs(context).getBoolean(KEY_ENABLED, false)) return
        val data = resolveCurrentData(context) ?: return
        post(context, data)
        armNext(context)
    }

    // ─── النشر ───

    private fun notificationManager(context: Context): NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun alarmManager(context: Context): AlarmManager =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    private fun ensureChannel(context: Context) {
        val manager = notificationManager(context)
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "العد التنازلي للصلاة",
                    NotificationManager.IMPORTANCE_LOW
                ).apply { setSound(null, null) }
            )
        }
    }

    /// يبني تخطيط العدّادين ويثبّت أساسيهما على خط elapsedRealtime.
    private fun buildViews(context: Context, data: PrayerCountdownData): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.notification_prayer_countdown)
        views.setTextViewText(R.id.prayer_countdown_next_label, data.nextLabel)
        views.setTextViewText(R.id.prayer_countdown_next_name, "${data.nextName} ${data.nextTime}")
        views.setTextViewText(R.id.prayer_countdown_elapsed_label, data.elapsedLabel)
        views.setTextViewText(R.id.prayer_countdown_prev_name, data.prevName)

        val nowWall = System.currentTimeMillis()
        val nowElapsed = SystemClock.elapsedRealtime()
        // تنازلي: يعرض المتبقي حتى nextAt (سمة countDown في التخطيط).
        views.setChronometer(
            R.id.prayer_countdown_next_chrono,
            nowElapsed + (data.nextAtMillis - nowWall),
            null,
            true
        )
        // تصاعدي: يعرض المنقضي منذ prevAt.
        views.setChronometer(
            R.id.prayer_countdown_elapsed_chrono,
            nowElapsed - (nowWall - data.prevAtMillis),
            null,
            true
        )
        return views
    }

    private fun buildNotification(context: Context, data: PrayerCountdownData): Notification {
        val openAppIntent = PendingIntent.getActivity(
            context,
            0,
            context.packageManager.getLaunchIntentForPackage(context.packageName),
            PendingIntent.FLAG_IMMUTABLE
        )
        // العنوان/النص القياسيان احتياط وصولية (قارئات الشاشة) فقط؛
        // العرض الفعلي هو التخطيط المخصص أعلاه.
        val refreshIntent = PendingIntent.getBroadcast(
            context, 4243,
            Intent(context, CountdownNotificationReceiver::class.java).setAction(ACTION_REFRESH),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("${data.nextLabel}: ${data.nextName} ${data.nextTime}")
            .setContentText("${data.elapsedLabel} ${data.prevName}")
            .setCustomContentView(buildViews(context, data))
            .setContentIntent(openAppIntent)
            .addAction(Notification.Action.Builder(
                null, prefs(context).getString(KEY_REFRESH_LABEL, "Refresh"), refreshIntent
            ).build())
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_STOPWATCH)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .build()
    }

    private fun post(context: Context, data: PrayerCountdownData) {
        ensureChannel(context)
        try {
            notificationManager(context).notify(
                NOTIFICATION_ID,
                buildNotification(context, data)
            )
        } catch (e: SecurityException) {
            // سُحب إذن الإشعارات (أندرويد 13+)؛ لا شيء لنفعله هنا.
        }
    }

    /// الحالة الراهنة للعرض بعد حدث نظام: المخزونة إن ظلت صالحة، وإلا
    ///  آخر حدّ مضى من المخزون (وإلا أول حدّ قادم).
    private fun resolveCurrentData(context: Context): PrayerCountdownData? {
        val now = System.currentTimeMillis()
        prefs(context).getString(KEY_CURRENT, null)?.let {
            runCatching { PrayerCountdownData.fromJson(JSONObject(it)) }
                .getOrNull()
                ?.takeIf { it.nextAtMillis > now }
                ?.let { return it }
        }
        val entries = readEntries(context) ?: return null
        var passed: JSONObject? = null
        for (i in 0 until entries.length()) {
            val entry = entries.optJSONObject(i) ?: continue
            if (entry.optLong("at", Long.MAX_VALUE) > now) break
            passed = entry
        }
        return passed?.let { PrayerCountdownData.fromJson(it) }
            ?: entries.optJSONObject(0)?.let { PrayerCountdownData.fromJson(it) }
    }

    // ─── التسليح ───

    private fun boundaryPendingIntent(context: Context): PendingIntent =
        boundaryPendingIntentWithIndex(context, 0)

    private fun boundaryPendingIntentWithIndex(
        context: Context,
        index: Int
    ): PendingIntent {
        val intent = Intent(context, CountdownNotificationReceiver::class.java)
            .setAction(ACTION_BOUNDARY)
            .putExtra(EXTRA_INDEX, index)
        return PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    /** يسحب فهرس أول حدّ مستقبلي من المخزون (بمفتاح at)، أو -1. */
    private fun nextFutureIndex(context: Context): Int {
        val entries = readEntries(context) ?: return -1
        val now = System.currentTimeMillis()
        for (i in 0 until entries.length()) {
            val entry = entries.optJSONObject(i) ?: continue
            if (entry.optLong("at", Long.MAX_VALUE) > now) return i
        }
        return -1
    }

    /** سلّح منبّه الحدّ القادم (دقيق مع التراجع المرن كنمط الأذان). */
    private fun armNext(context: Context) {
        val index = nextFutureIndex(context)
        if (index < 0) return
        val entries = readEntries(context) ?: return
        val triggerAt = entries.optJSONObject(index)?.optLong("at", 0L) ?: return

        val manager = alarmManager(context)
        val pending = boundaryPendingIntentWithIndex(context, index)
        val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            manager.canScheduleExactAlarms()
        try {
            if (canExact) {
                manager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    pending
                )
            } else {
                manager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    pending
                )
            }
        } catch (e: SecurityException) {
            manager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAt,
                pending
            )
        }
    }

    private fun readEntries(context: Context): JSONArray? {
        val raw = prefs(context).getString(KEY_ENTRIES, null) ?: return null
        return try {
            JSONArray(raw)
        } catch (e: Exception) {
            null
        }
    }

    private fun mapToJson(map: Map<String, Any?>): JSONObject {
        val json = JSONObject()
        for ((key, value) in map) {
            when (value) {
                is Boolean -> json.put(key, value)
                is Int -> json.put(key, value)
                is Long -> json.put(key, value)
                is Double -> json.put(key, value)
                else -> json.put(key, value?.toString() ?: JSONObject.NULL)
            }
        }
        return json
    }
}
