package com.sakina.app.bridge

import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import com.sakina.app.aod.AlwaysOnConfig
import com.sakina.app.aod.AlwaysOnService
import com.sakina.app.aod.AodActivity
import android.app.Activity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * AodBridgePlugin — Flutter MethodChannel for controlling the Always-On Display (AOD).
 *
 * Channel: "com.sakina.app/aod"
 * Methods:
 *   - showAodScreen(prayerData: Map/JSON)
 *   - hideAodScreen()
 *   - isAodSupported() -> Boolean
 *   - updateAodData(prayerData: Map/JSON)
 *   - setAlwaysOn(config: Map) / alwaysOnStatus() -> Map
 */
class AodBridgePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    companion object {
        const val CHANNEL_NAME = "com.sakina.app/aod"
        private const val TAG = "AodBridgePlugin"
    }

    private lateinit var context: Context
    private var methodChannel: MethodChannel? = null
    private var activity: Activity? = null

    override fun onAttachedToActivity(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivity() { activity = null }

    private fun launch(intent: Intent) {
        val a = activity
        if (a != null) a.startActivity(intent)
        else context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME).apply {
            setMethodCallHandler(this@AodBridgePlugin)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "showAodScreen" -> {
                // Preview of the always-on screen (opened from the app, no permission needed).
                launch(Intent(context, AodActivity::class.java).apply {
                    putExtra(AodActivity.EXTRA_PREVIEW, true)
                })
                result.success(true)
            }

            "hideAodScreen" -> {
                context.sendBroadcast(Intent(AodActivity.ACTION_CLOSE_AOD).setPackage(context.packageName))
                result.success(true)
            }

            "isAodSupported" -> result.success(true)

            "updateAodData" -> result.success(true)

            "setAlwaysOn" -> {
                val m = call.arguments as? Map<*, *>
                if (m != null) AlwaysOnConfig.save(context, m)
                AlwaysOnService.syncWithConfig(context)
                result.success(true)
            }

            "alwaysOnStatus" -> {
                val canOverlay = Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                    android.provider.Settings.canDrawOverlays(context)
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                val fsi = if (Build.VERSION.SDK_INT >= 34) nm.canUseFullScreenIntent() else true
                val pm = context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
                val battery = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                    pm.isIgnoringBatteryOptimizations(context.packageName) else true
                result.success(mapOf(
                    "overlay" to canOverlay,
                    "fullScreenIntent" to fsi,
                    "battery" to battery,
                    "miui" to (Build.MANUFACTURER.equals("xiaomi", true) ||
                        Build.MANUFACTURER.equals("redmi", true) ||
                        Build.MANUFACTURER.equals("poco", true))
                ))
            }

            "openFullScreenIntentSettings" -> {
                var ok = false
                try {
                    if (Build.VERSION.SDK_INT >= 34) {
                        launch(Intent(android.provider.Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                            android.net.Uri.parse("package:${context.packageName}")))
                        ok = true
                    }
                } catch (_: Exception) {}
                result.success(ok)
            }

            "openBatterySettings" -> {
                var ok = false
                try {
                    launch(Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                        android.net.Uri.parse("package:${context.packageName}")))
                    ok = true
                } catch (_: Exception) {
                    try {
                        launch(Intent(android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                        ok = true
                    } catch (_: Exception) {}
                }
                result.success(ok)
            }

            "openMiuiPermissions" -> {
                var ok = false
                try {
                    launch(Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                        setClassName("com.miui.securitycenter",
                            "com.miui.permcenter.permissions.PermissionsEditorActivity")
                        putExtra("extra_pkgname", context.packageName)
                    })
                    ok = true
                } catch (_: Exception) {
                    try {
                        launch(Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            android.net.Uri.parse("package:${context.packageName}")))
                        ok = true
                    } catch (_: Exception) {}
                }
                result.success(ok)
            }

            "requestDrawOverApps" -> {
                try {
                    val intent = Intent(
                        android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        android.net.Uri.parse("package:${context.packageName}")
                    ).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            }

            else -> result.notImplemented()
        }
    }
}
