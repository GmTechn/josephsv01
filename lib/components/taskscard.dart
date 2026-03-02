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
        return isDark ? Colors.green.shade300 : Colors.green;
      case "In progress":
        return isDark ? Colors.orange.shade300 : Colors.orange;
      case "To do":
        return difference <= 2
            ? (isDark ? Colors.red.shade300 : Colors.red)
            : (isDark ? Colors.deepPurple.shade300 : Colors.deepPurple);
      default:
        return isDark ? Colors.deepPurple.shade300 : Colors.deepPurple;
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusColor = _getStatusColor(isDark);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: scheme.surfaceContainer, // ✅ adaptatif
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STATUS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(isDark ? 0.25 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
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
                color: scheme.onSurface, // ✅ plus de navy fixe
              ),
            ),

            // SUBJECT
            Text(
              subject,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurface.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 10),

            // DATE
            Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 16,
                  color: scheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // PROGRESS
            LinearProgressIndicator(
              value: _getProgressValue(),
              backgroundColor: scheme.surfaceContainerHighest,
              color: statusColor,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ),
    );
  }
}
