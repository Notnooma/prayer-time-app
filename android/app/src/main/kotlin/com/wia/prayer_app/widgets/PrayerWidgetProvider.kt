package com.wia.prayer_app.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.widget.RemoteViews
import com.wia.prayer_app.R

class PrayerWidgetProvider : AppWidgetProvider() {
    
    companion object {
        private const val TAG = "PrayerWidgetProvider"
        private const val WIDGET_PREFS = "prayer_widget_prefs"
        private const val ACTION_UPDATE = "com.wia.prayer_app.UPDATE_WIDGET"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update each widget instance
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
        
        // Schedule next update as backup (in case repeating alarm fails)
        if (appWidgetIds.isNotEmpty()) {
            PrayerWidgetUpdateManager.scheduleLiveUpdate(context, 10000L) // 10 seconds
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            ACTION_UPDATE -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, PrayerWidgetProvider::class.java)
                )
                onUpdate(context, appWidgetManager, appWidgetIds)
                
                // Force notify widget manager of updates
                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.countdown_timer)
            }
            "com.wia.prayer_app.UPDATE_WIDGET_COUNTDOWN" -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, PrayerWidgetProvider::class.java)
                )
                onUpdate(context, appWidgetManager, appWidgetIds)
                
                // Schedule next 1-second update
                PrayerWidgetUpdateManager.scheduleCountdownUpdate(context)
            }
            Intent.ACTION_CONFIGURATION_CHANGED -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, PrayerWidgetProvider::class.java)
                )
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Create RemoteViews for the widget layout
        val views = RemoteViews(context.packageName, R.layout.widget_4x1_horizontal)
        
        try {
            // Load prayer data and update widget
            val widgetData = PrayerDataManager.getPrayerWidgetData(context)
            
            // Update prayer times
            views.setTextViewText(R.id.fajr_time, widgetData.fajrTime)
            views.setTextViewText(R.id.dhuhr_time, widgetData.dhuhrTime)
            views.setTextViewText(R.id.asr_time, widgetData.asrTime)
            views.setTextViewText(R.id.maghrib_time, widgetData.maghribTime)
            views.setTextViewText(R.id.isha_time, widgetData.ishaTime)
            
            // Update countdown timer
            views.setTextViewText(R.id.countdown_timer, widgetData.countdownText)
            
            // Apply your existing dark theme (keeping what works!)
            applyDarkThemeWithGreenText(views)
            
        } catch (e: Exception) {
            // Show error state
            views.setTextViewText(R.id.countdown_timer, "Prayer times unavailable")
        }
        
        // Set click intent to open the app
        val intent = Intent(context, com.wia.prayer_app.MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        
        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun isSystemInDarkMode(context: Context): Boolean {
        val nightModeFlags = context.resources.configuration.uiMode and 
                android.content.res.Configuration.UI_MODE_NIGHT_MASK
        return nightModeFlags == android.content.res.Configuration.UI_MODE_NIGHT_YES
    }

    override fun onEnabled(context: Context) {
        // Force immediate update first to prevent freeze
        PrayerWidgetUpdateManager.scheduleImmediateUpdate(context)
        // Then start periodic updates
        PrayerWidgetUpdateManager.startPeriodicUpdates(context)
        // Start 1-second countdown updates for Widget A
        PrayerWidgetUpdateManager.scheduleCountdownUpdate(context)
    }

    override fun onDisabled(context: Context) {
        PrayerWidgetUpdateManager.stopPeriodicUpdates(context)
        PrayerWidgetUpdateManager.stopCountdownUpdate(context)
    }

    // Your existing dark theme method that works perfectly
    private fun applyDarkThemeWithGreenText(views: RemoteViews) {
        // Set dark background with green outline
        views.setInt(R.id.widget_root, "setBackgroundResource", R.drawable.widget_dark_green_outline)
        
        // Apply green color to all text elements
        val greenColor = android.graphics.Color.parseColor("#4CAF50")
        
        views.setTextColor(R.id.fajr_time, greenColor)
        views.setTextColor(R.id.dhuhr_time, greenColor)
        views.setTextColor(R.id.asr_time, greenColor)
        views.setTextColor(R.id.maghrib_time, greenColor)
        views.setTextColor(R.id.isha_time, greenColor)
        views.setTextColor(R.id.countdown_timer, greenColor)
    }
}
