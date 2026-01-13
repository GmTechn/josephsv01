// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:josephs_vs_01/components/mybutton.dart';
import 'package:josephs_vs_01/pages/profilesetup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  Future<void> _handleGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SetUpProfile()),
    );
  }

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ✅ CHANGE #1: helper to go Next
  void _goNext() {
    if (_currentPage >= onboardingData.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ✅ CHANGE #2: helper to go Back (optional)
  void _goBack() {
    if (_currentPage <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/onboarding1.jpg",
      "title": "Boost Your Productivity",
      "subtitle":
          "Stay organized and motivated every day with Joseph's, your productivity partner.",
    },
    {
      "image": "assets/images/onboarding2.jpg",
      "title": "Create & Manage Tasks",
      "subtitle":
          "Add tasks, set times, and visualize your progress with smart color codes that adapt to your schedule.",
    },
    {
      "image": "assets/images/onboarding3.jpg",
      "title": "Get Smart Notifications",
      "subtitle":
          "Never miss a thing! Receive reminders and updates exactly when it’s time to act.",
    },
    {
      "image": "assets/images/onboarding4.jpg",
      "title": "Let’s Get Started!",
      "subtitle":
          "Your productivity journey begins now. Track, manage, and complete your tasks effortlessly.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == onboardingData.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          itemCount: onboardingData.length,

          // ✅ CHANGE #3: keep scroll enabled + nicer feel on iOS
          physics: const BouncingScrollPhysics(),

          onPageChanged: (index) {
            setState(() => _currentPage = index);
          },
          itemBuilder: (context, index) {
            final data = onboardingData[index];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// IMAGE
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(data["image"]!, fit: BoxFit.cover),
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// TITLE
                  Text(
                    data["title"]!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff050c20),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  /// SUBTITLE
                  Text(
                    data["subtitle"]!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  /// DOTS (clickable)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                      (i) => GestureDetector(
                        // ✅ CHANGE #4: tap dot -> go to that page
                        onTap: () {
                          _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                        child: _buildDot(i),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// ✅ CHANGE #5: show Back/Next on non-last pages
                  if (!isLastPage) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _currentPage == 0 ? null : _goBack,
                          child: Text(
                            "Back",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: const Color(0xff050c20),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(onPressed: _goNext, child: Text("Next")),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  /// ✅ BUTTON ONLY ON LAST PAGE
                  if (isLastPage) ...[
                    MyButton(onPressed: _handleGetStarted, text: "Get Started"),
                    const SizedBox(height: 30),
                  ] else ...[
                    // Keeps spacing consistent
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: _currentPage == index ? 20 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? const Color(0xff050c20)
            : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
