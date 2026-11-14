package com.sakina.app.aod

import android.app.Activity
import android.content.*
import android.graphics.*
import android.os.*
import android.provider.Settings
import android.view.*
import androidx.core.content.ContextCompat
import com.sakina.app.widget.WidgetData
import java.text.SimpleDateFormat
import java.util.*

/** Same renderer for preview and actual lock display; never dismisses the keyguard. */
class LockDisplayActivity : Activity() {
    companion object {
        const val PREVIEW = "preview"
        var visible = false
            private set
    }
    private val handler = Handler(Looper.getMainLooper())
    private var preview = false
    private lateinit var display: PrayerDisplay
    private val closeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) { finish() }
    }
    private val tick = object : Runnable {
        override fun run() {
            if (!preview && (!LockDisplayService.enabled(this@LockDisplayActivity) ||
                        !Settings.canDrawOverlays(this@LockDisplayActivity) ||
                        !LockDisplayService.powerAllowed(this@LockDisplayActivity))) {
                finish()
                return
            }
            display.invalidate()
            handler.postDelayed(this, 60_000 - System.currentTimeMillis() % 60_000)
        }
    }
    @Suppress("DEPRECATION")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        preview = intent.getBooleanExtra(PREVIEW, false)
        if (!preview && (!LockDisplayService.enabled(this) || !Settings.canDrawOverlays(this))) {
            finish()
            return
        }
        if (!preview) {
            if (Build.VERSION.SDK_INT >= 27) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            } else window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            window.attributes = window.attributes.apply {
                screenBrightness = LockDisplayService.prefs(this@LockDisplayActivity).getFloat("brightness", 0.1f).coerceIn(0.02f, 0.3f)
            }
        }
        window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        display = PrayerDisplay()
        setContentView(display)
        ContextCompat.registerReceiver(this, closeReceiver, IntentFilter(LockDisplayService.CLOSE), ContextCompat.RECEIVER_NOT_EXPORTED)
        registered = true
        handler.post(tick)
    }
    private var registered = false
    override fun onResume() { super.onResume(); visible = !preview }
    override fun onPause() {
        if (!preview) {
            LockDisplayService.suppressUntil = SystemClock.elapsedRealtime() + 1500
        }
        visible = false
        // Do not leave an always-awake window behind another app or the normal keyguard.
        if (!preview) finish()
        super.onPause()
    }
    override fun onDestroy() {
        visible = false
        handler.removeCallbacksAndMessages(null)
        if (registered) unregisterReceiver(closeReceiver)
        super.onDestroy()
    }
    private inner class PrayerDisplay : View(this@LockDisplayActivity) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.CENTER }
        private val gestures = GestureDetector(context, object : GestureDetector.SimpleOnGestureListener() {
            override fun onDown(e: MotionEvent) = true
            override fun onDoubleTap(e: MotionEvent): Boolean { finish(); return true }
        })
        init {
            setBackgroundColor(Color.BLACK)
            contentDescription = "شاشة سكينة الدائمة؛ اضغط مرتين للعودة"
            setOnClickListener { if (preview) finish() }
        }
        override fun onTouchEvent(event: MotionEvent): Boolean {
            gestures.onTouchEvent(event)
            if (event.action == MotionEvent.ACTION_UP) performClick()
            return true
        }
        override fun performClick(): Boolean { super.performClick(); return true }
        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val prefs = LockDisplayService.prefs(context)
            val shared = context.getSharedPreferences(SakinaWallpaperService.PREFS_NAME, Context.MODE_PRIVATE)
            val locale = if (shared.getBoolean(SakinaWallpaperService.KEY_USE_ARABIC_NUMERALS, false)) Locale.forLanguageTag("ar") else Locale.US
            val accent = prefs.getInt("color", 0xFF5FB59B.toInt())
            val now = System.currentTimeMillis()
            val data = WidgetData.load(context)
            val next = data?.next
            val scale = (width / 360f).coerceAtMost(height / 640f)
            val shift = ((now / 60_000 % 9) - 4).toFloat() * scale
            canvas.save()
            canvas.translate(width / 2f + shift, height / 2f - shift)
            fun line(text: String, y: Float, size: Float, alpha: Int = 255) {
                paint.color = accent; paint.alpha = alpha; paint.textSize = size * scale
                canvas.drawText(text, 0f, y * scale, paint)
            }
            line(SimpleDateFormat("HH:mm", locale).format(Date(now)), -130f, 58f)
            if (prefs.getBoolean("showHijri", true)) {
                val date = android.icu.util.IslamicCalendar().apply {
                    timeInMillis = now
                    add(android.icu.util.Calendar.DATE, shared.getInt(SakinaWallpaperService.KEY_HIJRI_OFFSET, 0))
                }
                val format = android.icu.text.SimpleDateFormat("d MMMM y", Locale.forLanguageTag("ar"))
                format.calendar = date
                line(format.format(date.time) + " هـ", -90f, 16f, 150)
            }
            if (next != null) {
                line(next.nameAr, -10f, 36f)
                line(SimpleDateFormat("HH:mm", locale).format(Date(next.ts)), 32f, 27f)
                val minutes = ((next.ts - now + 59_999) / 60_000).coerceAtLeast(0)
                line(String.format(locale, "متبقي %d:%02d", minutes / 60, minutes % 60), 70f, 20f, 170)
                if (prefs.getBoolean("showPrayers", true)) {
                    data?.todayFive()?.forEachIndexed { i, prayer ->
                        canvas.save()
                        canvas.translate((i - 2) * 64f * scale, 0f)
                        line(prayer.nameAr, 155f, 13f, if (prayer.key == next.key) 255 else 100)
                        line(SimpleDateFormat("HH:mm", locale).format(Date(prayer.ts)), 178f, 12f, 130)
                        canvas.restore()
                    }
                }
            } else line("افتح سكينة لتحديث مواقيت الصلاة", 0f, 17f, 170)
            if (preview) line("معاينة • اضغط للعودة", 240f, 13f, 140)
            canvas.restore()
        }
    }
}
