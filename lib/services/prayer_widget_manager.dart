import 'package:home_widget/home_widget.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class PrayerWidgetManager {
  static const String _widgetName = 'PrayerWidgetProvider';
  
  /// Initialize the widget system
  static Future<void> initialize() async {
    try {
      print('🎯 Initializing Prayer Widget Manager...');
      
      // Update widget data immediately
      await updateWidgetData();
      
      print('✅ Prayer Widget Manager initialized successfully');
    } catch (e) {
      print('❌ Error initializing Prayer Widget Manager: $e');
    }
  }
  
  /// Update widget with current prayer times and countdown
  static Future<void> updateWidgetData() async {
    try {
      print('🔄 Updating widget data...');
      
      // Get today's prayer times
      final prayerData = await _getTodaysPrayerTimes();
      if (prayerData == null) {
        print('⚠️ No prayer data available for today');
        return;
      }
      
      // Save data for Android widget to access
      final String todayKey = _getTodayDateKey();
      await HomeWidget.saveWidgetData('prayer_times_$todayKey', json.encode(prayerData));
      
      // Update the widget
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
      
      print('✅ Widget data updated successfully');
      
    } catch (e) {
      print('❌ Error updating widget data: $e');
    }
  }
  
  /// Get today's prayer times from assets
  static Future<Map<String, dynamic>?> _getTodaysPrayerTimes() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/prayer_times.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      final String todayKey = _getTodayDateKey();
      return data[todayKey];
      
    } catch (e) {
      print('Error loading prayer times: $e');
      return null;
    }
  }
  
  /// Get today's date in the format used in prayer_times.json
  static String _getTodayDateKey() {
    final DateTime now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
  
  /// Force refresh all widgets
  static Future<void> refreshAllWidgets() async {
    try {
      print('🔄 Refreshing all prayer widgets...');
      
      await updateWidgetData();
      
      // Also trigger Android-side update
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
      
      print('✅ All widgets refreshed');
      
    } catch (e) {
      print('❌ Error refreshing widgets: $e');
    }
  }
  
  /// Check if widgets are supported on this platform
  static Future<bool> isWidgetSupported() async {
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (e) {
      return false;
    }
  }
}
