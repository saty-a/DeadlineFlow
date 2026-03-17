package com.sun2.chessclock

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

data class TaskInfo(
    val name: String,
    val days: Long,
    val hours: Long,
    val mins: Long,
    val isExpired: Boolean
)

abstract class BaseDeadlineStyleProvider : HomeWidgetProvider() {

    abstract fun getLayoutId(): Int
    abstract fun bindViews(views: RemoteViews, task: TaskInfo?)

    private val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val task = getNearestTask(widgetData)
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, getLayoutId())
            bindViews(views, task)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
        scheduleNextUpdate(context, widgetData)
    }

    private fun getNearestTask(widgetData: SharedPreferences): TaskInfo? {
        val tasksJson = widgetData.getString("tasks", "[]") ?: "[]"
        val now = System.currentTimeMillis()
        var nearestTask: JSONObject? = null
        var nearestDeadline = Long.MAX_VALUE

        return try {
            val allTasks = JSONArray(tasksJson)
            for (i in 0 until allTasks.length()) {
                val task = allTasks.getJSONObject(i)
                if (task.optBoolean("isCompleted", false)) continue
                val deadlineMillis = parseDeadline(task)
                if (deadlineMillis in 1 until nearestDeadline) {
                    nearestDeadline = deadlineMillis
                    nearestTask = task
                }
            }

            nearestTask?.let { task ->
                val diff = nearestDeadline - now
                if (diff > 0) {
                    val totalSecs = diff / 1000
                    TaskInfo(
                        name = task.optString("name", "Untitled"),
                        days = totalSecs / 86400,
                        hours = (totalSecs % 86400) / 3600,
                        mins = (totalSecs % 3600) / 60,
                        isExpired = false
                    )
                } else if ((now - nearestDeadline) < 300_000L) {
                    // Show expired briefly for up to 5 min
                    TaskInfo(
                        name = task.optString("name", "Untitled"),
                        days = 0, hours = 0, mins = 0,
                        isExpired = true
                    )
                } else null
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun parseDeadline(task: JSONObject): Long {
        return try {
            dateFormat.parse(task.getString("deadline"))?.time ?: 0L
        } catch (e: Exception) { 0L }
    }

    private fun scheduleNextUpdate(context: Context, widgetData: SharedPreferences) {
        val tasksJson = widgetData.getString("tasks", "[]") ?: "[]"
        val now = System.currentTimeMillis()
        var nearestDeadline = Long.MAX_VALUE

        try {
            val allTasks = JSONArray(tasksJson)
            for (i in 0 until allTasks.length()) {
                val task = allTasks.getJSONObject(i)
                if (task.optBoolean("isCompleted", false)) continue
                val deadlineMillis = parseDeadline(task)
                if (deadlineMillis > now && deadlineMillis < nearestDeadline) {
                    nearestDeadline = deadlineMillis
                }
            }
        } catch (e: Exception) { return }

        if (nearestDeadline == Long.MAX_VALUE) return

        val timeToNearest = nearestDeadline - now
        val interval = when {
            timeToNearest <= 3_600_000L -> 60_000L
            timeToNearest <= 86_400_000L -> 300_000L
            else -> 1_800_000L
        }

        scheduleAlarm(context, now + interval, requestCode = 0)
        if (nearestDeadline < now + interval) {
            scheduleAlarm(context, nearestDeadline, requestCode = 1)
        }
    }

    private fun scheduleAlarm(context: Context, triggerAtMillis: Long, requestCode: Int) {
        try {
            val intent = Intent(context, this::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                val ids = AppWidgetManager.getInstance(context)
                    .getAppWidgetIds(ComponentName(context, this@BaseDeadlineStyleProvider::class.java))
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
        } catch (e: Exception) { /* ignore on restricted devices */ }
    }
}
