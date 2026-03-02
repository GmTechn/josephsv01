import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:josephs_vs_01/pages/dashboard.dart';
import 'package:josephs_vs_01/pages/schedule.dart';
import 'package:josephs_vs_01/pages/tasks.dart';
import 'package:josephs_vs_01/main.dart'; // ✅ for AppThemeKey

class MyNavBar extends StatelessWidget {
  const MyNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final themeKey = theme.extension<AppThemeKey>()?.key ?? "original";
    final isOriginal = themeKey == "original";
    final isDark = theme.brightness == Brightness.dark;

    final navBg = isOriginal
        ? Colors.white
        : isDark
        ? scheme.surfaceContainerHighest
        : scheme.surfaceContainerLow;

    return BottomAppBar(
      color: navBg,
      child: SizedBox(
        height: 56,
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconBottomBar(
                text: "Home",
                icon: CupertinoIcons.house_fill,
                selected: currentIndex == 0,
                themeKey: themeKey,
              ),
              IconBottomBar(
                text: "Tasks",
                icon: CupertinoIcons.square_list_fill,
                selected: currentIndex == 1,
                themeKey: themeKey,
              ),
              IconBottomBar(
                text: "Schedule",
                icon: CupertinoIcons.calendar,
                selected: currentIndex == 2,
                themeKey: themeKey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IconBottomBar extends StatelessWidget {
  const IconBottomBar({
    super.key,
    required this.text,
    required this.icon,
    required this.selected,
    required this.themeKey,
  });

  final String text;
  final IconData icon;
  final bool selected;
  final String themeKey;

  void _go(BuildContext context) {
    if (text == "Home") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    } else if (text == "Tasks") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TasksPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SchedulePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isOriginal = themeKey == "original";

    final activeColor = isOriginal
        ? const Color(0xFF050C20)
        : isDark
        ? scheme.onSurface
        : scheme.primary;

    final inactiveColor = isOriginal
        ? Colors.black54
        : scheme.onSurface.withValues(alpha: 0.6);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => _go(context),
          icon: Icon(
            icon,
            size: selected ? 30 : 25,
            color: selected ? activeColor : inactiveColor,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            height: .1,
            color: selected ? activeColor : inactiveColor,
          ),
        ),
      ],
    );
  }
}
