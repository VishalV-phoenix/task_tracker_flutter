import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/task_model.dart';
import 'task_card.dart';

class KanbanColumn extends StatelessWidget {
  final String title;
  final String icon;
  final List<TaskModel> tasks;
  final String status;
  final bool selectionMode;
  final Set<String> selectedIds;
  final Function(TaskModel) onTaskTap;
  final Function(TaskModel) onTaskLongPress;
  final Function(String, bool) onTaskSelect;
  final Function(String, String) onTaskDropped;
  final Function(TaskModel) calculateProgress;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.icon,
    required this.tasks,
    required this.status,
    required this.selectionMode,
    required this.selectedIds,
    required this.onTaskTap,
    required this.onTaskLongPress,
    required this.onTaskSelect,
    required this.onTaskDropped,
    required this.calculateProgress,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<TaskModel>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) {
        onTaskDropped(details.data.id, status);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: isHovering
                ? AppTheme.primary.withValues(alpha: 0.1)
                : AppTheme.surfaceBg(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$icon $title',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.subtextColor(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.hintColor(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (tasks.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Text('📭', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(
                        'No tasks',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.hintColor(context),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...tasks.map((task) {
                  final progress = calculateProgress(task);
                  final completed = progress['completed'] ?? 0;
                  final total = progress['total'] ?? 0;
                  final percent =
                      total > 0 ? ((completed / total) * 100).round() : 0;

                  return Draggable<TaskModel>(
                    data: task,
                    feedback: Material(
                      elevation: 8,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg(context),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: TaskCard(
                        task: task,
                        progressPercent: percent,
                        completedSubtasks: completed,
                        totalSubtasks: total,
                        selectionMode: selectionMode,
                        isSelected: selectedIds.contains(task.id),
                        onTap: () {},
                        onLongPress: () {},
                        onCheckChanged: (_) {},
                      ),
                    ),
                    child: TaskCard(
                      task: task,
                      progressPercent: percent,
                      completedSubtasks: completed,
                      totalSubtasks: total,
                      selectionMode: selectionMode,
                      isSelected: selectedIds.contains(task.id),
                      onTap: () => onTaskTap(task),
                      onLongPress: () => onTaskLongPress(task),
                      onCheckChanged: (val) =>
                          onTaskSelect(task.id, val ?? false),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}