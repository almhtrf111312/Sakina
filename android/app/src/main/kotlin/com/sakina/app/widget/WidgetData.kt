package com.sakina.app.widget

import android.content.Context
import org.json.JSONObject

/** Prayer schedule pushed from Flutter (SharedPreferences "sakina_widget_prefs"). */
data class WPrayer(val key: String, val ts: Long) {
    val nameAr: String
        get() = when (key) {
            "Fajr" -> "الفجر"
            "Dhuhr" -> "الظهر"
            "Asr" -> "العصر"
            "Maghrib" -> "المغرب"
            "Isha" -> "العشاء"
            else -> key
        }
}

class WidgetData(
    val city: String,
    val items: List<WPrayer>,
    val notificationEnabled: Boolean
) {
    private val now get() = System.currentTimeMillis()

    val next: WPrayer? get() = items.firstOrNull { it.ts > now }

    /** Previous prayer before [next] (for the progress bar). */
    val previous: WPrayer? get() {
        val n = next ?: return null
        return items.lastOrNull { it.ts <= now && it.ts < n.ts }
    }

    /** 0..100 progress between previous and next prayer. */
    val progress: Int get() {
        val n = next ?: return 0
        val p = previous?.ts ?: (n.ts - 5 * 3600_000L)
        val total = (n.ts - p).coerceAtLeast(1L)
        return (((now - p) * 100) / total).toInt().coerceIn(0, 100)
    }

    /** The five prayers of the day that contains the next prayer. */
    fun todayFive(): List<WPrayer> {
        val n = next ?: return items.takeLast(5)
        val cal = java.util.Calendar.getInstance().apply { timeInMillis = n.ts }
        val y = cal.get(java.util.Calendar.YEAR)
        val d = cal.get(java.util.Calendar.DAY_OF_YEAR)
        return items.filter {
            val c = java.util.Calendar.getInstance().apply { timeInMillis = it.ts }
            c.get(java.util.Calendar.YEAR) == y && c.get(java.util.Calendar.DAY_OF_YEAR) == d
        }.take(5)
    }

    companion object {
        const val PREFS = "sakina_widget_prefs"
        const val KEY = "data"

        fun save(context: Context, json: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putString(KEY, json).apply()
        }

        fun load(context: Context): WidgetData? {
            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY, null) ?: return null
            return try {
                val o = JSONObject(raw)
                val arr = o.getJSONArray("items")
                val list = ArrayList<WPrayer>()
                for (i in 0 until arr.length()) {
                    val it = arr.getJSONObject(i)
                    list.add(WPrayer(it.getString("n"), it.getLong("ts")))
                }
                list.sortBy { it.ts }
                WidgetData(o.optString("city", ""), list, o.optBoolean("notif", true))
            } catch (e: Exception) {
                null
            }
        }
    }
}
