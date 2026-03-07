// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:josephs_vs_01/components/mybutton.dart';
import 'package:josephs_vs_01/pages/profilesetup.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/onboarding1.jpg",
      "title": "Boost Your Productivity",
      "subtitle": "Stay organized and motivated every day with Joseph's.",
    },

    {
      "image": "assets/images/onboarding2.jpg",
      "title": "Create & Manage Tasks",
      "subtitle": "Add tasks and visualize progress with smart colors.",
    },

    {
      "image": "assets/images/onboarding3.jpg",
      "title": "Get Smart Notifications",
      "subtitle": "Never miss a thing with reminders.",
    },

    {
      "image": "assets/images/onboarding4.jpg",
      "title": "Let’s Get Started!",
      "subtitle": "Your productivity journey begins now.",
    },
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SetUpProfile()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == onboardingData.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,

          itemCount: onboardingData.length,

          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },

          itemBuilder: (context, index) {
            final data = onboardingData[index];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(data["image"]!, fit: BoxFit.cover),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    data["title"]!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff050c20),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    data["subtitle"]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 40),

                  if (isLastPage)
                    MyButton(text: "Get Started", onPressed: _finishOnboarding),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
