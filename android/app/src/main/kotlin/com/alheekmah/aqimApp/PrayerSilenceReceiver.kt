package com.alheekmah.aqimApp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * يستقبل منبّهات بدء/نهاية فترات التصميت وأحداث النظام:
 * - الإقلاع وتغيّر الوقت أو المنطقة الزمنية أو التاريخ: إعادة تسوية
 *   القاعدة وتسليح القادم من الفترات المحفوظة.
 */
class PrayerSilenceReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            PrayerSilenceManager.ACTION_START -> PrayerSilenceManager.onStartAlarm(context)
            PrayerSilenceManager.ACTION_END -> PrayerSilenceManager.onEndAlarm(context)
            else -> PrayerSilenceManager.onSystemEvent(context)
        }
    }
}
