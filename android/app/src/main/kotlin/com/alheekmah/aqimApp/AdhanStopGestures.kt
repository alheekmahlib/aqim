package com.alheekmah.aqimApp

import android.content.Context
import android.content.SharedPreferences

/**
 * حالة إيماءات إيقاف الأذان (المرحلة الرابعة):
 * - تفضيلا القلب وزر الصوت يرسلهما Flutter عبر القناة ويقرأهما
 *   AdhanPlaybackService (القلب) وMainActivity (زر الصوت).
 * - علم inAppPlaying يخبر المنصة بأن التطبيق يشغّل الأذان داخل الواجهة
 *   (بعد نقر الإشعار) فيوجَّه زر الصوت إلى Flutter بدل الخدمة.
 */
object AdhanStopGestures {

    private const val PREFS = "adhan_stop_gestures"
    private const val KEY_FLIP = "flip_enabled"
    private const val KEY_VOLUME = "volume_enabled"

    @Volatile
    var inAppPlaying: Boolean = false

    fun setGestures(context: Context, flip: Boolean, volume: Boolean) {
        prefs(context).edit()
            .putBoolean(KEY_FLIP, flip)
            .putBoolean(KEY_VOLUME, volume)
            .apply()
    }

    fun flipEnabled(context: Context): Boolean =
        prefs(context).getBoolean(KEY_FLIP, false)

    fun volumeEnabled(context: Context): Boolean =
        prefs(context).getBoolean(KEY_VOLUME, false)

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
