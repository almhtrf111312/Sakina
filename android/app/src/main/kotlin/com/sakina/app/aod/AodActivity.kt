package com.sakina.app.aod

import android.annotation.SuppressLint
import android.app.Activity
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.InsetDrawable
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.telephony.TelephonyManager
import android.util.TypedValue
import android.view.Gravity
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.KeyEvent
import com.sakina.app.service.AdhanForegroundService
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

/**
 * Always-on screen: black background, dim text, large clock/date/next prayer,
 * slow drift of the whole block to protect AMOLED panels from burn-in.
 *
 * Shown over the lock screen (no unlock required). Closed on unlock, on
 * or after the configured timeout.
 */
class AodActivity : Activity() {

    companion object {
        const val EXTRA_DEADLINE = "aod_deadline"
        const val EXTRA_ALWAYS_ON = "always_on"
        const val EXTRA_PRAYER_ALERT = "prayer_alert"
        const val EXTRA_PREVIEW = "preview"
        const val ACTION_CLOSE_AOD = "com.sakina.app.ACTION_CLOSE_AOD"
        private const val DRIFT_MS = 60_000L
    }

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var cfg: AlwaysOnConfig
    private var preview = false

    private lateinit var root: FrameLayout
    private lateinit var clockArea: FrameLayout
    private lateinit var statusBar: AodStatusView
    private lateinit var block: LinearLayout
    private lateinit var tvTime: TextView
    private var tvClockMinutes: TextView? = null
    private var analogClock: AnalogClockView? = null
    private lateinit var tvDate: TextView
    private lateinit var tvHijri: TextView
    private lateinit var tvExit: TextView
    private lateinit var tvAlert: TextView
    private lateinit var tvName: TextView
    private lateinit var tvPrayerTime: TextView
    private lateinit var tvCountdown: TextView
    private lateinit var rowPrayers: LinearLayout
    private lateinit var detector: GestureDetector
    private var cachedData: com.sakina.app.widget.WidgetData? = null
    private var cachedMinute = -1L

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(c: Context, i: Intent) {
            when (i.action) {
                ACTION_CLOSE_AOD -> finish()
                AdhanForegroundService.ACTION_ALERT_CHANGED -> updatePrayerAlert()
            }
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
            override fun onDown(e: MotionEvent): Boolean = true

            override fun onDoubleTap(e: MotionEvent): Boolean {
                dismiss()
                return true
            }

            override fun onFling(e1: MotionEvent?, e2: MotionEvent, vx: Float, vy: Float): Boolean {
                if ((e1?.y ?: 0f) - e2.y > 200 && abs(vy) > 500) { dismiss(); return true }
                return false
            }
        })
        val f = IntentFilter(ACTION_CLOSE_AOD).apply {
            addAction(AdhanForegroundService.ACTION_ALERT_CHANGED)
        }
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(receiver, f, Context.RECEIVER_NOT_EXPORTED)
        else registerReceiver(receiver, f)
        armTimeout()
    }

    private val timeoutTask = Runnable { timeoutClose() }

    private fun armTimeout() {
        handler.removeCallbacks(timeoutTask)
        if (intent.getBooleanExtra(EXTRA_PRAYER_ALERT, false)) return
        val deadline = intent.getLongExtra(EXTRA_DEADLINE, -1L)
        val timeout = when {
            preview -> 60_000L
            deadline > 0 -> (deadline - SystemClock.elapsedRealtime()).coerceAtLeast(1)
            deadline == 0L -> 0L
            else -> cfg.timeoutMin * 60_000L
        }
        if (timeout > 0) handler.postDelayed(timeoutTask, timeout)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        armTimeout()
        updatePrayerAlert()
    }

    override fun onStart() {
        super.onStart()
        cachedMinute = -1
        updatePrayerAlert()
        tick.run()
        if (statusBar.visibility == View.VISIBLE) statusTick.run()
        handler.post(drift)
    }

    override fun onStop() {
        handler.removeCallbacks(tick)
        handler.removeCallbacks(statusTick)
        handler.removeCallbacks(drift)
        super.onStop()
    }

    override fun onResume() {
        super.onResume()
        if (!preview && !(getSystemService(KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked) finish()
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
        lp.screenBrightness = (cfg.brightness * 0.5f).coerceIn(0.001f, 0.12f)
        window.attributes = lp
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
    }

    // ── UI ─────────────────────────────────────────────────────────────────

    private fun dimmed(c: Int, a: Float): Int =
        Color.argb((255 * a * (cfg.brightness / 0.10f).coerceIn(0.20f, 1f)).toInt(), Color.red(c), Color.green(c), Color.blue(c))

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
        clockArea = FrameLayout(this)
        root.addView(clockArea, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT
        ))
        statusBar = AodStatusView(this, main, cfg.hiddenElements)
        if (!visible("status") || listOf("ringer", "cell", "wifi", "battery").none(::visible)) {
            statusBar.visibility = View.GONE
        }
        root.addView(statusBar, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, (44 * d).toInt(), Gravity.TOP
        ))
        statusBar.addOnLayoutChangeListener { _, _, top, _, bottom, _, oldTop, _, oldBottom ->
            if (bottom - top != oldBottom - oldTop) {
                val params = clockArea.layoutParams as FrameLayout.LayoutParams
                params.topMargin = bottom - top
                clockArea.layoutParams = params
            }
        }
        block = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding((24 * d).toInt(), 0, (24 * d).toInt(), 0)
        }
        clockArea.addView(block, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT,
            Gravity.CENTER))

        val split = cfg.layout == "split"
        val analog = cfg.clockStyle >= 6
        val stackClock = split && !analog && cfg.clockStyle != 3
        val clock = column()
        val dates = column()
        if (split) block.addView(paired(dates, clock), lp(0))
        else {
            block.addView(clock, lp(0))
            block.addView(dates, lp(0))
        }

        if (analog) {
            analogClock = AnalogClockView(this, main, cfg.clockStyle == 6, visible("dial")).also {
                clock.addView(it, LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
                ))
            }
        }
        val timeSize = when (cfg.clockStyle) {
            1 -> 80f; 2 -> 74f; 3 -> 66f; 4 -> 68f; 5 -> 82f
            6, 7 -> 28f; else -> 86f
        }
        tvTime = timeLabel(timeSize, main, cfg.clockStyle != 2).also { clock.addView(it, lp(0)) }
        styleClock(tvTime, d)
        if (analog && !visible("digital")) tvTime.visibility = View.GONE
        if (stackClock) {
            tvClockMinutes = timeLabel(timeSize, main, cfg.clockStyle != 2).also {
                styleClock(it, d)
                clock.addView(it, lp(0))
            }
        }
        tvDate = label(if (split) 16f else 20f, soft).also { dates.addView(it, lp(6)) }
        tvHijri = label(if (split) 16f else 20f, soft).also { dates.addView(it, lp(2)) }
        tvDate.visibility = if (cfg.dateMode == "gregorian" || cfg.dateMode == "both") View.VISIBLE else View.GONE
        tvHijri.visibility = if (cfg.dateMode == "hijri" || cfg.dateMode == "both") View.VISIBLE else View.GONE
        if (tvDate.visibility == View.GONE && tvHijri.visibility == View.GONE) dates.visibility = View.GONE

        tvAlert = label(24f, main, true).apply {
            visibility = View.GONE
            accessibilityLiveRegion = View.ACCESSIBILITY_LIVE_REGION_POLITE
        }.also { block.addView(it, lp(0)) }

        val prayer = column()
        val countdown = column()
        val upcoming = if (split) paired(countdown, prayer) else column().apply {
            addView(prayer, lp(0))
            addView(countdown, lp(0))
        }
        block.addView(upcoming, lp(24))
        if (visible("name") && visible("caption")) {
            prayer.addView(label(15f, soft).apply { text = "الصلاة القادمة" }, lp(0))
        }
        tvName = label(44f, main, true).also { prayer.addView(it, lp(3)) }
        if (!visible("name")) tvName.visibility = View.GONE
        tvPrayerTime = timeLabel(38f, main).also { prayer.addView(it, lp(4)) }
        if (!visible("prayerTime")) tvPrayerTime.visibility = View.GONE
        if (visible("remaining")) {
            countdown.addView(label(15f, soft).apply { text = "المتبقي" }, lp(if (split) 0 else 8))
        }
        tvCountdown = timeLabel(30f, soft).also { countdown.addView(it, lp(2)) }
        if (!visible("remaining")) {
            tvCountdown.visibility = View.GONE
            countdown.visibility = View.GONE
        }
        if (!visible("name") && !visible("prayerTime")) prayer.visibility = View.GONE
        if (prayer.visibility == View.GONE && countdown.visibility == View.GONE) upcoming.visibility = View.GONE

        rowPrayers = LinearLayout(this).apply {
            orientation = if (cfg.layout == "list") LinearLayout.VERTICAL else LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutDirection = View.LAYOUT_DIRECTION_RTL
            tag = Pair(main, faint)
        }
        block.addView(rowPrayers, lp(18))
        if (!cfg.showPrayers) rowPrayers.visibility = View.GONE

        tvExit = label(16f, soft).apply {
            val lock = getDrawable(com.sakina.app.R.drawable.ic_aod_lock)?.mutate()
            lock?.setTint(soft)
            setCompoundDrawablesWithIntrinsicBounds(null, lock, null, null)
            contentDescription = "إظهار شاشة القفل"
            gravity = Gravity.CENTER
            setPadding((12 * d).toInt(), (8 * d).toInt(), (12 * d).toInt(), (8 * d).toInt())
            setOnClickListener { dismiss() }
        }
        root.addView(tvExit, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT,
            Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
        ).apply { bottomMargin = (24 * d).toInt() })
        val clockBounds = clockArea.layoutParams as FrameLayout.LayoutParams
        clockBounds.bottomMargin = (64 * d).toInt()
        clockArea.layoutParams = clockBounds
        setContentView(root)
    }

    private fun visible(key: String): Boolean = key !in cfg.hiddenElements

    private fun column() = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER
    }

    /** Physical left/right columns are independent of the device locale. */
    private fun paired(left: View, right: View) = LinearLayout(this).apply {
        layoutDirection = View.LAYOUT_DIRECTION_LTR
        gravity = Gravity.CENTER_VERTICAL
        for (view in listOf(left, right)) {
            addView(view, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        }
    }

    private fun timeLabel(size: Float, color: Int, bold: Boolean = false) =
        label(size, color, bold).apply { textDirection = View.TEXT_DIRECTION_LTR }

    /** Applies the clock design chosen in the app (digital / classic / minimal / boxed). */
    private fun styleClock(tv: TextView, d: Float) {
        when (cfg.clockStyle) {
            1 -> tv.typeface = Typeface.create(Typeface.SERIF, Typeface.BOLD)
            2 -> tv.typeface = Typeface.create("sans-serif-light", Typeface.NORMAL)
            3 -> {
                tv.typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
                val box = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    cornerRadius = 20 * d
                    setStroke((2 * d).toInt().coerceAtLeast(2), dimmed(cfg.color, 0.45f))
                }
                val inset = (28 * d).toInt()
                tv.background = InsetDrawable(box, inset, 0, inset, 0)
                // set after the background so it is not overridden by the drawable's padding
                tv.setPadding(inset + (18 * d).toInt(), (14 * d).toInt(),
                    inset + (18 * d).toInt(), (14 * d).toInt())
            }
            4 -> tv.typeface = Typeface.create("monospace", Typeface.NORMAL)
            5 -> tv.typeface = Typeface.create("sans-serif-rounded", Typeface.BOLD)
            6, 7 -> tv.typeface = Typeface.create("sans-serif-light", Typeface.NORMAL)
            else -> tv.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        }
    }

    /** Western digits -> Arabic-Indic digits when the user picked them. */
    private fun num(s: String): String {
        if (!cfg.arabicNumerals) return s
        val sb = StringBuilder(s.length)
        for (ch in s) sb.append(if (ch in '0'..'9') ('٠' + (ch - '0')) else ch)
        return sb.toString()
    }

    // ── updates ────────────────────────────────────────────────────────────

    private val tick = object : Runnable {
        override fun run() {
            update()
            handler.postDelayed(this, 60_000L - System.currentTimeMillis() % 60_000L)
        }
    }

    private val statusTick = object : Runnable {
        override fun run() {
            statusBar.bind(deviceStatus())
            handler.postDelayed(this, 5_000L)
        }
    }

    @Suppress("DEPRECATION")
    private fun deviceStatus(): AodStatusView.Status {
        val battery = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = battery?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = battery?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val percent = if (level >= 0 && scale > 0)
            num("${(level * 100 / scale).coerceIn(0, 100)}٪") else "—"
        val isCharging = battery?.getIntExtra(BatteryManager.EXTRA_STATUS, 0) ==
            BatteryManager.BATTERY_STATUS_CHARGING
        val charging = when (battery?.getIntExtra(BatteryManager.EXTRA_STATUS, 0)) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "قيد الشحن"
            BatteryManager.BATTERY_STATUS_FULL -> "ممتلئة"
            else -> if ((battery?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) ?: 0) > 0)
                "متصلة بالشاحن" else "غير متصلة بالشاحن"
        }
        val audio = getSystemService(AudioManager::class.java)
        val ringerMode = audio.ringerMode
        val ringer = when (ringerMode) {
            AudioManager.RINGER_MODE_SILENT -> "صامت"
            AudioManager.RINGER_MODE_VIBRATE -> "اهتزاز"
            else -> "رنين"
        }

        val connectivity = getSystemService(ConnectivityManager::class.java)
        val networks = connectivity.allNetworks.mapNotNull(connectivity::getNetworkCapabilities)
        val wifiManager = applicationContext.getSystemService(WifiManager::class.java)
        val wifiConnected = networks.any { it.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) }
        val wifiEnabled = wifiConnected || wifiManager?.isWifiEnabled == true
        val wifiLevel = if (wifiConnected) runCatching {
            wifiManager?.connectionInfo?.rssi?.takeIf { it > -127 && it < 0 }?.let {
                WifiManager.calculateSignalLevel(it, 4) + 1
            }
        }.getOrNull() else null
        val wifi = when {
            wifiConnected -> "متصل"
            wifiEnabled -> "غير متصل"
            else -> "متوقف"
        }
        val airplaneMode = Settings.Global.getInt(contentResolver, Settings.Global.AIRPLANE_MODE_ON, 0) != 0
        val cellSignal = if (!airplaneMode && Build.VERSION.SDK_INT >= 28) {
            runCatching {
                getSystemService(TelephonyManager::class.java)?.signalStrength?.level
            }.getOrNull()
        } else null
        val mobile = when {
            airplaneMode -> "وضع الطيران"
            cellSignal != null -> num("إشارة $cellSignal/4")
            networks.any { it.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) } -> "متصلة"
            else -> "غير متاحة"
        }
        return AodStatusView.Status(
            percent, isCharging, ringerMode, cellSignal, wifiEnabled, wifiConnected, wifiLevel,
            "البطارية $percent، $charging، $ringer، الجوال: $mobile، واي فاي: $wifi"
        )
    }

    private fun hm(ts: Long): String {
        val c = Calendar.getInstance().apply { timeInMillis = ts }
        return formattedTime(c)
    }

    private fun formattedTime(c: Calendar): String {
        val h = c.get(Calendar.HOUR_OF_DAY)
        val minute = c.get(Calendar.MINUTE)
        if (cfg.use24HourTime) return num(String.format(Locale.US, "%02d:%02d", h, minute))
        val h12 = if (h % 12 == 0) 12 else h % 12
        return num(String.format(Locale.US, "%02d:%02d", h12, minute)) +
            if (h < 12) " ص" else " م"
    }

    private val monthsAr = arrayOf("يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
        "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر")
    private val daysAr = arrayOf("الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت")
    private val hijriMonths = arrayOf("محرم", "صفر", "ربيع الأول", "ربيع الآخر", "جمادى الأولى",
        "جمادى الآخرة", "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة")

    private fun update() {
        val now = Calendar.getInstance()
        val clockMinutes = tvClockMinutes
        val time = formattedTime(now)
        if (clockMinutes == null) {
            tvTime.text = time
        } else {
            tvTime.text = time.substringBefore(':')
            clockMinutes.text = time.substringAfter(':')
        }
        analogClock?.invalidate()
        if (tvDate.visibility == View.VISIBLE) tvDate.text = num("${daysAr[now.get(Calendar.DAY_OF_WEEK) - 1]} ${now.get(Calendar.DAY_OF_MONTH)} " +
            "${monthsAr[now.get(Calendar.MONTH)]} ${now.get(Calendar.YEAR)}")
        if (tvHijri.visibility == View.VISIBLE) tvHijri.text = hijri(now)

        val minute = System.currentTimeMillis() / 60_000L
        if (minute != cachedMinute) {
            cachedMinute = minute
            cachedData = WidgetData.load(this)
        }
        val data = cachedData
        val next = data?.next
        if (next == null) {
            tvName.text = "المؤذان"; tvPrayerTime.text = ""; tvCountdown.text = ""
            return
        }
        tvName.text = next.nameAr
        tvPrayerTime.text = hm(next.ts)
        val minutes = ((next.ts - System.currentTimeMillis() + 59_999L) / 60_000L).coerceAtLeast(0)
        tvCountdown.text = num(String.format(Locale.US, "%02d:%02d",
            minutes / 60, minutes % 60))

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
        val vertical = cfg.layout == "list"
        for (p in list) {
            if (p.ts == next.ts && visible("name") && visible("prayerTime") && cfg.layout != "classic") continue
            val isNext = p.ts == next.ts
            val cell = column()
            val c = if (isNext) cols.first else cols.second
            val size = 15f * cfg.textScale.coerceAtMost(1.3f)
            val name = TextView(this).apply {
                text = p.nameAr; setTextColor(c); gravity = Gravity.CENTER
                setTextSize(TypedValue.COMPLEX_UNIT_SP, size)
            }
            val time = TextView(this).apply {
                text = hm(p.ts); setTextColor(c); gravity = Gravity.CENTER
                textDirection = View.TEXT_DIRECTION_LTR
                setTextSize(TypedValue.COMPLEX_UNIT_SP, size)
            }
            if (vertical) {
                rowPrayers.addView(paired(time, name), lp(4))
            } else {
                cell.addView(name)
                cell.addView(time)
                rowPrayers.addView(cell, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            }
        }
    }

    // ── burn-in protection: the whole block keeps wandering ────────────────

    private var driftIndex = 0
    private val drift = object : Runnable {
        private val offsets = arrayOf(0 to 0, 8 to 10, -8 to 10, -8 to -10, 8 to -10)
        override fun run() {
            val (x, y) = offsets[driftIndex]
            val density = resources.displayMetrics.density
            val verticalRoom = ((clockArea.height - block.height) / 2f).coerceAtLeast(0f)
            tvExit.translationX = x * density / 2
            statusBar.translationX = x * density / 2
            statusBar.translationY = (y + 10) * density / 4
            block.translationX = x * density
            block.translationY = (y * density).coerceIn(-verticalRoom, verticalRoom)
            driftIndex = (driftIndex + 1) % offsets.size
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
        if (AdhanForegroundService.activePrayer != null) {
            handler.postDelayed(timeoutTask, 1_000L)
            return
        }
        if (!preview) {
            sendBroadcast(Intent(AlwaysOnService.ACTION_TIMEOUT).setPackage(packageName))
        }
        finish()
    }

    private fun openApp() {
        if ((getSystemService(KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked) return
        packageManager.getLaunchIntentForPackage(packageName)?.let { startActivity(it) }
        dismiss()
    }

    private fun updatePrayerAlert() {
        if (preview) return
        val name = AdhanForegroundService.activePrayer
        if (name == null) {
            tvAlert.animate().cancel()
            tvAlert.visibility = View.GONE
            tvExit.contentDescription = "إظهار شاشة القفل"
            if (intent.getBooleanExtra(EXTRA_PRAYER_ALERT, false)) finish()
            return
        }
        val title = "حان الآن موعد أذان $name"
        if (tvAlert.visibility == View.VISIBLE && tvAlert.text == title) return
        tvExit.contentDescription = "المس الشاشة لإيقاف التنبيه"
        tvAlert.text = title
        tvAlert.visibility = View.VISIBLE
        tvAlert.alpha = 0.25f
        tvAlert.animate().alpha(1f).setDuration(550).start()
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN &&
            (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
                event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) &&
            AdhanForegroundService.stopIfAlerting(this)) return true
        return super.dispatchKeyEvent(event)
    }

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        if (!preview && AdhanForegroundService.activePrayer != null) {
            if (event.actionMasked == MotionEvent.ACTION_UP) {
                AdhanForegroundService.stopIfAlerting(this)
            }
            return true
        }
        // Observe the entire screen, including text and prayer rows; child
        // views must not swallow the double tap needed to reach the keyguard.
        val handled = ::detector.isInitialized && detector.onTouchEvent(event)
        return super.dispatchTouchEvent(event) || handled
    }

    // ── Hijri (tabular Kuwaiti algorithm) ──────────────────────────────────

    private fun hijri(base: Calendar): String {
        return try {
            val c = base.clone() as Calendar
            if (cfg.hijriOffset != 0) c.add(Calendar.DAY_OF_YEAR, cfg.hijriOffset)
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
            num("$day ${hijriMonths[(month - 1).toInt().coerceIn(0, 11)]} $year هـ")
        } catch (_: Exception) { "" }
    }
}
