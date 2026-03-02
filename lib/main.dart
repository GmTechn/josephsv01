// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'pages/homepage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ INIT TIMEZONE (FIX NOTIFICATION CRASH)
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('selected_theme') ?? 'original';

  runApp(MyApp(initialTheme: savedTheme));
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
  const MyApp({super.key, required this.initialTheme});

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

  // ================= LIGHT =================
  ThemeData _buildLightTheme() {
    final seed = _seedFromKey(_currentTheme);

    if (_currentTheme == "original") {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF050C20),
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF050C20),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF050C20),
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF050C20),
          unselectedItemColor: Colors.black54,
          type: BottomNavigationBarType.fixed,
        ),
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
    );
  }

  // ================= DARK =================
  ThemeData _buildDarkTheme() {
    if (_currentTheme == "original") {
      return ThemeData(useMaterial3: true, brightness: Brightness.dark);
    }

    final seed = _seedFromKey(_currentTheme) ?? const Color(0xFF050C20);

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
      home: const HomePage(),
    );
  }
}
