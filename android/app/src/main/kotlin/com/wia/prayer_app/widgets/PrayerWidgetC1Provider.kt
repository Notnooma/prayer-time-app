package com.wia.prayer_app.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import com.wia.prayer_app.MainActivity
import com.wia.prayer_app.R

class PrayerWidgetC1Provider : AppWidgetProvider() {

    companion object {
        private const val TAG = "PrayerWidgetC1Provider"
        private const val ACTION_UPDATE = "com.wia.prayer_app.UPDATE_C1_WIDGET"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called with ${appWidgetIds.size} C1 widgets")
        
        // Update each widget instance
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
        
        // Schedule next update as backup
        if (appWidgetIds.isNotEmpty()) {
            PrayerWidgetUpdateManager.scheduleLiveUpdate(context, 10000L) // 10 seconds
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            ACTION_UPDATE -> {
                Log.d(TAG, "Received update action for C1 widget")
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, PrayerWidgetC1Provider::class.java)
                )
                Log.d(TAG, "Found ${appWidgetIds.size} C1 widgets to update")
                onUpdate(context, appWidgetManager, appWidgetIds)
                
                // Force notify widget manager of updates
                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_root)
            }
            Intent.ACTION_CONFIGURATION_CHANGED -> {
                Log.d(TAG, "Configuration changed - updating C1 widget theme")
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, PrayerWidgetC1Provider::class.java)
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
        Log.d(TAG, "Updating C1 widget $appWidgetId")
        
        // Create RemoteViews for the widget layout
        val views = RemoteViews(context.packageName, R.layout.widget_2x2_list)
        
        try {
            // Load prayer data and update widget
            val widgetData = PrayerDataManager.getPrayerWidgetData(context)
            
            // Update prayer status label
            views.setTextViewText(R.id.prayer_status_label, "Next prayer is ${widgetData.nextPrayerName}")
            
            // Update prayer indicator colors
            updatePrayerIndicators(views, widgetData.nextPrayerName)
            
            // Update prayer times
            views.setTextViewText(R.id.fajr_time, widgetData.fajrTime)
            views.setTextViewText(R.id.dhuhr_time, widgetData.dhuhrTime)
            views.setTextViewText(R.id.asr_time, widgetData.asrTime)
            // Determine next prayer to highlight
            val nextPrayer = widgetData.nextPrayerName
            
            // Update prayer indicators based on next prayer
            updatePrayerIndicators(views, nextPrayer)
            
            // Apply your existing dark theme (keeping what works!)
            applyDarkThemeWithGreenText(views)
            
            Log.d(TAG, "C1 Widget data updated: Next prayer is $nextPrayer")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error updating C1 widget: ${e.message}")
            // Show error state - reset all indicators to empty
            views.setTextViewText(R.id.fajr_indicator, "○")
            views.setTextViewText(R.id.dhuhr_indicator, "○")
            views.setTextViewText(R.id.asr_indicator, "○")
            views.setTextViewText(R.id.maghrib_indicator, "○")
            views.setTextViewText(R.id.isha_indicator, "○")
        }
        
        // Set click intent to open the app
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        
        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
        Log.d(TAG, "C1 Widget $appWidgetId updated successfully")
    }

    private fun updatePrayerIndicators(views: RemoteViews, nextPrayer: String) {
        // Reset all indicators to empty circles
        views.setTextViewText(R.id.fajr_indicator, "○")
        views.setTextViewText(R.id.dhuhr_indicator, "○")
        views.setTextViewText(R.id.asr_indicator, "○")
        views.setTextViewText(R.id.maghrib_indicator, "○")
        views.setTextViewText(R.id.isha_indicator, "○")
        
        // Set the next prayer to filled circle
        when (nextPrayer.lowercase()) {
            "fajr" -> views.setTextViewText(R.id.fajr_indicator, "●")
            "dhuhr" -> views.setTextViewText(R.id.dhuhr_indicator, "●")
            "asr" -> views.setTextViewText(R.id.asr_indicator, "●")
            "maghrib" -> views.setTextViewText(R.id.maghrib_indicator, "●")
            "isha" -> views.setTextViewText(R.id.isha_indicator, "●")
            else -> {
                // If no next prayer identified, keep all empty
                Log.d(TAG, "Unknown next prayer: $nextPrayer")
            }
        }
    }

    // Your existing dark theme method that works perfectly
    private fun applyDarkThemeWithGreenText(views: RemoteViews) {
        // Set dark background with green outline
        views.setInt(R.id.widget_root, "setBackgroundResource", R.drawable.widget_dark_green_outline)
        
        // Apply green color to all text elements
        val greenColor = android.graphics.Color.parseColor("#4CAF50")
        
        views.setTextColor(R.id.fajr_label, greenColor)
        views.setTextColor(R.id.fajr_time, greenColor)
        views.setTextColor(R.id.fajr_indicator, greenColor)
        
        views.setTextColor(R.id.dhuhr_label, greenColor)
        views.setTextColor(R.id.dhuhr_time, greenColor)
        views.setTextColor(R.id.dhuhr_indicator, greenColor)
        
        views.setTextColor(R.id.asr_label, greenColor)
        views.setTextColor(R.id.asr_time, greenColor)
        views.setTextColor(R.id.asr_indicator, greenColor)
        
        views.setTextColor(R.id.maghrib_label, greenColor)
        views.setTextColor(R.id.maghrib_time, greenColor)
        views.setTextColor(R.id.maghrib_indicator, greenColor)
        
        views.setTextColor(R.id.isha_label, greenColor)
        views.setTextColor(R.id.isha_time, greenColor)
        views.setTextColor(R.id.isha_indicator, greenColor)
    }

    override fun onEnabled(context: Context) {
        Log.d(TAG, "First C1 widget added - setting up updates")
        // Force immediate update first to prevent freeze
        PrayerWidgetUpdateManager.scheduleImmediateUpdate(context)
        // Then start periodic updates
        PrayerWidgetUpdateManager.startPeriodicUpdates(context)
    }

    override fun onDisabled(context: Context) {
        Log.d(TAG, "Last C1 widget removed - stopping updates")
        PrayerWidgetUpdateManager.stopPeriodicUpdates(context)
    }
}
