package com.sakina.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.util.TypedValue
import android.widget.RemoteViews
import com.sakina.app.MainActivity
import com.sakina.app.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.text.DateFormat

abstract class BaseWidget : AppWidgetProvider() {

    abstract val layoutId: Int
    abstract fun bind(context: Context, v: RemoteViews, d: WidgetData?)

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, build(context, id))
        SakinaTick.refresh(context)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: android.os.Bundle) {
        manager.updateAppWidget(id, build(context, id))
    }

    override fun onEnabled(context: Context) {
        SakinaTick.refresh(context)
    }

    open fun bindSized(context: Context, v: RemoteViews, d: WidgetData?, id: Int?) {
        bind(context, v, d)
    }

    fun build(context: Context, id: Int? = null): RemoteViews {
        val v = RemoteViews(context.packageName, layoutId)
        val open = PendingIntent.getActivity(
            context, 0,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        v.setOnClickPendingIntent(R.id.widget_root, open)
        bindSized(context, v, WidgetData.load(context), id)
        val colors = WidgetAppearance.load(context)
        if (this is WidgetSmall || this is WidgetClock || this is WidgetProgress || this is WidgetLarge) {
            v.setTextColor(R.id.w_name, colors.accent)
        }
        return v
    }

    fun updateAll(context: Context) {
        val mgr = AppWidgetManager.getInstance(context)
        val ids = mgr.getAppWidgetIds(ComponentName(context, this::class.java))
        if (ids.isEmpty()) return
        for (id in ids) mgr.updateAppWidget(id, build(context, id))
    }

    fun hasInstances(context: Context): Boolean =
        AppWidgetManager.getInstance(context)
            .getAppWidgetIds(ComponentName(context, this::class.java)).isNotEmpty()

    companion object {
        fun hm(context: Context, ts: Long): String = AppTimeFormat.format(context, ts)

        /** Live countdown with no refresh needed (platform Chronometer). */
        fun countdown(v: RemoteViews, id: Int, targetTs: Long) {
            val base = SystemClock.elapsedRealtime() + (targetTs - System.currentTimeMillis())
            v.setChronometerCountDown(id, true)
            v.setChronometer(id, base, null, true)
        }
    }
}

class WidgetSmall : BaseWidget() {
    override val layoutId = R.layout.widget_small
    override fun bind(context: Context, v: RemoteViews, d: WidgetData?) {
        val n = d?.next
        if (n == null) {
            v.setTextViewText(R.id.w_name, "افتح المؤذن لتحديث المواقيت")
            v.setTextViewText(R.id.w_time, "")
            return
        }
        v.setTextViewText(R.id.w_name, n.nameAr)
        v.setTextViewText(R.id.w_time, AppTimeFormat.compact(context, n.ts))
        countdown(v, R.id.w_count, n.ts)
    }
}

class WidgetClock : BaseWidget() {
    override val layoutId = R.layout.widget_clock
    override fun bind(context: Context, v: RemoteViews, d: WidgetData?) {
        val n = d?.next
        if (n == null) {
            v.setTextViewText(R.id.w_name, "المؤذن"); v.setTextViewText(R.id.w_time, "")
            return
        }
        v.setTextViewText(R.id.w_name, "الصلاة القادمة: " + n.nameAr)
        v.setTextViewText(R.id.w_time, hm(context, n.ts))
        countdown(v, R.id.w_count, n.ts)
    }
}

class WidgetProgress : BaseWidget() {
    override val layoutId = R.layout.widget_progress_card
    override fun bind(context: Context, v: RemoteViews, d: WidgetData?) {
        val n = d?.next
        v.setTextViewText(R.id.w_city, d?.city ?: "")
        if (n == null) {
            v.setTextViewText(R.id.w_name, "المؤذن"); v.setTextViewText(R.id.w_time, "--:--")
            v.setProgressBar(R.id.w_progress, 100, 0, false)
            return
        }
        v.setTextViewText(R.id.w_name, n.nameAr)
        v.setTextViewText(R.id.w_time, hm(context, n.ts))
        v.setProgressBar(R.id.w_progress, 100, d.progress, false)
        countdown(v, R.id.w_count, n.ts)
    }
}

