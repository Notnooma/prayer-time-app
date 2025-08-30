import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static bool _initialized = false;
  
  /// Initialize the notification service with proper timezone support
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize AwesomeNotifications with proper configuration
      await AwesomeNotifications().initialize(
        'resource://drawable/launcher_icon', // Use your app icon
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
          NotificationChannel(
            channelKey: 'pre_adhan_channel',
            channelName: 'Pre-Adhan Reminders',
            channelDescription: '15-minute prayer reminders',
            defaultColor: const Color(0xFF2196F3),
            ledColor: Colors.blue,
            importance: NotificationImportance.Default,
            channelShowBadge: false,
            playSound: true,
            enableVibration: true,
          ),
        ],
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: 'prayer_group',
            channelGroupName: 'Prayer Times',
          ),
        ],
        debug: true,
      );

      _initialized = true;
      print('✅ AwesomeNotifications initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
      rethrow;
    }
  }

  /// Request notification permission
  static Future<bool> requestNotificationPermission() async {
    final permission = await AwesomeNotifications().isNotificationAllowed();
    if (!permission) {
      return await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return true;
  }

  /// Schedule all prayer notifications for today only
  static Future<void> scheduleAllPrayerNotifications() async {
    try {
      await _scheduleTodayOnly();
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }

  /// Schedule notifications for today only - CRITICAL DEBUG VERSION
  static Future<void> _scheduleTodayOnly() async {
    print('🔍 Starting _scheduleTodayOnly method...');
    
    try {
      // Cancel all existing notifications first
      await AwesomeNotifications().cancelAll();
      print('🗑️ Cleared all existing notifications');

      // Load prayer times
      final String jsonString = await rootBundle.loadString('assets/prayer_times.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<dynamic> prayerTimesList = data['prayer_times'];
      print('📖 Loaded ${prayerTimesList.length} days of prayer data');

      final DateTime today = DateTime.now();
      final String todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      print('📅 Looking for prayer times for: $todayStr');

      // Find today's prayer times
      Map<String, dynamic>? todayPrayers;
      for (var day in prayerTimesList) {
        if (day['date'] == todayStr) {
          todayPrayers = day;
          break;
        }
      }

      if (todayPrayers == null) {
        print('❌ No prayer times found for today: $todayStr');
        return;
      }

      print('✅ Found prayer times for today');
      print('📋 Prayer times: ${todayPrayers['prayers']}');

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      final bool preAdhanEnabled = prefs.getBool('preAdhanEnabled') ?? false;

      if (!notificationsEnabled) {
        print('🔕 Notifications are disabled in settings');
        return;
      }

      print('🔔 Notifications enabled. Pre-adhan: $preAdhanEnabled');

      // Prayer names mapping
      final Map<String, String> prayerNames = {
        'fajr': 'Fajr',
        'sunrise': 'Sunrise',
        'dhuhr': 'Dhuhr',
        'asr': 'Asr',
        'maghrib': 'Maghrib',
        'isha': 'Isha',
      };

      int scheduledCount = 0;
      final DateTime now = DateTime.now();

      // Schedule notifications for each prayer
      for (String prayerKey in prayerNames.keys) {
        final String? timeStr = todayPrayers['prayers'][prayerKey];
        if (timeStr == null) {
          print('⚠️ No time found for $prayerKey');
          continue;
        }

        print('⏰ Processing $prayerKey at $timeStr');

        try {
          final DateTime prayerTime = _parseTimeString(timeStr, today);
          print('🕐 Parsed $prayerKey time: $prayerTime');

          // Only schedule if prayer time is in the future
          if (prayerTime.isAfter(now)) {
            print('✅ $prayerKey is in the future, scheduling...');

            // Create main prayer notification
            final int notificationId = prayerKey.hashCode;
            print('🆔 Creating notification with ID: $notificationId');
            
            await _createNotification(
              id: notificationId,
              title: 'Time for ${prayerNames[prayerKey]} Prayer',
              body: 'It\'s time for ${prayerNames[prayerKey]} prayer',
              scheduledTime: prayerTime,
              channelKey: 'prayer_channel',
            );
            
            scheduledCount++;
            print('✅ Scheduled ${prayerNames[prayerKey]} notification');

            // Create pre-adhan notification if enabled and not for sunrise
            if (preAdhanEnabled && prayerKey != 'sunrise') {
              final DateTime preAdhanTime = prayerTime.subtract(const Duration(minutes: 15));
              if (preAdhanTime.isAfter(now)) {
                final int preAdhanId = '${prayerKey}_pre'.hashCode;
                print('🔔 Creating pre-adhan notification with ID: $preAdhanId');
                
                await _createNotification(
                  id: preAdhanId,
                  title: '${prayerNames[prayerKey]} Prayer in 15 minutes',
                  body: 'Get ready for ${prayerNames[prayerKey]} prayer',
                  scheduledTime: preAdhanTime,
                  channelKey: 'pre_adhan_channel',
                );
                
                scheduledCount++;
                print('✅ Scheduled pre-${prayerNames[prayerKey]} notification');
              } else {
                print('⏭️ Pre-adhan time for $prayerKey has passed');
              }
            }
          } else {
            print('⏭️ $prayerKey time has already passed today');
          }
        } catch (e) {
          print('❌ Error processing $prayerKey: $e');
        }
      }

      print('📊 Total notifications scheduled: $scheduledCount');

      // Verify what was actually scheduled
      final List<NotificationModel> actualScheduled = await AwesomeNotifications().listScheduledNotifications();
      print('🔍 Actually scheduled notifications: ${actualScheduled.length}');
      
      if (actualScheduled.isEmpty) {
        print('❌ CRITICAL: No notifications were actually scheduled despite success messages!');
      } else {
        print('✅ Verified: ${actualScheduled.length} notifications are scheduled');
        for (var notification in actualScheduled) {
          print('📋 Scheduled: ID ${notification.content?.id}, Title: ${notification.content?.title}');
        }
      }

      // Save the date of successful scheduling
      await prefs.setString('lastScheduledDate', todayStr);
      print('💾 Saved last scheduled date: $todayStr');

    } catch (e) {
      print('❌ Error in _scheduleTodayOnly: $e');
      print('📍 Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Create and schedule a notification
  static Future<void> _createNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelKey,
  }) async {
    try {
      print('🚀 Creating notification: ID=$id, Title="$title", Time=$scheduledTime');
      
      final bool created = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true,
          category: NotificationCategory.Reminder,
          payload: {'prayer_time': scheduledTime.toIso8601String()},
        ),
        schedule: NotificationCalendar(
          year: scheduledTime.year,
          month: scheduledTime.month,
          day: scheduledTime.day,
          hour: scheduledTime.hour,
          minute: scheduledTime.minute,
          second: 0,
          millisecond: 0,
          repeats: false,
        ),
      );
      
      print('📝 Notification creation result: $created');
      
      if (!created) {
        print('❌ Failed to create notification with ID: $id');
      } else {
        print('✅ Successfully created notification with ID: $id');
      }
      
    } catch (e) {
      print('❌ Error creating notification $id: $e');
      rethrow;
    }
  }

  /// Parse time string to DateTime
  static DateTime _parseTimeString(String timeStr, DateTime referenceDate) {
    try {
      // Parse time in format "HH:mm" or "H:mm"
      final parts = timeStr.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid time format: $timeStr');
      }
      
      final int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);
      
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

  /// Cancel all prayer notifications
  static Future<void> cancelAllPrayerNotifications() async {
    await AwesomeNotifications().cancelAll();
    print('🗑️ All notifications cancelled');
  }

  /// Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  /// Check if we need to reschedule notifications and do it if needed
  static Future<void> checkAndReschedule() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastScheduledStr = prefs.getString('lastScheduledDate');
    print('🔍 Checking if reschedule needed...');
    print('🔍 Last scheduled: $lastScheduledStr');
    
    final DateTime today = DateTime.now();
    
    if (lastScheduledStr != null) {
      final DateTime lastScheduled = DateTime.parse('$lastScheduledStr 00:00:00');
      final int daysSinceScheduled = today.difference(lastScheduled).inDays;
      print('🔍 Days since last schedule: $daysSinceScheduled');
      
      if (daysSinceScheduled >= 1) {
        print('🔧 FORCING RESCHEDULE FOR TESTING...');
        await scheduleAllPrayerNotifications();
      }
    } else {
      // First time, schedule all
      print('📅 First time scheduling notifications');
      await scheduleAllPrayerNotifications();
    }
  }

  /// Get all scheduled notifications
  static Future<List<NotificationModel>> getScheduledNotifications() async {
    return await AwesomeNotifications().listScheduledNotifications();
  }

  /// Setup notification listeners
  static void setupNotificationListeners() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    print('Notification action received: ${receivedAction.payload}');
  }

  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    print('Notification created: ${receivedNotification.id}');
  }

  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    print('Notification displayed: ${receivedNotification.id}');
  }

  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    print('Notification dismissed: ${receivedAction.id}');
  }
}
