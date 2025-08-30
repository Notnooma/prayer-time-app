package com.wia.prayer_app.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.util.Log
import android.widget.RemoteViews
import com.wia.prayer_app.MainActivity
import com.wia.prayer_app.R

class PrayerWidget2x2Provider : AppWidgetProvider() {

    companion object {
        private const val TAG = "PrayerWidget2x2Provider"
        private const val WIDGET_PREFS = "prayer_widget_2x2_prefs"
        private const val ACTION_UPDATE = "com.wia.prayer_app.UPDATE_2X2_WIDGET"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called with ${appWidgetIds.size} 2x2 widgets")
        
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
                Log.d(TAG, "Received update action for 2x2 widget")
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    android.content.ComponentName(context, PrayerWidget2x2Provider::class.java)
                )
                Log.d(TAG, "Found ${appWidgetIds.size} 2x2 widgets to update")
                onUpdate(context, appWidgetManager, appWidgetIds)
                
                // Force notify widget manager of updates
                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.countdown_timer)
            }
            Intent.ACTION_CONFIGURATION_CHANGED -> {
                Log.d(TAG, "Configuration changed - updating 2x2 widget theme")
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    android.content.ComponentName(context, PrayerWidget2x2Provider::class.java)
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
        Log.d(TAG, "Updating 2x2 widget $appWidgetId")
        
        // Create RemoteViews for the widget layout
        val views = RemoteViews(context.packageName, R.layout.widget_2x2_square)
        
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
            
            Log.d(TAG, "2x2 Widget data updated: ${widgetData.countdownText}")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error updating 2x2 widget: ${e.message}")
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
        Log.d(TAG, "2x2 Widget $appWidgetId updated successfully")
    }

    private fun isSystemInDarkMode(context: Context): Boolean {
        return (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
    }

    override fun onEnabled(context: Context) {
        Log.d(TAG, "First 2x2 widget added - setting up updates")
        // Force immediate update first to prevent freeze
        PrayerWidgetUpdateManager.scheduleImmediateUpdate(context)
        // Then start periodic updates
        PrayerWidgetUpdateManager.startPeriodicUpdates(context)
    }

    override fun onDisabled(context: Context) {
        Log.d(TAG, "Last 2x2 widget removed - stopping updates")
        PrayerWidgetUpdateManager.stopPeriodicUpdates(context)
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