class WidgetList : BaseWidget() {
    override val layoutId = R.layout.widget_list
    private val names = intArrayOf(R.id.n0, R.id.n1, R.id.n2, R.id.n3, R.id.n4)
    private val times = intArrayOf(R.id.t0, R.id.t1, R.id.t2, R.id.t3, R.id.t4)
    override fun bind(context: Context, v: RemoteViews, d: WidgetData?) {
        v.setTextViewText(R.id.w_city, d?.city ?: "")
        val list = d?.todayFive() ?: emptyList()
        val next = d?.next
        val colors = WidgetAppearance.load(context)
        v.setTextColor(R.id.w_next, colors.accent)
        v.setTextViewText(R.id.w_next, next?.let { "القادمة: ${it.nameAr}" }
            ?: "افتح المؤذن لتحديث المواقيت")
        if (next != null) countdown(v, R.id.w_count, next.ts)
        for (i in 0 until 5) {
            val p = list.getOrNull(i)
            v.setTextViewText(names[i], p?.nameAr ?: "")
            v.setTextViewText(times[i], if (p != null) hm(context, p.ts) else "")
            val isNext = p != null && next != null && p.ts == next.ts
            val color = if (isNext) colors.accent else 0xFFE8EFEC.toInt()
            v.setTextColor(names[i], color)
            v.setTextColor(times[i], color)
        }
    }
}

class WidgetStrip : BaseWidget() {
    override val layoutId = R.layout.widget_strip
    private val names = intArrayOf(R.id.n0, R.id.n1, R.id.n2, R.id.n3, R.id.n4)
    private val times = intArrayOf(R.id.t0, R.id.t1, R.id.t2, R.id.t3, R.id.t4)
    override fun bind(context: Context, v: RemoteViews, d: WidgetData?) {
        val list = d?.todayFive() ?: emptyList()
        val next = d?.next
        val colors = WidgetAppearance.load(context)
        for (i in 0 until 5) {
            val p = list.getOrNull(i)
            v.setTextViewText(names[i], p?.nameAr ?: "")
            v.setTextViewText(times[i], if (p != null) hm(context, p.ts) else "")
            val isNext = p != null && next != null && p.ts == next.ts
            v.setTextColor(names[i], if (isNext) colors.accent else 0xFF9DB0AA.toInt())
            v.setTextColor(times[i], if (isNext) colors.accent else 0xFFE8EFEC.toInt())
        }
    }
}

class WidgetLarge : BaseWidget() {
    override val layoutId = R.layout.widget_large
    private val names = intArrayOf(R.id.n0, R.id.n1, R.id.n2, R.id.n3, R.id.n4)
    private val times = intArrayOf(R.id.t0, R.id.t1, R.id.t2, R.id.t3, R.id.t4)

    override fun bind(context: Context, v: RemoteViews, d: WidgetData?) {
        val next = d?.next
        val colors = WidgetAppearance.load(context)
        v.setTextViewText(R.id.w_city, d?.city?.ifEmpty { "المؤذن" } ?: "المؤذن")
        v.setTextViewText(R.id.w_name, next?.nameAr ?: "افتح المؤذن لتحديث المواقيت")
        v.setTextViewText(R.id.w_time, next?.let { hm(context, it.ts) } ?: "")
        v.setProgressBar(R.id.w_progress, 100, d?.progress ?: 0, false)
        if (next != null) countdown(v, R.id.w_count, next.ts)
        val prayers = d?.todayFive() ?: emptyList()
        for (i in names.indices) {
            val prayer = prayers.getOrNull(i)
            v.setTextViewText(names[i], prayer?.nameAr ?: "")
            v.setTextViewText(times[i], prayer?.let { hm(context, it.ts) } ?: "")
            val color = if (prayer != null && prayer.ts == next?.ts) colors.accent
                else 0xFFE8EFEC.toInt()
            v.setTextColor(names[i], color)
            v.setTextColor(times[i], color)
        }
    }
}

class WidgetCircle : BaseWidget() {
    override val layoutId = R.layout.widget_circle
    override fun bind(context: Context, v: RemoteViews, d: WidgetData?) = bindSized(context, v, d, null)

