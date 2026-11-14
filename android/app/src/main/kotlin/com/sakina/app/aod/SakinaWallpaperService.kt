package com.sakina.app.aod

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Typeface
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.abs

/**
 * SakinaWallpaperService — Live Wallpaper service for Lock Screen and Home Screen.
 *
 * Implements an Always-On Display (AOD) style lock screen wallpaper:
 * - True AMOLED black background (#000000)
 * - Highly customizable Clock (Digital Modern, Classic Calligraphy, Minimal, Boxed)
 * - Gregorian & Hijri Date with manual offset support
 * - Next prayer name, target time, and live countdown
 * - Row of 5 daily prayers with active prayer highlighted
 * - Pixel shift burn-in protection (shifts coordinates slightly every minute)
 * - Low power consumption (updates only once per minute on ACTION_TIME_TICK)
 * - Syncs with Flutter settings via SharedPreferences and broadcast action
 */
class SakinaWallpaperService : WallpaperService() {

    companion object {
        const val ACTION_UPDATE_WALLPAPER = "com.sakina.app.ACTION_UPDATE_WALLPAPER"
        const val PREFS_NAME = "sakina_aod_wallpaper_prefs"

        const val KEY_CLOCK_STYLE = "clock_style" // 0: digital, 1: classic, 2: minimal, 3: boxed
        const val KEY_ACCENT_COLOR = "accent_color" // hex color int
        const val KEY_SHOW_HIJRI = "show_hijri"
        const val KEY_SHOW_GREGORIAN = "show_gregorian"
        const val KEY_SHOW_COUNTDOWN = "show_countdown"
        const val KEY_SHOW_PRAYERS_ROW = "show_prayers_row"
        const val KEY_PRAYER_DATA = "prayer_data"
        const val KEY_HIJRI_OFFSET = "hijri_offset"
        const val KEY_USE_ARABIC_NUMERALS = "use_arabic_numerals"
    }

    override fun onCreateEngine(): Engine {
        return SakinaEngine()
    }

    inner class SakinaEngine : Engine() {

        private val handler = Handler(Looper.getMainLooper())
        private var visible = false
        private lateinit var prefs: SharedPreferences

        // Paint objects
        private val bgPaint = Paint().apply {
            color = Color.BLACK
            style = Paint.Style.FILL
        }

        private val timePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        }

