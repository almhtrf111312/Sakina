package com.sakina.app.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Binder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.sakina.app.R
import com.sakina.app.alarm.AdhanReceiver
import com.sakina.app.aod.AodActivity
import org.json.JSONObject
import java.io.File

/**
 * AdhanForegroundService — plays adhan audio as a foreground service.
 *
 * Features:
 *  - Plays adhan from app assets (or file path override)
 *  - Fajr uses special adhan with "الصلاة خير من النوم"
 *  - Requests STREAM_ALARM audio focus
 *  - Optional gradual volume increase
 *  - Auto-stops after configurable timeout (default 3 minutes)
 *  - Stops on: user action / next adhan start / timeout
 *  - Proper notification channel with IMPORTANCE_HIGH
 *  - Wake lock to keep CPU alive during playback
 */
class AdhanForegroundService : Service() {

    companion object {
        private const val TAG = "AdhanForegroundService"

        const val CHANNEL_ID   = "sakina_adhan_service_channel"
        const val CHANNEL_NAME = "خدمة أذان سكينة"
        const val NOTIFICATION_ID = 1001

        const val EXTRA_PRAYER_NAME = "prayer_name"
        const val EXTRA_PRAYER_TIME = "prayer_time"
        const val EXTRA_PRAYER_JSON = "prayer_json"
        const val EXTRA_IS_FAJR     = "is_fajr"
        const val EXTRA_NOTIF_TYPE  = "notif_type"
        const val EXTRA_NOTIF_ID    = "notification_id"

        // Adhan asset filenames (placed in android/app/src/main/assets/audio/)
        private const val ADHAN_ASSET_DEFAULT = "flutter_assets/assets/audio/adhan_takbeer.mp3"
        private const val ADHAN_ASSET_FAJR    = "flutter_assets/assets/audio/adhan_fajr.mp3"   // includes sobhi

        private const val DEFAULT_TIMEOUT_MS  = 3 * 60 * 1000L  // 3 min
        private const val GRADUAL_VOLUME_STEP_MS = 500L
        private const val GRADUAL_VOLUME_STEPS   = 20
    }

