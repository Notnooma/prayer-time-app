import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationWrapper {
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await AwesomeNotifications().initialize(
        'resource://drawable/launcher_icon',
        [
          NotificationChannel(
            channelKey: 'prayer_channel',
            channelName: 'Prayer Notifications',
            channelDescription: 'Notifications for prayer times',
            defaultColor: const Color(0xFF4CAF50),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            channelShowBadge: true,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            criticalAlerts: true,
          ),
        ],
        debug: false,
      );

      _initialized = true;
      print('✅ AwesomeNotifications initialized successfully');
    } catch (e) {
      print('Error initializing NotificationWrapper: $e');
      rethrow;
    }
  }

  static Future<bool> requestNotificationPermission() async {
    final permission = await AwesomeNotifications().isNotificationAllowed();
    if (!permission) {
      return await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return true;
  }

  static Future<void> scheduleAllPrayerNotifications() async {
    try {
      // Cancel all existing notifications first
      await AwesomeNotifications().cancelAll();

      // Load prayer times
      final String jsonString = await rootBundle.loadString('assets/prayer_times.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      final DateTime now = DateTime.now();
      final String todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Find today's prayer times using the date as key
      Map<String, dynamic>? dayData = data[todayStr];
      DateTime targetDate = now;
      String targetDateStr = todayStr;
      
      if (dayData == null) {
        print('❌ No prayer times found for today: $todayStr');
        return;
      }

      Map<String, dynamic>? times = dayData['times'];
      if (times == null) {
        print('❌ No times found in prayer data for today');
        return;
      }

      print('✅ Found prayer times for today');
      print('📋 Prayer times: $times');

      // Check if all today's prayers have passed
      bool allPrayersPassedToday = await _checkIfAllPrayersPassedForDate(times, now);
      
      if (allPrayersPassedToday) {
        print('⏭️ All prayers for today have passed, scheduling for tomorrow...');
        
        // Get tomorrow's date
        final DateTime tomorrow = now.add(const Duration(days: 1));
        final String tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        
        // Load tomorrow's prayer times
        final Map<String, dynamic>? tomorrowData = data[tomorrowStr];
        if (tomorrowData == null) {
          print('❌ No prayer times found for tomorrow: $tomorrowStr');
          return;
        }
        
        final Map<String, dynamic>? tomorrowTimes = tomorrowData['times'];
        if (tomorrowTimes == null) {
          print('❌ No times found in prayer data for tomorrow');
          return;
        }
        
        print('✅ Found prayer times for tomorrow');
        print('📋 Tomorrow\'s prayer times: $tomorrowTimes');
        
        // Use tomorrow's data for scheduling
        dayData = tomorrowData;
        times = tomorrowTimes;
        targetDate = tomorrow;
        targetDateStr = tomorrowStr;
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      final bool preAdhanEnabled = prefs.getBool('pre_adhan_enabled') ?? false;

      if (!notificationsEnabled) {
        print('🔕 Notifications are disabled in settings');
        return;
      }

      print('🔔 Notifications enabled, scheduling...');
      print('🔔 Pre-adhan notifications enabled: $preAdhanEnabled');

      // Prayer names mapping - updated for new JSON structure
      final Map<String, String> prayerNames = {
        'fajr': 'Fajr',
        'dhuhr': 'Dhuhr',
        'asr': 'Asr',
        'maghrib': 'Maghrib',
        'isha': 'Isha',
      };

      int scheduledCount = 0;

      // Schedule notifications for each prayer
      for (String prayerKey in prayerNames.keys) {
        final dynamic prayerData = times[prayerKey];
        if (prayerData == null) {
          print('⚠️ No data found for $prayerKey');
          continue;
        }

        // Extract time - could be a string or an object with adhan
        String? timeStr;
        if (prayerData is String) {
          timeStr = prayerData;
        } else if (prayerData is Map<String, dynamic> && prayerData['adhan'] != null) {
          timeStr = prayerData['adhan'];
        }

        if (timeStr == null) {
          print('⚠️ No time found for $prayerKey');
          continue;
        }

        print('⏰ Processing $prayerKey at $timeStr');

        try {
          final DateTime prayerTime = _parseTimeString(timeStr, targetDate);
          print('🕐 Parsed $prayerKey time: $prayerTime');

          // Only schedule if prayer time is in the future
          if (prayerTime.isAfter(now)) {
            print('✅ $prayerKey is in the future, scheduling...');

            // Create main prayer notification
            final int notificationId = prayerKey.hashCode;
            print('🆔 Creating notification with ID: $notificationId');
            
            try {
              await AwesomeNotifications().createNotification(
                content: NotificationContent(
                  id: notificationId,
                  channelKey: 'prayer_channel',
                  title: 'Time for ${prayerNames[prayerKey]} Prayer',
                  body: 'It\'s time for ${prayerNames[prayerKey]} prayer',
                  notificationLayout: NotificationLayout.Default,
                  wakeUpScreen: true,
                  category: NotificationCategory.Reminder,
                  payload: {'prayer_time': prayerTime.toIso8601String()},
                ),
                schedule: NotificationCalendar(
                  year: prayerTime.year,
                  month: prayerTime.month,
                  day: prayerTime.day,
                  hour: prayerTime.hour,
                  minute: prayerTime.minute,
                  second: 0,
                  millisecond: 0,
                  repeats: false,
                ),
              );
              
              scheduledCount++;
              print('✅ Scheduled ${prayerNames[prayerKey]} notification');
              
            } catch (e) {
              print('❌ Failed to schedule ${prayerNames[prayerKey]} notification: $e');
            }

            // Schedule pre-adhan notification if enabled
            if (preAdhanEnabled) {
              final DateTime preAdhanTime = prayerTime.subtract(const Duration(minutes: 15));
              
              // Only schedule pre-adhan if it's also in the future
              if (preAdhanTime.isAfter(now)) {
                final int preAdhanId = ('$prayerKey-pre').hashCode;
                print('🆔 Creating pre-adhan notification with ID: $preAdhanId');
                
                try {
                  await AwesomeNotifications().createNotification(
                    content: NotificationContent(
                      id: preAdhanId,
                      channelKey: 'prayer_channel',
                      title: '${prayerNames[prayerKey]} in 15 minutes',
                      body: 'Get ready for ${prayerNames[prayerKey]} prayer in 15 minutes',
                      notificationLayout: NotificationLayout.Default,
                      wakeUpScreen: false,
                      category: NotificationCategory.Reminder,
                      payload: {'pre_adhan_time': preAdhanTime.toIso8601String()},
                    ),
                    schedule: NotificationCalendar(
                      year: preAdhanTime.year,
                      month: preAdhanTime.month,
                      day: preAdhanTime.day,
                      hour: preAdhanTime.hour,
                      minute: preAdhanTime.minute,
                      second: 0,
                      millisecond: 0,
                      repeats: false,
                    ),
                  );
                  
                  scheduledCount++;
                  print('✅ Scheduled pre-adhan for ${prayerNames[prayerKey]}');
                  
                } catch (e) {
                  print('❌ Failed to schedule pre-adhan for ${prayerNames[prayerKey]}: $e');
                }
              } else {
                print('⏭️ Pre-adhan time for $prayerKey has already passed');
              }
            }
          } else {
            print('⏭️ $prayerKey time has already passed today');
          }
        } catch (e) {
          print('❌ Error processing $prayerKey: $e');
        }
      }

      print('📊 Total notifications requested: $scheduledCount');

      // Verify what was actually scheduled (final verification)
      final List<NotificationModel> actualScheduled = await AwesomeNotifications().listScheduledNotifications();
      print('🔍 Actually scheduled notifications: ${actualScheduled.length}');
      
      if (actualScheduled.isEmpty) {
        print('❌ CRITICAL: No notifications were actually scheduled!');
      } else if (actualScheduled.length != scheduledCount) {
        print('⚠️ WARNING: Requested $scheduledCount but ${actualScheduled.length} were actually scheduled');
        print('✅ Verified: ${actualScheduled.length} notifications are scheduled');
        for (var notification in actualScheduled) {
          print('📋 Scheduled: ID ${notification.content?.id}, Title: ${notification.content?.title}');
        }
      } else {
        print('✅ SUCCESS: All $scheduledCount notifications scheduled correctly');
        for (var notification in actualScheduled) {
          print('📋 Scheduled: ID ${notification.content?.id}, Title: ${notification.content?.title}');
        }
      }

      // Save the date of successful scheduling
      await prefs.setString('lastScheduledDate', targetDateStr);
      print('💾 Saved last scheduled date: $targetDateStr');

    } catch (e) {
      print('❌ Error in scheduleAllPrayerNotifications: $e');
      rethrow;
    }
  }

  /// Parse time string to DateTime (handles AM/PM format)
  static DateTime _parseTimeString(String timeStr, DateTime referenceDate) {
    try {
      // Remove AM/PM and parse time in format "6:29 AM" or "12:36 PM"
      final bool isPM = timeStr.toUpperCase().contains('PM');
      final bool isAM = timeStr.toUpperCase().contains('AM');
      
      // Clean the time string
      final String cleanTime = timeStr.replaceAll(RegExp(r'[AP]M'), '').trim();
      
      final parts = cleanTime.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid time format: $timeStr');
      }
      
      int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);
      
      // Convert to 24-hour format
      if (isPM && hour != 12) {
        hour += 12;
      } else if (isAM && hour == 12) {
        hour = 0;
      }
      
      return DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day,
        hour,
        minute,
      );
    } catch (e) {
      print('Error parsing time string "$timeStr": $e');
      rethrow;
    }
  }

  static Future<void> cancelAllPrayerNotifications() async {
    await AwesomeNotifications().cancelAll();
    print('🗑️ All notifications cancelled');
  }

  static Future<List<NotificationModel>> getScheduledNotifications() async {
    return await AwesomeNotifications().listScheduledNotifications();
  }

  static Future<void> checkAndReschedule() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastScheduledStr = prefs.getString('lastScheduledDate');
    final bool lastPreAdhanEnabled = prefs.getBool('lastPreAdhanEnabled') ?? false;
    final bool currentPreAdhanEnabled = prefs.getBool('pre_adhan_enabled') ?? false;
    
    print('🔍 Checking if reschedule needed...');
    print('🔍 Last scheduled: $lastScheduledStr');
    print('🔍 Pre-adhan last: $lastPreAdhanEnabled, current: $currentPreAdhanEnabled');
    
    final DateTime today = DateTime.now();
    
    // Always check how many notifications are actually scheduled
    final List<NotificationModel> currentScheduled = await AwesomeNotifications().listScheduledNotifications();
    print('🔍 Currently scheduled notifications: ${currentScheduled.length}');
    
    bool needsReschedule = false;
    String reason = '';
    
    if (lastScheduledStr != null) {
      final DateTime lastScheduled = DateTime.parse('$lastScheduledStr 00:00:00');
      final int daysSinceScheduled = today.difference(lastScheduled).inDays;
      print('🔍 Days since last schedule: $daysSinceScheduled');
      
      // Reschedule if it's been 1+ days OR if no notifications are scheduled OR pre-adhan setting changed
      if (daysSinceScheduled >= 1) {
        needsReschedule = true;
        reason = 'new day detected';
      } else if (currentScheduled.isEmpty) {
        needsReschedule = true;
        reason = 'no notifications found despite recent scheduling';
      } else if (lastPreAdhanEnabled != currentPreAdhanEnabled) {
        needsReschedule = true;
        reason = 'pre-adhan setting changed';
      } else {
        print('✅ Notifications are up to date');
      }
    } else {
      // First time, schedule all
      needsReschedule = true;
      reason = 'first time scheduling notifications';
    }
    
    if (needsReschedule) {
      print('🔧 Reschedule needed - $reason');
      await scheduleAllPrayerNotifications();
      // Save the pre-adhan setting state
      await prefs.setBool('lastPreAdhanEnabled', currentPreAdhanEnabled);
    }
  }

  static void setupNotificationListeners() {
    print('🔧 Notification listeners setup');
    // For now, just log
  }

  /// Check if all prayers for a given date have passed
  static Future<bool> _checkIfAllPrayersPassedForDate(Map<String, dynamic> times, DateTime currentTime) async {
    try {
      // Prayer names to check
      final List<String> prayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
      
      for (String prayerKey in prayerKeys) {
        final dynamic prayerData = times[prayerKey];
        if (prayerData == null) continue;

        // Extract time - could be a string or an object with adhan
        String? timeStr;
        if (prayerData is String) {
          timeStr = prayerData;
        } else if (prayerData is Map<String, dynamic> && prayerData['adhan'] != null) {
          timeStr = prayerData['adhan'];
        }

        if (timeStr == null) continue;

        try {
          final DateTime prayerTime = _parseTimeString(timeStr, currentTime);
          
          // If any prayer is still in the future, not all have passed
          if (prayerTime.isAfter(currentTime)) {
            print('🔍 Prayer $prayerKey at $timeStr is still in the future');
            return false;
          }
        } catch (e) {
          print('⚠️ Error parsing time for $prayerKey: $e');
          continue;
        }
      }
      
      print('✅ All prayers for the day have passed');
      return true;
      
    } catch (e) {
      print('❌ Error checking prayer times: $e');
      return false;
    }
  }
}
