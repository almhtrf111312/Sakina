package com.sakina.app.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import com.sakina.app.R

internal object WidgetPinning {
    private data class Item(val title: String, val provider: Class<*>, val preview: Int)

    private val items = mapOf(
        "small" to Item("الصلاة القادمة", WidgetSmall::class.java, R.drawable.preview_small),
        "clock" to Item("الساعة والمواقيت", WidgetClock::class.java, R.drawable.preview_clock),
        "progress" to Item("بطاقة التقدّم", WidgetProgress::class.java, R.drawable.preview_progress),
        "list" to Item("جدول الصلوات", WidgetList::class.java, R.drawable.preview_list),
        "circle" to Item("الساعة الدائرية", WidgetCircle::class.java, R.drawable.preview_circle),
        "banner" to Item("الشريط الأفقي", WidgetBanner::class.java, R.drawable.preview_banner)
    )

    fun catalogue(context: Context): List<Map<String, Any>> {
        val manager = AppWidgetManager.getInstance(context)
        val supported = Build.VERSION.SDK_INT >= 26 && manager.isRequestPinAppWidgetSupported
        return items.map { (id, item) ->
            mapOf(
                "id" to id,
                "title" to item.title,
                "preview" to context.resources.openRawResource(item.preview).use { it.readBytes() },
                "canPin" to supported
            )
        }
    }

    fun request(context: Context, id: String?): Boolean {
        if (Build.VERSION.SDK_INT < 26) return false
        val item = items[id ?: return false] ?: return false
        val manager = AppWidgetManager.getInstance(context)
        return manager.isRequestPinAppWidgetSupported &&
            manager.requestPinAppWidget(ComponentName(context, item.provider), null, null)
    }
}
