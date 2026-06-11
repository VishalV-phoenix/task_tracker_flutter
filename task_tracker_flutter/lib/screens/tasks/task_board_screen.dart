// =============================================
// TASK_BOARD_SCREEN.DART
// Kanban board with 3 columns
// Supports: drag-drop, selection mode, bulk ops
// =============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../core/utils.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';

import '../../widgets/confirmation_dialog.dart';
import '../archive/archive_screen.dart';
import 'task_detail_screen.dart';
import 'widgets/kanban_column.dart';
import 'widgets/bulk_action_bar.dart';

class TaskBoardScreen extends StatefulWidget {
  final String categoryId;
  const TaskBoardScreen({super.key, required this.categoryId});

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
  @override
  void initState() {
    super.initState();
    // Load tasks for this category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadByCategory(widget.categoryId);
    });
  }

  @override
  void dispose() {
    // Exit selection mode when leaving
    context.read<TaskProvider>().exitSelectionMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final category = categoryProvider.getById(widget.categoryId);

    if (category == null) {
      return const Scaffold(body: Center(child: Text('Category not found')));
    }

    final todoTasks = taskProvider.getByStatus(widget.categoryId, 'todo');
    final inProgressTasks = taskProvider.getByStatus(widget.categoryId, 'inProgress');
    final completedTasks = taskProvider.getByStatus(widget.categoryId, 'completed');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.pop(context),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (taskProvider.selectionMode) ...[
            // Selection mode header
            TextButton(
              onPressed: () {
                final allTasks = taskProvider.getTasksByCategory(widget.categoryId);
                if (taskProvider.selectedCount == allTasks.length) {
                  taskProvider.deselectAll();
                } else {
                  taskProvider.selectAll(widget.categoryId);
                }
              },
              child: Text(
                '${taskProvider.selectedCount} selected',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => taskProvider.exitSelectionMode(),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                // Navigate back to dashboard where edit dialog lives
                AppRouter.pop(context);
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // ── Kanban Board ─────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // On wide screens, show columns side by side
                  // On narrow screens, stack vertically
                  final isWide = constraints.maxWidth > 700;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildColumn('To Do', '📋', todoTasks, 'todo', taskProvider)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildColumn('In Progress', '🔄', inProgressTasks, 'inProgress', taskProvider)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildCompletedColumn(completedTasks, taskProvider)),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _buildColumn('To Do', '📋', todoTasks, 'todo', taskProvider),
                      const SizedBox(height: 12),
                      _buildColumn('In Progress', '🔄', inProgressTasks, 'inProgress', taskProvider),
                      const SizedBox(height: 12),
                      _buildCompletedColumn(completedTasks, taskProvider),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── Bulk Action Bar ──────────────────────
          if (taskProvider.selectionMode)
            BulkActionBar(
              selectedCount: taskProvider.selectedCount,
              onMoveTodo: () => _bulkMove('todo'),
              onMoveProgress: () => _bulkMove('inProgress'),
              onMoveCompleted: () => _bulkMove('completed'),
              onSetDueDate: () => _showBulkDueDatePicker(),
              onDelete: () => _bulkDelete(),
              onCancel: () => taskProvider.exitSelectionMode(),
            ),
        ],
      ),
      // ── FAB (hidden during selection) ──────────
      floatingActionButton: taskProvider.selectionMode
          ? null
          : FloatingActionButton(
              backgroundColor: AppTheme.primary,
              onPressed: () {
                AppRouter.push(
                  context,
                  TaskDetailScreen(categoryId: widget.categoryId),
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  // ── Build a kanban column widget ──────────────
  Widget _buildColumn(String title, String icon, List tasks, String status, TaskProvider provider) {
    return KanbanColumn(
      title: title,
      icon: icon,
      tasks: tasks.cast(),
      status: status,
      selectionMode: provider.selectionMode,
      selectedIds: provider.selectedTaskIds,
      onTaskTap: (task) {
        AppRouter.push(context, TaskDetailScreen(
          categoryId: widget.categoryId,
          taskId: task.id,
        ));
      },
      onTaskLongPress: (task) {
        if (!provider.selectionMode) {
          provider.enterSelectionMode();
          provider.toggleSelection(task.id);
        }
      },
      onTaskSelect: (taskId, selected) {
        provider.toggleSelection(taskId);
      },
      onTaskDropped: (taskId, newStatus) {
        provider.updateStatus(taskId, newStatus);
      },
      calculateProgress: (task) => provider.calculateProgress(task),
    );
  }

  Widget _buildCompletedColumn(List tasks, TaskProvider provider) {
    return Column(
      children: [
        _buildColumn('Completed', '✅', tasks, 'completed', provider),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            AppRouter.push(context, ArchiveScreen(categoryId: widget.categoryId));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderMedium),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              '📦 View Archive',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  // ── Bulk move to status ───────────────────────
  void _bulkMove(String status) {
    final count = context.read<TaskProvider>().selectedCount;
    final label = AppUtils.getStatusLabel(status);

    ConfirmationDialog.show(
      context,
      title: 'Move Tasks',
      message: 'Move $count task(s) to "$label"?',
      confirmText: 'Move',
      confirmColor: AppTheme.primary,
      onConfirm: () {
        context.read<TaskProvider>().bulkMoveToStatus(status);
      },
    );
  }

  // ── Bulk set due date ─────────────────────────
  void _showBulkDueDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
    );
    if (!mounted) return;

    final dueDate = DateTime(
      date.year, date.month, date.day,
      time?.hour ?? 23, time?.minute ?? 59,
    );

    context.read<TaskProvider>().bulkSetDueDate(dueDate, 3);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Due date set for ${context.read<TaskProvider>().selectedCount} task(s)')),
      );
    }
  }

  // ── Bulk delete ───────────────────────────────
  void _bulkDelete() {
    final count = context.read<TaskProvider>().selectedCount;

    ConfirmationDialog.show(
      context,
      title: 'Delete Tasks',
      message: 'Permanently delete $count task(s)? This cannot be undone.',
      confirmText: 'Delete',
      onConfirm: () {
        context.read<TaskProvider>().bulkDelete();
      },
    );
  }
}