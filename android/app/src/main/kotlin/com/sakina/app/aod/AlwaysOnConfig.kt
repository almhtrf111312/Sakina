package com.sakina.app.aod

import android.content.Context

/** Always-on screen settings, written by Flutter via AodBridgePlugin.setAlwaysOn. */
class AlwaysOnConfig(
    val enabled: Boolean,
    val dateMode: String,        // none | gregorian | hijri | both
    val textScale: Float,        // 1.0 / 1.3 / 1.6
    val brightness: Float,       // 0.02 .. 0.30
    val showPrayers: Boolean,
    val doubleTapWake: Boolean,
    val timeoutMin: Int,         // 0 = until the phone is unlocked
    val color: Int,
    val clockStyle: Int,         // 0..5 digital, 6..7 analog
    val use24HourTime: Boolean,
    val arabicNumerals: Boolean, // ٠١٢٣ instead of 0123
    val hijriOffset: Int,        // -2 .. +2 days, same as the app setting
    val showWhen: String,        // always | adhan | charging | schedule
    val beforeAdhanMin: Int,     // "adhan" mode: minutes before the prayer
    val afterAdhanMin: Int,      // "adhan" mode: minutes after the prayer
    val scheduleFromMin: Int,    // "schedule" mode: minutes since midnight
    val scheduleToMin: Int
) {
    companion object {
        private const val PREFS = "sakina_always_on"

        fun save(ctx: Context, m: Map<*, *>) {
            ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putBoolean("enabled", m["enabled"] as? Boolean ?: false)
                .putString("dateMode", m["dateMode"] as? String ?: "both")
                .putFloat("textScale", (m["textScale"] as? Number)?.toFloat() ?: 1.3f)
                .putFloat("brightness", (m["brightness"] as? Number)?.toFloat() ?: 0.08f)
                .putBoolean("showPrayers", m["showPrayers"] as? Boolean ?: true)
                .putBoolean("doubleTapWake", m["doubleTapWake"] as? Boolean ?: false)
                .putInt("timeoutMin", (m["timeoutMin"] as? Number)?.toInt() ?: 5)
                .putInt("color", (m["color"] as? Number)?.toInt() ?: 0xFF5FB59B.toInt())
                .putInt("clockStyle", (m["clockStyle"] as? Number)?.toInt() ?: 0)
                .putBoolean("use24HourTime", m["use24HourTime"] as? Boolean ?: false)
                .putBoolean("arabicNumerals", m["arabicNumerals"] as? Boolean ?: false)
                .putInt("hijriOffset", (m["hijriOffset"] as? Number)?.toInt() ?: 0)
                .putString("showWhen", m["showWhen"] as? String ?: "always")
                .putInt("beforeAdhanMin", (m["beforeAdhanMin"] as? Number)?.toInt() ?: 10)
                .putInt("afterAdhanMin", (m["afterAdhanMin"] as? Number)?.toInt() ?: 15)
                .putInt("scheduleFromMin", (m["scheduleFromMin"] as? Number)?.toInt() ?: 22 * 60)
                .putInt("scheduleToMin", (m["scheduleToMin"] as? Number)?.toInt() ?: 6 * 60)
                .apply()
        }

        fun load(ctx: Context): AlwaysOnConfig {
            val p = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            return AlwaysOnConfig(
                p.getBoolean("enabled", false),
                p.getString("dateMode", "both") ?: "both",
                p.getFloat("textScale", 1.3f),
                p.getFloat("brightness", 0.08f).coerceIn(0.01f, 0.5f),
                p.getBoolean("showPrayers", true),
                p.getBoolean("doubleTapWake", false),
                p.getInt("timeoutMin", 5),
                p.getInt("color", 0xFF5FB59B.toInt()),
                p.getInt("clockStyle", 0).coerceIn(0, 7),
                p.getBoolean("use24HourTime", false),
                p.getBoolean("arabicNumerals", false),
                p.getInt("hijriOffset", 0).coerceIn(-2, 2),
                p.getString("showWhen", "always") ?: "always",
                p.getInt("beforeAdhanMin", 10),
                p.getInt("afterAdhanMin", 15),
                p.getInt("scheduleFromMin", 22 * 60),
                p.getInt("scheduleToMin", 6 * 60)
            )
        }
    }
}
