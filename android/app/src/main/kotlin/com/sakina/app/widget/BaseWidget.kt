package com.sakina.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.widget.RemoteViews
import com.sakina.app.MainActivity
import com.sakina.app.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

abstract class BaseWidget : AppWidgetProvider() {

    abstract val layoutId: Int
    abstract fun bind(context: Context, v: RemoteViews, d: WidgetData?)

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, build(context))
        SakinaTick.refresh(context)
    }

    override fun onEnabled(context: Context) {
        SakinaTick.refresh(context)
    }

    fun build(context: Context): RemoteViews {
        val v = RemoteViews(context.packageName, layoutId)
        val open = PendingIntent.getActivity(
            context, 0,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        v.setOnClickPendingIntent(R.id.widget_root, open)
        bind(context, v, WidgetData.load(context))
        return v
    }

    fun updateAll(context: Context) {
        val mgr = AppWidgetManager.getInstance(context)
        val ids = mgr.getAppWidgetIds(ComponentName(context, this::class.java))
        if (ids.isEmpty()) return
        mgr.updateAppWidget(ids, build(context))
    }

    fun hasInstances(context: Context): Boolean =
        AppWidgetManager.getInstance(context)
            .getAppWidgetIds(ComponentName(context, this::class.java)).isNotEmpty()

    companion object {
        fun hm(ts: Long): String = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(ts))

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
            v.setTextViewText(R.id.w_name, "سكينة"); v.setTextViewText(R.id.w_time, "--:--")
            return
        }
        v.setTextViewText(R.id.w_name, n.nameAr)
        v.setTextViewText(R.id.w_time, hm(n.ts))
        countdown(v, R.id.w_count, n.ts)
    }
}

class WidgetClock : BaseWidget() {
    override val layoutId = R.layout.widget_clock
    override fun bind(context: Context, v: RemoteViews, d: WidgetData?) {
        val n = d?.next
        if (n == null) {
            v.setTextViewText(R.id.w_name, "سكينة"); v.setTextViewText(R.id.w_time, "")
            return
        }
        v.setTextViewText(R.id.w_name, "الصلاة القادمة: " + n.nameAr)
        v.setTextViewText(R.id.w_time, hm(n.ts))
        countdown(v, R.id.w_count, n.ts)
    }
}

class WidgetProgress : BaseWidget() {
    override val layoutId = R.layout.widget_progress_card
    override fun bind(context: Context, v: RemoteViews, d: WidgetData?) {
        val n = d?.next
        v.setTextViewText(R.id.w_city, d?.city ?: "")
        if (n == null) {
            v.setTextViewText(R.id.w_name, "سكينة"); v.setTextViewText(R.id.w_time, "--:--")
            v.setProgressBar(R.id.w_progress, 100, 0, false)
            return
        }
        v.setTextViewText(R.id.w_name, n.nameAr)
        v.setTextViewText(R.id.w_time, hm(n.ts))
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
        for (i in 0 until 5) {
            val p = list.getOrNull(i)
            v.setTextViewText(names[i], p?.nameAr ?: "")
            v.setTextViewText(times[i], if (p != null) hm(p.ts) else "")
            val isNext = p != null && next != null && p.ts == next.ts
            val color = if (isNext) 0xFF5FB59B.toInt() else 0xFFE8EFEC.toInt()
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
        for (i in 0 until 5) {
            val p = list.getOrNull(i)
            v.setTextViewText(names[i], p?.nameAr ?: "")
            v.setTextViewText(times[i], if (p != null) hm(p.ts) else "")
            val isNext = p != null && next != null && p.ts == next.ts
            v.setTextColor(names[i], if (isNext) 0xFF5FB59B.toInt() else 0xFF9DB0AA.toInt())
            v.setTextColor(times[i], if (isNext) 0xFF5FB59B.toInt() else 0xFFE8EFEC.toInt())
        }
    }
}
