// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyTaskCard extends StatelessWidget {
  const MyTaskCard({
    super.key,
    required this.title,
    required this.status,
    required this.subject,
    required this.date,
  });

  final String status;
  final String title;
  final String subject;
  final DateTime date;

  Color _getStatusColor(bool isDark) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    switch (status) {
      case "Done":
        return isDark
            ? const Color(0xFF81C784)
            : const Color.fromARGB(255, 55, 165, 60);

      case "In progress":
        return isDark
            ? const Color(0xFFFFB74D)
            : const Color.fromARGB(255, 249, 135, 22);

      case "To do":
        return isDark
            ? const Color(0xFFE57373)
            : (difference <= 2
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF512DA8));

      default:
        return isDark ? const Color(0xFFB39DDB) : const Color(0xFF512DA8);
    }
  }

  double _getProgressValue() {
    switch (status) {
      case "Done":
        return 1.0;
      case "In progress":
        return 0.6;
      case "To do":
        return 0.1;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final statusColor = _getStatusColor(isDark);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: isDark ? 4 : 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? BorderSide(color: Colors.white.withOpacity(.05), width: 1)
            : BorderSide.none,
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STATUS BADGE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(isDark ? 0.20 : 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // TITLE
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),

            const SizedBox(height: 4),

            // SUBJECT
            Text(
              subject,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurface.withOpacity(.7),
              ),
            ),

            const SizedBox(height: 10),

            // DATE
            Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 16,
                  color: scheme.onSurface.withOpacity(.6),
                ),
                const SizedBox(width: 6),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(color: scheme.onSurface.withOpacity(.6)),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // PROGRESS BAR
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _getProgressValue(),
                backgroundColor: scheme.surfaceContainerHighest,
                color: statusColor,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
