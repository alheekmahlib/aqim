package com.alheekmah.aqimApp

import android.app.AlarmManager
import android.app.AutomaticZenRule
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.content.SharedPreferences
import android.os.Build
import android.provider.Settings
import org.json.JSONArray
import org.json.JSONObject

/**
 * مالك تصميت الصلاة على أندرويد (المرحلة الثالثة):
 * - قاعدة AutomaticZenRule يملكها التطبيق وحده؛ تُفعّل عند بدء الفترة
 *   وتُعطّل عند نهايتها دون المساس بقواعد أخرى أو بوضع اختاره المستخدم
 *   (لذلك لا يُستخدم setInterruptionFilter إطلاقًا — سلوك أندرويد 15).
 * - فلاتر INTERRUPTION_FILTER_PRIORITY بلا سياسة مخصصة فيحترم استثناءات
 *   النظام التي ضبطها المستخدم.
 * - الفترات تُحفظ في SharedPreferences وتُسلّح منبّهات دقيقة (بدء/نهاية
 *   أقرب فترة قادمة)؛ الإقلاع وتغيّر الوقت/المنطقة يعيد التسوية والتسليح.
 */
object PrayerSilenceManager {

    private const val PREFS = "prayer_silence"
    private const val KEY_PERIODS = "periods_json"
    private const val KEY_RULE_ID = "rule_id"
    private const val REQUEST_CODE_START = 9101
    private const val REQUEST_CODE_END = 9102

    /** معرّف شرط ثابت لقاعدة التصميت؛ لا مزود حالة خلفها. */
    private val RULE_URI: Uri = Uri.parse("aqim://prayer-silence-rule")

    const val ACTION_START = "com.alheekmah.aqimApp.PRAYER_SILENCE_START"
    const val ACTION_END = "com.alheekmah.aqimApp.PRAYER_SILENCE_END"

    // ─── الاستعلامات والأذونات ───

    fun hasDndAccess(context: Context): Boolean = try {
        notifications(context).isNotificationPolicyAccessGranted
    } catch (e: Exception) {
        false
    }

