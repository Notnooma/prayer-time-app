package com.wia.prayer_app.widgets

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

object PrayerDataManager {
    
    private const val TAG = "PrayerDataManager"
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    
    // Cache variables
    private var cachedPrayerData: PrayerWidgetData? = null
    private var cachedDate: String? = null
    private var lastUpdateTime: Long = 0
    private const val CACHE_DURATION_MS = 10000L // 10 seconds cache
    
    data class PrayerWidgetData(
        val fajrTime: String,
        val dhuhrTime: String,
        val asrTime: String,
        val maghribTime: String,
        val ishaTime: String,
        val countdownText: String,
        val nextPrayerName: String
    )
    
    data class PrayerTime(
        val name: String,
        val time: String,
        val hour: Int,
        val minute: Int
    )

    fun getPrayerWidgetData(context: Context): PrayerWidgetData {
        try {
            // Get today's date
            val calendar = Calendar.getInstance()
            val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val todayKey = dateFormat.format(calendar.time)
            val currentTime = System.currentTimeMillis()
            
            // Check if we have valid cached data
            if (cachedPrayerData != null && 
                cachedDate == todayKey && 
                (currentTime - lastUpdateTime) < CACHE_DURATION_MS) {
                Log.d(TAG, "Returning cached prayer data for: $todayKey")
                
                // Update countdown in cached data and return
                return updateCountdownInCachedData()
            }
            
            Log.d(TAG, "Loading fresh prayer data for: $todayKey")
            
            // Try to get data from SharedPreferences (Flutter bridge)
            val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val prayerDataJson = prefs.getString("flutter.prayer_times_$todayKey", null)
            
            val freshData = if (prayerDataJson != null) {
                parsePrayerDataFromJson(prayerDataJson, todayKey)
            } else {
                // Fallback: Try to read from assets directly
                loadPrayerDataFromAssets(context, todayKey)
            }
            
            // Cache the fresh data
            cachedPrayerData = freshData
            cachedDate = todayKey
            lastUpdateTime = currentTime
            
            return freshData
            
        } catch (e: Exception) {
            Log.e(TAG, "Error getting prayer data: ${e.message}")
            return getErrorData()
        }
    }
    
    private fun parsePrayerDataFromJson(jsonString: String, dateKey: String): PrayerWidgetData {
        val jsonObject = JSONObject(jsonString)
        val times = jsonObject.getJSONObject("times")
        
        // Extract prayer times
        val fajrTime = times.getJSONObject("fajr").getString("adhan")
        val dhuhrTime = times.getJSONObject("dhuhr").getString("adhan")
        val asrTime = times.getJSONObject("asr").getString("adhan")
        val maghribTime = times.getJSONObject("maghrib").getString("adhan")
        val ishaTime = times.getJSONObject("isha").getString("adhan")
        
        Log.d(TAG, "Parsed prayer times - Fajr: $fajrTime, Dhuhr: $dhuhrTime, Asr: $asrTime, Maghrib: $maghribTime, Isha: $ishaTime")
        
        // Calculate countdown
        val prayerTimes = listOf(
            PrayerTime("Fajr", fajrTime, parseHour(fajrTime), parseMinute(fajrTime)),
            PrayerTime("Dhuhr", dhuhrTime, parseHour(dhuhrTime), parseMinute(dhuhrTime)),
            PrayerTime("Asr", asrTime, parseHour(asrTime), parseMinute(asrTime)),
            PrayerTime("Maghrib", maghribTime, parseHour(maghribTime), parseMinute(maghribTime)),
            PrayerTime("Isha", ishaTime, parseHour(ishaTime), parseMinute(ishaTime))
        )
        
        val countdownResult = calculateCountdown(prayerTimes)
        
        return PrayerWidgetData(
            fajrTime = formatTime(fajrTime),
            dhuhrTime = formatTime(dhuhrTime),
            asrTime = formatTime(asrTime),
            maghribTime = formatTime(maghribTime),
            ishaTime = formatTime(ishaTime),
            countdownText = countdownResult.first,
            nextPrayerName = countdownResult.second
        )
    }
    
