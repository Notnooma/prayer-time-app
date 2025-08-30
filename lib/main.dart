import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_wrapper.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only essential UI setup that can't be deferred
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  // Start app immediately - defer orientation lock
  runApp(MyApp());
  
  // Set orientation after app starts (non-blocking)
  Future.microtask(() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  });
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Load theme with default first for instant UI
    _setDefaultTheme();
    
    // Initialize everything after UI is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load actual theme preferences
      _loadThemePreferences();
      
      // Start background initialization with progressive delays
      _initializeInStages();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // When app comes to foreground, check if we need to reschedule
    if (state == AppLifecycleState.resumed) {
      NotificationWrapper.checkAndReschedule();
    }
  }

  void _setDefaultTheme() {
    // Set default theme immediately for instant UI
    _themeMode = ThemeMode.system;
  }

  void _loadThemePreferences() {
    // Load theme preferences in background
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      
      String themeModeString = prefs.getString('theme_mode') ?? 'system';
      
      // For backward compatibility
      if (!prefs.containsKey('theme_mode') && prefs.containsKey('dark_mode')) {
        bool oldDarkMode = prefs.getBool('dark_mode') ?? false;
        themeModeString = oldDarkMode ? 'dark' : 'light';
      }
      
      ThemeMode newMode;
      switch (themeModeString) {
        case 'dark':
          newMode = ThemeMode.dark;
          break;
        case 'light':
          newMode = ThemeMode.light;
          break;
        case 'system':
        default:
          newMode = ThemeMode.system;
          break;
      }
      
      if (newMode != _themeMode) {
        setState(() {
          _themeMode = newMode;
        });
      }
    }).catchError((e) {
      // Keep default theme if loading fails
    });
  }

  void _initializeInStages() {
    // Stage 1: Core UI is shown (0ms) - already done
    
    // Stage 2: Light initialization (100ms delay)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _initializeEssentials();
    });
    
    // Stage 3: Notification system (300ms delay)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _initializeNotifications();
    });
    
    // Stage 4: Background services (800ms delay)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _initializeBackgroundServices();
    });
  }

  void _initializeEssentials() {
    // Quick essential setup that doesn't block UI
    try {
      NotificationWrapper.setupNotificationListeners();
    } catch (e) {
      // Silent error handling for production
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationWrapper.initialize();
    } catch (e) {
      // Silent error handling for production
    }
  }

  Future<void> _initializeBackgroundServices() async {
    try {
      // Background notification scheduling
      await NotificationWrapper.checkAndReschedule();
      
      // Check notification prompt after everything else is ready
      final prefs = await SharedPreferences.getInstance();
      final asked = prefs.getBool('asked_notification') ?? false;
      
      if (!asked && mounted) {
        _showSimpleNotificationPrompt();
      }
    } catch (e) {
      // Silent error handling for production
    }
  }



  void _showSimpleNotificationPrompt() {
    // Simple snackbar instead of blocking dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: const Text('Enable prayer time notifications?'),
            action: SnackBarAction(
              label: 'Enable',
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('asked_notification', true);
                await prefs.setBool('notifications_enabled', true);
                // TODO: Re-enable when NotificationService is fixed
                // await NotificationService.scheduleAllPrayerNotifications();
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }



  void changeThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    _saveThemeMode();
  }

  void changeTheme(bool? isDarkMode) {
    ThemeMode newMode;
    if (isDarkMode == null) {
      newMode = ThemeMode.system;
    } else if (isDarkMode) {
      newMode = ThemeMode.dark;
    } else {
      newMode = ThemeMode.light;
    }
    changeThemeMode(newMode);
  }

  void changeThemeFromString(String themeString) {
    ThemeMode newMode;
    switch (themeString.toLowerCase()) {
      case 'dark':
        newMode = ThemeMode.dark;
        break;
      case 'light':
        newMode = ThemeMode.light;
        break;
      case 'system':
      default:
        newMode = ThemeMode.system;
        break;
    }
    changeThemeMode(newMode);
  }

  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeString = 'system';
    
    switch (_themeMode) {
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }
    
    await prefs.setString('theme_mode', themeModeString);
    
    // For backward compatibility
    if (_themeMode == ThemeMode.dark) {
      await prefs.setBool('dark_mode', true);
    } else if (_themeMode == ThemeMode.light) {
      await prefs.setBool('dark_mode', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'WIA Prayer Times',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      themeMode: _themeMode,
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}