    private var mediaPlayer: MediaPlayer? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())

    private var prayerName  = "صلاة"
    private var prayerTime  = ""
    private var isFajr      = false
    private var notifType   = "adhan"
    private var timeoutMs   = DEFAULT_TIMEOUT_MS
    private var gradualVol  = false
    private var notifId     = NOTIFICATION_ID

    private val stopReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            when (intent.action) {
                AdhanReceiver.ACTION_STOP_ADHAN -> stopPlayback()
                AdhanReceiver.ACTION_PRAYED     -> stopPlayback()
            }
        }
    }

    // ── Lifecycle ────────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        ensureNotificationChannel()
        acquireWakeLock()
        registerStopReceiver()
    }

    private var soundId: String = ""

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent ?: return START_NOT_STICKY

        prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: "صلاة"
        prayerTime = intent.getStringExtra(EXTRA_PRAYER_TIME) ?: ""
        isFajr     = intent.getBooleanExtra(EXTRA_IS_FAJR, false)
        notifType  = intent.getStringExtra(EXTRA_NOTIF_TYPE) ?: "adhan"
        notifId    = intent.getIntExtra(EXTRA_NOTIF_ID, NOTIFICATION_ID)

        // Parse optional config from prayer JSON
        val prayerJson = intent.getStringExtra(EXTRA_PRAYER_JSON)
        if (prayerJson != null) {
            try {
                val obj = JSONObject(prayerJson)
                timeoutMs  = obj.optLong("timeoutMs", DEFAULT_TIMEOUT_MS)
                gradualVol = obj.optBoolean("gradualVolume", false)
                soundId    = obj.optString("soundId", "")
            } catch (_: Exception) {}
        }

        startForeground(NOTIFICATION_ID, buildNotification())
        startPlayback()
        scheduleTimeout()

        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder = Binder()

    override fun onDestroy() {
        super.onDestroy()
        stopPlayback()
        try { unregisterReceiver(stopReceiver) } catch (_: Exception) {}
        wakeLock?.release()
    }

    // ── Playback ─────────────────────────────────────────────────────────────

    private fun assetExists(path: String): Boolean = try {
        assets.openFd(path).close()
        true
    } catch (e: Exception) {
        false
    }

    private fun startPlayback() {
        if (notifType == "silent" || notifType == "off") return
        if (notifType == "vibrate") {
            triggerVibration()
            return
        }

        requestAudioFocus()

        val base = "flutter_assets/assets/audio/"
        val candidates = if (notifType == "short" || notifType == "beep") {
            listOf(base + "beep_short.mp3")
        } else {
            listOf(
                if (soundId.isNotEmpty()) "$base$soundId.mp3" else ADHAN_ASSET_DEFAULT,
                ADHAN_ASSET_DEFAULT
            )
        }
        val assetName = candidates.firstOrNull { assetExists(it) } ?: ADHAN_ASSET_DEFAULT

        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                // Try loading from assets
                val afd = assets.openFd(assetName)
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()

                isLooping = false
                if (gradualVol) {
                    setVolume(0f, 0f)
                }
                prepare()
                start()
            }

            if (gradualVol) {
                scheduleGradualVolumeIncrease()
            }

            mediaPlayer?.setOnCompletionListener {
                Log.d(TAG, "Adhan playback completed")
                stopSelf()
            }

            Log.i(TAG, "Adhan playback started ($assetName)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start MediaPlayer", e)
            // Fall back to system alarm sound
            playSystemAlarm()
        }
    }

    private fun playSystemAlarm() {
        try {
            val alarmUri = android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(applicationContext, alarmUri)
                isLooping = false
                prepare()
                start()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to play system alarm", e)
        }
    }

    private fun stopPlayback() {
        handler.removeCallbacksAndMessages(null)
        try {
            mediaPlayer?.let {
                if (it.isPlaying) it.stop()
                it.release()
            }
            mediaPlayer = null
        } catch (_: Exception) {}

        abandonAudioFocus()
        stopForeground(true)
        stopSelf()
    }

    private fun scheduleGradualVolumeIncrease() {
        var step = 0
        val stepVol = 1f / GRADUAL_VOLUME_STEPS
        val r = object : Runnable {
            override fun run() {
                if (step >= GRADUAL_VOLUME_STEPS || mediaPlayer == null) return
                val vol = stepVol * step
                mediaPlayer?.setVolume(vol, vol)
                step++
                handler.postDelayed(this, GRADUAL_VOLUME_STEP_MS)
            }
        }
        handler.post(r)
    }

    private fun scheduleTimeout() {
        handler.postDelayed({
            Log.i(TAG, "Adhan timeout reached – stopping")
            stopPlayback()
        }, timeoutMs)
    }

    // ── Audio focus ──────────────────────────────────────────────────────────

    private fun requestAudioFocus() {
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .setAcceptsDelayedFocusGain(false)
                .setOnAudioFocusChangeListener { }
                .build()
            am.requestAudioFocus(audioFocusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            am.requestAudioFocus(null, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
        }
    }

    private fun abandonAudioFocus() {
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            am.abandonAudioFocus(null)
        }
    }

    // ── Notification ─────────────────────────────────────────────────────────

    private fun buildNotification(): Notification {
        val arabicName = prayerArabicName(prayerName)
        val subtitle   = if (prayerTime.isNotEmpty()) "وقت $arabicName – $prayerTime" else "حان وقت $arabicName"

        // Open AOD on tap
        val tapIntent = Intent(this, AodActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val tapPi = PendingIntent.getActivity(
            this, 0, tapIntent, PendingIntent.FLAG_IMMUTABLE
        )

        val stopPi = makeBroadcastPi(AdhanReceiver.ACTION_STOP_ADHAN,  1)
        val prayedPi = makeBroadcastPi(AdhanReceiver.ACTION_PRAYED,    2)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_mosque)
            .setContentTitle(arabicName)
            .setContentText(subtitle)
            .setContentIntent(tapPi)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setColor(0xFF5FB59B.toInt())
            .addAction(0, "⏹ إيقاف", stopPi)
            .addAction(0, "✔ صليت", prayedPi)
            .build()
    }

    private fun makeBroadcastPi(action: String, reqCode: Int): PendingIntent {
        val i = Intent(this, AdhanReceiver::class.java).apply { this.action = action }
        return PendingIntent.getBroadcast(
            this, reqCode, i,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "خدمة تشغيل صوت الأذان"
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            enableVibration(false) // MediaPlayer handles audio
        }
        nm.createNotificationChannel(channel)
    }

    // ── Wake lock ─────────────────────────────────────────────────────────────

    private fun acquireWakeLock() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "sakina:AdhanWakeLock"
        ).apply { acquire(timeoutMs + 30_000L) }
    }

    // ── Misc helpers ─────────────────────────────────────────────────────────

    private fun registerStopReceiver() {
        val filter = IntentFilter().apply {
            addAction(AdhanReceiver.ACTION_STOP_ADHAN)
            addAction(AdhanReceiver.ACTION_PRAYED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(stopReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(stopReceiver, filter)
        }
    }

    private fun triggerVibration() {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as android.os.VibratorManager
            vm.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as android.os.Vibrator
        }
        val pattern = longArrayOf(0, 500, 300, 500, 300, 500)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(android.os.VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, -1)
        }
    }

    private fun prayerArabicName(name: String): String = when (name.lowercase()) {
        "fajr"    -> "الفجر"
        "dhuhr"   -> "الظهر"
        "asr"     -> "العصر"
        "maghrib" -> "المغرب"
        "isha"    -> "العشاء"
        else      -> name
    }
}
