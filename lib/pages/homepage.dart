// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:josephs_vs_01/pages/dashboard.dart';
import 'package:josephs_vs_01/pages/onboarding.dart';
import 'package:josephs_vs_01/pages/profilesetup.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();

    final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final bool hasCompletedProfile =
        prefs.getBool('hasCompletedProfile') ?? false;

    debugPrint('hasSeenOnboarding: $hasSeenOnboarding');
    debugPrint('hasCompletedProfile: $hasCompletedProfile');

    if (!mounted) return;

    Widget nextPage;

    if (hasCompletedProfile) {
      nextPage = const Dashboard();
    } else if (hasSeenOnboarding) {
      nextPage = const SetUpProfile();
    } else {
      nextPage = const OnboardingPage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.book_fill, color: Color(0xff050c20), size: 64),
            SizedBox(height: 20),
            Text(
              "J O S E P H ' S",
              style: TextStyle(
                fontFamily: 'Abel',
                fontWeight: FontWeight.bold,
                fontSize: 38,
                color: Color(0xff050c20),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Welcome to your personal task manager!",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
