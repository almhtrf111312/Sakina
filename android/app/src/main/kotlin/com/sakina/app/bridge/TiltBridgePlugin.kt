package com.sakina.app.bridge

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.sqrt

/** Streams the angle from upright portrait; the gravity sensor avoids integration drift. */
class TiltBridgePlugin : FlutterPlugin, EventChannel.StreamHandler, SensorEventListener {
    private var channel: EventChannel? = null
    private var manager: SensorManager? = null
    private var sink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        manager = binding.applicationContext.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        channel = EventChannel(binding.binaryMessenger, "com.sakina.app/device_tilt").apply {
            setStreamHandler(this@TiltBridgePlugin)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        onCancel(null)
        channel?.setStreamHandler(null)
        channel = null
        manager = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        val gravity = manager?.getDefaultSensor(Sensor.TYPE_GRAVITY)
            ?: manager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        if (gravity == null) {
            events?.error("NO_TILT_SENSOR", "No gravity or accelerometer sensor", null)
        } else {
            manager?.registerListener(this, gravity, SensorManager.SENSOR_DELAY_UI)
        }
    }

    override fun onCancel(arguments: Any?) {
        manager?.unregisterListener(this)
        sink = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        val x = event.values[0].toDouble()
        val y = event.values[1].toDouble()
        val z = event.values[2].toDouble()
        val degreesFromVertical = Math.toDegrees(atan2(abs(z), sqrt(x * x + y * y)))
        sink?.success(degreesFromVertical)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
}
