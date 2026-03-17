package com.sun2.chessclock

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val intent = android.content.Intent(context, TaskWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    data = Uri.parse(toUri(android.content.Intent.URI_INTENT_SCHEME))
                }
                setRemoteAdapter(R.id.widget_list_view, intent)
                appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_list_view)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
        scheduleNextUpdate(context, widgetData)
    }

    private fun scheduleNextUpdate(context: Context, widgetData: SharedPreferences) {
        val tasksJson = widgetData.getString("tasks", "[]") ?: "[]"
        val now = System.currentTimeMillis()
        var nearestDeadline = Long.MAX_VALUE

        val format = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US)
        format.timeZone = java.util.TimeZone.getTimeZone("UTC")

        try {
            val allTasks = org.json.JSONArray(tasksJson)
            for (i in 0 until allTasks.length()) {
                val task = allTasks.getJSONObject(i)
                if (task.optBoolean("isCompleted", false)) continue
                val deadlineMillis = try { format.parse(task.getString("deadline"))?.time ?: 0L } catch (e: Exception) { 0L }
                if (deadlineMillis > now && deadlineMillis < nearestDeadline) {
                    nearestDeadline = deadlineMillis
                }
            }
        } catch (e: Exception) { return }

        if (nearestDeadline == Long.MAX_VALUE) return

        val timeToNearest = nearestDeadline - now
        // Periodic refresh interval based on urgency
        val interval = when {
            timeToNearest <= 3_600_000L -> 60_000L       // every 1 min when < 1 hour
            timeToNearest <= 86_400_000L -> 300_000L      // every 5 min when < 24 hours
            else -> 1_800_000L                             // every 30 min otherwise
        }

        val periodicTrigger = now + interval
        scheduleAlarm(context, periodicTrigger, requestCode = 0)

        // Also fire exactly at the deadline so widget flips to EXPIRED immediately
        if (nearestDeadline < periodicTrigger) {
            scheduleAlarm(context, nearestDeadline, requestCode = 1)
        }
    }

    private fun scheduleAlarm(context: Context, triggerAtMillis: Long, requestCode: Int) {
        try {
            val intent = android.content.Intent(context, HomeWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                val ids = AppWidgetManager.getInstance(context).getAppWidgetIds(
                    android.content.ComponentName(context, HomeWidgetProvider::class.java)
                )
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                addFlags(android.content.Intent.FLAG_RECEIVER_FOREGROUND)
            }
            val pendingIntent = android.app.PendingIntent.getBroadcast(
                context, requestCode, intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            alarmManager.setExactAndAllowWhileIdle(
                android.app.AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent
            )
        } catch (e: Exception) {
            // Ignore SecurityException on restricted devices
        }
    }
}
