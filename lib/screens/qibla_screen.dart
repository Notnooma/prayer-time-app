import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({Key? key}) : super(key: key);

  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with TickerProviderStateMixin {
  bool _hasPermissions = false;
  double? _heading = 0;
  double? _qiblaDirection;
  String _locationName = "Windsor";
  StreamSubscription<CompassEvent>? _compassSubscription;
  late AnimationController _calibrationController;
  int _calibrationStep = 0;
  
  // Compass smoothing variables for better performance
  double? _lastHeading;
  DateTime _lastUpdate = DateTime.now();
  static const int _updateInterval = 50; // milliseconds - throttle updates
  static const double _smoothingFactor = 0.3; // Lower = smoother, Higher = more responsive
  
  // Kaaba coordinates
  static const double _kaabaLatitude = 21.4225;
  static const double _kaabaLongitude = 39.8262;
  
  @override
  void initState() {
    super.initState();
    _calibrationController = AnimationController(
      duration: const Duration(milliseconds: 1200), // Slightly faster animation
      vsync: this,
    );
    _calibrationController.addListener(() {
      if (_calibrationController.isCompleted) {
        if (mounted) {
          setState(() {
            _calibrationStep = (_calibrationStep + 1) % 4;
          });
        }
        _calibrationController.reset();
        _calibrationController.forward();
      }
    });
    _calibrationController.forward();
    _fetchPermissionsAndLocation();
  }

  Future<void> _fetchPermissionsAndLocation() async {
    // Check location permission
    final locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted) {
      return;
    }

    // Get current location with optimized settings
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // Add timeout for better UX
      );
      
      // Get city name from coordinates (with error handling)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude
        ).timeout(const Duration(seconds: 10)); // Add timeout for geocoding
        
        if (placemarks.isNotEmpty && mounted) {
          final placemark = placemarks.first;
          String cityName = placemark.locality ?? 
                           placemark.subAdministrativeArea ?? 
                           placemark.administrativeArea ?? 
                           "Unknown Location";
          setState(() {
            _locationName = cityName;
          });
        }
      } catch (e) {
        // Keep default location name if geocoding fails
      }
      
      // Calculate Qibla direction
      double qibla = _calculateQiblaDirection(
        position.latitude,
        position.longitude,
      );
      
      if (mounted) {
        setState(() {
          _qiblaDirection = qibla;
          _hasPermissions = true;
        });
      }
    } catch (e) {
      // Use Windsor, ON coordinates as fallback
      double qibla = _calculateQiblaDirection(42.3149, -83.0364);
      if (mounted) {
        setState(() {
          _qiblaDirection = qibla;
          _hasPermissions = true;
        });
      }
    }

    // Start listening to compass with smoothing and throttling for better performance
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (!mounted || event.heading == null) return;
      
      final now = DateTime.now();
      
      // Throttle updates to prevent excessive rebuilds
      if (now.difference(_lastUpdate).inMilliseconds < _updateInterval) {
        return;
      }
      
      double newHeading = event.heading!;
      
      // Handle 360° wrap-around for smooth transitions
      if (_lastHeading != null) {
        double diff = newHeading - _lastHeading!;
        
        // If crossing 0°/360° boundary, adjust for smooth transition
        if (diff > 180) {
          newHeading -= 360;
        } else if (diff < -180) {
          newHeading += 360;
        }
        
        // Apply exponential smoothing for fluid motion
        newHeading = _lastHeading! + (_smoothingFactor * (newHeading - _lastHeading!));
        
        // Normalize back to 0-360 range
        newHeading = (newHeading + 360) % 360;
      }
      
      _lastHeading = newHeading;
      _lastUpdate = now;
      
      setState(() {
        _heading = newHeading;
      });
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _calibrationController.dispose();
    super.dispose();
  }

  double _calculateQiblaDirection(double latitude, double longitude) {
    double phiK = _kaabaLatitude * (math.pi / 180.0);
    double lambdaK = _kaabaLongitude * (math.pi / 180.0);
    double phi = latitude * (math.pi / 180.0);
    double lambda = longitude * (math.pi / 180.0);
    
    double y = math.sin(lambdaK - lambda);
    double x = math.cos(phi) * math.tan(phiK) - 
               math.sin(phi) * math.cos(lambdaK - lambda);
    
    double qibla = math.atan2(y, x);
    qibla = qibla * (180.0 / math.pi);
    qibla = (qibla + 360.0) % 360.0;
    
    return qibla;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1a3a52) : const Color(0xFF2c5f7c),
      appBar: AppBar(
        title: const Text('Qibla Compass'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: GestureDetector(
          onPanUpdate: (details) {
            // Detect swipe from left edge - made more sensitive
            if (details.delta.dx > 8 && details.globalPosition.dx < 80) {
              Navigator.pop(context);
            }
          },
          onPanEnd: (details) {
            // Alternative: detect completed swipe gesture
            if (details.velocity.pixelsPerSecond.dx > 500 && details.localPosition.dx < 100) {
              Navigator.pop(context);
            }
          },
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'LOCATION',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _locationName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Compass
              Expanded(
                child: Center(
                  child: _hasPermissions
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            // Compass Circle with optimized rotation
                            Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: AnimatedRotation(
                                turns: -(_heading ?? 0) / 360.0, // Smooth animated rotation
                                duration: const Duration(milliseconds: 100), // Fast, smooth transitions
                                child: CustomPaint(
                                  size: const Size(280, 280),
                                  painter: CompassPainter(),
                                ),
                              ),
                            ),
                            
                            // Qibla Direction Indicator (Orange line from center pointing away)
                            if (_qiblaDirection != null)
                              AnimatedRotation(
                                turns: ((_qiblaDirection! - (_heading ?? 0) + 180) % 360) / 360.0,
                                duration: const Duration(milliseconds: 100), // Smooth animated rotation
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: 140), // Space from center to start line
                                    // Orange Qibla line from center pointing away from Qibla
                                    QiblaLine(
                                      width: 3,
                                      height: 100,
                                      color: Colors.orange,
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Red Reference Line (Fixed North - straight up from center pointing away)
                            AnimatedRotation(
                              turns: 0.5, // 180 degrees to point away from North
                              duration: Duration(milliseconds: 100),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: 140), // Space from center to start line
                                  // Red reference line pointing away from North
                                  QiblaLine(
                                    width: 2,
                                    height: 100,
                                    color: Color.fromRGBO(244, 67, 54, 0.8),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              color: Colors.white.withOpacity(0.5),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Location permission required',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              // Direction Text
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Text(
                  _getDirectionText(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getDirectionText() {
    if (_qiblaDirection == null || _heading == null) {
      final calibrationTexts = [
        'Calibrating',
        'Calibrating.',
        'Calibrating..',
        'Calibrating...'
      ];
      return calibrationTexts[_calibrationStep];
    }
    
    double diff = (_qiblaDirection! - _heading!) % 360;
    
    if (diff > 180) diff -= 360;
    
    if (diff.abs() < 5) {
      return 'You are facing Makkah';
    } else if (diff > 0) {
      return 'Turn to your right';
    } else {
      return 'Turn to your left';
    }
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw cardinal directions
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    final directions = ['N', 'E', 'S', 'W'];
    final angles = [0, 90, 180, 270];
    
    for (int i = 0; i < 4; i++) {
      final angle = angles[i] * (math.pi / 180) - math.pi / 2;
      final x = center.dx + radius * 0.85 * math.cos(angle);
      final y = center.dy + radius * 0.85 * math.sin(angle);
      
      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: directions[i] == 'N' 
              ? Colors.red.withOpacity(0.8)
              : Colors.white.withOpacity(0.6),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
    
    // Draw degree markers
    for (int i = 0; i < 360; i += 30) {
      final angle = i * (math.pi / 180) - math.pi / 2;
      final start = Offset(
        center.dx + radius * 0.95 * math.cos(angle),
        center.dy + radius * 0.95 * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * 0.9 * math.cos(angle),
        center.dy + radius * 0.9 * math.sin(angle),
      );
      
      canvas.drawLine(start, end, paint);
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Optimized reusable widget for compass lines
class QiblaLine extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const QiblaLine({
    Key? key,
    required this.width,
    required this.height,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(width / 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}