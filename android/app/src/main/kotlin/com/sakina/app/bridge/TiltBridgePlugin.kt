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
    private var uprightHeading: Double? = null
    private val rotation = FloatArray(9)
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
            manager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)?.let {
                manager?.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        manager?.unregisterListener(this)
        sink = null
        uprightHeading = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type == Sensor.TYPE_ROTATION_VECTOR) {
            SensorManager.getRotationMatrixFromVector(rotation, event.values)
            // Horizontal bearing of the rear camera when held upright.
            uprightHeading = (Math.toDegrees(atan2(-rotation[2].toDouble(),
                -rotation[5].toDouble())) + 360) % 360
            return
        }
        val x = event.values[0].toDouble()
        val y = event.values[1].toDouble()
        val z = event.values[2].toDouble()
        val degreesFromVertical = Math.toDegrees(atan2(abs(z), sqrt(x * x + y * y)))
        sink?.success(mapOf("tilt" to degreesFromVertical, "uprightHeading" to uprightHeading))
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
}
