import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/category_model.dart';
import '../../../models/task_model.dart';
import '../../../widgets/progress_bar.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final List<TaskModel> tasks;
  final int noteCount;
  final int noteCompletedCount;
  final int progress;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;
  final VoidCallback onQuickAdd;

  const CategoryCard({
    super.key,
    required this.category,
    this.tasks = const [],
    this.noteCount = 0,
    this.noteCompletedCount = 0,
    required this.progress,
    required this.onTap,
    required this.onMenuTap,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.colorFromHex(category.color);
    final isKanban = category.type == 'kanban';

    final overdueCount = isKanban
        ? tasks.where((t) =>
            t.dueDate != null &&
            t.status != 'completed' &&
            DateTime.now().isAfter(t.dueDate!)).length
        : 0;

    final dueSoonCount = isKanban
        ? tasks.where((t) {
            if (t.dueDate == null || t.status == 'completed') return false;
            final diff = t.dueDate!.difference(DateTime.now()).inHours;
            return diff >= 0 && diff < 24;
          }).length
        : 0;

    final totalItems = isKanban ? tasks.length : noteCount;
    final completedItems = isKanban
        ? tasks.where((t) => t.status == 'completed').length
        : noteCompletedCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppTheme.cardDecorationThemed(context),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(height: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceBg(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(category.icon,
                              style: const TextStyle(fontSize: 18)),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceBg(context),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isKanban ? 'Kanban' : 'Checklist',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.hintColor(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: onMenuTap,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.more_vert,
                                    size: 18,
                                    color: AppTheme.hintColor(context)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Title
                    Text(
                      category.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (overdueCount > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '🔴 overdue',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.overdue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ] else if (dueSoonCount > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '🟡 due soon',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    AppProgressBar(
                      progress: progress / 100,
                      color: color,
                    ),
                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completedItems/$totalItems ${isKanban ? 'tasks' : 'items'}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.hintColor(context),
                          ),
                        ),
                        GestureDetector(
                          onTap: onQuickAdd,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}