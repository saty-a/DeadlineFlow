package com.sun2.chessclock

import android.view.View
import android.widget.RemoteViews

class TickerWidgetProvider : BaseDeadlineStyleProvider() {

    override fun getLayoutId() = R.layout.widget_layout_ticker

    override fun bindViews(views: RemoteViews, task: TaskInfo?) {
        if (task == null) {
            views.setTextViewText(R.id.ticker_task_name, "No deadlines")
            views.setTextViewText(R.id.ticker_days, "--")
            views.setTextViewText(R.id.ticker_hours, "--")
            views.setTextViewText(R.id.ticker_mins, "--")
            views.setViewVisibility(R.id.ticker_expired, View.GONE)
            return
        }

        views.setTextViewText(R.id.ticker_task_name, task.name)

        if (task.isExpired) {
            views.setViewVisibility(R.id.ticker_expired, View.VISIBLE)
            views.setTextViewText(R.id.ticker_days, "--")
            views.setTextViewText(R.id.ticker_hours, "--")
            views.setTextViewText(R.id.ticker_mins, "--")
        } else {
            views.setViewVisibility(R.id.ticker_expired, View.GONE)
            views.setTextViewText(R.id.ticker_days, task.days.toString().padStart(2, '0'))
            views.setTextViewText(R.id.ticker_hours, task.hours.toString().padStart(2, '0'))
            views.setTextViewText(R.id.ticker_mins, task.mins.toString().padStart(2, '0'))
        }
    }
}
