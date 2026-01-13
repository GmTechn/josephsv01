// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:josephs_vs_01/management/notifications.dart';
import 'package:josephs_vs_01/pages/dashboard.dart';
import 'package:josephs_vs_01/pages/homepage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationServices.initTimeZone();
  await NotificationServices.instance.initialize();
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Josephs',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,

      // ✅ ENTRY POINT
      home: const HomePage(),

      routes: {'/dashboard': (_) => const Dashboard()},
    );
  }
}
