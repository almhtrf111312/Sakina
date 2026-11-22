package com.sakina.app.alarm

import android.app.AlarmManager
import android.app.AutomaticZenRule
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.service.notification.Condition
import android.service.notification.ZenPolicy
import android.util.Log
import androidx.annotation.RequiresApi
import com.sakina.app.MainActivity
import org.json.JSONArray

class PrayerSilenceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        PrayerSilenceScheduler.refresh(context)
    }
}

object PrayerSilenceScheduler {
    private const val PREFS = "sakina_prayer_silence"
    private const val WINDOWS = "windows"
    private const val RULE = "rule"
    private const val TRANSITION = 1
    private const val RESTORE_BACKUP = 2

    private data class Window(val start: Long, val end: Long)

    val supported: Boolean
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

    fun hasAccess(context: Context): Boolean = supported &&
        context.getSystemService(NotificationManager::class.java).isNotificationPolicyAccessGranted

    @Synchronized
    fun replace(context: Context, json: String) {
        if (!supported) return
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (prefs.getString(WINDOWS, "[]") != json) {
            check(prefs.edit().putString(WINDOWS, json).commit())
        }
        refresh(context)
    }

    @Synchronized
    fun refresh(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        try {
            reconcile(context)
        } catch (e: Exception) {
            Log.e("PrayerSilence", "Could not update the prayer silence rule", e)
        }
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun reconcile(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val notifications = context.getSystemService(NotificationManager::class.java)
        val alarms = context.getSystemService(AlarmManager::class.java)
        val now = System.currentTimeMillis()
        val windows = mergeWindows(JSONArray(prefs.getString(WINDOWS, "[]") ?: "[]"), now)
        val first = windows.firstOrNull()
        val active = first != null && first.start <= now
        val exactAllowed = AlarmScheduler.canScheduleExactAlarms(context, alarms)
        val transition = alarmIntent(context, TRANSITION)
        val backup = alarmIntent(context, RESTORE_BACKUP)

        if (!notifications.isNotificationPolicyAccessGranted) {
            alarms.cancel(transition)
            alarms.cancel(backup)
            return
        }

        val conditionId = Uri.parse("condition://${context.packageName}/prayer-silence")
        var ruleId = prefs.getString(RULE, null)
        if (ruleId == null || notifications.getAutomaticZenRule(ruleId) == null) {
            // Reuse the app rule if the process died between creating it and persisting its ID.
            ruleId = notifications.automaticZenRules.entries
                .firstOrNull { it.value.conditionId == conditionId }?.key
        }
        if (first == null || !exactAllowed) {
            if (ruleId != null) {
                if (prefs.getString(WINDOWS, "[]") == "[]") {
                    notifications.removeAutomaticZenRule(ruleId)
                    prefs.edit().remove(RULE).apply()
                } else {
                    setCondition(notifications, ruleId, conditionId, false)
                }
            }
            alarms.cancel(transition)
            alarms.cancel(backup)
            return
        }

        // Arm restoration before applying the rule. The inexact alarm still exists
        // if Android removes the exact alarm when its special access is revoked.
        if (active) {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, first.end, backup)
        } else {
            alarms.cancel(backup)
        }
        alarms.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP, if (active) first.end else first.start, transition
        )

        if (ruleId == null && active) {
            val policy = ZenPolicy.Builder().disallowAllSounds().allowAlarms(true).build()
            ruleId = notifications.addAutomaticZenRule(
                AutomaticZenRule(
                    "الصامت أثناء الصلاة", null, ComponentName(context, MainActivity::class.java),
                    conditionId, policy, NotificationManager.INTERRUPTION_FILTER_PRIORITY, true
                )
            )
            if (ruleId != null) prefs.edit().putString(RULE, ruleId).commit()
        }
        if (ruleId != null) setCondition(notifications, ruleId, conditionId, active)
    }

    private fun mergeWindows(json: JSONArray, now: Long): List<Window> {
        val windows = (0 until json.length()).mapNotNull { index ->
            val pair = json.optJSONArray(index) ?: return@mapNotNull null
            val start = pair.optLong(0)
            val end = pair.optLong(1)
            if (start > 0 && end > now && start < end) Window(start, end) else null
        }.sortedBy { it.start }

        val merged = mutableListOf<Window>()
        for (window in windows) {
            val previous = merged.lastOrNull()
            if (previous != null && window.start <= previous.end) {
                merged[merged.lastIndex] = Window(previous.start, maxOf(previous.end, window.end))
            } else {
                merged.add(window)
            }
        }
        return merged
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun setCondition(
        notifications: NotificationManager, ruleId: String, uri: Uri, active: Boolean
    ) {
        notifications.setAutomaticZenRuleState(
            ruleId,
            Condition(uri, "الصامت أثناء الصلاة", if (active) Condition.STATE_TRUE else Condition.STATE_FALSE)
        )
    }

    private fun alarmIntent(context: Context, requestCode: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context, requestCode, Intent(context, PrayerSilenceReceiver::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
}
