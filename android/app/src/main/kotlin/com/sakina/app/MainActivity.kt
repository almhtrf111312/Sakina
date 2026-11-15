package com.sakina.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.sakina.app.bridge.AlarmBridgePlugin
import com.sakina.app.bridge.AodBridgePlugin
import com.sakina.app.bridge.TiltBridgePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

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
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestNotificationPermissionIfNeeded()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register native bridge plugins with Flutter engine
        flutterEngine.plugins.add(AlarmBridgePlugin())
        flutterEngine.plugins.add(AodBridgePlugin())
        flutterEngine.plugins.add(TiltBridgePlugin())
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

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
