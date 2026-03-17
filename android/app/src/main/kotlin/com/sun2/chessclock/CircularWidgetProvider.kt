package com.sun2.chessclock

import android.view.View
import android.widget.RemoteViews

class CircularWidgetProvider : BaseDeadlineStyleProvider() {

    override fun getLayoutId() = R.layout.widget_layout_circular

    override fun bindViews(views: RemoteViews, task: TaskInfo?) {
        if (task == null) {
            views.setTextViewText(R.id.circular_task_name, "No deadlines")
            views.setTextViewText(R.id.circular_days, "–")
            views.setViewVisibility(R.id.circular_expired, View.GONE)
            return
        }

        views.setTextViewText(R.id.circular_task_name, task.name)

        if (task.isExpired) {
            views.setViewVisibility(R.id.circular_circle, View.INVISIBLE)
            views.setViewVisibility(R.id.circular_expired, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.circular_expired, View.GONE)
            views.setViewVisibility(R.id.circular_circle, View.VISIBLE)
            views.setTextViewText(R.id.circular_days, task.days.toString())
        }
    }
}
