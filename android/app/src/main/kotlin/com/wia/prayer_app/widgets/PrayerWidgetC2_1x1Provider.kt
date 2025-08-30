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

class PrayerWidgetC2_1x1Provider : AppWidgetProvider() {

    companion object {
        private const val TAG = "PrayerWidgetC2_1x1Provider"
        private const val ACTION_UPDATE = "com.wia.prayer_app.UPDATE_C2_1X1_WIDGET"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called with ${appWidgetIds.size} C2 1x1 widgets")
        
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
                Log.d(TAG, "Received update action for C2 1x1 widget")
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    android.content.ComponentName(context, PrayerWidgetC2_1x1Provider::class.java)
                )
                Log.d(TAG, "Found ${appWidgetIds.size} C2 1x1 widgets to update")
                onUpdate(context, appWidgetManager, appWidgetIds)
                
                // Force notify widget manager of updates
                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_root)
            }
            Intent.ACTION_CONFIGURATION_CHANGED -> {
                Log.d(TAG, "Configuration changed - updating C2 1x1 widget theme")
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    android.content.ComponentName(context, PrayerWidgetC2_1x1Provider::class.java)
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
        Log.d(TAG, "Updating C2 1x1 widget $appWidgetId")
        
        // Create RemoteViews for the widget layout
        val views = RemoteViews(context.packageName, R.layout.widget_1x1_focus)
        
        try {
            // Load prayer data and update widget
            val widgetData = PrayerDataManager.getPrayerWidgetData(context)
            
            // Get compact prayer data for 1x1 widget
            val (prayerName, prayerTime, countdownText) = getCompactPrayerData(widgetData)
            
            // Update the widget content
            views.setTextViewText(R.id.next_prayer_label, "Next Prayer")
            views.setTextViewText(R.id.current_prayer_name, prayerName)
            views.setTextViewText(R.id.prayer_time, prayerTime)
            views.setTextViewText(R.id.countdown_time, countdownText)
            
            // Apply theme based on app preference
            // Apply your existing dark theme (keeping what works!)
            applyDarkThemeWithGreenText(views)
            
            Log.d(TAG, "C2 1x1 Widget data updated: Next Prayer - $prayerName at $prayerTime - $countdownText")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error updating C2 1x1 widget: ${e.message}")
            // Show error state
            views.setTextViewText(R.id.next_prayer_label, "Next Prayer")
            views.setTextViewText(R.id.current_prayer_name, "Prayer")
            views.setTextViewText(R.id.prayer_time, "--:--")
            views.setTextViewText(R.id.countdown_time, "in --:--")
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
        Log.d(TAG, "C2 1x1 Widget $appWidgetId updated successfully")
    }

    private fun getCompactPrayerData(widgetData: PrayerDataManager.PrayerWidgetData): Array<String> {
        // Extract just the time from countdown (remove "until [prayer]" text)
        val countdownText = widgetData.countdownText
        val timeOnly = countdownText.split(" until ")[0]
        
        // Get the prayer time for the next prayer
        val nextPrayerTime = when (widgetData.nextPrayerName.lowercase()) {
            "fajr" -> widgetData.fajrTime
            "dhuhr" -> widgetData.dhuhrTime
            "asr" -> widgetData.asrTime
            "maghrib" -> widgetData.maghribTime
            "isha" -> widgetData.ishaTime
            else -> "00:00"
        }
        
        return arrayOf(
            widgetData.nextPrayerName,
            nextPrayerTime,
            "in $timeOnly"
        )
    }

    override fun onEnabled(context: Context) {
        Log.d(TAG, "First C2 1x1 widget added - setting up updates")
        // Force immediate update first to prevent freeze
        PrayerWidgetUpdateManager.scheduleImmediateUpdate(context)
        // Then start periodic updates
        PrayerWidgetUpdateManager.startPeriodicUpdates(context)
    }

    override fun onDisabled(context: Context) {
        Log.d(TAG, "Last C2 1x1 widget removed - stopping updates")
        PrayerWidgetUpdateManager.stopPeriodicUpdates(context)
    }

    // Your existing dark theme method that works perfectly
    private fun applyDarkThemeWithGreenText(views: RemoteViews) {
        // Set dark background with green outline
        views.setInt(R.id.widget_root, "setBackgroundResource", R.drawable.widget_dark_green_outline)
        
        // Apply green color to all text elements
        val greenColor = android.graphics.Color.parseColor("#4CAF50")
        
        views.setTextColor(R.id.next_prayer_label, greenColor)
        views.setTextColor(R.id.current_prayer_name, greenColor)
        views.setTextColor(R.id.prayer_time, greenColor)
        views.setTextColor(R.id.countdown_time, greenColor)
    }
}
