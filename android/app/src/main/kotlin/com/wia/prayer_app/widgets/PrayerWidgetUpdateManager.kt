package com.wia.prayer_app.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.util.Log

object PrayerWidgetUpdateManager {
    
    private const val TAG = "PrayerWidgetUpdateManager"
    private const val LIVE_UPDATE_INTERVAL = 10 * 1000L // 10 seconds for live countdown
    private const val NEAR_PRAYER_INTERVAL = 10 * 1000L // 10 seconds when prayer is within 15 minutes
    private const val COUNTDOWN_UPDATE_INTERVAL = 1 * 1000L // 1 second for precise countdown (Widget A)
    
    // Check which widget types have active instances on the home screen
    private fun getActiveWidgetTypes(context: Context): List<String> {
        val activeTypes = mutableListOf<String>()
        val appWidgetManager = AppWidgetManager.getInstance(context)
        
        // Check each widget type
        val widget4x1Ids = appWidgetManager.getAppWidgetIds(ComponentName(context, PrayerWidgetProvider::class.java))
        if (widget4x1Ids.isNotEmpty()) {
            activeTypes.add("4x1")
            Log.d(TAG, "Found ${widget4x1Ids.size} 4x1 widgets")
        }
        
        val widget2x2Ids = appWidgetManager.getAppWidgetIds(ComponentName(context, PrayerWidget2x2Provider::class.java))
        if (widget2x2Ids.isNotEmpty()) {
            activeTypes.add("2x2")
            Log.d(TAG, "Found ${widget2x2Ids.size} 2x2 widgets")
        }
        
        val widgetC1Ids = appWidgetManager.getAppWidgetIds(ComponentName(context, PrayerWidgetC1Provider::class.java))
        if (widgetC1Ids.isNotEmpty()) {
            activeTypes.add("C1")
            Log.d(TAG, "Found ${widgetC1Ids.size} C1 widgets")
        }
        
        val widgetC2Ids = appWidgetManager.getAppWidgetIds(ComponentName(context, PrayerWidgetC2Provider::class.java))
        if (widgetC2Ids.isNotEmpty()) {
            activeTypes.add("C2")
            Log.d(TAG, "Found ${widgetC2Ids.size} C2 widgets")
        }
        
        val widgetC2_1x1Ids = appWidgetManager.getAppWidgetIds(ComponentName(context, PrayerWidgetC2_1x1Provider::class.java))
        if (widgetC2_1x1Ids.isNotEmpty()) {
            activeTypes.add("C2_1x1")
            Log.d(TAG, "Found ${widgetC2_1x1Ids.size} C2 1x1 widgets")
        }
        
        Log.d(TAG, "Active widget types: $activeTypes")
        return activeTypes
    }
    
