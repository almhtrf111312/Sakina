package com.sakina.app.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import org.json.JSONObject

/** Shared palette for home widgets and the persistent prayer notification. */
data class WidgetAppearance(val accent: Int, val foreground: Int, val muted: Int, val background: Int) {
    companion object {
        fun load(context: Context): WidgetAppearance {
            val raw = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .getString("flutter.app_settings_v1", null)
            val settings = try { JSONObject(raw ?: "{}") } catch (_: Exception) { JSONObject() }
            val day = settings.optString("themeMode") == "day"
            val accent = when (settings.optString("accentColor")) {
                "gold" -> if (day) 0xFFA9843F.toInt() else 0xFFD9B46A.toInt()
                "white" -> if (day) 0xFF3B4A46.toInt() else 0xFFE8EFEC.toInt()
                "blue" -> if (day) 0xFF3F78B5.toInt() else 0xFF6FA8DC.toInt()
                "teal" -> if (day) 0xFF1F8A84.toInt() else 0xFF4DD0C8.toInt()
                "purple" -> if (day) 0xFF6A4FB0.toInt() else 0xFFB39DDB.toInt()
                "rose" -> if (day) 0xFFC2477A.toInt() else 0xFFF28DB2.toInt()
                "orange" -> if (day) 0xFFC9702A.toInt() else 0xFFF0A15A.toInt()
                "red" -> if (day) 0xFFB83A3A.toInt() else 0xFFE57373.toInt()
                "lime" -> if (day) 0xFF6E9A1F.toInt() else 0xFFB5D96B.toInt()
                else -> if (day) 0xFF2F7F69.toInt() else 0xFF5FB59B.toInt()
            }
            val alpha = (settings.optDouble("widgetOpacity", 0.88).coerceIn(0.0, 1.0) * 255).toInt()
            return WidgetAppearance(accent,
                if (day) 0xFF14201C.toInt() else Color.WHITE,
                if (day) 0xFF475C54.toInt() else 0xFFB0C3BD.toInt(),
                Color.argb(alpha, if (day) 248 else 19, if (day) 250 else 24, if (day) 248 else 23))
        }
    }
}

object WidgetArtwork {
    fun background(width: Int, height: Int, colors: WidgetAppearance): Bitmap {
        val w = width.coerceIn(200, 750)
        val h = height.coerceIn(80, 240)
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = colors.background }
        canvas.drawRoundRect(0f, 0f, w.toFloat(), h.toFloat(), h * 0.22f, h * 0.22f, paint)
        return bitmap
    }
    fun ring(size: Int, progress: Int, colors: WidgetAppearance): Bitmap {
        val s = size.coerceIn(120, 420)
        val bitmap = Bitmap.createBitmap(s, s, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
        paint.color = colors.background
        canvas.drawCircle(s / 2f, s / 2f, s * 0.47f, paint)
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = s * 0.065f
        paint.strokeCap = Paint.Cap.ROUND
        val bounds = RectF(s * 0.065f, s * 0.065f, s * 0.935f, s * 0.935f)
        paint.color = Color.argb(90, Color.red(colors.muted), Color.green(colors.muted), Color.blue(colors.muted))
        canvas.drawArc(bounds, -90f, 360f, false, paint)
        paint.color = colors.accent
        canvas.drawArc(bounds, -90f, 360f * progress.coerceIn(0, 100) / 100f, false, paint)
        return bitmap
    }

    fun bar(width: Int, progress: Int, colors: WidgetAppearance, fromRight: Boolean = false): Bitmap {
        val w = width.coerceIn(200, 900)
        val h = 12
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val p = Paint(Paint.ANTI_ALIAS_FLAG)
        p.color = Color.argb(95, Color.red(colors.muted), Color.green(colors.muted), Color.blue(colors.muted))
        canvas.drawRoundRect(0f, 2f, w.toFloat(), 10f, 5f, 5f, p)
        p.color = colors.accent
        val filled = w * progress.coerceIn(0, 100) / 100f
        canvas.drawRoundRect(if (fromRight) w - filled else 0f, 2f,
            if (fromRight) w.toFloat() else filled, 10f, 5f, 5f, p)
        return bitmap
    }
}
