package com.sakina.app.aod

import android.animation.ObjectAnimator
import android.annotation.SuppressLint
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.widget.TextViewCompat
import com.sakina.app.widget.WPrayer
import com.sakina.app.widget.WidgetData
import java.util.Calendar
import java.util.Locale
import kotlin.math.abs
import kotlin.random.Random

/**
 * Always-on screen: black background, dim text, large clock/date/next prayer,
 * slow drift of the whole block to protect AMOLED panels from burn-in.
 *
 * Shown over the lock screen (no unlock required). Closed on unlock, on
 * double tap, or after the configured timeout.
 */
class AodActivity : Activity() {

    companion object {
        const val EXTRA_ALWAYS_ON = "always_on"
        const val EXTRA_PREVIEW = "preview"
        const val ACTION_CLOSE_AOD = "com.sakina.app.ACTION_CLOSE_AOD"
        private const val DRIFT_MS = 20_000L
    }

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var cfg: AlwaysOnConfig
    private var preview = false

    private lateinit var root: FrameLayout
    private lateinit var block: LinearLayout
    private lateinit var tvTime: TextView
    private lateinit var tvDate: TextView
    private lateinit var tvHijri: TextView
    private lateinit var tvName: TextView
    private lateinit var tvPrayerTime: TextView
    private lateinit var tvCountdown: TextView
    private lateinit var rowPrayers: LinearLayout
    private lateinit var detector: GestureDetector

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(c: Context, i: Intent) {
            if (i.action == ACTION_CLOSE_AOD) finish()
        }
    }

    // ── lifecycle ──────────────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        cfg = AlwaysOnConfig.load(this)
        preview = intent?.getBooleanExtra(EXTRA_PREVIEW, false) == true
        setupWindow()
        buildUi()
        detector = GestureDetector(this, object : GestureDetector.SimpleOnGestureListener() {
            override fun onDoubleTap(e: MotionEvent): Boolean { dismiss(); return true }
            override fun onFling(e1: MotionEvent?, e2: MotionEvent, vx: Float, vy: Float): Boolean {
                if ((e1?.y ?: 0f) - e2.y > 200 && abs(vy) > 500) { openApp(); return true }
                return false
            }
        })
        val f = IntentFilter(ACTION_CLOSE_AOD)
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(receiver, f, Context.RECEIVER_NOT_EXPORTED)
        else registerReceiver(receiver, f)
        tick.run()
        handler.postDelayed(drift, 4000)
        val timeout = if (preview) 60_000L else cfg.timeoutMin * 60_000L
        if (timeout > 0) handler.postDelayed({ timeoutClose() }, timeout)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        try { unregisterReceiver(receiver) } catch (_: Exception) {}
        super.onDestroy()
    }

    override fun onBackPressed() { dismiss() }

    // ── window ─────────────────────────────────────────────────────────────

    @Suppress("DEPRECATION")
    private fun setupWindow() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        val lp = window.attributes
        lp.screenBrightness = cfg.brightness.coerceIn(0.01f, 0.5f)
        window.attributes = lp
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
    }

    // ── UI ─────────────────────────────────────────────────────────────────

    private fun dimmed(c: Int, a: Float): Int =
        Color.argb((255 * a).toInt(), Color.red(c), Color.green(c), Color.blue(c))

    private fun label(size: Float, color: Int, bold: Boolean = false): TextView =
        TextView(this).apply {
            setTextColor(color)
            gravity = Gravity.CENTER
            maxLines = 1
            includeFontPadding = false
            setTextSize(TypedValue.COMPLEX_UNIT_SP, size * cfg.textScale)
            if (bold) typeface = Typeface.DEFAULT_BOLD
            TextViewCompat.setAutoSizeTextTypeUniformWithConfiguration(
                this, 10, (size * cfg.textScale).toInt(), 1, TypedValue.COMPLEX_UNIT_SP)
        }

    private fun lp(top: Int): LinearLayout.LayoutParams =
        LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = (top * resources.displayMetrics.density).toInt() }

    @SuppressLint("SetTextI18n")
    private fun buildUi() {
        val main = dimmed(cfg.color, 0.85f)      // never full brightness
        val soft = dimmed(cfg.color, 0.55f)
        val faint = dimmed(cfg.color, 0.35f)
        val d = resources.displayMetrics.density

        root = FrameLayout(this).apply { setBackgroundColor(Color.BLACK) }
        block = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding((24 * d).toInt(), 0, (24 * d).toInt(), 0)
        }
        root.addView(block, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT,
            Gravity.CENTER))

        tvTime = label(86f, main, true).also { block.addView(it, lp(0)) }
        tvDate = label(20f, soft).also { block.addView(it, lp(6)) }
        tvHijri = label(20f, soft).also { block.addView(it, lp(2)) }
        block.addView(View(this), LinearLayout.LayoutParams(1, (28 * d).toInt()))
        tvName = label(44f, main, true).also { block.addView(it, lp(0)) }
        tvPrayerTime = label(38f, main).also { block.addView(it, lp(4)) }
        tvCountdown = label(30f, soft).also { block.addView(it, lp(10)) }

        rowPrayers = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutDirection = View.LAYOUT_DIRECTION_RTL
        }
        block.addView(rowPrayers, lp(30))
        if (!cfg.showPrayers) rowPrayers.visibility = View.GONE
        tvDate.visibility = if (cfg.dateMode == "gregorian" || cfg.dateMode == "both") View.VISIBLE else View.GONE
        tvHijri.visibility = if (cfg.dateMode == "hijri" || cfg.dateMode == "both") View.VISIBLE else View.GONE
        // keep colours used by rows
        rowPrayers.tag = Pair(main, faint)
        setContentView(root)
    }

    // ── updates ────────────────────────────────────────────────────────────

    private val tick = object : Runnable {
        override fun run() {
            update()
            handler.postDelayed(this, 1000)
        }
    }

    private fun hm(ts: Long): String {
        val c = Calendar.getInstance().apply { timeInMillis = ts }
        return String.format(Locale.US, "%02d:%02d", c.get(Calendar.HOUR_OF_DAY), c.get(Calendar.MINUTE))
    }

    private val monthsAr = arrayOf("يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
        "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر")
    private val daysAr = arrayOf("الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت")
    private val hijriMonths = arrayOf("محرم", "صفر", "ربيع الأول", "ربيع الآخر", "جمادى الأولى",
        "جمادى الآخرة", "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة")

    private fun update() {
        val now = Calendar.getInstance()
        tvTime.text = String.format(Locale.US, "%02d:%02d", now.get(Calendar.HOUR_OF_DAY), now.get(Calendar.MINUTE))
        tvDate.text = "${daysAr[now.get(Calendar.DAY_OF_WEEK) - 1]} ${now.get(Calendar.DAY_OF_MONTH)} " +
            "${monthsAr[now.get(Calendar.MONTH)]} ${now.get(Calendar.YEAR)}"
        tvHijri.text = hijri(now)

        val data = WidgetData.load(this)
        val next = data?.next
        if (next == null) {
            tvName.text = "سكينة"; tvPrayerTime.text = ""; tvCountdown.text = ""
            return
        }
        tvName.text = "الصلاة القادمة: " + next.nameAr
        tvPrayerTime.text = hm(next.ts)
        val sec = ((next.ts - System.currentTimeMillis()) / 1000).coerceAtLeast(0)
        tvCountdown.text = String.format(Locale.US, "المتبقي %d:%02d:%02d",
            sec / 3600, (sec % 3600) / 60, sec % 60)

        if (cfg.showPrayers) fillRow(data.todayFive(), next)
    }

    private var rowKey = ""
    private fun fillRow(list: List<WPrayer>, next: WPrayer) {
        val key = list.joinToString { "${it.key}${it.ts}" } + next.ts
        if (key == rowKey) return
        rowKey = key
        rowPrayers.removeAllViews()
        @Suppress("UNCHECKED_CAST")
        val cols = rowPrayers.tag as Pair<Int, Int>
        for (p in list) {
            val isNext = p.ts == next.ts
            val cell = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER }
            val c = if (isNext) cols.first else cols.second
            cell.addView(TextView(this).apply {
                text = p.nameAr; setTextColor(c); gravity = Gravity.CENTER
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f * cfg.textScale.coerceAtMost(1.3f))
            })
            cell.addView(TextView(this).apply {
                text = hm(p.ts); setTextColor(c); gravity = Gravity.CENTER
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f * cfg.textScale.coerceAtMost(1.3f))
            })
            rowPrayers.addView(cell, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        }
    }

    // ── burn-in protection: the whole block keeps wandering ────────────────

    private val drift = object : Runnable {
        override fun run() {
            val d = resources.displayMetrics.density
            val maxX = 26 * d
            val maxY = 60 * d
            val x = Random.nextFloat() * 2 * maxX - maxX
            val y = Random.nextFloat() * 2 * maxY - maxY
            ObjectAnimator.ofFloat(block, "translationX", x).apply { duration = 4000; start() }
            ObjectAnimator.ofFloat(block, "translationY", y).apply { duration = 4000; start() }
            handler.postDelayed(this, DRIFT_MS)
        }
    }

    // ── closing ────────────────────────────────────────────────────────────

    private fun suppressUntilUnlock() {
        sendBroadcast(Intent(AlwaysOnService.ACTION_SUPPRESS).setPackage(packageName))
    }

    private fun dismiss() {
        if (!preview) suppressUntilUnlock()
        finish()
    }

    private fun timeoutClose() {
        if (!preview) suppressUntilUnlock()
        finish()
    }

    private fun openApp() {
        packageManager.getLaunchIntentForPackage(packageName)?.let { startActivity(it) }
        dismiss()
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent?): Boolean {
        event?.let { detector.onTouchEvent(it) }
        return super.onTouchEvent(event)
    }

    // ── Hijri (tabular Kuwaiti algorithm) ──────────────────────────────────

    private fun hijri(c: Calendar): String {
        return try {
            val y = c.get(Calendar.YEAR); val m = c.get(Calendar.MONTH) + 1; val dd = c.get(Calendar.DAY_OF_MONTH)
            val a = (14 - m) / 12
            val yy = y + 4800 - a
            val mm = m + 12 * a - 3
            val jd = dd + (153 * mm + 2) / 5 + 365L * yy + yy / 4 - yy / 100 + yy / 400 - 32045
            var l = jd - 1948440 + 10632
            val n = (l - 1) / 10631
            l = l - 10631 * n + 354
            val j = ((10985 - l) / 5316) * ((50 * l) / 17719) + (l / 5670) * ((43 * l) / 15238)
            l = l - ((30 - j) / 15) * ((17719 * j) / 50) - (j / 16) * ((15238 * j) / 43) + 29
            val month = (24 * l) / 709
            val day = l - (709 * month) / 24
            val year = 30 * n + j - 30
            "$day ${hijriMonths[(month - 1).toInt().coerceIn(0, 11)]} $year هـ"
        } catch (_: Exception) { "" }
    }
}
