// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

import 'package:josephs_vs_01/management/notifications.dart';
import 'package:josephs_vs_01/pages/dashboard.dart';
import 'package:josephs_vs_01/pages/homepage.dart';

/// 🔑 GLOBAL NAVIGATOR KEY
/// Utilisé par NotificationServices pour naviguer
/// même hors du contexte widget (notif tap, etc.)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Timezone required for zonedSchedule
  await NotificationServices.initTimeZone();

  // ✅ Init notifications plugin once
  await NotificationServices.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Josephs',
      debugShowCheckedModeBanner: false,

      // ✅ CRUCIAL POUR LES NOTIFICATIONS
      navigatorKey: navigatorKey,

      // ✅ ENTRY POINT
      home: HomePage(),

      // ✅ Routes for notification navigation
      routes: {'/dashboard': (_) => const Dashboard()},
    );
  }
}
