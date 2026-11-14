package com.sakina.app.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.provider.Settings
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * AlarmScheduler — schedules exact prayer alarms for 7 days using AlarmManager.
 *
 * Handles:
 *  - SCHEDULE_EXACT_ALARM permission (Android 12 / API 31+)
 *  - USE_EXACT_ALARM (Android 13 / API 33+)
 *  - Storing prayer times in SharedPreferences for boot rescheduling
 *  - Cancelling all previously scheduled alarms before rescheduling
 */
object AlarmScheduler {

    private const val TAG = "AlarmScheduler"
    private const val PREFS_NAME = "sakina_alarm_prefs"
    private const val PREFS_KEY_PRAYER_TIMES = "prayer_times_json"
    private const val PREFS_KEY_ALARM_IDS = "scheduled_alarm_ids"
    private const val MAX_ALARM_ID = 1_000_000_000

    // Prayer index constants (matches AdhanReceiver expectations)
    val PRAYER_NAMES = listOf("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")

    /**
     * Schedule prayer alarms from a JSON string of prayer time entries.
     *
     * Expected JSON format (array):
     * [
     *   {
     *     "name": "Fajr",
     *     "timestamp": 1700000000000,   // epoch millis
     *     "enabled": true,
     *     "notificationType": "adhan"   // adhan | silent | vibrate | short | off
     *   },
     *   ...
     * ]
     * Up to 7 days of prayer times may be provided.
     */
    fun schedulePrayerAlarms(context: Context, prayerTimesJson: String): Boolean {
        return try {
            // Persist for boot rescheduling
            getPrefs(context).edit().putString(PREFS_KEY_PRAYER_TIMES, prayerTimesJson).apply()

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            if (!canScheduleExactAlarms(context, alarmManager)) {
                Log.w(TAG, "Cannot schedule exact alarms – permission not granted")
                return false
            }

            // Cancel existing alarms first
            cancelAllAlarms(context)

            val prayerArray = JSONArray(prayerTimesJson)
            var scheduled = 0
            val scheduledIds = HashSet<String>()

            for (i in 0 until prayerArray.length()) {
                val prayer = prayerArray.getJSONObject(i)
                val enabled = prayer.optBoolean("enabled", true)
                val notifType = prayer.optString("notificationType", "adhan")

                if (!enabled || notifType == "off") continue

                val timestamp = prayer.getLong("timestamp")
                val name = prayer.getString("name")

                // Skip past alarms (allow 1 minute tolerance)
                if (timestamp < System.currentTimeMillis() - 60_000L) continue

                val alarmId = generateAlarmId(timestamp, name)
                scheduleExactAlarm(context, alarmManager, alarmId, timestamp, prayer.toString())
                scheduledIds.add(alarmId.toString())
                scheduled++
                Log.d(TAG, "Scheduled $name at $timestamp (id=$alarmId)")
            }

            getPrefs(context).edit().putStringSet(PREFS_KEY_ALARM_IDS, scheduledIds).apply()
            Log.i(TAG, "Scheduled $scheduled prayer alarms")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to schedule alarms", e)
            false
        }
    }

    /**
     * Cancel all scheduled prayer alarms (IDs 0 .. MAX_ALARM_ID).
     * Called before rescheduling to avoid duplicates.
     */
    fun cancelAllAlarms(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val prefs = getPrefs(context)
        val ids = prefs.getStringSet(PREFS_KEY_ALARM_IDS, emptySet()) ?: emptySet()
        // Only cancel alarms we actually scheduled (previously this looped over
        // 10,000 ids and froze the main thread).
        for (idStr in ids) {
            val id = idStr.toIntOrNull() ?: continue
            val intent = createAlarmIntent(context, id, null)
            val pi = PendingIntent.getBroadcast(
                context,
                id,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (pi != null) {
                alarmManager.cancel(pi)
                pi.cancel()
            }
        }
        prefs.edit().remove(PREFS_KEY_ALARM_IDS).apply()
        Log.i(TAG, "Cancelled ${ids.size} existing alarms")
    }

    /**
     * Re-schedule alarms from stored SharedPreferences data.
     * Called after BOOT_COMPLETED or time zone change.
     */
    fun rescheduleFromStorage(context: Context): Boolean {
        val json = getPrefs(context).getString(PREFS_KEY_PRAYER_TIMES, null)
        return if (json != null) {
            Log.i(TAG, "Rescheduling alarms from stored data")
            schedulePrayerAlarms(context, json)
        } else {
            Log.w(TAG, "No stored prayer times found for rescheduling")
            false
        }
    }

    /**
     * Check whether exact alarm permission is available.
     */
    fun canScheduleExactAlarms(context: Context, alarmManager: AlarmManager? = null): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val am = alarmManager ?: context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return am.canScheduleExactAlarms()
    }

    /**
     * Return an Intent to open exact alarm settings (Android 12+).
     */
    fun getExactAlarmSettingsIntent(context: Context): Intent {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                data = android.net.Uri.parse("package:${context.packageName}")
            }
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                data = android.net.Uri.parse("package:${context.packageName}")
            }
        }
    }

    // ── Private helpers ─────────────────────────────────────────────────────

    private fun scheduleExactAlarm(
        context: Context,
        alarmManager: AlarmManager,
        alarmId: Int,
        triggerAtMillis: Long,
        prayerJson: String
    ) {
        val intent = createAlarmIntent(context, alarmId, prayerJson)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            }
            else -> {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            }
        }
    }

    private fun createAlarmIntent(context: Context, alarmId: Int, prayerJson: String?): Intent {
        return Intent(context, AdhanReceiver::class.java).apply {
            action = "com.sakina.app.ACTION_PRAYER_ALARM"
            putExtra("alarm_id", alarmId)
            if (prayerJson != null) {
                putExtra("prayer_json", prayerJson)
            }
        }
    }

    /**
     * Generate a stable integer alarm ID from timestamp + prayer name.
     * Keeps IDs within [0, MAX_ALARM_ID).
     */
    private fun generateAlarmId(timestamp: Long, name: String): Int {
        val minutes = timestamp / 60_000L // minute-precision
        val nameOffset = when (name) {
            "AzkarMorning" -> 6
            "AzkarEvening" -> 7
            else -> PRAYER_NAMES.indexOf(name).let { if (it < 0) 5 else it }
        }
        return ((minutes * 10 + nameOffset) % MAX_ALARM_ID).toInt()
    }

    private fun getPrefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
