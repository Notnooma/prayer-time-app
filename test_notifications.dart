import 'lib/services/notification_service.dart';

void main() async {
  print('Testing simplified notification system...');
  
  try {
    // Initialize the service
    await NotificationService.initialize();
    print('✅ NotificationService initialized successfully');
    
    // Request permissions
    final hasPermission = await NotificationService.requestNotificationPermission();
    print('✅ Notification permission: $hasPermission');
    
    // Schedule notifications
    await NotificationService.scheduleAllPrayerNotifications();
    print('✅ Prayer notifications scheduled');
    
    // Get scheduled notifications count
    final scheduled = await NotificationService.getScheduledNotifications();
    print('✅ Total scheduled notifications: ${scheduled.length}');
    
    print('\n🎉 Notification system test completed successfully!');
    
  } catch (e) {
    print('❌ Error during test: $e');
  }
}
