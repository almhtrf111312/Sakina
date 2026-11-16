package com.sakina.app

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.app.Activity
import android.provider.OpenableColumns
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.sakina.app.bridge.AlarmBridgePlugin
import com.sakina.app.bridge.AodBridgePlugin
import com.sakina.app.bridge.TiltBridgePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

/**
 * MainActivity — primary entry point for Sakina Flutter application.
 *
 * Responsibilities:
 *  - Registers custom plugins: AlarmBridgePlugin and AodBridgePlugin
 *  - Handles notification permissions on Android 13+ (POST_NOTIFICATIONS)
 *  - Forwards intent extras from notifications and widgets to Flutter
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val PERMISSION_REQUEST_CODE_NOTIFICATIONS = 101
        private const val REQUEST_CUSTOM_SOUND = 102
    }
    private var azkarReminderSink: EventChannel.EventSink? = null
    private var pendingSoundResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestNotificationPermissionIfNeeded()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.sakina.app/azkar_reminders").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                azkarReminderSink = events
                deliverAzkarReminder(intent)
            }

            override fun onCancel(arguments: Any?) {
                azkarReminderSink = null
            }
        })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.sakina.app/device_time").setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> {
                    val autoTime = android.provider.Settings.Global.getInt(contentResolver,
                        android.provider.Settings.Global.AUTO_TIME, 0) == 1
                    val autoZone = android.provider.Settings.Global.getInt(contentResolver,
                        android.provider.Settings.Global.AUTO_TIME_ZONE, 0) == 1
                    val clockMismatch = if (Build.VERSION.SDK_INT >= 33) {
                        try {
                            kotlin.math.abs(android.os.SystemClock.currentNetworkTimeClock().millis() -
                                System.currentTimeMillis()) > 120_000L
                        } catch (_: java.time.DateTimeException) {
                            false
                        }
                    } else false
                    result.success(mapOf("autoTime" to autoTime, "autoZone" to autoZone,
                        "clockMismatch" to clockMismatch))
                }
                "openSettings" -> try {
                    startActivity(Intent(android.provider.Settings.ACTION_DATE_SETTINGS))
                    result.success(null)
                } catch (e: android.content.ActivityNotFoundException) {
                    result.error("NO_DATE_SETTINGS", e.message, null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.sakina.app/app_info").setMethodCallHandler { call, result ->
            if (call.method != "installedVersion") {
                result.notImplemented()
            } else {
                @Suppress("DEPRECATION")
                val info = packageManager.getPackageInfo(packageName, 0)
                result.success(info.versionName)
            }
        }

        // Register native bridge plugins with Flutter engine
        flutterEngine.plugins.add(AlarmBridgePlugin())
        flutterEngine.plugins.add(AodBridgePlugin())
        flutterEngine.plugins.add(TiltBridgePlugin())
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.sakina.app/custom_sound").setMethodCallHandler { call, result ->
            if (call.method != "pickCustomSound") {
                result.notImplemented()
            } else if (pendingSoundResult != null) {
                result.error("PICKER_BUSY", "Sound picker is already open", null)
            } else {
                try {
                    pendingSoundResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "audio/*"
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                    }
                    startActivityForResult(intent, REQUEST_CUSTOM_SOUND)
                } catch (e: Exception) {
                    pendingSoundResult = null
                    result.error("PICKER_FAILED", e.message, null)
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.sakina.app/external_link").setMethodCallHandler { call, result ->
            val url = when (call.method) {
                "openTanzilSource" -> "https://tanzil.net/download/"
                "openDeveloperChannel" -> "https://t.me/flowpospro"
                else -> null
            }
            if (url != null) {
                try {
                    startActivity(Intent(Intent.ACTION_VIEW,
                        Uri.parse(url)))
                    result.success(null)
                } catch (e: Exception) {
                    result.error("NO_BROWSER", "Unable to open source link", null)
                }
            } else result.notImplemented()
        }
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val permission = Manifest.permission.POST_NOTIFICATIONS
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(permission),
                    PERMISSION_REQUEST_CODE_NOTIFICATIONS
                )
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        // Handled or delegated to Flutter permission_handler plugin
    }

    override fun dispatchKeyEvent(event: android.view.KeyEvent): Boolean {
        if (event.action == android.view.KeyEvent.ACTION_DOWN &&
            (event.keyCode == android.view.KeyEvent.KEYCODE_VOLUME_UP ||
                event.keyCode == android.view.KeyEvent.KEYCODE_VOLUME_DOWN) &&
            com.sakina.app.service.AdhanForegroundService.stopIfAlerting(this)) return true
        return super.dispatchKeyEvent(event)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        deliverAzkarReminder(intent)
    }

    private fun deliverAzkarReminder(intent: Intent?) {
        val sink = azkarReminderSink ?: return
        val category = intent?.getStringExtra("open_azkar") ?: return
        intent.removeExtra("open_azkar")
        if (category == "morning" || category == "evening") sink.success(category)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        azkarReminderSink = null
        EventChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.sakina.app/azkar_reminders").setStreamHandler(null)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_CUSTOM_SOUND) return
        val pending = pendingSoundResult ?: return
        pendingSoundResult = null
        val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
        if (uri == null) {
            pending.success(null)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION)
            var name = uri.lastPathSegment ?: "نغمة شخصية"
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME),
                null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) name = cursor.getString(0) ?: name
            }
            pending.success(mapOf("uri" to uri.toString(), "name" to name))
        } catch (e: Exception) {
            pending.error("SOUND_ACCESS", e.message, null)
        }
    }
}
