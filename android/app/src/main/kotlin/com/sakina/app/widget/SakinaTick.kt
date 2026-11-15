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
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.sakina.app.MainActivity
import com.sakina.app.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Once-a-minute refresher for the home-screen widgets and the persistent
 * "next prayer" notification. Re-arms itself only while something needs it.
 */
class SakinaTick : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        refresh(context)
    }

    companion object {
        const val CHANNEL = "sakina_next_prayer"
        const val NOTIF_ID = 7001
        private const val REQ = 7002

        private val widgets get() = listOf(
            WidgetSmall(), WidgetClock(), WidgetProgress(), WidgetList(), WidgetStrip()
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

            if (data != null && (data.notificationEnabled || com.sakina.app.aod.AlwaysOnService.running) && data.next != null) {
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
            if (d?.next != null) return buildNotification(context, d)
            ensureChannel(context)
            return NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_mosque)
                .setContentTitle("سكينة • الشاشة الدائمة")
                .setContentText("افتح سكينة لتحديث مواقيت الصلاة")
                .setOngoing(true).setSilent(true).build()
        }

        private fun ensureChannel(context: Context) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && nm.getNotificationChannel(CHANNEL) == null) {
                nm.createNotificationChannel(NotificationChannel(CHANNEL, "الصلاة القادمة", NotificationManager.IMPORTANCE_LOW)
                    .apply { setShowBadge(false) })
            }
        }

        private fun postNotification(context: Context, d: WidgetData) {
            if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIF_ID, buildNotification(context, d))
        }

        private fun buildNotification(context: Context, d: WidgetData): Notification {
            val n = d.next ?: return NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_mosque)
                .setContentTitle("سكينة • الشاشة الدائمة")
                .setOngoing(true).setSilent(true).build()
            ensureChannel(context)
            val remainMin = ((n.ts - System.currentTimeMillis()) / 60_000L).coerceAtLeast(0)
            val h = remainMin / 60
            val m = remainMin % 60
            val remain = when {
                h > 0 && m > 0 -> "$h ساعة و$m دقيقة"
                h > 0 -> "$h ساعة"
                else -> "$m دقيقة"
            }
            val nowStr = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
            val timeStr = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(n.ts))

            val open = PendingIntent.getActivity(
                context, 0, Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val title = "الصلاة القادمة: ${n.nameAr} — $timeStr"
            val text = "متبقي $remain • الساعة الآن $nowStr"

            return NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_mosque)
                .setContentTitle(title)
                .setContentText(text)
                .setStyle(NotificationCompat.BigTextStyle().bigText("$title\n$text"))
                .setSubText(d.city.ifEmpty { null })
                .setProgress(100, d.progress, false)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setWhen(n.ts)
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
                .setSilent(true)
                .setCategory(NotificationCompat.CATEGORY_STATUS)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setColor(0xFF5FB59B.toInt())
                .setContentIntent(open)
                .build()
        }
    }
}
