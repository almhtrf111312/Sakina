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
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import com.sakina.app.R

/**
 * Keeps a screen-state receiver alive. When the screen turns off the
 * AodActivity is shown over the lock screen (dim, black, AMOLED friendly).
 */
class AlwaysOnService : Service() {

    companion object {
        private const val TAG = "AlwaysOnService"
        private const val CHANNEL = "sakina_always_on_channel"
        private const val FSI_CHANNEL = "sakina_always_on_fsi"
        private const val NOTIF_ID = 7101
        private const val FSI_ID = 7102
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
    }

    private val handler = Handler(Looper.getMainLooper())
    private var suppressed = false

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    if (!suppressed && AlwaysOnConfig.load(context).enabled) {
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
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startForegroundCompat() {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL, "الشاشة الدائمة", NotificationManager.IMPORTANCE_MIN)
            )
        }
        val n: Notification = NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_mosque)
            .setContentTitle("الشاشة الدائمة مفعّلة")
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setOngoing(true)
            .setSilent(true)
            .build()
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIF_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIF_ID, n)
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
