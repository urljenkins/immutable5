package com.example.immutable5

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class PrayerTimesWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }

    companion object {
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)

            // Update next prayer
            val nextPrayerName = widgetData.getString("next_prayer_name", "Loading...")
            val nextPrayerTime = widgetData.getString("next_prayer_time", "--:--")
            val timeRemaining = widgetData.getString("time_remaining", "")
            val lastUpdated = widgetData.getString("last_updated", "")

            views.setTextViewText(R.id.next_prayer_name, nextPrayerName)
            views.setTextViewText(R.id.next_prayer_time, nextPrayerTime)
            views.setTextViewText(R.id.time_remaining, "in $timeRemaining")
            views.setTextViewText(R.id.last_updated, lastUpdated)

            // Update all prayer times
            views.setTextViewText(
                R.id.prayer_fajr,
                widgetData.getString("prayer_fajr", "--:--")
            )
            views.setTextViewText(
                R.id.prayer_dhuhr,
                widgetData.getString("prayer_dhuhr", "--:--")
            )
            views.setTextViewText(
                R.id.prayer_asr,
                widgetData.getString("prayer_asr", "--:--")
            )
            views.setTextViewText(
                R.id.prayer_maghrib,
                widgetData.getString("prayer_maghrib", "--:--")
            )
            views.setTextViewText(
                R.id.prayer_isha,
                widgetData.getString("prayer_isha", "--:--")
            )

            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
