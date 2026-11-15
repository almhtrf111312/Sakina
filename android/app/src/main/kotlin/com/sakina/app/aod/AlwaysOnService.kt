package com.sakina.app.aod

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import com.sakina.app.R
import com.sakina.app.widget.WidgetData
import com.sakina.app.widget.SakinaTick
import java.util.Calendar

/**
 * Keeps a screen-state receiver alive. When the screen turns off the
 * AodActivity is shown over the lock screen (dim, black, AMOLED friendly).
 */
class AlwaysOnService : Service() {

    companion object {
        private const val TAG = "AlwaysOnService"
        private const val FSI_CHANNEL = "sakina_always_on_fsi"
        private const val FSI_ID = 7102
        @Volatile var running = false
            private set
        const val ACTION_SUPPRESS = "com.sakina.app.ACTION_AOD_SUPPRESS"

        fun start(ctx: Context) {
            val i = Intent(ctx, AlwaysOnService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) ctx.startForegroundService(i)
                else ctx.startService(i)
            } catch (e: Exception) {
                Log.w(TAG, "start failed: ${e.message}")
            }
        }

        fun stop(ctx: Context) {
            ctx.stopService(Intent(ctx, AlwaysOnService::class.java))
        }

        fun syncWithConfig(ctx: Context) {
            if (AlwaysOnConfig.load(ctx).enabled) start(ctx) else stop(ctx)
        }

        /** Applies the "when to show" rule chosen in the app. */
        fun shouldShowNow(ctx: Context, cfg: AlwaysOnConfig): Boolean = when (cfg.showWhen) {
            "adhan" -> isAroundAdhan(ctx, cfg)
            "charging" -> isCharging(ctx)
            "schedule" -> isInSchedule(cfg)
            else -> true
        }

        private fun isAroundAdhan(ctx: Context, cfg: AlwaysOnConfig): Boolean {
            val items = WidgetData.load(ctx)?.items ?: return false
            val now = System.currentTimeMillis()
            val before = cfg.beforeAdhanMin * 60_000L
            val after = cfg.afterAdhanMin * 60_000L
            return items.any { now >= it.ts - before && now <= it.ts + after }
        }

        private fun isCharging(ctx: Context): Boolean {
            val i = ctx.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            return (i?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) ?: 0) != 0
        }

        private fun isInSchedule(cfg: AlwaysOnConfig): Boolean {
            val c = Calendar.getInstance()
            val now = c.get(Calendar.HOUR_OF_DAY) * 60 + c.get(Calendar.MINUTE)
            val from = cfg.scheduleFromMin
            val to = cfg.scheduleToMin
            return when {
                from == to -> true
                from < to -> now in from until to
                else -> now >= from || now < to   // crosses midnight
            }
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var suppressed = false

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    val cfg = AlwaysOnConfig.load(context)
                    if (!suppressed && cfg.enabled && shouldShowNow(context, cfg)) {
                        handler.postDelayed({ showAod() }, 350)
                    }
                }
                Intent.ACTION_USER_PRESENT -> {
                    suppressed = false
                    sendBroadcast(Intent(AodActivity.ACTION_CLOSE_AOD).setPackage(packageName))
                }
                ACTION_SUPPRESS -> suppressed = true
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        startForegroundCompat()
        running = true
        // Clear the notification left by older versions of this service.
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).apply { cancel(7101); cancel(FSI_ID) }
        val f = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
            addAction(ACTION_SUPPRESS)
        }
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(receiver, f, Context.RECEIVER_EXPORTED)
        else registerReceiver(receiver, f)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    override fun onDestroy() {
        try { unregisterReceiver(receiver) } catch (_: Exception) {}
        handler.removeCallbacksAndMessages(null)
        running = false
        super.onDestroy()
        SakinaTick.refresh(this)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startForegroundCompat() {
        val n = SakinaTick.foregroundNotification(this)
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(SakinaTick.NOTIF_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(SakinaTick.NOTIF_ID, n)
        }
    }

    private fun showAod() {
        val intent = Intent(this, AodActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_NO_ANIMATION)
            putExtra(AodActivity.EXTRA_ALWAYS_ON, true)
        }
        val canOverlay = Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)
        if (canOverlay || Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            try {
                startActivity(intent)
                return
            } catch (e: Exception) {
                Log.w(TAG, "startActivity failed: ${e.message}")
            }
        }
        // Fallback: full-screen-intent notification (works on the lock screen).
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(FSI_CHANNEL, "عرض الشاشة الدائمة", NotificationManager.IMPORTANCE_HIGH)
                    .apply { setSound(null, null); enableVibration(false) }
            )
        }
        val pi = PendingIntent.getActivity(
            this, 1, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val n = NotificationCompat.Builder(this, FSI_CHANNEL)
            .setSmallIcon(R.drawable.ic_mosque)
            .setContentTitle("سكينة")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pi, true)
            .setTimeoutAfter(4000)
            .setSilent(true)
            .build()
        nm.notify(FSI_ID, n)
    }
}
