// =============================================
// QUICK_STATS_BAR.DART
// Header stats: Tasks, Done, Overdue, Progress
// =============================================

import 'package:flutter/material.dart';

class QuickStatsBar extends StatelessWidget {
  final int totalTasks;
  final int completed;
  final int overdue;
  final int progress;

  const QuickStatsBar({
    super.key,
    required this.totalTasks,
    required this.completed,
    required this.overdue,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '$totalTasks', label: 'Tasks'),
          _StatItem(value: '$completed', label: 'Done'),
          _StatItem(value: '$overdue', label: 'Overdue'),
          _StatItem(value: '$progress%', label: 'Progress'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}