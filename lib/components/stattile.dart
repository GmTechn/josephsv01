// ignore_for_file: must_be_immutable, deprecated_member_use

import 'package:flutter/material.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 82,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? scheme.surfaceContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
