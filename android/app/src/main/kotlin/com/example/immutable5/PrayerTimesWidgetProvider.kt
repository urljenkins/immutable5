package com.example.immutable5

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerTimesWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    companion object {
        // Theme color definitions matching Flutter
        private data class ThemeColors(
            val background: Int,
            val text: Int,
            val textSecondary: Int,
            val accent: Int,
            val cardBg: Int
        )

        private fun getThemeColors(themeIndex: Int): ThemeColors {
            return when (themeIndex) {
                0 -> ThemeColors( // Night Sky
                    background = 0xFF0F172A.toInt(),
                    text = 0xFFF8FAFC.toInt(),
                    textSecondary = 0xFFCBD5E1.toInt(),
                    accent = 0xFFD4AF37.toInt(),
                    cardBg = 0xFF1E293B.toInt()
                )
                1 -> ThemeColors( // Ocean Blue
                    background = 0xFF1A365D.toInt(),
                    text = 0xFFF8FAFC.toInt(),
                    textSecondary = 0xFFCBD5E1.toInt(),
                    accent = 0xFF38B2AC.toInt(),
                    cardBg = 0xFF2C5282.toInt()
                )
                2 -> ThemeColors( // Forest
                    background = 0xFF1A4731.toInt(),
                    text = 0xFFF8FAFC.toInt(),
                    textSecondary = 0xFFCBD5E1.toInt(),
                    accent = 0xFF10B981.toInt(),
                    cardBg = 0xFF22543D.toInt()
                )
                3 -> ThemeColors( // Light
                    background = 0xFFFFFFFF.toInt(),
                    text = 0xFF334155.toInt(),
                    textSecondary = 0xFF64748B.toInt(),
                    accent = 0xFF1E293B.toInt(),
                    cardBg = 0xFFF1F5F9.toInt()
                )
                4 -> ThemeColors( // Pure Dark
                    background = 0xFF000000.toInt(),
                    text = 0xFFFFFFFF.toInt(),
                    textSecondary = 0xFFA1A1AA.toInt(),
                    accent = 0xFFD4AF37.toInt(),
                    cardBg = 0xFF18181B.toInt()
                )
                else -> getThemeColors(0) // Default to Night Sky
            }
        }

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            widgetData: SharedPreferences
        ) {
            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)

            // Get theme
            val themeIndex = widgetData.getInt("theme_index", 0)
            val colors = getThemeColors(themeIndex)

            // Apply background color
            views.setInt(R.id.widget_container, "setBackgroundColor", colors.background)

            // Update location and Hijri date
            val locationName = widgetData.getString("location_name", "Current Location") ?: "Current Location"
            val hijriDate = widgetData.getString("hijri_date", "") ?: ""
            views.setTextViewText(R.id.location_name, locationName)
            views.setTextViewText(R.id.hijri_date, hijriDate)
            views.setTextColor(R.id.location_name, colors.text)
            views.setTextColor(R.id.hijri_date, colors.textSecondary)

            // Update next prayer countdown
            val nextPrayerName = widgetData.getString("next_prayer_name", "Loading...") ?: "Loading..."
            val countdownFormatted = widgetData.getString("countdown_formatted", "--:--") ?: "--:--"
            views.setTextViewText(R.id.next_prayer_label, "$nextPrayerName in")
            views.setTextViewText(R.id.countdown_formatted, countdownFormatted)
            views.setTextColor(R.id.next_prayer_label, colors.textSecondary)
            views.setTextColor(R.id.countdown_formatted, colors.accent)

            // Update divider color
            views.setInt(
                R.id.divider, "setBackgroundColor",
                Color.argb(
                    51,
                    Color.red(colors.textSecondary),
                    Color.green(colors.textSecondary),
                    Color.blue(colors.textSecondary)
                )
            )

            // Get prayer times
            val fajr = widgetData.getString("prayer_fajr", "--:--") ?: "--:--"
            val dhuhr = widgetData.getString("prayer_dhuhr", "--:--") ?: "--:--"
            val asr = widgetData.getString("prayer_asr", "--:--") ?: "--:--"
            val maghrib = widgetData.getString("prayer_maghrib", "--:--") ?: "--:--"
            val isha = widgetData.getString("prayer_isha", "--:--") ?: "--:--"

            // Update prayer times with colors
            updatePrayerColumn(views, R.id.label_fajr, R.id.prayer_fajr, "Fajr", fajr,
                nextPrayerName == "Fajr", colors)
            updatePrayerColumn(views, R.id.label_dhuhr, R.id.prayer_dhuhr, "Dhuhr", dhuhr,
                nextPrayerName == "Dhuhr", colors)
            updatePrayerColumn(views, R.id.label_asr, R.id.prayer_asr, "Asr", asr,
                nextPrayerName == "Asr", colors)
            updatePrayerColumn(views, R.id.label_maghrib, R.id.prayer_maghrib, "Maghrib", maghrib,
                nextPrayerName == "Maghrib", colors)
            updatePrayerColumn(views, R.id.label_isha, R.id.prayer_isha, "Isha", isha,
                nextPrayerName == "Isha", colors)

            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun updatePrayerColumn(
            views: RemoteViews,
            labelId: Int,
            timeId: Int,
            name: String,
            time: String,
            isNext: Boolean,
            colors: ThemeColors
        ) {
            views.setTextViewText(labelId, name)
            views.setTextViewText(timeId, time)

            if (isNext) {
                views.setTextColor(labelId, colors.accent)
                views.setTextColor(timeId, colors.accent)
            } else {
                views.setTextColor(labelId, colors.textSecondary)
                views.setTextColor(timeId, colors.text)
            }
        }
    }
}
