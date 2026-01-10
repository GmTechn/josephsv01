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
    IconData statusIcon;
    Color statusColor;

    // Switch icon & color depending on task status
    switch (status) {
      case 'done':
        statusIcon = CupertinoIcons.check_mark_circled_solid;
        statusColor = Colors.green;
        break;
      case 'in_progress': // ✅ matches _computeStatus()
      case 'in progress': // ✅ supports both
        statusIcon = CupertinoIcons.clock_fill;
        statusColor = Colors.orange;
        break;
      case 'overdue':
        statusIcon = CupertinoIcons.xmark_circle_fill;
        statusColor = Colors.red;
        break;
      default:
        statusIcon = CupertinoIcons.clock;
        statusColor = Colors.blueGrey;
    }

    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: statusColor, width: 1.5),
          boxShadow: [
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xff050c20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),

            // ---- TIME + CLOCK SIDE (right) ----
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Time column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      start,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      end,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Clock icon
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
