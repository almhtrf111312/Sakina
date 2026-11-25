package com.sakina.app.aod

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Typeface
import android.media.AudioManager
import android.view.View

/** Compact status icons drawn in density-independent coordinates. */
internal class AodStatusView(context: Context, private val ink: Int, private val hidden: Set<String>) : View(context) {
    data class Status(
        val percent: String,
        val charging: Boolean,
        val ringer: Int,
        val cellLevel: Int?,
        val wifiEnabled: Boolean,
        val wifiConnected: Boolean,
        val wifiLevel: Int?,
        val description: String,
    )

    private val density = resources.displayMetrics.density
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        strokeWidth = 1.45f
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
        textAlign = Paint.Align.CENTER
        typeface = Typeface.DEFAULT_BOLD
        textSize = 10f
    }
    private val path = Path()
    private var status: Status? = null

    init {
        importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_YES
    }

    fun bind(value: Status) {
        if (status == value) return
        status = value
        contentDescription = value.description
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val current = status ?: return
        val batteryWidth = if (current.charging) 48f else 36f
        val groupWidth = (if ("ringer" in hidden) 0f else 25f) +
            (if ("cell" in hidden) 0f else 22f) +
            (if ("wifi" in hidden) 0f else 23f) +
            (if ("battery" in hidden) 0f else batteryWidth)
        canvas.save()
        canvas.translate(width - (groupWidth + 16) * density, 15 * density)
        canvas.scale(density, density)
        if ("ringer" !in hidden) {
            drawRinger(canvas, current.ringer)
            canvas.translate(25f, 0f)
        }
        if ("cell" !in hidden) {
            drawCell(canvas, current.cellLevel)
            canvas.translate(22f, 0f)
        }
        if ("wifi" !in hidden) {
            drawWifi(canvas, current)
            canvas.translate(23f, 0f)
        }
        if ("battery" !in hidden) drawBattery(canvas, current)
        canvas.restore()
    }

    private fun style(fill: Boolean, alpha: Float = 1f) {
        paint.color = ink
        paint.alpha = (paint.alpha * alpha).toInt()
        paint.style = if (fill) Paint.Style.FILL else Paint.Style.STROKE
    }

    private fun drawRinger(canvas: Canvas, ringer: Int) {
        style(fill = false)
        if (ringer == AudioManager.RINGER_MODE_VIBRATE) {
            canvas.drawRoundRect(6f, 3f, 14f, 17f, 1.5f, 1.5f, paint)
            canvas.drawLine(3f, 6f, 3f, 14f, paint)
            canvas.drawLine(17f, 6f, 17f, 14f, paint)
            canvas.drawLine(0.5f, 8f, 0.5f, 12f, paint)
            canvas.drawLine(19.5f, 8f, 19.5f, 12f, paint)
            return
        }
        path.reset()
        path.moveTo(3f, 14f)
        path.quadTo(5.5f, 11.5f, 5.5f, 8f)
        path.cubicTo(5.5f, 2f, 14.5f, 2f, 14.5f, 8f)
        path.quadTo(14.5f, 11.5f, 17f, 14f)
        path.close()
        canvas.drawPath(path, paint)
        canvas.drawArc(8f, 14f, 12f, 17f, 15f, 150f, false, paint)
        if (ringer == AudioManager.RINGER_MODE_SILENT) {
            canvas.drawLine(2f, 2f, 18f, 18f, paint)
        }
    }

    private fun drawCell(canvas: Canvas, level: Int?) {
        for (bar in 0 until 4) {
            style(fill = true, alpha = if (bar < (level ?: 0)) 1f else 0.30f)
            val x = 1f + bar * 4.25f
            canvas.drawRoundRect(x, 17f - (4 + bar * 3.25f), x + 3f, 17f, 0.5f, 0.5f, paint)
        }
        if (level == null) {
            style(fill = false)
            canvas.drawLine(13f, 12f, 18f, 17f, paint)
            canvas.drawLine(18f, 12f, 13f, 17f, paint)
        }
    }

    private fun drawWifi(canvas: Canvas, current: Status) {
        val level = if (current.wifiConnected) current.wifiLevel ?: 1 else 0
        for (ring in 1..3) {
            style(fill = false, alpha = if (ring < level) 1f else 0.30f)
            val radius = 4f + ring * 2.6f
            canvas.drawArc(10f - radius, 16f - radius, 10f + radius, 16f + radius,
                226f, 88f, false, paint)
        }
        style(fill = true, alpha = if (level > 0) 1f else 0.30f)
        canvas.drawCircle(10f, 16f, 1.45f, paint)
        if (!current.wifiEnabled) {
            style(fill = false)
            canvas.drawLine(3f, 3f, 17f, 17f, paint)
        }
    }

    private fun drawBattery(canvas: Canvas, current: Status) {
        style(fill = false)
        canvas.drawRoundRect(1f, 3f, 31f, 17f, 3f, 3f, paint)
        style(fill = true)
        canvas.drawRoundRect(33f, 7f, 35f, 13f, 1f, 1f, paint)
        canvas.drawText(current.percent, 16f, 10f - (paint.ascent() + paint.descent()) / 2, paint)
        if (!current.charging) return
        paint.color = 0xFF57DD80.toInt()
        path.reset()
        path.moveTo(44f, 2f)
        path.lineTo(38f, 11f)
        path.lineTo(42f, 11f)
        path.lineTo(41f, 18f)
        path.lineTo(47f, 8f)
        path.lineTo(43f, 8f)
        path.close()
        canvas.drawPath(path, paint)
    }
}
