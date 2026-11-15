package com.sakina.app.aod

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.View
import java.util.Calendar
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

/** Dim, drifted together with the rest of the AOD to reduce static pixels. */
class AnalogClockView(context: Context, private val color: Int, private val classic: Boolean) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { strokeCap = Paint.Cap.ROUND }
    private val density = resources.displayMetrics.density

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val desired = (216 * density).toInt()
        val size = min(desired, MeasureSpec.getSize(widthMeasureSpec))
        setMeasuredDimension(size, size)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val cx = width / 2f
        val cy = height / 2f
        val r = min(cx, cy) - 8 * density
        paint.color = color
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = (if (classic) 2f else 1.3f) * density
        canvas.drawCircle(cx, cy, r, paint)
        for (i in 0 until 60) {
            if (!classic && i % 5 != 0) continue
            val angle = i * Math.PI / 30 - Math.PI / 2
            val inner = r * (if (i % 5 == 0) 0.89f else 0.95f)
            paint.strokeWidth = (if (i % 5 == 0) 2f else 1f) * density
            canvas.drawLine(cx + (cos(angle) * inner).toFloat(), cy + (sin(angle) * inner).toFloat(),
                cx + (cos(angle) * r).toFloat(), cy + (sin(angle) * r).toFloat(), paint)
        }
        if (classic) {
            paint.style = Paint.Style.FILL
            paint.textAlign = Paint.Align.CENTER
            paint.textSize = 18 * density
            for (n in listOf(12, 3, 6, 9)) {
                val a = n * Math.PI / 6 - Math.PI / 2
                canvas.drawText(n.toString(), cx + (cos(a) * r * 0.72).toFloat(),
                    cy + (sin(a) * r * 0.72).toFloat() + 6 * density, paint)
            }
        }
        val now = Calendar.getInstance()
        hand(canvas, cx, cy, r * 0.51f,
            ((now.get(Calendar.HOUR) + now.get(Calendar.MINUTE) / 60f).toDouble() * Math.PI / 6 - Math.PI / 2), 4f)
        hand(canvas, cx, cy, r * 0.76f,
            ((now.get(Calendar.MINUTE) + now.get(Calendar.SECOND) / 60f).toDouble() * Math.PI / 30 - Math.PI / 2), 2.5f)
        paint.style = Paint.Style.FILL
        canvas.drawCircle(cx, cy, 4 * density, paint)
    }

    private fun hand(canvas: Canvas, cx: Float, cy: Float, length: Float, angle: Double, width: Float) {
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = width * density
        canvas.drawLine(cx, cy, cx + (cos(angle) * length).toFloat(),
            cy + (sin(angle) * length).toFloat(), paint)
    }
}
