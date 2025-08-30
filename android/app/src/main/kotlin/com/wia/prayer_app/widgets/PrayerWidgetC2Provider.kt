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

class PrayerWidgetC2Provider : AppWidgetProvider() {

    companion object {
        private const val TAG = "PrayerWidgetC2Provider"
        private const val ACTION_UPDATE = "com.wia.prayer_app.UPDATE_C2_WIDGET"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called with ${appWidgetIds.size} C2 widgets")
        
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
                Log.d(TAG, "Received update action for C2 widget")
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, PrayerWidgetC2Provider::class.java)
                )
                Log.d(TAG, "Found ${appWidgetIds.size} C2 widgets to update")
                onUpdate(context, appWidgetManager, appWidgetIds)
                
                // Force notify widget manager of updates
                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_root)
            }
            Intent.ACTION_CONFIGURATION_CHANGED -> {
                Log.d(TAG, "Configuration changed - updating C2 widget theme")
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, PrayerWidgetC2Provider::class.java)
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
        Log.d(TAG, "Updating C2 widget $appWidgetId")
        
        // Create RemoteViews for the widget layout
        val views = RemoteViews(context.packageName, R.layout.widget_2x2_focus)
        
        try {
            // Load prayer data and update widget
            val widgetData = PrayerDataManager.getPrayerWidgetData(context)
            
            // Get prayer data for 2x2 focus widget
            val nextPrayerTime = when (widgetData.nextPrayerName.lowercase()) {
                "fajr" -> widgetData.fajrTime
                "dhuhr" -> widgetData.dhuhrTime
                "asr" -> widgetData.asrTime
                "maghrib" -> widgetData.maghribTime
                "isha" -> widgetData.ishaTime
                else -> "00:00"
            }
            
            // Clean countdown text - remove "until [prayer]" and just show the time
            val cleanCountdownText = if (widgetData.countdownText.contains(" until ")) {
                widgetData.countdownText.split(" until ")[0]
            } else {
                widgetData.countdownText
            }
            
            // Update prayer status and current prayer info
            views.setTextViewText(R.id.prayer_status_label, "Next Prayer")
            views.setTextViewText(R.id.current_prayer_name, widgetData.nextPrayerName)
            views.setTextViewText(R.id.current_prayer_time, nextPrayerTime)
            views.setTextViewText(R.id.countdown_time, cleanCountdownText)
            
            // Apply your existing dark theme (keeping what works!)
            applyDarkThemeWithGreenText(views)
            
            Log.d(TAG, "C2 Widget data updated: Next Prayer - ${widgetData.nextPrayerName} at $nextPrayerTime")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error updating C2 widget: ${e.message}")
            // Show error state
            views.setTextViewText(R.id.prayer_status_label, "Prayer Times")
            views.setTextViewText(R.id.current_prayer_name, "Loading...")
            views.setTextViewText(R.id.current_prayer_time, "--:--")
            views.setTextViewText(R.id.countdown_time, "--:--")
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
        Log.d(TAG, "C2 Widget $appWidgetId updated successfully")
    }

    // Your existing dark theme method that works perfectly
    private fun applyDarkThemeWithGreenText(views: RemoteViews) {
        // Set dark background with green outline
        views.setInt(R.id.widget_root, "setBackgroundResource", R.drawable.widget_dark_green_outline)
        
        // Apply green color to all text elements
        val greenColor = android.graphics.Color.parseColor("#4CAF50")
        
        views.setTextColor(R.id.prayer_status_label, greenColor)
        views.setTextColor(R.id.current_prayer_name, greenColor)
        views.setTextColor(R.id.current_prayer_time, greenColor)
        views.setTextColor(R.id.countdown_prefix, greenColor)
        views.setTextColor(R.id.countdown_time, greenColor)
    }

    override fun onEnabled(context: Context) {
        Log.d(TAG, "First C2 widget added - setting up updates")
        // Force immediate update first to prevent freeze
        PrayerWidgetUpdateManager.scheduleImmediateUpdate(context)
        // Then start periodic updates
        PrayerWidgetUpdateManager.startPeriodicUpdates(context)
    }

    override fun onDisabled(context: Context) {
        Log.d(TAG, "Last C2 widget removed - stopping updates")
        PrayerWidgetUpdateManager.stopPeriodicUpdates(context)
    }
}
