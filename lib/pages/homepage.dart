// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:josephs_vs_01/components/mybutton.dart';
import 'package:josephs_vs_01/pages/dashboard.dart';
import 'package:josephs_vs_01/pages/onboarding.dart';

class HomePage extends StatelessWidget {
  const HomePage();

  Future<void> _goNext(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // If user has seen onboarding before, skip it
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (hasSeenOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    } else {
      Navigator.push(
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
            Text(
              'J O S E P H \'S',
              style: GoogleFonts.abel(
                fontWeight: FontWeight.bold,
                fontSize: 38,
                color: const Color(0xff050c20),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to your personal task manager!',
              style: GoogleFonts.inter(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            MyButton(onPressed: () => _goNext(context), text: "Next"),
          ],
        ),
      ),
    );
  }
}
