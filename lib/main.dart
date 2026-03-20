// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:josephs_vs_01/management/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'pages/dashboard.dart';
import 'pages/homepage.dart';
import 'pages/onboarding.dart';
import 'pages/profilesetup.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));

  // Notifications
  await NotificationServices.instance.initialize();

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('selected_theme') ?? 'original';

  final bool hasSeenSplash = prefs.getBool('hasSeenSplash') ?? false;
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  final bool hasCompletedProfile =
      prefs.getBool('hasCompletedProfile') ?? false;

  Widget firstPage;

  if (!hasSeenSplash) {
    firstPage = const HomePage();
  } else if (!hasSeenOnboarding) {
    firstPage = const OnboardingPage();
  } else if (!hasCompletedProfile) {
    firstPage = const SetUpProfile();
  } else {
    firstPage = const Dashboard();
  }

  runApp(MyApp(initialTheme: savedTheme, firstPage: firstPage));
}

@immutable
class AppThemeKey extends ThemeExtension<AppThemeKey> {
  final String key;

  const AppThemeKey(this.key);

  @override
  AppThemeKey copyWith({String? key}) {
    return AppThemeKey(key ?? this.key);
  }

  @override
  AppThemeKey lerp(ThemeExtension<AppThemeKey>? other, double t) {
    if (other is! AppThemeKey) return this;
    return this;
  }
}

class MyApp extends StatefulWidget {
  final String initialTheme;
  final Widget firstPage;

  const MyApp({super.key, required this.initialTheme, required this.firstPage});

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late String _currentTheme;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme;
  }

  Future<void> changeTheme(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', key);
    setState(() => _currentTheme = key);
  }

  Color? _seedFromKey(String key) {
    switch (key) {
      case "purple":
        return const Color(0xFFCAA8F5);
      case "pink":
        return const Color(0xFFF8BBD0);
      case "blue":
        return const Color(0xFF099DFF);
      case "green":
        return const Color(0xFF00C853);
      case "red":
        return const Color(0xFFEC080C);
      case "orange":
        return const Color(0xFFFF6D00);
      case "dark":
        return const Color(0xFF050C20);
      case "original":
      default:
        return null;
    }
  }

  ThemeData _buildLightTheme() {
    final seed = _seedFromKey(_currentTheme);

    if (_currentTheme == "original") {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF050C20),
          unselectedItemColor: Colors.black54,
          type: BottomNavigationBarType.fixed,
        ),
        extensions: const [AppThemeKey("original")],
      );
    }

    final scheme = ColorScheme.fromSeed(
      seedColor: seed!,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
      ),
      extensions: [AppThemeKey(_currentTheme)],
    );
  }

  ThemeData _buildDarkTheme() {
    final seed = _seedFromKey(_currentTheme) ?? const Color(0xFF050C20);

    if (_currentTheme == "original") {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: const [AppThemeKey("original")],
      );
    }

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedItemColor: scheme.onSurface,
        unselectedItemColor: scheme.onSurface.withOpacity(0.55),
        type: BottomNavigationBarType.fixed,
      ),
      extensions: [AppThemeKey(_currentTheme)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _currentTheme == "dark";

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: widget.firstPage,
    );
  }
}
