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
        const val CHANNEL = "sakina_next_prayer"
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
            ensureChannel(context)
            val n = d.next ?: return NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_mosque)
                .setContentTitle("سكينة • الشاشة الدائمة")
                .setOngoing(true).setSilent(true).build()
            val remainMin = ((n.ts - System.currentTimeMillis()) / 60_000L).coerceAtLeast(0)
            val h = remainMin / 60
            val m = remainMin % 60
            val remain = when {
                h > 0 && m > 0 -> "$h ساعة و$m دقيقة"
                h > 0 -> "$h ساعة"
                else -> "$m دقيقة"
            }
            val timeStr = AppTimeFormat.format(context, n.ts)

            val open = PendingIntent.getActivity(
                context, 0, Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val title = "الصلاة القادمة: ${n.nameAr} — $timeStr"
            val text = "المتبقي: $remain"
            val colors = WidgetAppearance.load(context)
            val isSystemDark = (context.resources.configuration.uiMode and
                android.content.res.Configuration.UI_MODE_NIGHT_MASK) ==
                android.content.res.Configuration.UI_MODE_NIGHT_YES
            val foreground = if (isSystemDark) 0xFFFFFFFF.toInt() else 0xFF17211D.toInt()
            val highlight = if (!isSystemDark && colors.accent == 0xFFE8EFEC.toInt())
                0xFF3B4A46.toInt() else colors.accent

            fun content(layout: Int): RemoteViews = RemoteViews(context.packageName, layout).apply {
                setTextViewText(R.id.notification_prayer, n.nameAr)
                setTextViewText(R.id.notification_time, timeStr)
                setTextViewText(R.id.notification_remaining, text)
                setTextColor(R.id.notification_prayer, highlight)
                setTextColor(R.id.notification_time, foreground)
                setTextColor(R.id.notification_remaining, foreground)
                setImageViewBitmap(R.id.notification_bar, WidgetArtwork.bar(
                    (context.resources.displayMetrics.widthPixels * 0.75).toInt(), d.progress, colors))
            }
            val dismissed = PendingIntent.getBroadcast(context, REQ_RESTORE,
                Intent(context, SakinaTick::class.java).setAction(ACTION_DISMISSED),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

            return NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_mosque)
                .setContentTitle(title)
                .setContentText(text)
                .setCustomContentView(content(R.layout.notification_next_prayer_compact))
                .setCustomBigContentView(content(R.layout.notification_next_prayer_expanded))
                .setStyle(NotificationCompat.DecoratedCustomViewStyle())
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setShowWhen(false)
                .setSilent(true)
                .setCategory(NotificationCompat.CATEGORY_STATUS)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setColor(highlight)
                .setDeleteIntent(dismissed)
                .setContentIntent(open)
                .build()
        }
    }
}
