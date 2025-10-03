import 'package:flutter/material.dart';
import 'package:attendence_tracker/theme/app_theme.dart';
import 'package:attendence_tracker/services/storage_service.dart';
import 'package:attendence_tracker/services/firebase_service.dart';

import 'package:attendence_tracker/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  bool firebaseInitialized = false;
  try {
    await FirebaseService.initialize();
    print('Firebase initialized successfully');
    firebaseInitialized = true;
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue with local storage only if Firebase fails
  }

  // Initialize storage with enhanced persistence
  try {
    await StorageService.init();
    print('Storage initialized successfully');
  } catch (e) {
    print('Storage initialization error: $e');
    // Even if there's an error, we'll continue with the app
    // The storage service has recovery mechanisms
  }

  runApp(AttendanceTrackerApp(firebaseInitialized: firebaseInitialized));
}

class AttendanceTrackerApp extends StatefulWidget {
  final bool firebaseInitialized;

  const AttendanceTrackerApp({super.key, required this.firebaseInitialized});

  @override
  State<AttendanceTrackerApp> createState() => _AttendanceTrackerAppState();
}

class _AttendanceTrackerAppState extends State<AttendanceTrackerApp> {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final isDark = await StorageService.isDarkMode();
    setState(() {
      _isDarkMode = isDark;
    });
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await StorageService.setDarkMode(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Attendance Tracker',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(onThemeToggle: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}
