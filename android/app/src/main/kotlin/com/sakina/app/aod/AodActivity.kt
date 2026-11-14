package com.sakina.app.aod

import android.animation.ObjectAnimator
import android.annotation.SuppressLint
import android.app.Activity
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.RelativeLayout
import android.widget.TextView
import com.sakina.app.R
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

/**
 * AodActivity — Full-screen Always-On Display shown over the lock screen during adhan.
 *
 * Features:
 *  - Shows on lock screen without unlock (setShowWhenLocked / FLAG_SHOW_WHEN_LOCKED)
 *  - Turns screen on (setTurnScreenOn / FLAG_TURN_SCREEN_ON)
 *  - Black AMOLED background #000000
 *  - Displays: current time, Hijri date, next prayer name + countdown
 *  - Row of 5 prayer icons at bottom (current lit, others dim)
 *  - Pixel shift every 60 seconds for burn-in protection
 *  - Screen brightness forced to 0.1
 *  - Double-tap to dismiss, swipe-up to open app (requires unlock)
 *  - Auto-closes after configurable timeout
 *  - Countdown updates every minute; every second in final minute
 */
class AodActivity : Activity() {

    companion object {
        private const val TAG = "AodActivity"

        const val EXTRA_PRAYER_NAME   = "prayer_name"
        const val EXTRA_PRAYER_TIME   = "prayer_time"
        const val EXTRA_PRAYER_JSON   = "prayer_json"
        const val EXTRA_PRAYER_DATA   = "prayer_data"
        const val EXTRA_TIMEOUT_MS    = "timeout_ms"
        const val ACTION_CLOSE_AOD    = "com.sakina.app.ACTION_CLOSE_AOD"

        private val PRAYER_NAMES_AR = listOf("الفجر", "الظهر", "العصر", "المغرب", "العشاء")
        private val PRAYER_NAMES_EN = listOf("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")

        private const val DEFAULT_TIMEOUT_MS = 5 * 60 * 1000L   // 5 minutes
        private const val PIXEL_SHIFT_INTERVAL_MS = 60_000L
        private const val MAX_PIXEL_SHIFT_DP = 8

        const val COLOR_GREEN  = 0xFF5FB59B.toInt()
        const val COLOR_GOLD   = 0xFFC9A86A.toInt()
        const val COLOR_WHITE  = 0xFFE8EFEC.toInt()
        const val COLOR_BLUE   = 0xFF4A90D9.toInt()
    }

    // ── Views ────────────────────────────────────────────────────────────────

    private lateinit var rootLayout: RelativeLayout
    private lateinit var contentContainer: LinearLayout
    private lateinit var tvTime: TextView
    private lateinit var tvHijriDate: TextView
    private lateinit var tvPrayerName: TextView
    private lateinit var tvPrayerTimeLabel: TextView
    private lateinit var tvCountdown: TextView
    private lateinit var prayerIconsRow: LinearLayout

    // ── State ────────────────────────────────────────────────────────────────

    private val handler = Handler(Looper.getMainLooper())
    private var timeoutMs  = DEFAULT_TIMEOUT_MS
    private var accentColor = COLOR_GREEN

    private var currentPrayerName  = "الفجر"
    private var currentPrayerIndex = 0
    private var nextPrayerTimestamp = 0L   // epoch ms of NEXT prayer (for countdown)
    private var currentPrayerTimestamp = 0L

    private var pixelShiftX = 0f
    private var pixelShiftY = 0f

    private lateinit var gestureDetector: GestureDetector

