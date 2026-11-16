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
                .setContentTitle("المؤذان • الشاشة الدائمة")
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
            // Refresh textual minutes silently; do not remove/recreate the notification.
            val n = d.next
            val palette = WidgetAppearance.load(context)
            val sig = "${n?.ts}|${System.currentTimeMillis() / 60_000L}|${palette.accent}|${palette.background}|${AppTimeFormat.is24Hour(context)}"
            val alive = try {
                nm.activeNotifications.any { it.id == NOTIF_ID }
            } catch (_: Exception) { false }
            if (alive && sig == lastSig) return
            lastSig = sig
            nm.notify(NOTIF_ID, buildNotification(context, d))
        }

        @Volatile private var lastSig: String? = null

        private fun notificationDate(context: Context, now: Long): String {
            val locale = java.util.Locale("ar")
            if (Build.VERSION.SDK_INT >= 24) {
                val raw = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    .getString("flutter.app_settings_v1", null)
                val offset = try { org.json.JSONObject(raw ?: "{}").optInt("hijriOffset", 0) }
                    catch (_: Exception) { 0 }
                val date = java.util.Calendar.getInstance().apply {
                    timeInMillis = now
                    add(java.util.Calendar.DAY_OF_YEAR, offset)
                }.time
                return android.icu.text.SimpleDateFormat("EEEE، d MMMM y", locale).apply {
                    calendar = android.icu.util.IslamicCalendar().apply {
                        setCalculationType(android.icu.util.IslamicCalendar.CalculationType.ISLAMIC_UMALQURA)
                    }
                }.format(date)
            }
            return java.text.SimpleDateFormat("EEEE، d MMMM yyyy", locale)
                .format(java.util.Date(now))
        }

        private fun buildNotification(context: Context, d: WidgetData): Notification {
            ensureChannel(context)
            val n = d.next ?: return NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_mosque)
                .setContentTitle("المؤذان • الشاشة الدائمة")
                .setOngoing(true).setSilent(true).build()
            val now = System.currentTimeMillis()
            val timeStr = AppTimeFormat.compact(context, n.ts)
            val minutes = ((n.ts - now + 59_999L) / 60_000L).coerceAtLeast(0L)
            val remaining = if (minutes >= 60) "${minutes / 60}س ${minutes % 60}د"
                else "${minutes}د"
            val previous = d.previous
            val previousText = previous?.let {
                "${it.nameAr} ${AppTimeFormat.compact(context, it.ts)}"
            } ?: ""
            val title = "${n.nameAr} $timeStr"
            val details = "${notificationDate(context, now)} • الآن ${AppTimeFormat.compact(context, now)}"
            val colors = WidgetAppearance.load(context)
            // Notification text follows the system panel's contrast, independent
            // of the in-app day/night palette. Never paint a white inner card.
            fun views(layout: Int) = RemoteViews(context.packageName, layout).apply {
                setTextViewText(R.id.prayer_notification_next, title)
                setTextViewText(R.id.prayer_notification_previous, previousText)
                val countdown = android.text.SpannableString(remaining)
                for (i in remaining.indices) {
                    if (remaining[i] == 'س' || remaining[i] == 'د') {
                        countdown.setSpan(android.text.style.RelativeSizeSpan(0.6f),
                            i, i + 1, android.text.Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                    }
                }
                setTextViewText(R.id.prayer_notification_remaining, countdown)
                setContentDescription(R.id.prayer_notification_remaining, "المتبقي $remaining")
                setTextViewText(R.id.prayer_notification_details, details)
                setImageViewBitmap(R.id.prayer_notification_progress,
                    WidgetArtwork.bar(900, d.progress, colors, fromRight = true))
            }

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
                .setContentTitle(title)
                .setContentText("المتبقي $remaining • $details")
                .setCustomContentView(views(R.layout.notification_next_prayer))
                .setCustomBigContentView(views(R.layout.notification_next_prayer_expanded))
                .setShowWhen(false)
                .setColor(colors.accent)
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
