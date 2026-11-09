package com.alheekmah.alheekmahLibrary

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetPlugin
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import android.view.View
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetProvider
import com.alheekmah.aqimApp.R
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH
import android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT
import android.graphics.Bitmap
import android.graphics.Canvas
import com.caverock.androidsvg.SVG
import org.json.JSONObject

open class PrayerWidget : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action ?: return
        when (action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_LOCALE_CHANGED -> {
                try {
                    val manager = AppWidgetManager.getInstance(context)
                    val component = android.content.ComponentName(context, this::class.java)
                    val ids = manager.getAppWidgetIds(component)
                    if (ids.isNotEmpty()) {
                        val updateIntent = Intent(context, this::class.java).apply {
                            this.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                        }
                        context.sendBroadcast(updateIntent)
                    }
                } catch (_: Exception) {}
            }
        }
    }

    // توقيع onUpdate المطلوب من HomeWidgetProvider (يمرّر SharedPreferences مباشرة)
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            updateAppWidget(context, appWidgetManager, id, widgetData)
        }
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        super.onAppWidgetOptionsChanged(context, manager, appWidgetId, newOptions)
        updateAppWidget(context, manager, appWidgetId, HomeWidgetPlugin.getData(context))
    }

    protected open fun resolveLayout(context: Context, manager: AppWidgetManager, appWidgetId: Int): Int {
        val options = manager.getAppWidgetOptions(appWidgetId)
        // The minimum dimensions describe different orientations. Select the
        // matching pair so a tall portrait widget does not remain in medium mode.
        val landscape = context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        val width = options.getInt(if (landscape) AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH else OPTION_APPWIDGET_MIN_WIDTH)
        val height = options.getInt(if (landscape) OPTION_APPWIDGET_MIN_HEIGHT else AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
        return when {
            width >= 250 && height >= 240 -> R.layout.prayer_widget_layout_large
            width >= 250 && height >= 110 -> R.layout.prayer_widget_layout_medium
            else -> R.layout.prayer_widget_layout_small
        }
    }

    protected open fun updateAppWidget(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        prefs: SharedPreferences
    ) {
        val lang = prefs.getString("app_language", "ar") ?: "ar"

        // محاولة قراءة بيانات الشهر الكامل لأوقات اليوم الدقيقة
        // Try monthly data for accurate daily prayer times
        var monthlyFajr: String? = null
        var monthlySunrise: String? = null
        var monthlyDhuhr: String? = null
        var monthlyAsr: String? = null
        var monthlyMaghrib: String? = null
        var monthlyIsha: String? = null
        var monthlyMidnight: String? = null
        var monthlyLastThird: String? = null
        var monthlyCurrentEpoch: Long = -1L
        var monthlyNextEpoch: Long = -1L
        var monthlyCurrentName: String? = null
        var monthlyNextName: String? = null
        var monthlyCurrentTime: String? = null
        var monthlyNextTime: String? = null

        try {
            val monthlyJson = prefs.getString("monthly_prayer_times", null)
            if (monthlyJson != null) {
                val json = JSONObject(monthlyJson)
                val cal = Calendar.getInstance()
                val curYear = cal.get(Calendar.YEAR)
                val curMonth = cal.get(Calendar.MONTH) + 1
                val curDay = cal.get(Calendar.DAY_OF_MONTH)

                if (json.getInt("year") == curYear && json.getInt("month") == curMonth) {
                    val days = json.getJSONObject("days")
                    val dayStr = days.optString("$curDay", "")
                    if (dayStr.isNotEmpty()) {
                        val parts = dayStr.split("|")
                        if (parts.size == 8) {
                            val sdf = SimpleDateFormat("h:mm a", Locale(lang))

                            fun hhmmToCalendar(hhmm: String): Calendar {
                                val (h, m) = hhmm.split(":").map { it.toInt() }
                                val c = Calendar.getInstance()
                                c.set(Calendar.HOUR_OF_DAY, h)
                                c.set(Calendar.MINUTE, m)
                                c.set(Calendar.SECOND, 0)
                                c.set(Calendar.MILLISECOND, 0)
                                return c
                            }

                            fun fmtHhmm(hhmm: String): String {
                                return toArabicDigits(sdf.format(hhmmToCalendar(hhmm).time), lang)
                            }

                            monthlyFajr = fmtHhmm(parts[0])
                            monthlySunrise = fmtHhmm(parts[1])
                            monthlyDhuhr = fmtHhmm(parts[2])
                            monthlyAsr = fmtHhmm(parts[3])
                            monthlyMaghrib = fmtHhmm(parts[4])
                            monthlyIsha = fmtHhmm(parts[5])
                            monthlyMidnight = fmtHhmm(parts[6])
                            monthlyLastThird = fmtHhmm(parts[7])

                            // حساب الصلاة الحالية والتالية من أوقات اليوم
                            val nowMillis = System.currentTimeMillis()
                            val prayerEpochs = listOf(
                                "fajr" to hhmmToCalendar(parts[0]).timeInMillis,
                                "dhuhr" to hhmmToCalendar(parts[2]).timeInMillis,
                                "asr" to hhmmToCalendar(parts[3]).timeInMillis,
                                "maghrib" to hhmmToCalendar(parts[4]).timeInMillis,
                                "isha" to hhmmToCalendar(parts[5]).timeInMillis,
                            )
                            val prayerDisplayTimes = listOf(monthlyFajr, monthlyDhuhr, monthlyAsr, monthlyMaghrib, monthlyIsha)
                            val prayerNames = listOf(
                                prefs.getString("fajr_name", "الفجر") ?: "الفجر",
                                prefs.getString("dhuhr_name", "الظهر") ?: "الظهر",
                                prefs.getString("asr_name", "العصر") ?: "العصر",
                                prefs.getString("maghrib_name", "المغرب") ?: "المغرب",
                                prefs.getString("isha_name", "العشاء") ?: "العشاء",
                            )

                            var foundCurrent = false
                            for (i in prayerEpochs.indices.reversed()) {
                                if (nowMillis >= prayerEpochs[i].second) {
                                    monthlyCurrentEpoch = prayerEpochs[i].second
                                    monthlyCurrentName = prayerNames[i]
                                    monthlyCurrentTime = prayerDisplayTimes[i]
                                    if (i < prayerEpochs.size - 1) {
                                        monthlyNextEpoch = prayerEpochs[i + 1].second
                                        monthlyNextName = prayerNames[i + 1]
                                        monthlyNextTime = prayerDisplayTimes[i + 1]
                                    } else {
                                        // بعد العشاء → الفجر غدًا
                                        monthlyNextEpoch = hhmmToCalendar(parts[0]).timeInMillis + 86_400_000L
                                        monthlyNextName = prayerNames[0]
                                        monthlyNextTime = prayerDisplayTimes[0]
                                    }
                                    foundCurrent = true
                                    break
                                }
                            }
                            if (!foundCurrent) {
                                // قبل الفجر
                                monthlyCurrentEpoch = hhmmToCalendar(parts[5]).timeInMillis - 86_400_000L
                                monthlyCurrentName = prayerNames[4]
                                monthlyCurrentTime = prayerDisplayTimes[4]
                                monthlyNextEpoch = prayerEpochs[0].second
                                monthlyNextName = prayerNames[0]
                                monthlyNextTime = prayerDisplayTimes[0]
                            }
                        }
                    }
                }
            }
        } catch (_: Exception) {}

        // Hijri values from Flutter (already Arabic digits), with local fallback
        val hijriDay = prefs.getString("hijri_day_number", null) ?: toArabicDigits(getHijriDay().toString(), lang)
        val hijriYear = prefs.getString("hijri_year", null) ?: toArabicDigits(getHijriYear().toString(), lang)
        val hijriMonthIdx = prefs.getString("hijri_month_image", null) ?: "1"
        val dayName = prefs.getString("hijri_day_name", null) ?: weekdayName(Locale(lang))

        val currentPrayerName = monthlyCurrentName ?: prefs.getString("current_prayer_name", null) ?: ""
        val nextPrayerName = monthlyNextName ?: (prefs.getString("next_prayer_name", null)
                ?: prefs.getString("althuluth_alakhir_name", null)) ?: ""
        var currentPrayerTime = monthlyCurrentTime ?: prefs.getString("current_prayer_time", "--:--") ?: "--:--"
        var nextPrayerTime = monthlyNextTime ?: prefs.getString("next_prayer_time", "--:--") ?: "--:--"

        // Epochs for countdown (milliseconds since epoch). Add fallback to now to avoid crash.
        var currentEpoch = if (monthlyCurrentEpoch > 0) monthlyCurrentEpoch else prefs.getLong("current_prayer_epoch", -1L)
        var nextEpoch = if (monthlyNextEpoch > 0) monthlyNextEpoch else prefs.getLong("next_prayer_epoch", -1L)

        val layoutId = resolveLayout(context, manager, appWidgetId)
        val views = RemoteViews(context.packageName, layoutId)

        // Set layout direction based on app_language (RTL for ar/ur/fa)
        val rtl = isRtlLanguage(lang)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            try {
                views.setInt(R.id.widget_root, "setLayoutDirection", if (rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR)
            } catch (_: Exception) {}
        }

        // Fill header/date if present (large layout) أو الصغير
        setTextIfExists(context, views, R.id.hijri_day_overlay, hijriDay)
        setTextIfExists(context, views, R.id.hijri_year_weekday, toArabicDigits(hijriYear, lang) + " " + dayName)
        // Render hijri watermark icon if view exists
        try {
            val assetPath = "flutter_assets/assets/svg/hijri/${hijriMonthIdx}.svg"
            renderSvgAssetToBitmap(context, assetPath, 96f, 54f)?.let {
                views.setImageViewBitmap(R.id.hijri_icon, it)
            }
        } catch (_: Exception) {}

        // Use the app's translations, since its language may differ from the system language.
        val nextLabel = try {
            context.assets.open("flutter_assets/assets/locales/$lang.json").bufferedReader().use {
                JSONObject(it.readText()).optString("nextPrayer", "Next prayer")
            }
        } catch (_: Exception) {
            if (lang == "ar") "الصلاة القادمة" else "Next prayer"
        }
        setTextIfExists(context, views, R.id.widget_next_label, nextLabel)
        val remainingLabel = try {
            context.assets.open("flutter_assets/assets/locales/$lang.json").bufferedReader().use {
                JSONObject(it.readText()).optString("timeLeft:", "Time remaining").trimEnd(':', '：', ' ')
            }
        } catch (_: Exception) {
            if (lang == "ar") "المتبقي" else "Time remaining"
        }
        setTextIfExists(context, views, R.id.widget_remaining_label,
            if (lang == "ar") "المتبقي" else remainingLabel)
        val nightPrayerNames = listOf("fajr_name", "maghrib_name", "isha_name")
            .mapNotNull { prefs.getString(it, null) }
        views.setImageViewResource(R.id.widget_prayer_icon,
            if (nextPrayerName in nightPrayerNames) R.drawable.ic_moon else R.drawable.ic_widget_sun)

        // The same logo used by the iOS widget, rendered from the bundled SVG.
        renderSvgAssetToBitmap(context, "flutter_assets/assets/svg/logo/aqem_logo_stroke.svg", 32f, 18f)?.let {
            views.setImageViewBitmap(R.id.widget_logo, it)
        }

        // Current / Next (both layouts have next_prayer_name/time in some form)
        setTextIfExists(context, views, R.id.current_prayer_name, currentPrayerName)
            setTextIfExists(context, views, R.id.current_prayer_time, currentPrayerTime)
        setTextIfExists(context, views, R.id.next_prayer_name, nextPrayerName)
        setTextIfExists(context, views, R.id.next_prayer_time, nextPrayerTime)
        setTextIfExists(context, views, R.id.next_prayer_name_big, nextPrayerName)
        setTextIfExists(context, views, R.id.next_prayer_time_big, nextPrayerTime)

        // Removed now_time view per request
        val now = System.currentTimeMillis()

        // Countdown using Chronometer (API 24+ supports countdown flag)
        if (nextEpoch > 0 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val base = SystemClock.elapsedRealtime() + (nextEpoch - System.currentTimeMillis())
            views.setChronometer(R.id.countdown, base, null, true)
            views.setChronometerCountDown(R.id.countdown, true)
            views.setViewVisibility(R.id.countdown, View.VISIBLE)
        } else {
            // Hide countdown when unsupported/unknown
            try { views.setViewVisibility(R.id.countdown, View.GONE) } catch (_: Exception) {}
        }

        // Remaining progress between current and next (100% at start → 0% at next)
        if (currentEpoch > 0 && nextEpoch > 0 && nextEpoch > currentEpoch) {
            val total = nextEpoch - currentEpoch
            val remain = (nextEpoch - now).coerceIn(0L, total)
            val percent = ((remain * 100) / total).toInt().coerceIn(0, 100)
            setProgressIfExists(views, R.id.progress, percent)
        }

        // Fill names/times in large grid if present (monthly data overrides stale prefs)
        setTextIfExists(context, views, R.id.fajr_name, prefs.getString("fajr_name", "الفجر")?:"الفجر")
        setTextIfExists(context, views, R.id.fajr_time, monthlyFajr ?: prefs.getString("fajr_time", "--:--")?:"--:--")
        setTextIfExists(context, views, R.id.sunrise_name, prefs.getString("shuroq_name", "الشروق")?:"الشروق")
        setTextIfExists(context, views, R.id.sunrise_time, monthlySunrise ?: prefs.getString("shuroq_time", "--:--")?:"--:--")
        setTextIfExists(context, views, R.id.dhuhr_name, prefs.getString("dhuhr_name", "الظهر")?:"الظهر")
        setTextIfExists(context, views, R.id.dhuhr_time, monthlyDhuhr ?: prefs.getString("dhuhr_time", "--:--")?:"--:--")
        setTextIfExists(context, views, R.id.asr_name, prefs.getString("asr_name", "العصر")?:"العصر")
        setTextIfExists(context, views, R.id.asr_time, monthlyAsr ?: prefs.getString("asr_time", "--:--")?:"--:--")
        setTextIfExists(context, views, R.id.maghrib_name, prefs.getString("maghrib_name", "المغرب")?:"المغرب")
        setTextIfExists(context, views, R.id.maghrib_time, monthlyMaghrib ?: prefs.getString("maghrib_time", "--:--")?:"--:--")
        setTextIfExists(context, views, R.id.isha_name, prefs.getString("isha_name", "العشاء")?:"العشاء")
        setTextIfExists(context, views, R.id.isha_time, monthlyIsha ?: prefs.getString("isha_time", "--:--")?:"--:--")

        // Midnight / last third
        setTextIfExists(context, views, R.id.midnight_name, prefs.getString("muntasaf_allayl_name", "منتصف الليل")?:"منتصف الليل")
        setTextIfExists(context, views, R.id.midnight_time, monthlyMidnight ?: prefs.getString("muntasaf_allayl_time", "--:--")?:"--:--")
        setTextIfExists(context, views, R.id.last_third_name, prefs.getString("althuluth_alakhir_name", "ثلث الليل الأخير")?:"ثلث الليل الأخير")
        setTextIfExists(context, views, R.id.last_third_time, monthlyLastThird ?: prefs.getString("althuluth_alakhir_time", "--:--")?:"--:--")

        // Highlight NEXT prayer (small layout) ليتطابق مع الكبير
        val nextSmall = nextPrayerName
        setBackgroundIfExists(views, R.id.pill_fajr, if (nextSmall == (prefs.getString("fajr_name", "الفجر") ?: "الفجر")) R.drawable.bg_pill_selected else R.drawable.bg_pill_unselected)
        setBackgroundIfExists(views, R.id.pill_dhuhr, if (nextSmall == (prefs.getString("dhuhr_name", "الظهر") ?: "الظهر")) R.drawable.bg_pill_selected else R.drawable.bg_pill_unselected)
        setBackgroundIfExists(views, R.id.pill_asr, if (nextSmall == (prefs.getString("asr_name", "العصر") ?: "العصر")) R.drawable.bg_pill_selected else R.drawable.bg_pill_unselected)
        setBackgroundIfExists(views, R.id.pill_maghrib, if (nextSmall == (prefs.getString("maghrib_name", "المغرب") ?: "المغرب")) R.drawable.bg_pill_selected else R.drawable.bg_pill_unselected)
        setBackgroundIfExists(views, R.id.pill_isha, if (nextSmall == (prefs.getString("isha_name", "العشاء") ?: "العشاء")) R.drawable.bg_pill_selected else R.drawable.bg_pill_unselected)

        // Highlight next prayer within rows (large layout)
        val next = nextPrayerName
        setBackgroundIfExists(views, R.id.row_fajr, if (next == (prefs.getString("fajr_name", "الفجر") ?: "الفجر")) R.drawable.bg_pill_selected else R.drawable.bg_pill_unselected)
        setBackgroundIfExists(views, R.id.row_sunrise, if (next == (prefs.getString("shuroq_name", "الشروق") ?: "الشروق")) R.drawable.bg_pill_selected else R.drawable.bg_pill_unselected)
        setBackgroundIfExists(views, R.id.row_dhuhr, if (next == (prefs.getString("dhuhr_name", "الظهر") ?: "الظهر")) R.drawable.bg_pill_selected else R.drawable.bg_pill_unselected)
        setBackgroundIfExists(views, R.id.row_asr, if (next == (prefs.getString("asr_name", "العصر") ?: "العصر")) R.drawable.bg_pill_selected else R.drawable.bg_pill_unselected)
        setBackgroundIfExists(views, R.id.row_maghrib, if (next == (prefs.getString("maghrib_name", "المغرب") ?: "المغرب")) R.drawable.bg_pill_selected else R.drawable.bg_pill_unselected)
        setBackgroundIfExists(views, R.id.row_isha, if (next == (prefs.getString("isha_name", "العشاء") ?: "العشاء")) R.drawable.bg_pill_selected else R.drawable.bg_pill_unselected)

        // Click: open app
        val intent = Intent(Intent.ACTION_MAIN).apply {
            setClassName(context.packageName, "com.alheekmah.aqimApp.MainActivity")
            addCategory(Intent.CATEGORY_LAUNCHER)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("widgetClicked", "PrayerWidget")
        }
        val pending = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0)
        )
        views.setOnClickPendingIntent(R.id.widget_root, pending)

        manager.updateAppWidget(appWidgetId, views)

        // Schedule next automatic update بعد وقت الصلاة القادم + دقيقة لتحديث التمييز
        if (nextEpoch > System.currentTimeMillis()) {
            scheduleNextUpdate(context, appWidgetId, nextEpoch + 60_000) // بعد دقيقة من الأذان
        }
    }

    private fun getHijriDay(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val cal = android.icu.util.IslamicCalendar()
            cal.get(Calendar.DAY_OF_MONTH)
        } else {
            // Fallback: use Gregorian day to avoid crash on old devices
            Calendar.getInstance().get(Calendar.DAY_OF_MONTH)
        }
    }

    private fun getHijriYear(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val cal = android.icu.util.IslamicCalendar()
            cal.get(Calendar.YEAR)
        } else {
            // Fallback: use Gregorian year
            Calendar.getInstance().get(Calendar.YEAR)
        }
    }

    private fun weekdayName(locale: Locale): String {
        return SimpleDateFormat("EEEE", locale).format(java.util.Date())
    }

    private fun toArabicDigits(input: String, lang: String): String {
        val target = when (lang) {
            "ar", "ur", "fa" -> charArrayOf('٠','١','٢','٣','٤','٥','٦','٧','٨','٩')
            else -> return input
        }
        val sb = StringBuilder(input.length)
        for (ch in input) {
            if (ch in '0'..'9') sb.append(target[ch - '0']) else sb.append(ch)
        }
        return sb.toString()
    }

    private fun formatTime(epochMillis: Long, lang: String): String {
        val locale = Locale(lang)
        val fmt = SimpleDateFormat("HH:mm", locale)
        return toArabicDigits(fmt.format(java.util.Date(epochMillis)), lang)
    }

    private fun isRtlLanguage(lang: String): Boolean {
        return when (lang.lowercase(Locale.ROOT)) {
            "ar", "fa", "ur", "he", "ku" -> true
            else -> false
        }
    }

    private fun setTextIfExists(context: Context, rv: RemoteViews, viewId: Int, text: String) {
        try { rv.setTextViewText(viewId, text) } catch (_: Exception) {}
    }

    private fun setBackgroundIfExists(rv: RemoteViews, viewId: Int, resId: Int) {
        try { rv.setInt(viewId, "setBackgroundResource", resId) } catch (_: Exception) {}
    }

    private fun setProgressIfExists(rv: RemoteViews, viewId: Int, progress: Int) {
        try { rv.setProgressBar(viewId, 100, progress, false) } catch (_: Exception) {}
    }

    private fun setImageResIfExists(rv: RemoteViews, viewId: Int, resId: Int) {
        try { rv.setImageViewResource(viewId, resId) } catch (_: Exception) {}
    }

    private fun dpToPx(context: Context, dp: Float): Int {
        val density = context.resources.displayMetrics.density
        return (dp * density).toInt()
    }

    private fun renderSvgAssetToBitmap(context: Context, assetPath: String, widthDp: Float, heightDp: Float): Bitmap? {
        return try {
            context.assets.open(assetPath).use { input ->
                val svg = SVG.getFromInputStream(input)
                val widthPx = dpToPx(context, widthDp)
                val heightPx = dpToPx(context, heightDp)
                svg.documentWidth = widthPx.toFloat()
                svg.documentHeight = heightPx.toFloat()
                val bmp = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                svg.renderToCanvas(canvas)
                bmp
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun scheduleNextUpdate(context: Context, appWidgetId: Int, triggerAtMillis: Long) {
        try {
            val am = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            val intent = Intent(context, this::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            }
            val pending = PendingIntent.getBroadcast(
                context,
                appWidgetId, // استخدام معرف الويدجت لضمان تميّز الإنذار
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0)
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, triggerAtMillis, pending)
            } else {
                am.setExact(android.app.AlarmManager.RTC_WAKEUP, triggerAtMillis, pending)
            }
        } catch (_: Exception) {}
    }
}
