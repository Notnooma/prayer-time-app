import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_wrapper.dart';
import '../main.dart';
import 'about_wia_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class DonationCoverage {
  static const double _yearlyGoal = 90.0;
  
  static double calculateCoverage(double donationAmount) {
    return donationAmount / _yearlyGoal;
  }
  
  static String formatCoverage(double coverageYears) {
    if (coverageYears <= 0) {
      return '0 months';
    } else if (coverageYears < 1) {
      final months = (coverageYears * 12).round();
      return '$months month${months != 1 ? 's' : ''}';
    } else {
      final years = coverageYears.floor();
      final remainingMonths = ((coverageYears - years) * 12).round();
      if (remainingMonths == 0) {
        return '$years year${years != 1 ? 's' : ''}';
      } else {
        return '$years year${years != 1 ? 's' : ''} $remainingMonths month${remainingMonths != 1 ? 's' : ''}';
      }
    }
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool preAdhanNotificationsEnabled = false;
  String themeMode = 'system';
  bool is24HourFormat = false;

  // Donation URLs
  static const String _wiaDonationUrl = 'https://ca.mohid.co/on/windsor/wia/masjid/online/donation';
  static const String _appDevDonationUrl = 'https://www.paypal.com/donate/?hosted_button_id=7VZHAZFJ9BS8W';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      preAdhanNotificationsEnabled = prefs.getBool('pre_adhan_enabled') ?? false;
      
      themeMode = prefs.getString('theme_mode') ?? 'system';
      
      if (!prefs.containsKey('theme_mode') && prefs.containsKey('dark_mode')) {
        final bool oldDarkMode = prefs.getBool('dark_mode') ?? false;
        themeMode = oldDarkMode ? 'dark' : 'light';
      }
      
      is24HourFormat = prefs.getBool('24_hour_format') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', notificationsEnabled);
    await prefs.setBool('pre_adhan_enabled', preAdhanNotificationsEnabled);
    await prefs.setString('theme_mode', themeMode);
    await prefs.setBool('24_hour_format', is24HourFormat);
  }

  // Show donation options dialog
  void _showDonationOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Donation Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.mosque, color: Colors.green[600]),
                title: const Text('Donate to WIA'),
                subtitle: const Text('Support Windsor Islamic Association'),
                onTap: () {
                  Navigator.pop(context);
                  _launchUrl(_wiaDonationUrl);
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.developer_mode, color: Colors.green[600]),
                title: const Text('App Development'),
                subtitle: const Text('Support app maintenance and updates'),
                onTap: () {
                  Navigator.pop(context);
                  _launchUrl(_appDevDonationUrl);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Launch URL helper
  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open the donation page'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening donation page: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  // Build the donation section
  Widget _buildDonationSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [Colors.green[800]!.withOpacity(0.6), Colors.green[900]!.withOpacity(0.4)]
              : [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.green[600]!
              : Colors.green[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.green[900]!.withOpacity(0.4)
                : Colors.green[200]!.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Support Development',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.green[200] 
                  : Colors.green[800],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Help keep this app running',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.green[300] 
                  : Colors.green[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showDonationOptions,
            icon: const Icon(Icons.favorite, size: 20),
            label: const Text(
              'Donate Now',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Apple App Publisher: \$90/year',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.green[400] 
                  : Colors.green[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'UI/UX Development: \$30/month',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.green[400] 
                  : Colors.green[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.green[700]
            : Colors.green[600],
        elevation: 4,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('App Settings'),
          _buildSettingsGroup([
            _buildThemeSelector(),
            _build24HourFormatToggle(),
          ]),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader('Prayer Notifications'),
          _buildSettingsGroup([
            _buildNotificationToggle(),
            _buildPreAdhanNotificationToggle(),
            _buildPrayerTimesReference(),
          ]),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader('About'),
          _buildSettingsGroup([
            _buildAboutTile(),
            _buildFeedbackTile(),
          ]),
          
          const SizedBox(height: 24),
          
          _buildDonationSection(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Change theme and save settings
  void _changeTheme(String mode) async {
    setState(() {
      themeMode = mode;
    });
    await _saveSettings();
    if (MyApp.of(context) != null) {
      MyApp.of(context)!.changeThemeFromString(mode);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.green[300]
              : Colors.green[700],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          int index = entry.key;
          Widget child = entry.value;
          
          return Column(
            children: [
              child,
              if (index < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]!.withOpacity(0.5)
                      : Colors.grey[200]!.withOpacity(0.5),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        _getThemeIcon(),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[600],
      ),
      title: Text(
        'Theme',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        _getThemeSubtitle(),
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[600]
            : Colors.grey[400],
      ),
      onTap: () {
        _showThemeDialog();
      },
    );
  }

  IconData _getThemeIcon() {
    switch (themeMode) {
      case 'light':
        return Icons.light_mode;
      case 'dark':
        return Icons.dark_mode;
      case 'system':
      default:
        return Icons.brightness_auto;
    }
  }

  String _getThemeSubtitle() {
    switch (themeMode) {
      case 'light':
        return 'Light theme enabled';
      case 'dark':
        return 'Dark theme enabled';
      case 'system':
      default:
        return 'Follow system theme';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('System Default'),
                subtitle: const Text('Follow your device settings'),
                leading: Radio<String>(
                  value: 'system',
                  groupValue: themeMode,
                  activeColor: Colors.green[600],
                  onChanged: (String? value) {
                    _changeTheme(value!);
                    Navigator.pop(context);
                  },
                ),
                trailing: const Icon(Icons.brightness_auto),
              ),
              ListTile(
                title: const Text('Light Mode'),
                leading: Radio<String>(
                  value: 'light',
                  groupValue: themeMode,
                  activeColor: Colors.green[600],
                  onChanged: (String? value) {
                    _changeTheme(value!);
                    Navigator.pop(context);
                  },
                ),
                trailing: const Icon(Icons.light_mode),
              ),
              ListTile(
                title: const Text('Dark Mode'),
                leading: Radio<String>(
                  value: 'dark',
                  groupValue: themeMode,
                  activeColor: Colors.green[600],
                  onChanged: (String? value) {
                    _changeTheme(value!);
                    Navigator.pop(context);
                  },
                ),
                trailing: const Icon(Icons.dark_mode),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _build24HourFormatToggle() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        Icons.access_time,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[600],
      ),
      title: Text(
        '24-Hour Format',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        is24HourFormat ? '24-hour time format' : '12-hour time format',
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: is24HourFormat,
        activeThumbColor: Colors.green[600],
        onChanged: (value) async {
          setState(() {
            is24HourFormat = value;
          });
          await _saveSettings();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                value
                    ? 'Switched to 24-hour format'
                    : 'Switched to 12-hour format',
              ),
              backgroundColor: Colors.green[600],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationToggle() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        Icons.notifications_outlined,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[600],
      ),
      title: Text(
        'Prayer Notifications',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        notificationsEnabled ? 'Notifications at prayer times' : 'Disabled',
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: notificationsEnabled,
        activeThumbColor: Colors.green[600],
        onChanged: (value) async {
          setState(() {
            notificationsEnabled = value;
            if (!value) {
              preAdhanNotificationsEnabled = false;
            }
          });
          await _saveSettings();
          if (value) {
            await NotificationWrapper.scheduleAllPrayerNotifications();
          } else {
            await NotificationWrapper.cancelAllPrayerNotifications();
          }
        },
      ),
    );
  }

  Widget _buildPreAdhanNotificationToggle() {
    return ListTile(
      enabled: notificationsEnabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        Icons.notifications_active_outlined,
        color: notificationsEnabled && preAdhanNotificationsEnabled 
            ? Colors.green[600] 
            : (Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[600]
                : Colors.grey[400]),
      ),
      title: Text(
        '15-Min Pre-Adhan Alert',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: notificationsEnabled 
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.grey[800])
              : Colors.grey,
        ),
      ),
      subtitle: Text(
        preAdhanNotificationsEnabled && notificationsEnabled 
            ? 'Alert 15 minutes before each prayer' 
            : 'Disabled',
        style: TextStyle(
          fontSize: 14,
          color: notificationsEnabled 
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600])
              : Colors.grey,
        ),
      ),
      trailing: Switch(
        value: preAdhanNotificationsEnabled && notificationsEnabled,
        activeThumbColor: Colors.green[600],
        onChanged: notificationsEnabled ? (value) async {
          setState(() {
            preAdhanNotificationsEnabled = value;
          });
          await _saveSettings();
          if (notificationsEnabled) {
            await NotificationWrapper.scheduleAllPrayerNotifications();
          } else {
            await NotificationWrapper.cancelAllPrayerNotifications();
          }
        } : null,
      ),
    );
  }

  Widget _buildPrayerTimesReference() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        Icons.schedule_outlined,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[600],
      ),
      title: Text(
        'Official 2025 Timetable',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        'View Windsor Islamic Association PDF',
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.open_in_new,
        size: 16,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[600]
            : Colors.grey[400],
      ),
      onTap: () {
        _showPrayerTimesDialog();
      },
    );
  }

  Widget _buildAboutTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        Icons.info_outline,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[600],
      ),
      title: Text(
        'About WIA',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        'Windsor Islamic Association',
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[600]
            : Colors.grey[400],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutWIAScreen()),
        );
      },
    );
  }

  Widget _buildFeedbackTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        Icons.feedback_outlined,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[600],
      ),
      title: Text(
        'Send Feedback',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        'Help us improve',
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[600]
            : Colors.grey[400],
      ),
      onTap: () {
        _showFeedbackDialog();
      },
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send Feedback'),
          content: const Text('Would you like to send feedback about the app?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _launchFeedbackForm();
              },
              child: const Text('Send Feedback'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchFeedbackForm() async {
    final Uri feedbackUrl = Uri.parse('https://forms.gle/CMDuaJLNnQ7mwEq38');
    
    try {
      if (await canLaunchUrl(feedbackUrl)) {
        await launchUrl(
          feedbackUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open feedback form'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error opening feedback form'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  void _showPrayerTimesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Official 2025 Timetable'),
          content: const Text(
            'All prayer times in this app are sourced from the Windsor Islamic Association\'s official 2025 timetable. '
            'Would you like to visit their website to view the complete PDF document?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _launchTimetableWebsite();
              },
              child: const Text('Visit'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchTimetableWebsite() async {
    final Uri url = Uri.parse('https://windsorislamicassociation.com/prayer-times');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open website'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error opening website'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }
}
