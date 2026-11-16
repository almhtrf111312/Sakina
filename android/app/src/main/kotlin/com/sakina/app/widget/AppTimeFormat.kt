package com.sakina.app.widget

import android.content.Context
import org.json.JSONObject
import java.util.Calendar
import java.util.Locale

/** Matches the Flutter appearance setting in native widgets and notifications. */
object AppTimeFormat {
    fun compact(context: Context, timestamp: Long): String = format(context, timestamp)
    fun is24Hour(context: Context): Boolean = try {
        val json = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.app_settings_v1", null)
        json != null && JSONObject(json).optBoolean("use24HourTime", false)
    } catch (_: Exception) { false }

    fun format(context: Context, timestamp: Long): String {
        val c = Calendar.getInstance().apply { timeInMillis = timestamp }
        val hour = c.get(Calendar.HOUR_OF_DAY)
        val minute = c.get(Calendar.MINUTE)
        if (is24Hour(context)) return String.format(Locale.US, "%02d:%02d", hour, minute)
        val hour12 = if (hour % 12 == 0) 12 else hour % 12
        return String.format(Locale.US, "%02d:%02d %s", hour12, minute,
            if (hour < 12) "ص" else "م")
    }
}
