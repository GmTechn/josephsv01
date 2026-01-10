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

  //Display the color of the task based on its status

  Color _getStatusColor() {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    switch (status) {
      case "Done":
        return Colors.green;
      case "In progress":
        return Colors.orange;
      case "To do":
        return difference <= 2 ? Colors.red : Colors.deepPurple;
      default:
        return Colors.deepPurple;
    }
  }

  //Displaying the level/progress of the task based on its status

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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),

            //Title of the Task
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff050c20),
              ),
            ),

            //Subject of the task
            Text(
              subject,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),

            //Displaying the Date and the progress indicator
            Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),

            //Progress bar on the bottom
            LinearProgressIndicator(
              value: _getProgressValue(),
              backgroundColor: Colors.grey.shade200,
              color: _getStatusColor(),
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ),
    );
  }
}