    fun startPeriodicUpdates(context: Context) {
        Log.d(TAG, "Starting periodic widget updates - checking for active widgets")
        
        val activeWidgetTypes = getActiveWidgetTypes(context)
        
        if (activeWidgetTypes.isEmpty()) {
            Log.d(TAG, "No active widgets found - skipping update scheduling")
            return
        }
        
        Log.d(TAG, "Scheduling updates for active widget types: $activeWidgetTypes")
        
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntents = mutableListOf<PendingIntent>()
        
        // Only create PendingIntents for active widget types
        if (activeWidgetTypes.contains("4x1")) {
            // Schedule updates for 4x1 widgets
            val intent4x1 = Intent(context, PrayerWidgetProvider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_WIDGET"
            }
            
            val pendingIntent4x1 = PendingIntent.getBroadcast(
                context, 
                1, // Unique request code for 4x1
                intent4x1,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntent4x1)
        }
        
        if (activeWidgetTypes.contains("2x2")) {
            // Schedule updates for 2x2 widgets
            val intent2x2 = Intent(context, PrayerWidget2x2Provider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_2X2_WIDGET"
            }
            
            val pendingIntent2x2 = PendingIntent.getBroadcast(
                context, 
                2, // Unique request code for 2x2
                intent2x2,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntent2x2)
        }
        
        if (activeWidgetTypes.contains("C1")) {
            // Schedule updates for C1 widgets
            val intentC1 = Intent(context, PrayerWidgetC1Provider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_C1_WIDGET"
            }
            
            val pendingIntentC1 = PendingIntent.getBroadcast(
                context, 
                3, // Unique request code for C1
                intentC1,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntentC1)
        }
        
        if (activeWidgetTypes.contains("C2")) {
            // Schedule updates for C2 widgets
            val intentC2 = Intent(context, PrayerWidgetC2Provider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_C2_WIDGET"
            }
            
            val pendingIntentC2 = PendingIntent.getBroadcast(
                context, 
                4, // Unique request code for C2
                intentC2,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntentC2)
        }
        
        if (activeWidgetTypes.contains("C2_1x1")) {
            // Schedule updates for C2 1x1 widgets
            val intentC2_1x1 = Intent(context, PrayerWidgetC2_1x1Provider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_C2_1X1_WIDGET"
            }
            
            val pendingIntentC2_1x1 = PendingIntent.getBroadcast(
                context, 
                5, // Unique request code for C2 1x1
                intentC2_1x1,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntentC2_1x1)
        }
        
        try {
            // Use setRepeating for continuous updates every 10 seconds for active widgets only
            for (pendingIntent in pendingIntents) {
                alarmManager.setRepeating(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    SystemClock.elapsedRealtime() + LIVE_UPDATE_INTERVAL,
                    LIVE_UPDATE_INTERVAL,
                    pendingIntent
                )
            }
            
            Log.d(TAG, "Repeating updates scheduled every ${LIVE_UPDATE_INTERVAL/1000} seconds for ${pendingIntents.size} active widget types")
        } catch (e: SecurityException) {
            Log.e(TAG, "Permission denied for repeating alarms: ${e.message}")
            // Try exact repeating as fallback
            try {
                for (pendingIntent in pendingIntents) {
                    alarmManager.setInexactRepeating(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        SystemClock.elapsedRealtime() + LIVE_UPDATE_INTERVAL,
                        AlarmManager.INTERVAL_FIFTEEN_MINUTES, // Android minimum
                        pendingIntent
                    )
                }
                Log.d(TAG, "Fallback to inexact repeating (15 min intervals) for ${pendingIntents.size} active widget types")
            } catch (e2: SecurityException) {
                Log.e(TAG, "All alarm methods failed: ${e2.message}")
            }
        }
    }
    
