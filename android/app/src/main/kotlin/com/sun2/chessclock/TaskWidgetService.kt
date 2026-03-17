package com.sun2.chessclock

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

class TaskWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TaskRemoteViewsFactory(this.applicationContext, intent)
    }
}

class TaskRemoteViewsFactory(
    private val context: Context,
    intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private val widgetId = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID
    )
    private var taskList = JSONArray()

    private val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val jsonString = prefs.getString("tasks", "[]") ?: "[]"
        val allTasks = JSONArray(jsonString)
        val now = System.currentTimeMillis()
        val filtered = JSONArray()

        for (i in 0 until allTasks.length()) {
            val task = allTasks.getJSONObject(i)
            if (task.optBoolean("isCompleted", false)) continue
            val deadline = parseDeadline(task)
            // Include active tasks + recently expired (≤5 min ago) so "EXPIRED" is briefly visible
            if (deadline > now || (now - deadline) < 300_000L) {
                filtered.put(task)
            }
        }
        taskList = filtered
    }

    override fun onDestroy() {}

    override fun getCount(): Int = taskList.length()

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.task_item)
        if (position >= taskList.length()) return views

        val task = taskList.getJSONObject(position)
        val name = task.optString("name", "Untitled")
        val deadline = parseDeadline(task)
        val diff = deadline - System.currentTimeMillis()

        views.setTextViewText(R.id.widget_item_task_name, name)

        if (diff > 0) {
            views.setTextViewText(R.id.widget_item_countdown, formatCountdown(diff))
            views.setTextColor(R.id.widget_item_countdown, 0xFFFF9800.toInt())
        } else {
            views.setTextViewText(R.id.widget_item_countdown, "EXPIRED")
            views.setTextColor(R.id.widget_item_countdown, 0xFFF44336.toInt())
        }

        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true

    private fun parseDeadline(task: JSONObject): Long {
        return try {
            dateFormat.parse(task.getString("deadline"))?.time ?: 0L
        } catch (e: Exception) { 0L }
    }

    private fun formatCountdown(diff: Long): String {
        if (diff <= 0) return "EXPIRED"
        val totalSecs = diff / 1000
        val days = totalSecs / 86400
        val hours = (totalSecs % 86400) / 3600
        val mins = (totalSecs % 3600) / 60
        val secs = totalSecs % 60
        return when {
            days > 0 -> "${days}d ${hours}h ${mins}m"
            hours > 0 -> "${hours}h ${mins}m"
            mins > 0 -> "${mins}m ${secs}s"
            else -> "${secs}s"
        }
    }
}
