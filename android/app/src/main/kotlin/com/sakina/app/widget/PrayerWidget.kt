package com.sakina.app.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import com.sakina.app.MainActivity
import com.sakina.app.R
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * PrayerWidget — 2x1 small AppWidget showing next prayer name, time, and countdown.
 *
 * Updates:
 *  - Driven by AlarmManager exact alarms (NO battery-draining polling)
 *  - Updates immediately on prayer transitions or settings changes
 *  - Tap opens MainActivity
 */
class PrayerWidget : AppWidgetProvider() {

    companion object {
        private const val TAG = "PrayerWidget"
        const val ACTION_UPDATE_WIDGET = "com.sakina.app.ACTION_UPDATE_WIDGET"
        private const val PREFS_NAME = "sakina_alarm_prefs"
        private const val PREFS_KEY_PRAYER_TIMES = "prayer_times_json"
        private const val ALARM_REQUEST_CODE = 9999

        /**
         * Trigger an update of all active PrayerWidget instances.
         */
        fun updateAllWidgets(context: Context) {
            val intent = Intent(context, PrayerWidget::class.java).apply {
                action = ACTION_UPDATE_WIDGET
            }
            context.sendBroadcast(intent)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
        scheduleNextWidgetAlarm(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_UPDATE_WIDGET ||
            intent.action == Intent.ACTION_TIME_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, PrayerWidget::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
            scheduleNextWidgetAlarm(context)
        }
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Cancel scheduled alarms when last widget is removed
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, PrayerWidget::class.java).apply {
            action = ACTION_UPDATE_WIDGET
        }
        val pi = PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pi != null) {
            alarmManager.cancel(pi)
            pi.cancel()
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.prayer_widget)

        // 1. Pending intent to open MainActivity on widget click
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, openAppPendingIntent)

        // 2. Compute next prayer data from stored prayer schedule
        val nextPrayer = findNextPrayer(context)

        if (nextPrayer != null) {
            val arabicName = prayerArabicName(nextPrayer.name)
            views.setTextViewText(R.id.widget_prayer_name, arabicName)

            val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
            views.setTextViewText(R.id.widget_prayer_time, timeFormat.format(Date(nextPrayer.timestamp)))

            val diffMs = nextPrayer.timestamp - System.currentTimeMillis()
            if (diffMs > 0) {
                val diffSec = diffMs / 1000L
                val hrs = diffSec / 3600L
                val mins = (diffSec % 3600L) / 60L
                val secs = diffSec % 60L

                val countdownStr = if (hrs > 0) {
                    String.format(Locale.getDefault(), "%02d:%02d:%02d", hrs, mins, secs)
                } else {
                    String.format(Locale.getDefault(), "%02d:%02d", mins, secs)
                }
                views.setTextViewText(R.id.widget_countdown, countdownStr)
            } else {
                views.setTextViewText(R.id.widget_countdown, "الآن")
            }
        } else {
            views.setTextViewText(R.id.widget_prayer_name, "سكينة")
            views.setTextViewText(R.id.widget_prayer_time, "--:--")
            views.setTextViewText(R.id.widget_countdown, "--:--")
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private data class NextPrayerInfo(val name: String, val timestamp: Long)

    private fun findNextPrayer(context: Context): NextPrayerInfo? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val json = prefs.getString(PREFS_KEY_PRAYER_TIMES, null) ?: return null

        return try {
            val array = JSONArray(json)
            val now = System.currentTimeMillis()
            var closest: NextPrayerInfo? = null
            var minDiff = Long.MAX_VALUE

            for (i in 0 until array.length()) {
                val item = array.getJSONObject(i)
                val enabled = item.optBoolean("enabled", true)
                if (!enabled) continue

                val ts = item.optLong("timestamp", 0L)
                val name = item.optString("name", "")

                if (ts > now) {
                    val diff = ts - now
                    if (diff < minDiff) {
                        minDiff = diff
                        closest = NextPrayerInfo(name, ts)
                    }
                }
            }
            closest
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing prayer times in widget", e)
            null
        }
    }

    private fun scheduleNextWidgetAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, PrayerWidget::class.java).apply {
            action = ACTION_UPDATE_WIDGET
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Update every 60 seconds aligned to wall clock minute
        val now = System.currentTimeMillis()
        val nextMinute = (now / 60_000L + 1) * 60_000L

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC,
                nextMinute,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC,
                nextMinute,
                pendingIntent
            )
        }
    }

    private fun prayerArabicName(name: String): String = when (name.lowercase()) {
        "fajr"    -> "الفجر"
        "dhuhr"   -> "الظهر"
        "asr"     -> "العصر"
        "maghrib" -> "المغرب"
        "isha"    -> "العشاء"
        "sunrise" -> "الشروق"
        else      -> name
    }
}
