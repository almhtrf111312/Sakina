package com.sakina.app.widget

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.sakina.app.MainActivity
import com.sakina.app.R

/**
 * Once-a-minute refresher for the home-screen widgets and the persistent
 * "next prayer" notification. Re-arms itself only while something needs it.
 */
class SakinaTick : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == ACTION_DISMISSED) {
            if (WidgetData.load(context)?.notificationEnabled == true) {
                val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val retry = PendingIntent.getBroadcast(context, REQ_RESTORE,
                    Intent(context, SakinaTick::class.java).setAction(ACTION_RESTORE),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                try {
                    alarm.set(AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime() + 3000, retry)
                } catch (_: Exception) {
                    // The regular minute refresh still restores the notification.
                }
            }
            return
        }
        refresh(context)
    }

    companion object {
        const val CHANNEL = "sakina_next_prayer_v2"
        const val NOTIF_ID = 7001
        private const val REQ = 7002
        private const val REQ_RESTORE = 7003
        private const val ACTION_DISMISSED = "com.sakina.app.PRAYER_NOTIFICATION_DISMISSED"
        private const val ACTION_RESTORE = "com.sakina.app.PRAYER_NOTIFICATION_RESTORE"

        private val widgets get() = listOf(
            WidgetSmall(), WidgetClock(), WidgetProgress(), WidgetList(), WidgetStrip(),
            WidgetLarge(), WidgetCircle(), WidgetBanner()
        )

        fun refresh(context: Context) {
            val app = context.applicationContext
            val data = WidgetData.load(app)
            var needTick = false

            for (w in widgets) {
                if (w.hasInstances(app)) {
                    w.updateAll(app)
                    needTick = true
                }
            }

            if (data?.notificationEnabled == true && data.next != null) {
                postNotification(app, data)
                needTick = true
            } else {
                if (com.sakina.app.aod.AlwaysOnService.running) {
                    (app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                        .notify(NOTIF_ID, foregroundNotification(app))
                } else {
                    NotificationManagerCompat.from(app).cancel(NOTIF_ID)
                }
            }

            if (needTick) arm(app) else disarm(app)
        }

        private fun pending(context: Context, flags: Int): PendingIntent? =
            PendingIntent.getBroadcast(
                context, REQ, Intent(context, SakinaTick::class.java),
                flags or PendingIntent.FLAG_IMMUTABLE
            )

        private fun arm(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val at = (System.currentTimeMillis() / 60_000L + 1) * 60_000L
            val pi = pending(context, PendingIntent.FLAG_UPDATE_CURRENT) ?: return
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                    am.setAndAllowWhileIdle(AlarmManager.RTC, at, pi)
                else am.set(AlarmManager.RTC, at, pi)
            } catch (_: Exception) {}
        }

        private fun disarm(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            pending(context, PendingIntent.FLAG_NO_CREATE)?.let { am.cancel(it) }
        }

        fun foregroundNotification(context: Context): Notification {
            val d = WidgetData.load(context)
            if (d?.notificationEnabled == true && d.next != null) return buildNotification(context, d)
            ensureChannel(context)
            return NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_mosque)
                .setContentTitle("المؤذن • الشاشة الدائمة")
                .setContentText("مواقيت الصلاة")
                .setOngoing(true).setSilent(true).build()
        }

        private fun ensureChannel(context: Context) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && nm.getNotificationChannel(CHANNEL) == null) {
                nm.createNotificationChannel(NotificationChannel(CHANNEL, "الصلاة القادمة", NotificationManager.IMPORTANCE_LOW)
                    .apply {
                        setShowBadge(false)
                        setSound(null, null)
                        enableVibration(false)
                        enableLights(false)
                    })
            }
        }

        private fun postNotification(context: Context, d: WidgetData) {
            if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            // Re-post only when what is shown actually changed: the countdown
            // ticks by itself, so a re-post every minute only caused flicker.
            val n = d.next
            val sig = "${n?.ts}|${d.progress / 4}|${AppTimeFormat.format(context, n?.ts ?: 0L)}"
            val alive = try {
                nm.activeNotifications.any { it.id == NOTIF_ID }
            } catch (_: Exception) { false }
            if (alive && sig == lastSig) return
            lastSig = sig
            nm.notify(NOTIF_ID, buildNotification(context, d))
        }

        @Volatile private var lastSig: String? = null

        private fun buildNotification(context: Context, d: WidgetData): Notification {
            ensureChannel(context)
            val n = d.next ?: return NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_mosque)
                .setContentTitle("المؤذن • الشاشة الدائمة")
                .setOngoing(true).setSilent(true).build()
            val timeStr = AppTimeFormat.format(context, n.ts)

            val open = PendingIntent.getActivity(
                context, 0, Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val dismissed = PendingIntent.getBroadcast(context, REQ_RESTORE,
                Intent(context, SakinaTick::class.java).setAction(ACTION_DISMISSED),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

            return NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_mosque)
                .setContentTitle("${n.nameAr} • $timeStr")
                .setContentText("المتبقي")
                .setWhen(n.ts)
                .setShowWhen(true)
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
                .setProgress(100, d.progress, false)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setSilent(true)
                .setCategory(NotificationCompat.CATEGORY_STATUS)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setDeleteIntent(dismissed)
                .setContentIntent(open)
                .build()
        }
    }
}
