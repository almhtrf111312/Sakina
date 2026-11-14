package com.sakina.app.alarm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.sakina.app.R
import com.sakina.app.aod.AodActivity
import com.sakina.app.service.AdhanForegroundService
import org.json.JSONObject

/**
 * AdhanReceiver — triggered by AlarmScheduler when prayer time arrives.
 *
 * Responsibilities:
 *  1. Start AdhanForegroundService (plays adhan audio)
 *  2. On Android 10+: fire a fullScreenIntent to show AodActivity
 *  3. Build a rich notification: prayer name, time, Stop / Delay / Prayed actions
 *  4. Category ALARM, priority HIGH, visibility PUBLIC (shows on lock screen)
 */
class AdhanReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AdhanReceiver"

        const val CHANNEL_ID = "sakina_adhan_channel"
        const val CHANNEL_NAME = "أذان الصلاة"

        // Action constants (also used by AodActivity / AlarmBridgePlugin)
        const val ACTION_STOP_ADHAN  = "com.sakina.app.ACTION_STOP_ADHAN"
        const val ACTION_DELAY_ADHAN = "com.sakina.app.ACTION_DELAY_ADHAN"
        const val ACTION_PRAYED      = "com.sakina.app.ACTION_PRAYED"

        const val EXTRA_PRAYER_NAME      = "prayer_name"
        const val EXTRA_PRAYER_TIME      = "prayer_time"
        const val EXTRA_PRAYER_JSON      = "prayer_json"
        const val EXTRA_NOTIFICATION_ID  = "notification_id"

        const val NOTIFICATION_ID_BASE = 2000
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        Log.d(TAG, "onReceive: $action")

        when (action) {
            "com.sakina.app.ACTION_PRAYER_ALARM" -> handlePrayerAlarm(context, intent)
            ACTION_STOP_ADHAN  -> stopAdhan(context, intent)
            ACTION_DELAY_ADHAN -> delayAdhan(context, intent)
            ACTION_PRAYED      -> markPrayed(context, intent)
        }
    }

    // ── Alarm fired ─────────────────────────────────────────────────────────

    private fun handlePrayerAlarm(context: Context, intent: Intent) {
        val prayerJson = intent.getStringExtra(EXTRA_PRAYER_JSON) ?: return
        val alarmId    = intent.getIntExtra("alarm_id", NOTIFICATION_ID_BASE)

        val prayer = try { JSONObject(prayerJson) } catch (e: Exception) {
            Log.e(TAG, "Invalid prayer JSON", e); return
        }

        val prayerName  = prayer.optString("name", "صلاة")
        val prayerTime  = prayer.optString("timeLabel", "")
        val notifType   = prayer.optString("notificationType", "adhan")
        val isFajr      = prayerName.equals("Fajr", ignoreCase = true)
        val notificationId = alarmId + NOTIFICATION_ID_BASE

        ensureNotificationChannel(context)

        // ── 1. Start foreground service to play adhan ─────────────────────
        val serviceIntent = Intent(context, AdhanForegroundService::class.java).apply {
            putExtra(EXTRA_PRAYER_NAME, prayerName)
            putExtra(EXTRA_PRAYER_TIME, prayerTime)
            putExtra(EXTRA_PRAYER_JSON, prayerJson)
            putExtra("is_fajr", isFajr)
            putExtra("notif_type", notifType)
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // ── 2. Build notification ─────────────────────────────────────────
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val stopIntent   = buildActionIntent(context, ACTION_STOP_ADHAN,  prayerJson, notificationId)
        val delayIntent  = buildActionIntent(context, ACTION_DELAY_ADHAN, prayerJson, notificationId)
        val prayedIntent = buildActionIntent(context, ACTION_PRAYED,       prayerJson, notificationId)

        // Full-screen intent (AOD / lock screen) — Android 10+
        val fullScreenPi = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val aodIntent = Intent(context, AodActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(EXTRA_PRAYER_NAME, prayerName)
                putExtra(EXTRA_PRAYER_TIME, prayerTime)
                putExtra(EXTRA_PRAYER_JSON, prayerJson)
            }
            PendingIntent.getActivity(
                context, notificationId + 500, aodIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else null

        val titleAr = prayerArabicName(prayerName)
        val subtitle = if (prayerTime.isNotEmpty()) "وقت $titleAr – $prayerTime" else "حان وقت $titleAr"

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_mosque)        // must exist in res/drawable
            .setContentTitle(titleAr)
            .setContentText(subtitle)
            .setStyle(NotificationCompat.BigTextStyle().bigText(subtitle))
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(false)
            .setOngoing(true)
            .setColorized(true)
            .setColor(0xFF5FB59B.toInt())
            // Actions
            .addAction(0, "⏹ إيقاف", stopIntent)
            .addAction(0, "⏱ تأجيل ١٠د", delayIntent)
            .addAction(0, "✔ صليت", prayedIntent)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            builder.setFullScreenIntent(fullScreenPi, true)
        }

        nm.notify(notificationId, builder.build())
        Log.i(TAG, "Notification posted for $prayerName (id=$notificationId)")
    }

    // ── Action handlers ──────────────────────────────────────────────────────

    private fun stopAdhan(context: Context, intent: Intent) {
        val notifId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1)
        context.stopService(Intent(context, AdhanForegroundService::class.java))
        if (notifId != -1) {
            (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .cancel(notifId)
        }
    }

    private fun delayAdhan(context: Context, intent: Intent) {
        val prayerJson = intent.getStringExtra(EXTRA_PRAYER_JSON) ?: return
        val notifId    = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1)

        stopAdhan(context, intent)

        // Reschedule 10 minutes later
        val prayer = try { JSONObject(prayerJson) } catch (e: Exception) { return }
        val delayMs = 10 * 60 * 1000L
        val newTimestamp = System.currentTimeMillis() + delayMs
        prayer.put("timestamp", newTimestamp)
        prayer.put("timeLabel", "")

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        val delayedIntent = Intent(context, AdhanReceiver::class.java).apply {
            action = "com.sakina.app.ACTION_PRAYER_ALARM"
            putExtra(EXTRA_PRAYER_JSON, prayer.toString())
            putExtra("alarm_id", notifId)
        }
        val pi = PendingIntent.getBroadcast(
            context, notifId + 100, delayedIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, newTimestamp, pi)
        } else {
            alarmManager.setExact(android.app.AlarmManager.RTC_WAKEUP, newTimestamp, pi)
        }
        Log.i(TAG, "Delayed adhan by 10 minutes")
    }

    private fun markPrayed(context: Context, intent: Intent) {
        // Simply stop adhan; Flutter side handles prayer tracking
        stopAdhan(context, intent)
        Log.i(TAG, "Marked as prayed")
    }

    // ── Notification channel ─────────────────────────────────────────────────

    private fun ensureNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تنبيهات أوقات الصلاة"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 300, 200, 300)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setShowBadge(true)
            // Note: custom sound is set by AdhanForegroundService via STREAM_ALARM;
            // this channel uses default alarm ringtone as fallback.
        }
        nm.createNotificationChannel(channel)
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private fun buildActionIntent(
        context: Context,
        action: String,
        prayerJson: String,
        notifId: Int
    ): PendingIntent {
        val i = Intent(context, AdhanReceiver::class.java).apply {
            this.action = action
            putExtra(EXTRA_PRAYER_JSON, prayerJson)
            putExtra(EXTRA_NOTIFICATION_ID, notifId)
        }
        val requestCode = when (action) {
            ACTION_STOP_ADHAN  -> notifId + 1
            ACTION_DELAY_ADHAN -> notifId + 2
            ACTION_PRAYED      -> notifId + 3
            else               -> notifId + 4
        }
        return PendingIntent.getBroadcast(
            context, requestCode, i,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun prayerArabicName(englishName: String): String = when (englishName.lowercase()) {
        "fajr"    -> "الفجر"
        "dhuhr"   -> "الظهر"
        "asr"     -> "العصر"
        "maghrib" -> "المغرب"
        "isha"    -> "العشاء"
        "sunrise" -> "الشروق"
        else      -> englishName
    }
}
