package com.sun2.chessclock

import android.view.View
import android.widget.RemoteViews

class MinimalWidgetProvider : BaseDeadlineStyleProvider() {

    override fun getLayoutId() = R.layout.widget_layout_minimal

    override fun bindViews(views: RemoteViews, task: TaskInfo?) {
        if (task == null) {
            views.setTextViewText(R.id.minimal_task_name, "No deadlines")
            views.setTextViewText(R.id.minimal_days, "–")
            views.setTextViewText(R.id.minimal_time, "")
            views.setViewVisibility(R.id.minimal_expired, View.GONE)
            return
        }

        views.setTextViewText(R.id.minimal_task_name, task.name)

        if (task.isExpired) {
            views.setViewVisibility(R.id.minimal_days, View.GONE)
            views.setViewVisibility(R.id.minimal_time, View.GONE)
            views.setViewVisibility(R.id.minimal_expired, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.minimal_expired, View.GONE)
            views.setViewVisibility(R.id.minimal_days, View.VISIBLE)
            views.setViewVisibility(R.id.minimal_time, View.VISIBLE)
            views.setTextViewText(R.id.minimal_days, task.days.toString())
            views.setTextViewText(R.id.minimal_time, "${task.hours} hrs  ${task.mins} mins")
        }
    }
}
