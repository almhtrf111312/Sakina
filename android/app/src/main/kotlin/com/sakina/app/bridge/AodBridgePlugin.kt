package com.sakina.app.bridge

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import androidx.annotation.NonNull
import com.sakina.app.aod.AodActivity
import com.sakina.app.aod.SakinaWallpaperService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject

/**
 * AodBridgePlugin — Flutter MethodChannel for controlling the Always-On Display (AOD)
 * and Live Lock Screen Wallpaper.
 *
 * Channel: "com.sakina.app/aod"
 * Methods:
 *   - showAodScreen(prayerData: Map/JSON)
 *   - hideAodScreen()
 *   - isAodSupported() -> Boolean
 *   - updateAodData(prayerData: Map/JSON)
 *   - setAsLockscreenWallpaper() -> Boolean
 *   - updateWallpaperSettings(settings: Map) -> Boolean
 *   - isWallpaperSupported() -> Boolean
 */
class AodBridgePlugin : FlutterPlugin, MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.sakina.app/aod"
        private const val TAG = "AodBridgePlugin"
    }

    private lateinit var context: Context
    private var methodChannel: MethodChannel? = null

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
                val prayerDataArg = call.argument<Any>("prayerData")
                val prayerDataJson = when (prayerDataArg) {
                    is String -> prayerDataArg
                    is Map<*, *> -> JSONObject(prayerDataArg).toString()
                    else -> null
                }

                val intent = Intent(context, AodActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP
                    if (prayerDataJson != null) {
                        putExtra(AodActivity.EXTRA_PRAYER_DATA, prayerDataJson)
                        try {
                            val obj = JSONObject(prayerDataJson)
                            putExtra(AodActivity.EXTRA_PRAYER_NAME, obj.optString("prayerName", "Fajr"))
                            putExtra(AodActivity.EXTRA_PRAYER_TIME, obj.optString("prayerTime", ""))
                        } catch (_: Exception) {}
                    }
                }
                context.startActivity(intent)
                result.success(true)
            }

            "hideAodScreen" -> {
                val closeIntent = Intent(AodActivity.ACTION_CLOSE_AOD).apply {
                    setPackage(context.packageName)
                }
                context.sendBroadcast(closeIntent)
                result.success(true)
            }

            "isAodSupported" -> {
                result.success(true)
            }

            "updateAodData" -> {
                val prayerDataArg = call.argument<Any>("prayerData")
                val prayerDataJson = when (prayerDataArg) {
                    is String -> prayerDataArg
                    is Map<*, *> -> JSONObject(prayerDataArg).toString()
                    else -> null
                }

                val updateIntent = Intent(context, AodActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    if (prayerDataJson != null) {
                        putExtra(AodActivity.EXTRA_PRAYER_DATA, prayerDataJson)
                    }
                }
                context.startActivity(updateIntent)
                result.success(true)
            }

            "setAsLockscreenWallpaper" -> {
                try {
                    val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
                        putExtra(
                            WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                            ComponentName(context, SakinaWallpaperService::class.java)
                        )
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    try {
                        val chooserIntent = Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(chooserIntent)
                        result.success(true)
                    } catch (e2: Exception) {
                        result.error("WALLPAPER_ERROR", e2.message, null)
                    }
                }
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

            "updateWallpaperSettings" -> {
                try {
                    val prefs = context.getSharedPreferences(
                        SakinaWallpaperService.PREFS_NAME,
                        Context.MODE_PRIVATE
                    )
                    val editor = prefs.edit()

                    call.argument<Int>("clockStyle")?.let {
                        editor.putInt(SakinaWallpaperService.KEY_CLOCK_STYLE, it)
                    }
                    call.argument<Int>("accentColor")?.let {
                        editor.putInt(SakinaWallpaperService.KEY_ACCENT_COLOR, it)
                    }
                    call.argument<Boolean>("showHijri")?.let {
                        editor.putBoolean(SakinaWallpaperService.KEY_SHOW_HIJRI, it)
                    }
                    call.argument<Boolean>("showGregorian")?.let {
                        editor.putBoolean(SakinaWallpaperService.KEY_SHOW_GREGORIAN, it)
                    }
                    call.argument<Boolean>("showCountdown")?.let {
                        editor.putBoolean(SakinaWallpaperService.KEY_SHOW_COUNTDOWN, it)
                    }
                    call.argument<Boolean>("showPrayersRow")?.let {
                        editor.putBoolean(SakinaWallpaperService.KEY_SHOW_PRAYERS_ROW, it)
                    }
                    call.argument<Int>("hijriOffset")?.let {
                        editor.putInt(SakinaWallpaperService.KEY_HIJRI_OFFSET, it)
                    }
                    call.argument<Boolean>("useArabicNumerals")?.let {
                        editor.putBoolean(SakinaWallpaperService.KEY_USE_ARABIC_NUMERALS, it)
                    }

                    val prayerDataArg = call.argument<Any>("prayerData")
                    if (prayerDataArg != null) {
                        val prayerJsonStr = when (prayerDataArg) {
                            is String -> prayerDataArg
                            is Map<*, *> -> JSONObject(prayerDataArg).toString()
                            else -> null
                        }
                        if (prayerJsonStr != null) {
                            editor.putString(SakinaWallpaperService.KEY_PRAYER_DATA, prayerJsonStr)
                        }
                    }

                    editor.apply()

                    val updateIntent = Intent(SakinaWallpaperService.ACTION_UPDATE_WALLPAPER).apply {
                        setPackage(context.packageName)
                    }
                    context.sendBroadcast(updateIntent)

                    result.success(true)
                } catch (e: Exception) {
                    result.error("SETTINGS_ERROR", e.message, null)
                }
            }

            "isWallpaperSupported" -> {
                val wm = WallpaperManager.getInstance(context)
                val supported = wm.isWallpaperSupported
                result.success(supported)
            }

            else -> result.notImplemented()
        }
    }
}
