package com.sun2.chessclock

import android.view.View
import android.widget.RemoteViews

class BoldWidgetProvider : BaseDeadlineStyleProvider() {

    override fun getLayoutId() = R.layout.widget_layout_bold

    override fun bindViews(views: RemoteViews, task: TaskInfo?) {
        if (task == null) {
            views.setTextViewText(R.id.bold_task_name, "No deadlines")
            views.setViewVisibility(R.id.bold_days, View.INVISIBLE)
            views.setViewVisibility(R.id.bold_hours, View.INVISIBLE)
            views.setViewVisibility(R.id.bold_mins, View.INVISIBLE)
            views.setViewVisibility(R.id.bold_expired, View.GONE)
            return
        }

        views.setTextViewText(R.id.bold_task_name, task.name)

        if (task.isExpired) {
            views.setViewVisibility(R.id.bold_days, View.INVISIBLE)
            views.setViewVisibility(R.id.bold_hours, View.INVISIBLE)
            views.setViewVisibility(R.id.bold_mins, View.INVISIBLE)
            views.setViewVisibility(R.id.bold_expired, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.bold_expired, View.GONE)
            views.setViewVisibility(R.id.bold_days, View.VISIBLE)
            views.setViewVisibility(R.id.bold_hours, View.VISIBLE)
            views.setViewVisibility(R.id.bold_mins, View.VISIBLE)
            views.setTextViewText(R.id.bold_days, task.days.toString())
            views.setTextViewText(R.id.bold_hours, "${task.hours}h")
            views.setTextViewText(R.id.bold_mins, "${task.mins}m")
        }
    }
}
