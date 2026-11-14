package com.sakina.app.bridge

import android.app.AlarmManager
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.PowerManager
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

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
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
                val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
                Thread {
                    try {
                        AlarmScheduler.cancelAllAlarms(context)
                        mainHandler.post { result.success(true) }
                    } catch (e: Exception) {
                        mainHandler.post { result.success(false) }
                    }
                }.start()
            }

            "checkPermissions" -> {
                val perms = checkAllPermissions()
                result.success(perms)
            }

            "requestExactAlarmPermission" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val intent = AlarmScheduler.getExactAlarmSettingsIntent(context)
                    context.startActivity(intent)
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
