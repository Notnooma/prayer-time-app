import 'package:awesome_notifications/awesome_notifications.dart';

class SimpleNotificationTest {
  static Future<void> createTestNotification() async {
    print('🧪 Starting simple test notification...');
    
    try {
      // Initialize AwesomeNotifications with minimal setup
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic Notifications',
            channelDescription: 'Test notifications',
            importance: NotificationImportance.High,
          ),
        ],
        debug: true,
      );
      
      print('✅ AwesomeNotifications initialized');
      
      // Request permission
      final bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      print('🔐 Notification permission: $isAllowed');
      
      if (!isAllowed) {
        final bool granted = await AwesomeNotifications().requestPermissionToSendNotifications();
        print('🔐 Permission request result: $granted');
      }
      
      // Create immediate notification (5 seconds from now)
      final DateTime testTime = DateTime.now().add(const Duration(seconds: 5));
      print('⏰ Scheduling test notification for: $testTime');
      
      final bool created = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: 'basic_channel',
          title: 'Test Notification',
          body: 'This is a test notification in 5 seconds',
        ),
        schedule: NotificationCalendar(
          year: testTime.year,
          month: testTime.month,
          day: testTime.day,
          hour: testTime.hour,
          minute: testTime.minute,
          second: testTime.second,
          repeats: false,
        ),
      );
      
      print('📝 Notification creation result: $created');
      
      // Check what's scheduled
      final scheduled = await AwesomeNotifications().listScheduledNotifications();
      print('📋 Scheduled notifications: ${scheduled.length}');
      
      for (var notification in scheduled) {
        print('   - ID: ${notification.content?.id}, Title: ${notification.content?.title}');
        print('   - Schedule: ${notification.schedule}');
      }
      
    } catch (e) {
      print('❌ Test notification error: $e');
      print('📍 Stack trace: ${StackTrace.current}');
    }
  }
}