    // Receivers
    private val minuteReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_TIME_TICK -> {
                    updateTimeDisplay()
                    updateCountdown()
                }
                ACTION_CLOSE_AOD -> {
                    finish()
                }
            }
        }
    }

    // ── Lifecycle ────────────────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupWindowFlags()
        setScreenBrightness(0.1f)
        parseIntent(intent)
        buildLayout()
        setupGestureDetector()
        registerMinuteReceiver()
        startAutoClose()
        startPixelShiftTimer()
        updateTimeDisplay()
        updateCountdown()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        parseIntent(intent)
        updatePrayerDisplay()
        updateCountdown()
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacksAndMessages(null)
        try { unregisterReceiver(minuteReceiver) } catch (_: Exception) {}
    }

    override fun onBackPressed() {
        // Swallow – user must double-tap or use swipe-up to dismiss
    }

    // ── Window setup ─────────────────────────────────────────────────────────

    @Suppress("DEPRECATION")
    private fun setupWindowFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val km = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
            km.requestDismissKeyguard(this, object : KeyguardManager.KeyguardDismissCallback() {
                override fun onDismissError()     { /* still showing */ }
                override fun onDismissSucceeded() { /* user unlocked — could open app */ }
                override fun onDismissCancelled() { /* still on lock screen */ }
            })
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }

        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Full screen
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_FULLSCREEN or
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        )
    }

    // ── Layout (built in code – no XML required) ─────────────────────────────

    @SuppressLint("SetTextI18n")
    private fun buildLayout() {
        // Root: black
        rootLayout = RelativeLayout(this).apply {
            setBackgroundColor(Color.BLACK)
        }
        setContentView(rootLayout)

        val density = resources.displayMetrics.density

        // Content container (vertical, centered)
        contentContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity     = android.view.Gravity.CENTER_HORIZONTAL
        }
        val centerParams = RelativeLayout.LayoutParams(
            RelativeLayout.LayoutParams.MATCH_PARENT,
            RelativeLayout.LayoutParams.WRAP_CONTENT
        ).apply { addRule(RelativeLayout.CENTER_IN_PARENT) }
        rootLayout.addView(contentContainer, centerParams)

        // Current time (large)
        tvTime = TextView(this).apply {
            textSize = 72f
            setTextColor(accentColor)
            gravity = android.view.Gravity.CENTER
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }
        contentContainer.addView(tvTime, lp(16.dp(density)))

        // Hijri date (small, dimmer)
        tvHijriDate = TextView(this).apply {
            textSize = 16f
            setTextColor(dimColor(accentColor))
            gravity = android.view.Gravity.CENTER
        }
        contentContainer.addView(tvHijriDate, lp(8.dp(density)))

        // Spacer
        contentContainer.addView(spacer(32.dp(density)))

        // Prayer name
        tvPrayerName = TextView(this).apply {
            textSize = 36f
            setTextColor(accentColor)
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 4.dp(density).toInt())
        }
        contentContainer.addView(tvPrayerName, lp(4.dp(density)))

        // Prayer time label
        tvPrayerTimeLabel = TextView(this).apply {
            textSize = 20f
            setTextColor(dimColor(accentColor))
            gravity = android.view.Gravity.CENTER
        }
        contentContainer.addView(tvPrayerTimeLabel, lp(4.dp(density)))

        // Countdown
        tvCountdown = TextView(this).apply {
            textSize = 18f
            setTextColor(dimColor(accentColor, 0.5f))
            gravity = android.view.Gravity.CENTER
        }
        contentContainer.addView(tvCountdown, lp(8.dp(density)))

        // Prayer icons row (bottom)
        prayerIconsRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = android.view.Gravity.CENTER
        }
        val bottomParams = RelativeLayout.LayoutParams(
            RelativeLayout.LayoutParams.MATCH_PARENT,
            RelativeLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
            setMargins(0, 0, 0, 48.dp(density).toInt())
        }
        rootLayout.addView(prayerIconsRow, bottomParams)
        buildPrayerIconsRow()

        updatePrayerDisplay()
    }

    private fun buildPrayerIconsRow() {
        prayerIconsRow.removeAllViews()
        val density = resources.displayMetrics.density
        val iconSize = 32.dp(density).toInt()
        val iconMargin = 16.dp(density).toInt()

        PRAYER_NAMES_AR.forEachIndexed { index, name ->
            val tv = TextView(this).apply {
                text = name
                textSize = 12f
                gravity = android.view.Gravity.CENTER
                setTextColor(
                    if (index == currentPrayerIndex) accentColor
                    else dimColor(accentColor, 0.3f)
                )
            }
            val p = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(iconMargin, 0, iconMargin, 0) }
            prayerIconsRow.addView(tv, p)
        }
    }

    // ── Data ─────────────────────────────────────────────────────────────────

    private fun parseIntent(intent: Intent?) {
        intent ?: return
        currentPrayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: "الفجر"
        currentPrayerIndex = PRAYER_NAMES_EN.indexOfFirst {
            it.equals(currentPrayerName, ignoreCase = true)
        }.coerceAtLeast(0)
        timeoutMs = intent.getLongExtra(EXTRA_TIMEOUT_MS, DEFAULT_TIMEOUT_MS)

        val prayerJson = intent.getStringExtra(EXTRA_PRAYER_JSON)
        if (prayerJson != null) {
            try {
                val obj = JSONObject(prayerJson)
                currentPrayerTimestamp = obj.optLong("timestamp", 0L)
                nextPrayerTimestamp    = obj.optLong("nextTimestamp", 0L)
                accentColor            = when (obj.optString("color", "green")) {
                    "gold"  -> COLOR_GOLD
                    "white" -> COLOR_WHITE
                    "blue"  -> COLOR_BLUE
                    else    -> COLOR_GREEN
                }
            } catch (_: Exception) {}
        }

        val prayerData = intent.getStringExtra(EXTRA_PRAYER_DATA)
        if (prayerData != null) {
            try {
                val obj = JSONObject(prayerData)
                // prayerData may carry a "prayers" array for full context
                nextPrayerTimestamp = obj.optLong("nextPrayerTimestamp", nextPrayerTimestamp)
                accentColor         = when (obj.optString("color", "green")) {
                    "gold"  -> COLOR_GOLD
                    "white" -> COLOR_WHITE
                    "blue"  -> COLOR_BLUE
                    else    -> COLOR_GREEN
                }
            } catch (_: Exception) {}
        }
    }

    // ── Display updates ──────────────────────────────────────────────────────

    private fun updateTimeDisplay() {
        val now = Calendar.getInstance()
        val h   = now.get(Calendar.HOUR_OF_DAY)
        val m   = now.get(Calendar.MINUTE)
        tvTime.text = String.format(Locale.getDefault(), "%02d:%02d", h, m)
        tvTime.setTextColor(accentColor)

        tvHijriDate.text = getHijriDateString()
        tvHijriDate.setTextColor(dimColor(accentColor))
    }

    private fun updatePrayerDisplay() {
        tvPrayerName.text = prayerArabicName(currentPrayerName)
        tvPrayerName.setTextColor(accentColor)

        if (currentPrayerTimestamp > 0L) {
            val sdf = SimpleDateFormat("HH:mm", Locale.getDefault())
            tvPrayerTimeLabel.text = sdf.format(Date(currentPrayerTimestamp))
        } else {
            tvPrayerTimeLabel.text = ""
        }

        buildPrayerIconsRow()
    }

    private fun updateCountdown() {
        val nowMs = System.currentTimeMillis()
        // Count down to next prayer (after current)
        val target = if (nextPrayerTimestamp > nowMs) nextPrayerTimestamp else {
            tvCountdown.text = ""
            return
        }
        val diffMs  = target - nowMs
        val diffSec = diffMs / 1000L
        val hrs     = diffSec / 3600L
        val mins    = (diffSec % 3600L) / 60L
        val secs    = diffSec % 60L

        tvCountdown.text = if (hrs > 0)
            String.format(Locale.getDefault(), "الصلاة القادمة بعد %d:%02d:%02d", hrs, mins, secs)
        else
            String.format(Locale.getDefault(), "الصلاة القادمة بعد %02d:%02d", mins, secs)

        // In the final minute, reschedule every second
        if (diffMs < 60_000L) {
            handler.postDelayed({ updateCountdown() }, 1000L)
        }
    }

    // ── Pixel shift (burn-in protection) ────────────────────────────────────

    private val pixelShiftRunnable = object : Runnable {
        override fun run() {
            val density = resources.displayMetrics.density
            val maxShift = MAX_PIXEL_SHIFT_DP * density
            pixelShiftX = (Math.random() * maxShift * 2 - maxShift).toFloat()
            pixelShiftY = (Math.random() * maxShift * 2 - maxShift).toFloat()

            ObjectAnimator.ofFloat(contentContainer, "translationX", pixelShiftX).apply {
                duration = 1000; start()
            }
            ObjectAnimator.ofFloat(contentContainer, "translationY", pixelShiftY).apply {
                duration = 1000; start()
            }

            handler.postDelayed(this, PIXEL_SHIFT_INTERVAL_MS)
        }
    }

    private fun startPixelShiftTimer() = handler.postDelayed(pixelShiftRunnable, PIXEL_SHIFT_INTERVAL_MS)

    // ── Auto-close ───────────────────────────────────────────────────────────

    private fun startAutoClose() {
        handler.postDelayed({ finish() }, timeoutMs)
    }

    // ── Gesture handling ─────────────────────────────────────────────────────

    private fun setupGestureDetector() {
        gestureDetector = GestureDetector(this, object : GestureDetector.SimpleOnGestureListener() {
            private var tapCount = 0
            private val tapHandler = Handler(Looper.getMainLooper())

            override fun onDoubleTap(e: MotionEvent): Boolean {
                finish()   // double-tap to dismiss
                return true
            }

            override fun onFling(
                e1: MotionEvent?, e2: MotionEvent,
                velocityX: Float, velocityY: Float
            ): Boolean {
                // Swipe up — open the app (behind keyguard)
                if ((e1?.y ?: 0f) - e2.y > 200 && Math.abs(velocityY) > 500) {
                    openApp()
                    return true
                }
                return false
            }
        })
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent?): Boolean {
        event?.let { gestureDetector.onTouchEvent(it) }
        return super.onTouchEvent(event)
    }

    private fun openApp() {
        val km = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            km.requestDismissKeyguard(this, null)
        }
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        launchIntent?.let { startActivity(it) }
        finish()
    }

    // ── Screen brightness ────────────────────────────────────────────────────

    private fun setScreenBrightness(brightness: Float) {
        val lp = window.attributes
        lp.screenBrightness = brightness.coerceIn(0.01f, 1.0f)
        window.attributes = lp
    }

    // ── Minute receiver ──────────────────────────────────────────────────────

    private fun registerMinuteReceiver() {
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_TIME_TICK)
            addAction(ACTION_CLOSE_AOD)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(minuteReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(minuteReceiver, filter)
        }
    }

    // ── Hijri date ───────────────────────────────────────────────────────────

    private fun getHijriDateString(): String {
        // Simple Hijri conversion using UmAlQura approximation
        return try {
            val cal = Calendar.getInstance()
            val jd  = gregorianToJD(
                cal.get(Calendar.YEAR),
                cal.get(Calendar.MONTH) + 1,
                cal.get(Calendar.DAY_OF_MONTH)
            )
            val (hy, hm, hd) = jdToHijri(jd)
            val hijriMonths = arrayOf(
                "محرم","صفر","ربيع الأول","ربيع الثاني",
                "جمادى الأولى","جمادى الآخرة","رجب","شعبان",
                "رمضان","شوال","ذو القعدة","ذو الحجة"
            )
            "$hd ${hijriMonths[hm - 1]} $hy هـ"
        } catch (_: Exception) {
            ""
        }
    }

    private fun gregorianToJD(y: Int, m: Int, d: Int): Long {
        val a = (14 - m) / 12
        val year = y + 4800 - a
        val mon  = m + 12 * a - 3
        return d + (153 * mon + 2) / 5 + 365L * year + year / 4 - year / 100 + year / 400 - 32045
    }

    private fun jdToHijri(jd: Long): Triple<Int, Int, Int> {
        val l = jd - 1948440 + 10632
        val n = (l - 1) / 10631
        val l2 = l - 10631 * n + 354
        val j = ((10985 - l2) / 5316) * ((50 * l2) / 17719) +
                (l2 / 5670) * ((43 * l2) / 15238)
        val l3 = l2 - ((30 - j) / 15) * ((17719 * j) / 50) -
                 (j / 16) * ((15238 * j) / 43) + 29
        val month = (24 * l3) / 709
        val day   = l3 - (709 * month) / 24
        val year  = 30 * n + j - 30
        return Triple(year.toInt(), month.toInt(), day.toInt())
    }

    // ── Util ─────────────────────────────────────────────────────────────────

    private fun prayerArabicName(name: String): String = when (name.lowercase()) {
        "fajr"    -> "الفجر"
        "dhuhr"   -> "الظهر"
        "asr"     -> "العصر"
        "maghrib" -> "المغرب"
        "isha"    -> "العشاء"
        else      -> name
    }

    private fun dimColor(color: Int, alpha: Float = 0.4f): Int {
        val r = Color.red(color)
        val g = Color.green(color)
        val b = Color.blue(color)
        return Color.argb((255 * alpha).toInt(), r, g, b)
    }

    private fun Int.dp(density: Float) = this * density

    private fun lp(topMarginPx: Float) = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT,
        LinearLayout.LayoutParams.WRAP_CONTENT
    ).apply { topMargin = topMarginPx.toInt() }

    private fun spacer(heightPx: Float): View = View(this).apply {
        layoutParams = LinearLayout.LayoutParams(1, heightPx.toInt())
    }
}
