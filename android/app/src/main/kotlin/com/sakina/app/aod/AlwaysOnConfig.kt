package com.sakina.app.aod

import android.content.Context

/** Always-on screen settings, written by Flutter via AodBridgePlugin.setAlwaysOn. */
class AlwaysOnConfig(
    val enabled: Boolean,
    val dateMode: String,        // none | gregorian | hijri | both
    val textScale: Float,        // 1.0 / 1.3 / 1.6
    val brightness: Float,       // 0.02 .. 0.30
    val showPrayers: Boolean,
    val timeoutMin: Int,         // 0 = until the phone is unlocked
    val color: Int
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
                .putInt("timeoutMin", (m["timeoutMin"] as? Number)?.toInt() ?: 10)
                .putInt("color", (m["color"] as? Number)?.toInt() ?: 0xFF5FB59B.toInt())
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
                p.getInt("timeoutMin", 10),
                p.getInt("color", 0xFF5FB59B.toInt())
            )
        }
    }
}
