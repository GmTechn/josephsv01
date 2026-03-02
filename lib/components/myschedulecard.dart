// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MyScheduleCard extends StatelessWidget {
  final Color clockColor;

  const MyScheduleCard({
    required this.title,
    required this.subtitle,
    required this.start,
    required this.end,
    required this.status,
    required this.avatarColor,
    required this.onClockTap,
    required this.clockColor,
    super.key,
  });

  final String title;
  final String start;
  final String end;
  final String subtitle;
  final String status; // 'todo' | 'in_progress' | 'done' | 'overdue'
  final Color avatarColor;
  final VoidCallback? onClockTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    IconData statusIcon;
    Color statusColor;

    switch (status) {
      case 'done':
        statusIcon = CupertinoIcons.check_mark_circled_solid;
        statusColor = Colors.green;
        break;
      case 'in_progress':
      case 'in progress':
        statusIcon = CupertinoIcons.clock_fill;
        statusColor = Colors.orange;
        break;
      case 'overdue':
        statusIcon = CupertinoIcons.xmark_circle_fill;
        statusColor = isDark
            ? const Color.fromARGB(255, 210, 10, 10) // rouge profond en dark
            : Colors.red;
        break;
      default:
        statusIcon = CupertinoIcons.clock;
        statusColor = scheme.outline;
    }

    // 🔥 Background adaptatif
    final backgroundColor = isDark
        ? scheme.surfaceContainerHighest
        : scheme.surface;

    // 🔥 Texte adaptatif
    final titleColor = scheme.onSurface;
    final subtitleColor = scheme.onSurface.withOpacity(.65);
    final startColor = scheme.onSurface.withOpacity(.85);
    final endColor = scheme.onSurface.withOpacity(.65);

    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: statusColor, width: 1.5),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ---- TEXT SIDE (left) ----
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: subtitleColor)),
                ],
              ),
            ),

            // ---- TIME + CLOCK SIDE (right) ----
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      start,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: startColor,
                        fontSize: 13,
                      ),
                    ),
                    Text(end, style: TextStyle(color: endColor, fontSize: 13)),
                  ],
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: onClockTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
