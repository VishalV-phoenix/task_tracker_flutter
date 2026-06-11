// =============================================
// SUBTASK_ITEM.DART
// Editable subtask row in task detail form
// Shows: checkbox, text input, delete button
// =============================================

import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class SubtaskItem extends StatelessWidget {
  final TextEditingController controller;
  final bool completed;
  final ValueChanged<bool?> onCompletedChanged;
  final VoidCallback onDelete;

  const SubtaskItem({
    super.key,
    required this.controller,
    required this.completed,
    required this.onCompletedChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: completed,
              onChanged: onCompletedChanged,
              activeColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontSize: 14,
                decoration:
                    completed ? TextDecoration.lineThrough : null,
                color: completed
                    ? AppTheme.textTertiary
                    : AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Subtask description',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 18, color: AppTheme.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}