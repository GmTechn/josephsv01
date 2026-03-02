// ignore_for_file: use_build_context_synchronously, use_key_in_widget_constructors

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:josephs_vs_01/pages/dashboard.dart';
import 'package:josephs_vs_01/pages/onboarding.dart';

class HomePage extends StatefulWidget {
  const HomePage();

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
    // Splash delay
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();

    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!mounted) return;

    if (hasSeenOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.book_fill,
              color: Color(0xff050c20),
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text(
              "J O S E P H ' S",
              style: TextStyle(
                fontFamily: 'Abel',
                fontWeight: FontWeight.bold,
                fontSize: 38,
                color: Color(0xff050c20),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to your personal task manager!',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
