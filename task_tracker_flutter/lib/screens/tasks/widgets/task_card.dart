import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../models/task_model.dart';
import '../../../widgets/urgency_badge.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final int progressPercent;
  final int completedSubtasks;
  final int totalSubtasks;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?> onCheckChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.progressPercent,
    required this.completedSubtasks,
    required this.totalSubtasks,
    required this.selectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onCheckChanged,
  });

  @override
  Widget build(BuildContext context) {
    final urgency = AppUtils.getUrgency(task.dueDate);
    final hasLinks = task.links.isNotEmpty;
    final linkedCount = task.linkedTaskIds.length;

    Color borderColor = AppTheme.primary;
    if (task.status != 'completed' && urgency != 'none') {
      borderColor = AppTheme.urgencyColor(urgency);
    }

    return GestureDetector(
      onTap: selectionMode ? () => onCheckChanged(!isSelected) : onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 2),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: onCheckChanged,
                      activeColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textColor(context),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (linkedCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '🔗',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.subtextColor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    if (task.dueDate != null && task.status != 'completed') ...[
                      const SizedBox(height: 6),
                      UrgencyBadge(dueDate: task.dueDate, compact: true),
                    ],

                    if (hasLinks) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: task.links.take(4).map((link) {
                          final detected = AppUtils.detectLinkType(link.url);
                          return Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceBg(context),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                detected['icon']!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    if (totalSubtasks > 0 ||
                        (task.estimatedTime != null &&
                            task.estimatedTime!.isNotEmpty)) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (totalSubtasks > 0) ...[
                            SizedBox(
                              width: 60,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: progressPercent / 100,
                                  backgroundColor: AppTheme.surfaceBg(context),
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppTheme.secondary),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$progressPercent%',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.hintColor(context),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (task.estimatedTime != null &&
                              task.estimatedTime!.isNotEmpty)
                            Text(
                              '⏱ ${task.estimatedTime}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.hintColor(context),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}