    private fun loadPrayerDataFromAssets(context: Context, dateKey: String): PrayerWidgetData {
        Log.d(TAG, "Loading from assets for $dateKey")
        
        try {
            // Read prayer times from assets
            val inputStream = context.assets.open("flutter_assets/assets/prayer_times.json")
            val jsonString = inputStream.bufferedReader().use { it.readText() }
            val jsonObject = JSONObject(jsonString)
            
            // Get today's prayer data
            val dayData = jsonObject.optJSONObject(dateKey)
            if (dayData != null) {
                return parsePrayerDataFromJson(dayData.toString(), dateKey)
            } else {
                Log.w(TAG, "No prayer data found for $dateKey in assets")
                return getErrorData()
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error loading from assets: ${e.message}")
            return getErrorData()
        }
    }
    
    private fun calculateCountdown(prayerTimes: List<PrayerTime>): Pair<String, String> {
        val now = Calendar.getInstance()
        
        // Find next prayer
        for (prayer in prayerTimes) {
            val prayerCalendar = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, prayer.hour)
                set(Calendar.MINUTE, prayer.minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            
            if (prayerCalendar.after(now)) {
                val timeDiff = prayerCalendar.timeInMillis - now.timeInMillis
                val hours = (timeDiff / (1000 * 60 * 60)).toInt()
                val minutes = ((timeDiff % (1000 * 60 * 60)) / (1000 * 60)).toInt()
                val seconds = ((timeDiff % (1000 * 60)) / 1000).toInt()
                
                val countdownText = String.format("%02d:%02d:%02d until %s", 
                    hours, minutes, seconds, prayer.name)
                
                Log.d(TAG, "Next prayer: ${prayer.name} in ${hours}h ${minutes}m ${seconds}s")
                return Pair(countdownText, prayer.name)
            }
        }
        
        // If no prayer found today, get tomorrow's Fajr
        val tomorrowFajr = prayerTimes[0] // Fajr
        val tomorrowCalendar = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, tomorrowFajr.hour)
            set(Calendar.MINUTE, tomorrowFajr.minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        
        val timeDiff = tomorrowCalendar.timeInMillis - now.timeInMillis
        val hours = (timeDiff / (1000 * 60 * 60)).toInt()
        val minutes = ((timeDiff % (1000 * 60 * 60)) / (1000 * 60)).toInt()
        val seconds = ((timeDiff % (1000 * 60)) / 1000).toInt()
        
        val countdownText = String.format("%02d:%02d:%02d until Fajr", 
            hours, minutes, seconds)
        
        Log.d(TAG, "Tomorrow's Fajr in ${hours}h ${minutes}m ${seconds}s")
        return Pair(countdownText, "Fajr")
    }
    
    private fun parseHour(timeStr: String): Int {
        val parts = timeStr.split(" ")
        val timePart = parts[0]
        val period = parts[1]
        val hourMin = timePart.split(":")
        var hour = hourMin[0].toInt()
        
        if (period.uppercase() == "PM" && hour != 12) {
            hour += 12
        } else if (period.uppercase() == "AM" && hour == 12) {
            hour = 0
        }
        
        return hour
    }
    
    private fun parseMinute(timeStr: String): Int {
        val parts = timeStr.split(" ")
        val timePart = parts[0]
        val hourMin = timePart.split(":")
        return hourMin[1].toInt()
    }
    
    private fun formatTime(timeStr: String): String {
        // For now, return as-is. Later we can add 24-hour format option
        return timeStr
    }
    
    private fun getSampleData(): PrayerWidgetData {
        // Use today's actual prayer times for testing
        val now = Calendar.getInstance()
        val currentHour = now.get(Calendar.HOUR_OF_DAY)
        
        // Create sample countdown based on current time
        val sampleCountdown = when {
            currentHour < 5 -> "02:30:00 until Fajr"
            currentHour < 13 -> "01:45:00 until Dhuhr" 
            currentHour < 17 -> "02:15:00 until Asr"
            currentHour < 20 -> "01:20:00 until Maghrib"
            else -> "00:45:00 until Isha"
        }
        
        return PrayerWidgetData(
            fajrTime = "5:23 AM",
            dhuhrTime = "1:33 PM", 
            asrTime = "5:16 PM",
            maghribTime = "8:13 PM",
            ishaTime = "9:32 PM",
            countdownText = sampleCountdown,
            nextPrayerName = "Maghrib"
        )
    }
    
    private fun updateCountdownInCachedData(): PrayerWidgetData {
        val cached = cachedPrayerData ?: return getErrorData()
        
        // Extract prayer times from cached data and recalculate countdown
        val prayerTimes = listOf(
            PrayerTime("Fajr", cached.fajrTime, parseHour(cached.fajrTime), parseMinute(cached.fajrTime)),
            PrayerTime("Dhuhr", cached.dhuhrTime, parseHour(cached.dhuhrTime), parseMinute(cached.dhuhrTime)),
            PrayerTime("Asr", cached.asrTime, parseHour(cached.asrTime), parseMinute(cached.asrTime)),
            PrayerTime("Maghrib", cached.maghribTime, parseHour(cached.maghribTime), parseMinute(cached.maghribTime)),
            PrayerTime("Isha", cached.ishaTime, parseHour(cached.ishaTime), parseMinute(cached.ishaTime))
        )
        
        val countdownResult = calculateCountdown(prayerTimes)
        
        // Return cached data with updated countdown
        return cached.copy(
            countdownText = countdownResult.first,
            nextPrayerName = countdownResult.second
        )
    }
    
    private fun getErrorData(): PrayerWidgetData {
        return PrayerWidgetData(
            fajrTime = "--:--",
            dhuhrTime = "--:--",
            asrTime = "--:--", 
            maghribTime = "--:--",
            ishaTime = "--:--",
            countdownText = "Unable to load prayer times",
            nextPrayerName = ""
        )
    }
}
