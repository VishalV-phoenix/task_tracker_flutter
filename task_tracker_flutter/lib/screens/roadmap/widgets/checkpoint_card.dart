// =============================================
// CHECKPOINT_CARD.DART
// Single checkpoint on the roadmap path
// Shows: marker, title, description, progress
// =============================================

import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/roadmap_model.dart';

class CheckpointCard extends StatelessWidget {
  final CheckpointModel checkpoint;
  final int index;
  final bool isCurrent;
  final bool isFinalGoal;
  final int linkedTaskCount;
  final int progressPercent;
  final VoidCallback onTap;

  const CheckpointCard({
    super.key,
    required this.checkpoint,
    required this.index,
    required this.isCurrent,
    this.isFinalGoal = false,
    required this.linkedTaskCount,
    required this.progressPercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isFinalGoal ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 40, bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Marker ────────────────────────────
            _buildMarker(),
            const SizedBox(width: 16),

            // ── Content ───────────────────────────
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isFinalGoal
                      ? const Color(0xFFFEF3C7)
                      : checkpoint.completed
                          ? const Color(0xFFD1FAE5)
                          : AppTheme.bgTertiary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: isCurrent
                      ? Border.all(color: AppTheme.primary, width: 2)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      isFinalGoal ? checkpoint.title : checkpoint.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isFinalGoal ? 16 : 14,
                        color: isFinalGoal
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                      ),
                    ),

                    // Description
                    if (checkpoint.description != null &&
                        checkpoint.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        checkpoint.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],

                    // Meta info
                    if (!isFinalGoal) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '📋 $linkedTaskCount task${linkedTaskCount != 1 ? 's' : ''} linked',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                          Text(
                            progressPercent > 0
                                ? '$progressPercent% complete'
                                : 'No subtasks',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (isFinalGoal) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Your ultimate goal! 🚀',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarker() {
    if (isFinalGoal) {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEC4899)],
          ),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text('🎯', style: TextStyle(fontSize: 20)),
        ),
      );
    }

    Color markerColor;
    Color borderColor;
    Widget child;

    if (checkpoint.completed) {
      markerColor = AppTheme.secondary;
      borderColor = AppTheme.secondary;
      child = const Icon(Icons.check, size: 16, color: Colors.white);
    } else if (isCurrent) {
      markerColor = AppTheme.primary;
      borderColor = AppTheme.primary;
      child = Text(
        '${index + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      markerColor = AppTheme.bgSecondary;
      borderColor = AppTheme.borderMedium;
      child = Text(
        '${index + 1}',
        style: const TextStyle(
          color: AppTheme.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: markerColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 3),
      ),
      child: Center(child: child),
    );
  }
}