    override fun bindSized(context: Context, v: RemoteViews, d: WidgetData?, id: Int?) {
        val colors = WidgetAppearance.load(context)
        val options = id?.let { AppWidgetManager.getInstance(context).getAppWidgetOptions(it) }
        val widthDp = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 140) ?: 140
        val heightDp = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 140) ?: 140
        val diameter = (minOf(widthDp, heightDp).coerceIn(120, 380) * context.resources.displayMetrics.density).toInt()
        v.setInt(R.id.w_ring, "setBackgroundResource", 0)
        v.setImageViewBitmap(R.id.w_ring, WidgetArtwork.ring(diameter, d?.progress ?: 0, colors))
        val scale = (minOf(widthDp, heightDp) / 140f).coerceIn(1f, 2.1f)
        v.setTextViewTextSize(R.id.w_clock, TypedValue.COMPLEX_UNIT_SP, 27f * scale)
        v.setTextViewTextSize(R.id.w_name, TypedValue.COMPLEX_UNIT_SP, 14f * scale)
        v.setTextViewTextSize(R.id.w_time, TypedValue.COMPLEX_UNIT_SP, 12f * scale)
        v.setTextViewTextSize(R.id.w_date, TypedValue.COMPLEX_UNIT_SP, 10f * scale)
        v.setTextViewTextSize(R.id.w_count, TypedValue.COMPLEX_UNIT_SP, 14f * scale)
        v.setTextColor(R.id.w_clock, colors.foreground)
        v.setTextColor(R.id.w_date, colors.muted)
        v.setTextColor(R.id.w_name, colors.accent)
        v.setTextColor(R.id.w_time, colors.foreground)
        v.setTextColor(R.id.w_count, colors.muted)
        v.setTextViewText(R.id.w_clock, AppTimeFormat.compact(context, System.currentTimeMillis()))
        v.setTextViewText(R.id.w_date, DateFormat.getDateInstance(DateFormat.MEDIUM, Locale("ar"))
            .format(Date()))
        val n = d?.next
        v.setTextViewText(R.id.w_name, n?.nameAr ?: "الصلاة القادمة")
        v.setTextViewText(R.id.w_time, n?.let { AppTimeFormat.compact(context, it.ts) }
            ?: "افتح المؤذن")
        if (n != null) countdown(v, R.id.w_count, n.ts)
        else v.setTextViewText(R.id.w_count, "")
    }
}

class WidgetBanner : BaseWidget() {
    override val layoutId = R.layout.widget_banner
    override fun bind(context: Context, v: RemoteViews, d: WidgetData?) = bindSized(context, v, d, null)

    override fun bindSized(context: Context, v: RemoteViews, d: WidgetData?, id: Int?) {
        val colors = WidgetAppearance.load(context)
        val options = id?.let { AppWidgetManager.getInstance(context).getAppWidgetOptions(it) }
        val widthDp = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 290) ?: 290
        val heightDp = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 64) ?: 64
        v.setInt(R.id.w_background, "setBackgroundResource", 0)
        v.setImageViewBitmap(R.id.w_background, WidgetArtwork.background(
            (widthDp * context.resources.displayMetrics.density).toInt(),
            (heightDp * context.resources.displayMetrics.density).toInt(), colors))
        v.setImageViewBitmap(R.id.w_bar, WidgetArtwork.bar(
            (widthDp * context.resources.displayMetrics.density).toInt(), d?.progress ?: 0, colors))
        v.setTextColor(R.id.w_clock, colors.foreground)
        v.setTextColor(R.id.w_next, colors.accent)
        v.setTextColor(R.id.w_time, colors.foreground)
        v.setTextColor(R.id.w_count, colors.muted)
        v.setTextColor(R.id.w_date, colors.muted)
        v.setTextViewText(R.id.w_clock, AppTimeFormat.compact(context, System.currentTimeMillis()))
        v.setTextViewText(R.id.w_date, DateFormat.getDateInstance(DateFormat.MEDIUM, Locale("ar"))
            .format(Date()))
        val n = d?.next
        v.setTextViewText(R.id.w_next, n?.nameAr ?: "الصلاة القادمة")
        v.setTextViewText(R.id.w_time, n?.let { AppTimeFormat.compact(context, it.ts) }
            ?: "افتح المؤذن")
        if (n != null) countdown(v, R.id.w_count, n.ts)
        else v.setTextViewText(R.id.w_count, "")
    }
}
