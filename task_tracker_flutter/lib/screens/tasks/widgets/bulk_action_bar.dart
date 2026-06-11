// =============================================
// BULK_ACTION_BAR.DART
// Bottom bar during selection mode
// Actions: move to status, set due date, delete
// =============================================

import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class BulkActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onMoveTodo;
  final VoidCallback onMoveProgress;
  final VoidCallback onMoveCompleted;
  final VoidCallback onSetDueDate;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const BulkActionBar({
    super.key,
    required this.selectedCount,
    required this.onMoveTodo,
    required this.onMoveProgress,
    required this.onMoveCompleted,
    required this.onSetDueDate,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Move To Row ─────────────────────
            Row(
              children: [
                const Text(
                  'Move to:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: '📋 To Do',
                  onTap: onMoveTodo,
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  label: '🔄 Progress',
                  onTap: onMoveProgress,
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  label: '✅ Done',
                  onTap: onMoveCompleted,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Date + Delete Row ────────────────
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: '📅 Set Due Date',
                    onTap: onSetDueDate,
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: '🗑️ Delete ($selectedCount)',
                    onTap: onDelete,
                    color: AppTheme.overdue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: color ?? AppTheme.borderLight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}