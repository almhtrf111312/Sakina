package com.sakina.app.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.sakina.app.widget.PrayerWidget

/**
 * TimeChangeReceiver — listens for system time or timezone changes and triggers
 * alarm rescheduling and widget refreshes.
 */
class TimeChangeReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "TimeChangeReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        Log.i(TAG, "Time change event received: $action")

        // Reschedule alarms
        AlarmScheduler.rescheduleFromStorage(context)

        // Notify Flutter isolate
        val rescheduleIntent = Intent(BootReceiver.ACTION_RESCHEDULE_NEEDED).apply {
            setPackage(context.packageName)
            putExtra("trigger", action)
        }
        context.sendBroadcast(rescheduleIntent)

        // Refresh home screen widget
        PrayerWidget.updateAllWidgets(context)
    }
}
