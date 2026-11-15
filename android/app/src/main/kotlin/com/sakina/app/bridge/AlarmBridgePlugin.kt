package com.sakina.app.bridge

import android.app.AlarmManager
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.SoundPool
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import com.sakina.app.R
import androidx.annotation.NonNull
import androidx.core.app.NotificationManagerCompat
import com.sakina.app.alarm.AdhanReceiver
import com.sakina.app.alarm.AlarmScheduler
import com.sakina.app.alarm.BootReceiver
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * AlarmBridgePlugin — Flutter MethodChannel & EventChannel plugin for prayer alarms.
 *
 * MethodChannel: "com.sakina.app/alarm"
 *   - schedulePrayerAlarms(prayerTimes: String JSON or List<Map>)
 *   - cancelAllAlarms()
 *   - checkPermissions() -> Map<String, Boolean>
 *   - requestExactAlarmPermission()
 *   - requestBatteryOptimizations()
 *
 * EventChannel: "com.sakina.app/alarm_events"
 *   - Emits events back to Flutter when:
 *       - Reschedule requested (boot/time change)
 *       - Adhan stopped / delayed / prayed
 */
class AlarmBridgePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL_NAME = "com.sakina.app/alarm"
        const val EVENT_CHANNEL_NAME  = "com.sakina.app/alarm_events"
        private const val TAG = "AlarmBridgePlugin"
    }

    private lateinit var context: Context
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private val alarmEventReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val action = intent.action ?: return
            val eventMap = HashMap<String, Any>()
            eventMap["action"] = action

            when (action) {
                BootReceiver.ACTION_RESCHEDULE_NEEDED -> {
                    eventMap["type"] = "reschedule_needed"
                    eventMap["trigger"] = intent.getStringExtra("trigger") ?: "unknown"
                }
                AdhanReceiver.ACTION_STOP_ADHAN -> {
                    eventMap["type"] = "adhan_stopped"
                    eventMap["prayer_json"] = intent.getStringExtra(AdhanReceiver.EXTRA_PRAYER_JSON) ?: ""
                }
                AdhanReceiver.ACTION_DELAY_ADHAN -> {
                    eventMap["type"] = "adhan_delayed"
                    eventMap["prayer_json"] = intent.getStringExtra(AdhanReceiver.EXTRA_PRAYER_JSON) ?: ""
                }
                AdhanReceiver.ACTION_PRAYED -> {
                    eventMap["type"] = "prayer_completed"
                    eventMap["prayer_json"] = intent.getStringExtra(AdhanReceiver.EXTRA_PRAYER_JSON) ?: ""
                }
            }
            eventSink?.success(eventMap)
        }
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME).apply {
            setMethodCallHandler(this@AlarmBridgePlugin)
        }
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME).apply {
            setStreamHandler(this@AlarmBridgePlugin)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
    }

    // ── MethodCallHandler ───────────────────────────────────────────────────

    // ── Tap feedback (sound + vibration), independent of system touch settings ──
    private val tapExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()
    private var tapPool: SoundPool? = null
    private var tapSoundId = 0
    private var tapLoaded = false

    private fun tapFeedback(sound: Boolean, haptic: Boolean) {
        try {
            if (haptic) {
                val vib = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                if (vib != null && vib.hasVibrator()) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        vib.vibrate(VibrationEffect.createOneShot(10, 70))
                    } else {
                        @Suppress("DEPRECATION")
                        vib.vibrate(10)
                    }
                }
            }
            if (sound) {
                var pool = tapPool
                if (pool == null) {
                    pool = SoundPool.Builder()
                        .setMaxStreams(2)
                        .setAudioAttributes(
                            AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                .build()
                        )
                        .build()
                    pool.setOnLoadCompleteListener { sp, id, status ->
                        if (status == 0) {
                            tapLoaded = true
                            sp.play(id, 0.15f, 0.15f, 1, 0, 1f)
                        }
                    }
                    tapSoundId = pool.load(context, R.raw.tap_click, 1)
                    tapPool = pool
                } else if (tapLoaded) {
                    pool.play(tapSoundId, 0.15f, 0.15f, 1, 0, 1f)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "tapFeedback failed: ${e.message}")
        }
    }

    // ── Adhan preview (used by the sound picker) ──
    private var previewPlayer: MediaPlayer? = null

    private fun stopPreview() {
        try {
            previewPlayer?.stop()
        } catch (_: Exception) {}
        try {
            previewPlayer?.release()
        } catch (_: Exception) {}
        previewPlayer = null
    }

    private fun playPreview(soundId: String, volume: Float): Boolean {
        stopPreview()
        val path = "flutter_assets/assets/audio/$soundId.mp3"
        return try {
            val afd = context.assets.openFd(path)
            val mp = MediaPlayer()
            mp.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            mp.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            afd.close()
            mp.setVolume(volume, volume)
            mp.setOnCompletionListener { stopPreview() }
            mp.prepare()
            mp.start()
            previewPlayer = mp
            true
        } catch (e: Exception) {
            Log.w(TAG, "preview failed for $soundId: ${e.message}")
            false
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "testAdhan" -> {
                val id = call.argument<String>("soundId") ?: "adhan_5"
                val vol = (call.argument<Double>("volume") ?: 1.0).toFloat()
                result.success(playPreview(id, vol))
            }
            "stopTestAdhan" -> {
                stopPreview()
                result.success(true)
            }
            "updateWidgetData" -> {
                val json = call.argument<String>("json")
                if (json != null) {
                    com.sakina.app.widget.WidgetData.save(context, json)
                    com.sakina.app.widget.SakinaTick.refresh(context)
                }
                result.success(true)
            }
            "cancelAlarm" -> {
                // Alarms are rescheduled as a whole; cancel everything off the main thread.
                Thread { AlarmScheduler.cancelAllAlarms(context) }.start()
                result.success(true)
            }
            "tapFeedback" -> {
                val sound = call.argument<Boolean>("sound") ?: true
                val haptic = call.argument<Boolean>("haptic") ?: true
                // Never touch SoundPool / audio HAL on the main thread: creating it
                // on some devices (MIUI) blocks and made every tap freeze the app.
                try {
                    tapExecutor.execute { tapFeedback(sound, haptic) }
                } catch (_: Exception) {}
                result.success(true)
            }
            "schedulePrayerAlarms" -> {
                val prayerTimesArg = call.argument<Any>("prayerTimes")
                val prayerTimesJson = when (prayerTimesArg) {
                    is String -> prayerTimesArg
                    is List<*> -> org.json.JSONArray(prayerTimesArg).toString()
                    else -> null
                }

                if (prayerTimesJson == null) {
                    result.error("INVALID_ARGUMENT", "prayerTimes must be a JSON string or List", null)
                    return
                }

                // Run off the main thread so the UI never blocks on AlarmManager work.
                val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
                Thread {
                    val success = try {
                        AlarmScheduler.schedulePrayerAlarms(context, prayerTimesJson)
                    } catch (e: Exception) {
                        false
                    }
                    mainHandler.post { result.success(success) }
                }.start()
            }

            "cancelAllAlarms" -> {
                AlarmScheduler.cancelAllAlarms(context)
                result.success(true)
            }

            "checkPermissions" -> {
                val perms = checkAllPermissions()
                result.success(perms)
            }

            "requestExactAlarmPermission" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    try {
                        context.startActivity(AlarmScheduler.getExactAlarmSettingsIntent(context))
                    } catch (e: Exception) {
                        // Some ROMs (e.g. MIUI) lack this screen: open the app's own settings page.
                        context.startActivity(
                            Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = android.net.Uri.parse("package:${context.packageName}")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                        )
                    }
                    result.success(true)
                } else {
                    result.success(true)
                }
            }

            "requestBatteryOptimizationExemption" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                    if (!pm.isIgnoringBatteryOptimizations(context.packageName)) {
                        val intent = Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                            data = android.net.Uri.parse("package:${context.packageName}")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(true)
                    }
                } else {
                    result.success(true)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun checkAllPermissions(): Map<String, Boolean> {
        val permissions = HashMap<String, Boolean>()

        // Exact Alarm
        permissions["exactAlarm"] = AlarmScheduler.canScheduleExactAlarms(context)

        // Notifications
        permissions["notifications"] = NotificationManagerCompat.from(context).areNotificationsEnabled()

        // Battery Optimizations
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            permissions["batteryOptimizationIgnored"] = pm.isIgnoringBatteryOptimizations(context.packageName)
        } else {
            permissions["batteryOptimizationIgnored"] = true
        }

        // Full screen intent (Android 14+ / API 34+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            permissions["fullScreenIntent"] = nm.canUseFullScreenIntent()
        } else {
            permissions["fullScreenIntent"] = true
        }

        return permissions
    }

    // ── EventChannel.StreamHandler ──────────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val filter = IntentFilter().apply {
            addAction(BootReceiver.ACTION_RESCHEDULE_NEEDED)
            addAction(AdhanReceiver.ACTION_STOP_ADHAN)
            addAction(AdhanReceiver.ACTION_DELAY_ADHAN)
            addAction(AdhanReceiver.ACTION_PRAYED)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(alarmEventReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(alarmEventReceiver, filter)
        }
    }

    override fun onCancel(arguments: Any?) {
        try {
            context.unregisterReceiver(alarmEventReceiver)
        } catch (_: Exception) {}
        eventSink = null
    }
}
