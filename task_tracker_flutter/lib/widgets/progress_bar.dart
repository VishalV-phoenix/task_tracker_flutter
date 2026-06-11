// =============================================
// PROGRESS_BAR.DART
// Reusable progress bar widget
// Used on dashboard cards, task cards, etc.
// =============================================

import 'package:flutter/material.dart';
import '../core/theme.dart';

class AppProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final bool showLabel;

  const AppProgressBar({
    super.key,
    required this.progress,
    this.height = 6,
    this.color,
    this.backgroundColor,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final barColor = color ?? AppTheme.primary;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: clampedProgress,
            backgroundColor: backgroundColor ?? AppTheme.bgTertiary,
            valueColor: AlwaysStoppedAnimation(barColor),
            minHeight: height,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(clampedProgress * 100).round()}%',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textTertiary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}