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
    // ✅ keep splash
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();

    // ===========================
    // 🔥 CHANGE #1 (optional debug)
    // Add prints to see what's happening
    // ===========================
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final hasAccount = prefs.getBool('hasAccount') ?? false;

    debugPrint("hasSeenOnboarding = $hasSeenOnboarding");
    debugPrint("hasAccount = $hasAccount");

    // ===========================
    // 🔥 CHANGE #2 (clean routing)
    // Build the destination first, then navigate once
    // ===========================
    if (!mounted) return;

    final Widget next =
        (hasSeenOnboarding && hasAccount) // ✅ same rule, but cleaner
        ? const Dashboard()
        : const OnboardingPage();

    // ===========================
    // 🔥 CHANGE #3 (safer navigation)
    // Use pushReplacement only once (no duplicated blocks)
    // ===========================
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
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
            Text(
              "J O S E P H ' S",

              style: TextStyle(
                fontFamily: 'Abel',
                fontWeight: FontWeight.bold,
                fontSize: 38,
                color: const Color(0xff050c20),
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
