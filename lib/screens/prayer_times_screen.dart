import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show compute;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({Key? key}) : super(key: key);

  @override
  _PrayerTimesScreenState createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  Map<String, dynamic>? prayerData;
  DateTime selectedDate = DateTime.now();
  DateTime currentDate = DateTime.now();
  bool isLoading = true;
  String errorMessage = '';
  Timer? _timer;
  Duration _timeUntilNextPrayer = Duration.zero;
  String _nextPrayerName = '';
  bool _isToday = true;
  bool _use24HourFormat = false;

  @override
  void initState() {
    super.initState();
    // Load preferences and data in parallel, non-blocking
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    // Start both operations in parallel
    final preferencesFuture = _load24HourPreference();
    final dataFuture = _loadPrayerTimes();
    
    // Wait for both to complete
    await Future.wait([preferencesFuture, dataFuture]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh the 24-hour preference when returning from settings
    _load24HourPreference();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
      
      // Load and parse JSON in background isolate for better performance
      final String jsonString = await rootBundle.loadString('assets/prayer_times.json');
      
      // Parse JSON asynchronously to avoid blocking main thread
      final Map<String, dynamic> data = await compute(_parseJson, jsonString);
      
      setState(() {
        prayerData = data;
        isLoading = false;
      });
      
      // Start the countdown timer after data is loaded
      _startCountdownTimer();
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load prayer times: $e';
        isLoading = false;
      });
    }
  }

  // Static function for isolate parsing
  static Map<String, dynamic> _parseJson(String jsonString) {
    return json.decode(jsonString);
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2025, 1),
      lastDate: DateTime(2025, 12, 31),
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _isToday = _isSelectedDateToday();
      });
      
      // Only start timer if viewing today
      if (_isToday) {
        _startCountdownTimer();
      } else {
        _timer?.cancel();
      }
    }
  }

  void _refreshToCurrentDate() {
    setState(() {
      selectedDate = DateTime.now();
      _isToday = true;
    });
    _startCountdownTimer();
  }

  bool _isSelectedDateToday() {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
           selectedDate.month == now.month &&
           selectedDate.day == now.day;
  }

  Future<void> _load24HourPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _use24HourFormat = prefs.getBool('24_hour_format') ?? false;
    });
  }

  String _formatTimeString(String timeString) {
    if (!_use24HourFormat) {
      return timeString; // Return original format (12-hour with AM/PM)
    }
    
    // Convert to 24-hour format
    final parts = timeString.split(' ');
    if (parts.length != 2) return timeString;
    
    final timePart = parts[0];
    final period = parts[1];
    final timeParts = timePart.split(':');
    if (timeParts.length != 2) return timeString;
    
    int hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = timeParts[1];
    
    if (period.toUpperCase() == 'PM' && hour != 12) {
      hour += 12;
    } else if (period.toUpperCase() == 'AM' && hour == 12) {
      hour = 0;
    }
    
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  void _startCountdownTimer() {
    _timer?.cancel();
    
    // Only calculate countdown if viewing today
    if (_isToday) {
      // Calculate time until next prayer
      _calculateTimeUntilNextPrayer();
      
      // Update the timer every second
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeUntilNextPrayer.inSeconds > 0) {
          setState(() {
            _timeUntilNextPrayer = _timeUntilNextPrayer - const Duration(seconds: 1);
          });
        } else {
          // When countdown reaches zero, recalculate for the next prayer
          _calculateTimeUntilNextPrayer();
        }
        
        // Widget updating removed - no widgets currently registered
      });
    }
  }

  void _calculateTimeUntilNextPrayer() {
    if (prayerData == null) return;
    
    final String dateKey = _formatDateKey(selectedDate);
    final dayData = prayerData?[dateKey];
    if (dayData == null) return;
    
    final times = dayData['times'];
    final now = DateTime.now();
    
    // Define prayer times in order
    final prayers = [
      {'name': 'Fajr', 'time': _parseTimeString(times['fajr']['adhan'])},
      {'name': 'Dhuhr', 'time': _parseTimeString(times['dhuhr']['adhan'])},
      {'name': 'Asr', 'time': _parseTimeString(times['asr']['adhan'])},
      {'name': 'Maghrib', 'time': _parseTimeString(times['maghrib']['adhan'])},
      {'name': 'Isha', 'time': _parseTimeString(times['isha']['adhan'])},
    ];
    
    // Find the next prayer
    DateTime nextPrayerTime = DateTime(now.year, now.month, now.day, 23, 59, 59);
    String nextPrayerName = 'Fajr';
    
    for (var prayer in prayers) {
      DateTime prayerTime = prayer['time'] as DateTime;
      if (prayerTime.isAfter(now) && prayerTime.isBefore(nextPrayerTime)) {
        nextPrayerTime = prayerTime;
        nextPrayerName = prayer['name'] as String;
      }
    }
    
    // If no prayer found for today, use first prayer of next day
    if (nextPrayerTime.hour == 23 && nextPrayerTime.minute == 59) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowKey = _formatDateKey(tomorrow);
      final tomorrowData = prayerData?[tomorrowKey];
      
      if (tomorrowData != null) {
        final tomorrowTimes = tomorrowData['times'];
        nextPrayerTime = _parseTimeString(tomorrowTimes['fajr']['adhan']).add(const Duration(days: 1));
      }
    }
    
    setState(() {
      _timeUntilNextPrayer = nextPrayerTime.difference(now);
      _nextPrayerName = nextPrayerName;
    });
  }

  DateTime _parseTimeString(String timeStr) {
    // Parse time string like "5:21 AM" or "1:33 PM"
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    
    if (parts[1].toUpperCase() == 'PM' && hour != 12) {
      hour += 12;
    } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
      hour = 0;
    }
    
    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour, minute);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildPrayerTimeRow(String prayerName, String adhanTime, String iqamaTime) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [Colors.grey[850]!, Colors.grey[800]!]
              : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.green[700]!.withOpacity(0.3)
              : Colors.green[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.green[100]!.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                prayerName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.green[300]
                      : Colors.green[700],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Adhan",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          adhanTime,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 25,
                    alignment: Alignment.center,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[600]!.withOpacity(0.5)
                        : Colors.green[300]!.withOpacity(0.7),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Iqama",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          iqamaTime,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSunriseBox(String time) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [Colors.orange[900]!.withOpacity(0.3), Colors.orange[800]!.withOpacity(0.2)]
              : [Colors.orange[50]!, Colors.orange[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.orange[600]!.withOpacity(0.4)
              : Colors.orange[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.orange[100]!.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                "Sunrise",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.orange[300]
                      : Colors.orange[700],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJummaBox() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [Colors.green[900]!.withOpacity(0.4), Colors.green[800]!.withOpacity(0.3)]
              : [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.green[600]!.withOpacity(0.5)
              : Colors.green[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.green[900]!.withOpacity(0.3)
                : Colors.green[200]!.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Text(
              "Jumma",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.green[300]
                    : Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "12:45",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[800],
                  ),
                ),
                Text(
                  "|",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[400]
                        : Colors.green[600],
                  ),
                ),
                Text(
                  "1:45",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[800],
                  ),
                ),
                Text(
                  "|",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[400]
                        : Colors.green[600],
                  ),
                ),
                Text(
                  "3:00",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.green[400]!
                      : Colors.green[600]!,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading prayer times...',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.green[300]
                      : Colors.green[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[400],
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPrayerTimes,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text("Retry", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.green[600]
                      : Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final String dateKey = _formatDateKey(selectedDate);
    final dayData = prayerData?[dateKey];
    
    if (dayData == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[400],
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No prayer times available for selected date',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refreshToCurrentDate,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text("Back to Today", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.green[600]
                      : Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final gregorian = dayData['gregorian'];
    final hijri = dayData['hijri'];
    final times = dayData['times'];

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.green[700]
            : Colors.green[600],
        elevation: 4,
        toolbarHeight: 50,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Prayer Times',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Date Display Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
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
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.green[900]!.withOpacity(0.3)
                      : Colors.green[200]!.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "${gregorian['weekday']}, ${gregorian['day']} ${gregorian['month']} ${gregorian['year']}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[200]
                        : Colors.green[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  "${hijri['day']} ${hijri['month']} ${hijri['year']} AH",
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[300]
                        : Colors.green[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (_isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? [Colors.green[600]!, Colors.green[700]!]
                            : [Colors.green[600]!, Colors.green[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "${_formatDuration(_timeUntilNextPrayer)} until ${_nextPrayerName}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Text(
                    "Viewing historical date",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.orange[300]
                          : Colors.orange[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),

          // Prayer Times List
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildPrayerTimeRow("Fajr", _formatTimeString(times['fajr']['adhan']), _formatTimeString(times['fajr']['iqama'])),
                  _buildSunriseBox(times['sunrise']),
                  _buildPrayerTimeRow("Dhuhr", _formatTimeString(times['dhuhr']['adhan']), _formatTimeString(times['dhuhr']['iqama'])),
                  _buildPrayerTimeRow("Asr", _formatTimeString(times['asr']['adhan']), _formatTimeString(times['asr']['iqama'])),
                  _buildPrayerTimeRow("Maghrib", _formatTimeString(times['maghrib']['adhan']), _formatTimeString(times['maghrib']['iqama'])),
                  _buildPrayerTimeRow("Isha", _formatTimeString(times['isha']['adhan']), _formatTimeString(times['isha']['iqama'])),
                  _buildJummaBox(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [Colors.grey[850]!, Colors.grey[900]!]
                    : [Colors.white, Colors.grey[100]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.green[700]!.withOpacity(0.3)
                      : Colors.green[200]!,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text("Select Date"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[600]
                        : Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _refreshToCurrentDate,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Today"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[600]
                        : Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}