        private val subTimePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFF9DB0AA.toInt()
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
        }

        private val accentPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFF5FB59B.toInt() // Default emerald green
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        }

        private val dimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0x559DB0AA
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
        }

        private val boxPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0x335FB59B
            style = Paint.Style.STROKE
            strokeWidth = 3f
        }

        // Burn-in pixel shift variables
        private var pixelShiftX = 0f
        private var pixelShiftY = 0f
        private val random = Random()

        // Cached prayer data
        private var nextPrayerNameAr = "الفجر"
        private var nextPrayerNameEn = "Fajr"
        private var nextPrayerTime = "05:12"
        private var nextPrayerTimestamp = 0L

        private val prayerNamesAr = listOf("الفجر", "الظهر", "العصر", "المغرب", "العشاء")
        private val prayerTimes = mutableListOf("05:12", "12:15", "15:30", "18:05", "19:35")
        private var activePrayerIndex = 0

        // Time tick broadcast receiver
        private val tickReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_TIME_TICK,
                    Intent.ACTION_TIME_CHANGED,
                    Intent.ACTION_TIMEZONE_CHANGED,
                    ACTION_UPDATE_WALLPAPER -> {
                        loadPreferences()
                        applyPixelShift()
                        drawFrame()
                    }
                }
            }
        }

        override fun onCreate(surfaceHolder: SurfaceHolder?) {
            super.onCreate(surfaceHolder)
            prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            loadPreferences()

            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_TIME_TICK)
                addAction(Intent.ACTION_TIME_CHANGED)
                addAction(Intent.ACTION_TIMEZONE_CHANGED)
                addAction(ACTION_UPDATE_WALLPAPER)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(tickReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(tickReceiver, filter)
            }
        }

        override fun onDestroy() {
            super.onDestroy()
            try {
                unregisterReceiver(tickReceiver)
            } catch (_: Exception) {}
        }

        override fun onVisibilityChanged(visible: Boolean) {
            this.visible = visible
            if (visible) {
                loadPreferences()
                applyPixelShift()
                drawFrame()
            }
        }

        override fun onSurfaceChanged(holder: SurfaceHolder?, format: Int, width: Int, height: Int) {
            super.onSurfaceChanged(holder, format, width, height)
            drawFrame()
        }

        private fun loadPreferences() {
            try {
                val prayerJsonStr = prefs.getString(KEY_PRAYER_DATA, null)
                if (!prayerJsonStr.isNullOrEmpty()) {
                    val json = JSONObject(prayerJsonStr)
                    nextPrayerNameAr = json.optString("prayerNameAr", nextPrayerNameAr)
                    nextPrayerNameEn = json.optString("prayerNameEn", nextPrayerNameEn)
                    nextPrayerTime = json.optString("prayerTime", nextPrayerTime)
                    nextPrayerTimestamp = json.optLong("timestamp", nextPrayerTimestamp)
                    activePrayerIndex = json.optInt("prayerIndex", activePrayerIndex)

                    val timesArray = json.optJSONArray("dailyTimes")
                    if (timesArray != null && timesArray.length() == 5) {
                        prayerTimes.clear()
                        for (i in 0 until 5) {
                            prayerTimes.add(timesArray.optString(i))
                        }
                    }
                }

                val accentColor = prefs.getInt(KEY_ACCENT_COLOR, 0xFF5FB59B.toInt())
                accentPaint.color = accentColor
                boxPaint.color = (accentColor and 0x00FFFFFF) or 0x44000000
            } catch (_: Exception) {}
        }

        private fun applyPixelShift() {
            // Shift coordinates up to +/- 6 pixels every minute to protect AMOLED from burn-in
            pixelShiftX = (random.nextInt(13) - 6).toFloat()
            pixelShiftY = (random.nextInt(13) - 6).toFloat()
        }

        private fun drawFrame() {
            val holder = surfaceHolder ?: return
            var canvas: Canvas? = null

            try {
                canvas = holder.lockCanvas()
                if (canvas != null) {
                    renderWallpaper(canvas)
                }
            } catch (e: Exception) {
                // Surface might be released
            } finally {
                if (canvas != null) {
                    try {
                        holder.unlockCanvasAndPost(canvas)
                    } catch (_: Exception) {}
                }
            }
        }

        private fun renderWallpaper(canvas: Canvas) {
            val width = canvas.width.toFloat()
            val height = canvas.height.toFloat()

            // 1. True AMOLED Black Background
            canvas.drawRect(0f, 0f, width, height, bgPaint)

            val centerX = (width / 2f) + pixelShiftX
            var currentY = (height * 0.22f) + pixelShiftY

            val clockStyle = prefs.getInt(KEY_CLOCK_STYLE, 0)
            val useArabicNumerals = prefs.getBoolean(KEY_USE_ARABIC_NUMERALS, false)
            val showHijri = prefs.getBoolean(KEY_SHOW_HIJRI, true)
            val showGregorian = prefs.getBoolean(KEY_SHOW_GREGORIAN, true)
            val showCountdown = prefs.getBoolean(KEY_SHOW_COUNTDOWN, true)
            val showPrayersRow = prefs.getBoolean(KEY_SHOW_PRAYERS_ROW, true)

            // Current Time
            val now = Calendar.getInstance()
            val timeSdf = SimpleDateFormat("HH:mm", Locale.getDefault())
            var timeStr = timeSdf.format(now.time)
            if (useArabicNumerals) {
                timeStr = toArabicNumbers(timeStr)
            }

            // Draw Clock according to selected style
            when (clockStyle) {
                0 -> { // Modern Digital Bold
                    timePaint.textSize = width * 0.22f
                    timePaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
                    canvas.drawText(timeStr, centerX, currentY, timePaint)
                }
                1 -> { // Classic Serif / Amiri feel
                    timePaint.textSize = width * 0.20f
                    timePaint.typeface = Typeface.create(Typeface.SERIF, Typeface.BOLD)
                    canvas.drawText(timeStr, centerX, currentY, timePaint)
                }
                2 -> { // Minimalist Thin
                    timePaint.textSize = width * 0.18f
                    timePaint.typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
                    canvas.drawText(timeStr, centerX, currentY, timePaint)
                }
                3 -> { // Boxed Digital
                    timePaint.textSize = width * 0.18f
                    timePaint.typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
                    val textBounds = Rect()
                    timePaint.getTextBounds(timeStr, 0, timeStr.length, textBounds)
                    val padX = 40f
                    val padY = 25f
                    canvas.drawRoundRect(
                        centerX - textBounds.width() / 2f - padX,
                        currentY - textBounds.height() - padY,
                        centerX + textBounds.width() / 2f + padX,
                        currentY + padY,
                        24f, 24f, boxPaint
                    )
                    canvas.drawText(timeStr, centerX, currentY, timePaint)
                }
            }

            currentY += 50f

            // 2. Dates Section (Hijri + Gregorian)
            subTimePaint.textSize = width * 0.045f

            if (showHijri) {
                val hijriOffset = prefs.getInt(KEY_HIJRI_OFFSET, 0)
                val hijriStr = getHijriDateString(now, hijriOffset, useArabicNumerals)
                canvas.drawText(hijriStr, centerX, currentY, accentPaint)
                currentY += 45f
            }

            if (showGregorian) {
                val gregSdf = SimpleDateFormat("EEEE، d MMMM yyyy", Locale("ar"))
                var gregStr = gregSdf.format(now.time)
                if (useArabicNumerals) {
                    gregStr = toArabicNumbers(gregStr)
                }
                canvas.drawText(gregStr, centerX, currentY, subTimePaint)
                currentY += 80f
            } else {
                currentY += 40f
            }

            // 3. Next Prayer Focus Card
            currentY = height * 0.48f + pixelShiftY

            accentPaint.textSize = width * 0.075f
            canvas.drawText(nextPrayerNameAr, centerX, currentY, accentPaint)
            currentY += 55f

            subTimePaint.textSize = width * 0.055f
            var prayerTimeDisplay = nextPrayerTime
            if (useArabicNumerals) {
                prayerTimeDisplay = toArabicNumbers(prayerTimeDisplay)
            }
            canvas.drawText(prayerTimeDisplay, centerX, currentY, subTimePaint)
            currentY += 50f

            // 4. Countdown to next prayer
            if (showCountdown) {
                val diffMs = nextPrayerTimestamp - System.currentTimeMillis()
                val countdownStr = if (diffMs > 0) {
                    val hours = (diffMs / (1000 * 60 * 60)).toInt()
                    val minutes = ((diffMs / (1000 * 60)) % 60).toInt()
                    val formatted = String.format(Locale.getDefault(), "متبقي %02d:%02d", hours, minutes)
                    if (useArabicNumerals) toArabicNumbers(formatted) else formatted
                } else {
                    "حان الآن وقت الصلاة"
                }

                subTimePaint.textSize = width * 0.042f
                subTimePaint.color = 0xAA9DB0AA.toInt()
                canvas.drawText(countdownStr, centerX, currentY, subTimePaint)
                subTimePaint.color = 0xFF9DB0AA.toInt()
            }

            // 5. Daily 5 Prayers Bottom Row
            if (showPrayersRow) {
                val rowY = height * 0.78f + pixelShiftY
                val itemWidth = width / 5f

                for (i in prayerNamesAr.indices) {
                    val itemCenterX = (i * itemWidth) + (itemWidth / 2f) + pixelShiftX
                    val isCurrent = (i == activePrayerIndex)

                    val namePaint = if (isCurrent) accentPaint else dimPaint
                    val timeP = if (isCurrent) subTimePaint else dimPaint

                    namePaint.textSize = width * 0.038f
                    timeP.textSize = width * 0.032f

                    // Prayer Name
                    canvas.drawText(prayerNamesAr[i], itemCenterX, rowY, namePaint)

                    // Prayer Time
                    val pTime = if (i < prayerTimes.size) prayerTimes[i] else "--:--"
                    val formattedTime = if (useArabicNumerals) toArabicNumbers(pTime) else pTime
                    canvas.drawText(formattedTime, itemCenterX, rowY + 36f, timeP)

                    // Active dot under current prayer
                    if (isCurrent) {
                        canvas.drawCircle(itemCenterX, rowY + 54f, 4f, accentPaint)
                    }
                }
            }
        }

        private fun toArabicNumbers(str: String): String {
            val arabicDigits = charArrayOf('٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩')
            val sb = java.lang.StringBuilder()
            for (ch in str) {
                if (ch in '0'..'9') {
                    sb.append(arabicDigits[ch - '0'])
                } else {
                    sb.append(ch)
                }
            }
            return sb.toString()
        }

        private fun getHijriDateString(cal: Calendar, offsetDays: Int, useArabic: Boolean): String {
            val adjusted = cal.clone() as Calendar
            if (offsetDays != 0) {
                adjusted.add(Calendar.DAY_OF_YEAR, offsetDays)
            }
            val d = adjusted.get(Calendar.DAY_OF_MONTH)
            val m = adjusted.get(Calendar.MONTH)
            val y = adjusted.get(Calendar.YEAR)

            val jd = gregorianToJulianDay(y, m + 1, d)
            val (hYear, hMonth, hDay) = julianDayToHijri(jd)

            val hijriMonthNames = arrayOf(
                "محرم", "صفر", "ربيع الأول", "ربيع الآخر",
                "جمادى الأولى", "جمادى الآخرة", "رجب", "شعبان",
                "رمضان", "شوال", "ذو القعدة", "ذو الحجة"
            )
            val monthName = if (hMonth in 1..12) hijriMonthNames[hMonth - 1] else ""
            val raw = "$hDay $monthName $hYear هـ"
            return if (useArabic) toArabicNumbers(raw) else raw
        }

        private fun gregorianToJulianDay(year: Int, month: Int, day: Int): Double {
            var y = year
            var m = month
            if (m <= 2) {
                y -= 1
                m += 12
            }
            val a = (y / 100.0).toInt()
            val b = 2 - a + (a / 4.0).toInt()
            return (365.25 * (y + 4716)).toInt() + (30.6001 * (m + 1)).toInt() + day + b - 1524.5
        }

        private fun julianDayToHijri(jd: Double): Triple<Int, Int, Int> {
            val l = (jd - 1948440 + 10632).toInt()
            val n = ((l - 1) / 10631.0).toInt()
            val l2 = l - 10631 * n + 354
            val j = ((10985 - l2) / 5316.0).toInt() * ((50 * l2) / 17719.0).toInt() +
                    (l2 / 5670.0).toInt() * ((43 * l2) / 15238.0).toInt()
            val l3 = l2 - ((30 - j) / 15.0).toInt() * ((17719 * j) / 50.0).toInt() -
                    (j / 16.0).toInt() * ((15238 * j) / 43.0).toInt() + 29
            val m = ((24 * l3) / 709.0).toInt()
            val d = l3 - ((709 * m) / 24.0).toInt()
            val y = 30 * n + j - 30
            return Triple(y, m, d)
        }
    }
}