    /** قواعد DND المملوكة تتطلب Android 10 (API 29) فأحدث. */
    fun isSupported(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

    fun dndAccessSettingsIntent(): Intent =
        Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

    // ─── واجهة القناة ───

    /** مزامنة كاملة: حفظ الفترات ثم تسوية الحالة الراهنة وتسليح القادم. */
    fun sync(context: Context, periods: List<Pair<Long, Long>>) {
        val prefs = prefs(context)
        if (periods.isEmpty()) {
            endAndCancel(context)
            return
        }
        prefs.edit().putString(KEY_PERIODS, encode(periods)).apply()
        reconcile(context)
        armUpcoming(context)
    }

    /** إنهاء فائت وتفعيل جارٍ ثم تسليح القادم؛ لا يمس ما لا يملكه. */
    fun reconcile(context: Context) {
        val now = System.currentTimeMillis()
        val periods = loadPeriods(context)
        val active = periods.any { it.first <= now && now < it.second }
        if (active) {
            enableRule(context)
        } else {
            // قاعدتنا قد بقيت مفعّلة (إقلاع بعد انقضاء الفترة مثلًا)؛
            // نعطّلها وحدها.
            disableRule(context)
        }
    }

    fun endAndCancel(context: Context) {
        prefs(context).edit().remove(KEY_PERIODS).apply()
        cancelAlarms(context)
        disableRule(context)
    }

    // ─── مستقبِلات المنبّهات وأحداث النظام ───

    fun onStartAlarm(context: Context) {
        enableRule(context)
        armUpcoming(context)
    }

    fun onEndAlarm(context: Context) {
        // نهاية الفترة الحالية؛ إن كانت فترة أخرى جارية فتبقى القاعدة.
        reconcile(context)
        armUpcoming(context)
    }

    fun onSystemEvent(context: Context) {
        val hasPeriods = !prefs(context).getString(KEY_PERIODS, null).isNullOrEmpty()
        if (!hasPeriods) return
        reconcile(context)
        armUpcoming(context)
    }

    // ─── تسليح المنبّهات (أقرب بدء وأقرب نهاية فقط) ───

    private fun armUpcoming(context: Context) {
        val now = System.currentTimeMillis()
        val periods = loadPeriods(context)
        cancelAlarms(context)

        periods.filter { it.second > now }
            .minOfOrNull { it.first.coerceAtLeast(now) }
            ?.let { nextStart -> schedule(context, REQUEST_CODE_START, ACTION_START, nextStart) }

        periods.filter { it.second > now }
            .minOfOrNull { it.second }
            ?.let { nextEnd -> schedule(context, REQUEST_CODE_END, ACTION_END, nextEnd) }
    }

    private fun schedule(context: Context, requestCode: Int, action: String, atMillis: Long) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = pendingIntent(context, requestCode, action)
        val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            manager.canScheduleExactAlarms()
        try {
            if (canExact) {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pending)
            } else {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pending)
            }
        } catch (e: SecurityException) {
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pending)
        }
    }

    private fun cancelAlarms(context: Context) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        manager.cancel(pendingIntent(context, REQUEST_CODE_START, ACTION_START))
        manager.cancel(pendingIntent(context, REQUEST_CODE_END, ACTION_END))
    }

    private fun pendingIntent(context: Context, requestCode: Int, action: String): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            requestCode,
            Intent(context, PrayerSilenceReceiver::class.java).setAction(action),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

    // ─── قاعدة DND التي يملكها التطبيق ───

    private fun enableRule(context: Context): Boolean {
        if (!isSupported()) return false
        val nm = notifications(context)
        if (!nm.isNotificationPolicyAccessGranted) return false
        val existingId = prefs(context).getString(KEY_RULE_ID, null)
        if (existingId != null) {
            val current = runCatching { nm.getAutomaticZenRule(existingId) }.getOrNull()
            if (current != null) {
                current.isEnabled = true
                runCatching { nm.updateAutomaticZenRule(existingId, current) }
                    .onFailure { return false }
                return true
            }
        }
        val id = runCatching { nm.addAutomaticZenRule(buildRule(context, enabled = true)) }
            .getOrNull() ?: return false
        prefs(context).edit().putString(KEY_RULE_ID, id).apply()
        return true
    }

    /** تعطيل قاعدة التطبيق وحدها؛ لا يحذف القاعدة ولا يمس غيرها. */
    private fun disableRule(context: Context) {
        val nm = notifications(context)
        if (!nm.isNotificationPolicyAccessGranted) return
        val id = prefs(context).getString(KEY_RULE_ID, null) ?: return
        val current = runCatching { nm.getAutomaticZenRule(id) }.getOrNull() ?: return
        if (current.isEnabled) {
            current.isEnabled = false
            runCatching { nm.updateAutomaticZenRule(id, current) }
        }
    }

    /** التوقيع ثابت منذ API 29/30 ومدعوم حتى 37. */
    private fun buildRule(context: Context, enabled: Boolean): AutomaticZenRule =
        AutomaticZenRule(
            context.getString(R.string.prayer_silence_rule_name),
            ComponentName(context, MainActivity::class.java),
            null, /* configurationActivity */
            RULE_URI, /* معرّف ثابت لقاعدة بلا مزود حالة؛ النظام يشترط غير-فارغ */
            null, /* ZenPolicy=null: استثناءات النظام كما ضبطها المستخدم */
            NotificationManager.INTERRUPTION_FILTER_PRIORITY,
            enabled
        )

    // ─── التخزين ───

    private fun notifications(context: Context): NotificationManager =
        context.getSystemService(NotificationManager::class.java)

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun encode(periods: List<Pair<Long, Long>>): String {
        val array = JSONArray()
        for ((start, end) in periods) {
            array.put(JSONObject().put("s", start).put("e", end))
        }
        return array.toString()
    }

    private fun loadPeriods(context: Context): List<Pair<Long, Long>> {
        val raw = prefs(context).getString(KEY_PERIODS, null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { i ->
                val o = array.getJSONObject(i)
                val s = o.optLong("s", -1)
                val e = o.optLong("e", -1)
                if (s > 0 && e > s) s to e else null
            }
        }.getOrDefault(emptyList())
    }
}
