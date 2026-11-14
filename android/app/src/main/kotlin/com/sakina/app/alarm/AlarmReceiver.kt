package com.sakina.app.alarm

import android.content.Context
import android.content.Intent

/**
 * AlarmReceiver — alias / wrapper for AdhanReceiver referenced in AndroidManifest.xml.
 */
class AlarmReceiver : android.content.BroadcastReceiver() {
    private val delegate = AdhanReceiver()

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        val remappedIntent = Intent(intent).apply {
            when (action) {
                "com.sakina.app.PRAYER_ALARM" -> this.action = "com.sakina.app.ACTION_PRAYER_ALARM"
                "com.sakina.app.ADHAN_STOP"   -> this.action = AdhanReceiver.ACTION_STOP_ADHAN
                "com.sakina.app.ADHAN_SNOOZE" -> this.action = AdhanReceiver.ACTION_DELAY_ADHAN
            }
        }
        delegate.onReceive(context, remappedIntent)
    }
}