    private fun scheduleNextUpdate(context: Context, interval: Long) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, PrayerWidgetProvider::class.java).apply {
            action = "com.wia.prayer_app.UPDATE_WIDGET"
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context, 
            0, 
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        try {
            // Use setExactAndAllowWhileIdle for better reliability
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + interval,
                pendingIntent
            )
            Log.d(TAG, "Next update scheduled in ${interval/1000} seconds")
        } catch (e: SecurityException) {
            Log.e(TAG, "Permission denied for exact alarms: ${e.message}")
            // Fallback to inexact repeating
            alarmManager.setInexactRepeating(
                AlarmManager.ELAPSED_REALTIME,
                SystemClock.elapsedRealtime() + interval,
                interval,
                pendingIntent
            )
        }
    }
    
    fun stopPeriodicUpdates(context: Context) {
        Log.d(TAG, "Stopping periodic widget updates for all widget types")
        
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        // Stop updates for 4x1 widgets
        val intent4x1 = Intent(context, PrayerWidgetProvider::class.java).apply {
            action = "com.wia.prayer_app.UPDATE_WIDGET"
        }
        
        val pendingIntent4x1 = PendingIntent.getBroadcast(
            context, 
            1, // Same request code as start method
            intent4x1,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Stop updates for 2x2 widgets
        val intent2x2 = Intent(context, PrayerWidget2x2Provider::class.java).apply {
            action = "com.wia.prayer_app.UPDATE_2X2_WIDGET"
        }
        
        val pendingIntent2x2 = PendingIntent.getBroadcast(
            context, 
            2, // Same request code as start method
            intent2x2,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Stop updates for C1 widgets
        val intentC1 = Intent(context, PrayerWidgetC1Provider::class.java).apply {
            action = "com.wia.prayer_app.UPDATE_C1_WIDGET"
        }
        
        val pendingIntentC1 = PendingIntent.getBroadcast(
            context, 
            3, // Same request code as start method
            intentC1,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Stop updates for C2 widgets
        val intentC2 = Intent(context, PrayerWidgetC2Provider::class.java).apply {
            action = "com.wia.prayer_app.UPDATE_C2_WIDGET"
        }
        
        val pendingIntentC2 = PendingIntent.getBroadcast(
            context, 
            4, // Same request code as start method
            intentC2,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Stop updates for C2 1x1 widgets
        val intentC2_1x1 = Intent(context, PrayerWidgetC2_1x1Provider::class.java).apply {
            action = "com.wia.prayer_app.UPDATE_C2_1X1_WIDGET"
        }
        
        val pendingIntentC2_1x1 = PendingIntent.getBroadcast(
            context, 
            5, // Same request code as start method
            intentC2_1x1,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        alarmManager.cancel(pendingIntent4x1)
        alarmManager.cancel(pendingIntent2x2)
        alarmManager.cancel(pendingIntentC1)
        alarmManager.cancel(pendingIntentC2)
        alarmManager.cancel(pendingIntentC2_1x1)
        Log.d(TAG, "Periodic updates stopped for all widget types")
    }
    
    fun scheduleImmediateUpdate(context: Context) {
        Log.d(TAG, "Scheduling immediate widget update - checking for active widgets")
        
        val activeWidgetTypes = getActiveWidgetTypes(context)
        
        if (activeWidgetTypes.isEmpty()) {
            Log.d(TAG, "No active widgets found - skipping immediate update")
            return
        }
        
        Log.d(TAG, "Updating active widget types: $activeWidgetTypes")
        
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntents = mutableListOf<PendingIntent>()
        
        // Only update active widget types
        if (activeWidgetTypes.contains("4x1")) {
            // Update 4x1 widgets
            val intent4x1 = Intent(context, PrayerWidgetProvider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_WIDGET"
            }
            context.sendBroadcast(intent4x1)
            
            // 4x1 widget follow-up
            val pendingIntent4x1 = PendingIntent.getBroadcast(
                context, 
                999, // Unique request code for immediate updates
                intent4x1,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntent4x1)
        }
        
        if (activeWidgetTypes.contains("2x2")) {
            // Update 2x2 widgets
            val intent2x2 = Intent(context, PrayerWidget2x2Provider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_2X2_WIDGET"
            }
            context.sendBroadcast(intent2x2)
            
            // 2x2 widget follow-up
            val pendingIntent2x2 = PendingIntent.getBroadcast(
                context, 
                998, // Unique request code for 2x2 immediate updates
                intent2x2,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntent2x2)
        }
        
        if (activeWidgetTypes.contains("C1")) {
            // Update C1 widgets
            val intentC1 = Intent(context, PrayerWidgetC1Provider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_C1_WIDGET"
            }
            context.sendBroadcast(intentC1)
            
            // C1 widget follow-up
            val pendingIntentC1 = PendingIntent.getBroadcast(
                context, 
                997, // Unique request code for C1 immediate updates
                intentC1,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntentC1)
        }
        
        if (activeWidgetTypes.contains("C2")) {
            // Update C2 widgets
            val intentC2 = Intent(context, PrayerWidgetC2Provider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_C2_WIDGET"
            }
            context.sendBroadcast(intentC2)
            
            // C2 widget follow-up
            val pendingIntentC2 = PendingIntent.getBroadcast(
                context, 
                996, // Unique request code for C2 immediate updates
                intentC2,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntentC2)
        }
        
        if (activeWidgetTypes.contains("C2_1x1")) {
            // Update C2 1x1 widgets
            val intentC2_1x1 = Intent(context, PrayerWidgetC2_1x1Provider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_C2_1X1_WIDGET"
            }
            context.sendBroadcast(intentC2_1x1)
            
            // C2 1x1 widget follow-up
            val pendingIntentC2_1x1 = PendingIntent.getBroadcast(
                context, 
                995, // Unique request code for C2 1x1 immediate updates
                intentC2_1x1,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntentC2_1x1)
        }
        
        // Schedule follow-up updates for active widget types only
        try {
            for (pendingIntent in pendingIntents) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    SystemClock.elapsedRealtime() + 1000, // 1 second delay
                    pendingIntent
                )
            }
            
            Log.d(TAG, "Follow-up updates scheduled for ${pendingIntents.size} active widget types in 1 second")
        } catch (e: SecurityException) {
            Log.w(TAG, "Could not schedule immediate follow-up updates")
        }
    }
    
    // This method schedules a single update after a delay
    fun scheduleLiveUpdate(context: Context, delayMillis: Long = LIVE_UPDATE_INTERVAL) {
        Log.d(TAG, "Scheduling live update - checking for active widgets")
        
        val activeWidgetTypes = getActiveWidgetTypes(context)
        
        if (activeWidgetTypes.isEmpty()) {
            Log.d(TAG, "No active widgets found - skipping live update")
            return
        }
        
        Log.d(TAG, "Scheduling live update for active widget types: $activeWidgetTypes")
        
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntents = mutableListOf<PendingIntent>()
        
        if (activeWidgetTypes.contains("4x1")) {
            // Schedule update for 4x1 widgets
            val intent4x1 = Intent(context, PrayerWidgetProvider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_WIDGET"
            }
            
            val pendingIntent4x1 = PendingIntent.getBroadcast(
                context, 
                (System.currentTimeMillis() / 1000).toInt(), // Unique request code based on timestamp
                intent4x1,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntent4x1)
        }
        
        if (activeWidgetTypes.contains("2x2")) {
            // Schedule update for 2x2 widgets
            val intent2x2 = Intent(context, PrayerWidget2x2Provider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_2X2_WIDGET"
            }
            
            val pendingIntent2x2 = PendingIntent.getBroadcast(
                context, 
                (System.currentTimeMillis() / 1000 + 1).toInt(), // Slightly different request code
                intent2x2,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntent2x2)
        }
        
        if (activeWidgetTypes.contains("C1")) {
            // Schedule update for C1 widgets
            val intentC1 = Intent(context, PrayerWidgetC1Provider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_C1_WIDGET"
            }
            
            val pendingIntentC1 = PendingIntent.getBroadcast(
                context, 
                (System.currentTimeMillis() / 1000 + 2).toInt(), // Slightly different request code
                intentC1,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntentC1)
        }
        
        if (activeWidgetTypes.contains("C2")) {
            // Schedule update for C2 widgets
            val intentC2 = Intent(context, PrayerWidgetC2Provider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_C2_WIDGET"
            }
            
            val pendingIntentC2 = PendingIntent.getBroadcast(
                context, 
                (System.currentTimeMillis() / 1000 + 3).toInt(), // Slightly different request code
                intentC2,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntentC2)
        }
        
        if (activeWidgetTypes.contains("C2_1x1")) {
            // Schedule update for C2 1x1 widgets
            val intentC2_1x1 = Intent(context, PrayerWidgetC2_1x1Provider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_C2_1X1_WIDGET"
            }
            
            val pendingIntentC2_1x1 = PendingIntent.getBroadcast(
                context, 
                (System.currentTimeMillis() / 1000 + 4).toInt(), // Slightly different request code
                intentC2_1x1,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntents.add(pendingIntentC2_1x1)
        }
        
        try {
            for (pendingIntent in pendingIntents) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    SystemClock.elapsedRealtime() + delayMillis,
                    pendingIntent
                )
            }
            
            Log.d(TAG, "Live update scheduled in ${delayMillis/1000} seconds for ${pendingIntents.size} active widget types")
        } catch (e: SecurityException) {
            // Fallback to regular update schedule
            Log.w(TAG, "Cannot schedule exact alarm for live updates, using regular interval")
        }
    }

    // Schedule precise 1-second countdown updates specifically for Widget A (4x1)
    fun scheduleCountdownUpdate(context: Context) {
        Log.d(TAG, "Scheduling 1-second countdown update for Widget A")
        
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val widget4x1Ids = appWidgetManager.getAppWidgetIds(ComponentName(context, PrayerWidgetProvider::class.java))
        
        if (widget4x1Ids.isEmpty()) {
            Log.d(TAG, "No Widget A (4x1) instances found - skipping countdown update")
            return
        }
        
        Log.d(TAG, "Found ${widget4x1Ids.size} Widget A instances - scheduling 1-second update")
        
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(context, PrayerWidgetProvider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_WIDGET_COUNTDOWN"
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context, 
                99999, // Unique request code for countdown updates
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            val triggerTime = SystemClock.elapsedRealtime() + COUNTDOWN_UPDATE_INTERVAL
            
            alarmManager.setExact(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                triggerTime,
                pendingIntent
            )
            
            Log.d(TAG, "Widget A countdown update scheduled in 1 second")
        } catch (e: SecurityException) {
            Log.w(TAG, "Cannot schedule exact alarm for countdown updates, falling back to live update")
            scheduleLiveUpdate(context, COUNTDOWN_UPDATE_INTERVAL)
        }
    }

    // Stop countdown updates for Widget A
    fun stopCountdownUpdate(context: Context) {
        Log.d(TAG, "Stopping countdown updates for Widget A")
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(context, PrayerWidgetProvider::class.java).apply {
                action = "com.wia.prayer_app.UPDATE_WIDGET_COUNTDOWN"
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context, 
                99999, // Same request code used in scheduleCountdownUpdate
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            alarmManager.cancel(pendingIntent)
            Log.d(TAG, "Widget A countdown updates stopped")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to stop countdown updates: ${e.message}")
        }
    }
}
