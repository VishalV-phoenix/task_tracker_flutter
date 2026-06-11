// =============================================
// URGENCY_BADGE.DART
// Shows due date urgency as colored badge
// Used on task cards and dashboard
// =============================================

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/utils.dart';

class UrgencyBadge extends StatelessWidget {
  final DateTime? dueDate;
  final bool showIcon;
  final bool compact;

  const UrgencyBadge({
    super.key,
    required this.dueDate,
    this.showIcon = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dueDate == null) return const SizedBox.shrink();

    final urgency = AppUtils.getUrgency(dueDate);
    if (urgency == 'none') return const SizedBox.shrink();

    final text = AppUtils.getUrgencyText(dueDate);
    final icon = AppUtils.getUrgencyIcon(urgency);
    final color = AppTheme.urgencyColor(urgency);
    final bgColor = AppTheme.urgencyBgColor(urgency);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Text(icon, style: TextStyle(fontSize: compact ? 10 : 12)),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}