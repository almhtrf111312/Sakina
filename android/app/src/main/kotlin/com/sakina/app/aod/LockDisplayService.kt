package com.sakina.app.aod

import android.app.*
import android.content.*
import android.content.pm.ServiceInfo
import android.os.*
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.sakina.app.MainActivity
import com.sakina.app.R

/** User-enabled, software AOD. Does not install a wallpaper or alter system AOD. */
class LockDisplayService : Service() {
    companion object {
        const val PREFS = "sakina_lock_display"
        const val CLOSE = "com.sakina.app.CLOSE_LOCK_DISPLAY"
        private const val STOP = "com.sakina.app.STOP_LOCK_DISPLAY"
        private const val CHANNEL = "sakina_lock_display"
        var suppressUntil = 0L
        var running = false
            private set
        fun prefs(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        fun enabled(c: Context) = prefs(c).getBoolean("enabled", false)
        fun start(c: Context) {
            ContextCompat.startForegroundService(c, Intent(c, LockDisplayService::class.java))
        }
        fun close(c: Context) = c.sendBroadcast(Intent(CLOSE).setPackage(c.packageName))
        fun disable(c: Context) {
            prefs(c).edit().putBoolean("enabled", false).apply()
            close(c)
            c.stopService(Intent(c, LockDisplayService::class.java))
        }
        fun powerAllowed(c: Context): Boolean {
            val power = c.getSystemService(POWER_SERVICE) as PowerManager
            val battery = c.getSystemService(BATTERY_SERVICE) as BatteryManager
            val level = battery.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            return !power.isPowerSaveMode && (level !in 0..10 || battery.isCharging)
        }
    }
    private val handler = Handler(Looper.getMainLooper())
    private val launchDisplay = Runnable {
        val power = getSystemService(POWER_SERVICE) as PowerManager
        if (enabled(this) && Settings.canDrawOverlays(this) && !power.isInteractive && powerAllowed(this)) {
            try {
                startActivity(Intent(this, LockDisplayActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP))
            } catch (_: RuntimeException) {
                // OEM restrictions may still block background activities. Keep normal keyguard intact.
            }
        }
    }
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    handler.removeCallbacks(launchDisplay)
                    if (LockDisplayActivity.visible || SystemClock.elapsedRealtime() < suppressUntil) close(context)
                    else handler.postDelayed(launchDisplay, 600)
                }
                Intent.ACTION_SCREEN_ON -> handler.removeCallbacks(launchDisplay)
                Intent.ACTION_USER_PRESENT -> {
                    handler.removeCallbacks(launchDisplay)
                    close(context)
                }
            }
        }
    }
    override fun onCreate() {
        super.onCreate()
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(CHANNEL, "الشاشة الدائمة", NotificationManager.IMPORTANCE_LOW))
        }
        val open = PendingIntent.getActivity(this, 701, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val stop = PendingIntent.getService(this, 702, Intent(this, LockDisplayService::class.java).setAction(STOP), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val notification = NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_mosque).setContentTitle("شاشة سكينة الدائمة مفعّلة")
            .setContentText("تظهر بعد إطفاء الشاشة • اضغط مرتين للعودة إلى القفل")
            .setOngoing(true).setSilent(true).setContentIntent(open)
            .addAction(0, "إيقاف", stop).build()
        if (Build.VERSION.SDK_INT >= 34) startForeground(701, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        else startForeground(701, notification)
        ContextCompat.registerReceiver(this, screenReceiver, IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }, ContextCompat.RECEIVER_NOT_EXPORTED)
        running = true
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == STOP || !enabled(this) || !Settings.canDrawOverlays(this)) {
            disable(this)
            return START_NOT_STICKY
        }
        return START_STICKY
    }
    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        unregisterReceiver(screenReceiver)
        running = false
        close(this)
        super.onDestroy()
    }
    override fun onBind(intent: Intent?) = null
}
