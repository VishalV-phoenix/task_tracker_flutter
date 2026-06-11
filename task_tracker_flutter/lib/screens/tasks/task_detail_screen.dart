// =============================================
// TASK_DETAIL_SCREEN.DART
// Full task creation/editing form
// Fields: title, description, status, duration,
//         due date, notification, links,
//         linked tasks, subtasks, progress
// =============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../core/utils.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/task_model.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/progress_bar.dart';
import 'widgets/subtask_item.dart';
import 'widgets/link_item.dart';

class TaskDetailScreen extends StatefulWidget {
  final String categoryId;
  final String? taskId; // null = creating new task

  const TaskDetailScreen({
    super.key,
    required this.categoryId,
    this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  // ── Form Controllers ──────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _notifyController = TextEditingController();

  // ── Form State ────────────────────────────────
  String _status = 'todo';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  List<_SubtaskFormItem> _subtasks = [];
  List<TaskLinkModel> _links = [];
  Set<String> _selectedLinkedTaskIds = {};

  // ── Computed ──────────────────────────────────
  bool get _isEditing => widget.taskId != null;
  TaskModel? _existingTask;

  @override
  void initState() {
    super.initState();

    final defaultNotify = context.read<SettingsProvider>().defaultNotifyBefore;
    _notifyController.text = defaultNotify.toString();

    if (_isEditing) {
      // Load existing task data into form
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingTask();
      });
    }
  }

  void _loadExistingTask() {
    final task = context.read<TaskProvider>().getById(widget.taskId!);
    if (task == null) return;

    _existingTask = task;

    setState(() {
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _durationController.text = task.estimatedTime ?? '';
      _status = task.status;
      _notifyController.text = task.notifyBefore.toString();

      if (task.dueDate != null) {
        _dueDate = task.dueDate;
        _dueTime = TimeOfDay.fromDateTime(task.dueDate!);
      }

      // Load subtasks into form items
      _subtasks = task.subtasks
          .map((s) => _SubtaskFormItem(
                id: s.id,
                controller: TextEditingController(text: s.title),
                completed: s.completed,
              ))
          .toList();

      // Load links
      _links = List.from(task.links);

      // Load linked task IDs
      _selectedLinkedTaskIds = Set.from(task.linkedTaskIds);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _notifyController.dispose();
    for (final s in _subtasks) {
      s.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteTask(),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title Field ─────────────────────────
              _buildSectionTitle('Task Title'),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Enter task title'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // ── Description Field ───────────────────
              _buildSectionTitle('Description'),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Optional description'),
                maxLines: 3,
                minLines: 2,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Status'),
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: _inputDecoration(''),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'todo',
                              child: Text('📋 To Do',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'inProgress',
                              child: Text('🔄 Progress',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'completed',
                              child: Text('✅ Done',
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _status = v ?? 'todo'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Est. Duration'),
                        TextFormField(
                          controller: _durationController,
                          decoration: _inputDecoration('e.g., 2 hours'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Due Date & Notification ─────────────
              _buildSectionTitle('Due Date & Notification'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBg(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Column(
                  children: [
                    // Date and Time pickers
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickDate(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.borderColor(context)),
                                borderRadius: BorderRadius.circular(8),
                                color: AppTheme.cardBg(context),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 16, color: AppTheme.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    _dueDate != null
                                        ? DateFormat('MMM d, y')
                                            .format(_dueDate!)
                                        : 'Select date',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _dueDate != null
                                          ? AppTheme.textPrimary
                                          : AppTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickTime(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.borderColor(context)),
                                borderRadius: BorderRadius.circular(8),
                                color: AppTheme.cardBg(context),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 16, color: AppTheme.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    _dueTime != null
                                        ? _dueTime!.format(context)
                                        : 'Select time',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _dueTime != null
                                          ? AppTheme.textPrimary
                                          : AppTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_dueDate != null) ...[
                      const SizedBox(height: 8),
                      // Clear due date button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() {
                            _dueDate = null;
                            _dueTime = null;
                          }),
                          child: const Text('Clear due date',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Notification timing
                    Row(
                      children: [
                        const Text('🔔', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        const Text('Notify ',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary)),
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            controller: _notifyController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('hours before',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Links Section ───────────────────────
              _buildSectionTitle('🔗 Links (${_links.length}/10)'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBg(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Column(
                  children: [
                    ..._links.map((link) => LinkItem(
                          link: link,
                          onDelete: () => setState(() => _links.remove(link)),
                        )),
                    if (_links.length < 10)
                      GestureDetector(
                        onTap: () => _showAddLinkDialog(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppTheme.borderLight,
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '+ Add Link',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Linked Tasks ────────────────────────
              _buildSectionTitle('Link to Other Tasks'),
              const Text(
                'Progress includes linked task subtasks',
                style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
              ),
              const SizedBox(height: 8),
              _buildLinkedTasksSelector(),
              const SizedBox(height: 16),

              // ── Subtasks Section ────────────────────
              _buildSubtasksSection(),
              const SizedBox(height: 24),

              // ── Save Button ─────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => AppRouter.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _saveTask(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: Text(_isEditing ? 'Update Task' : 'Create Task'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper: Section Title ─────────────────────
  Widget _buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.subtextColor(context),
      ),
    ),
  );
}
  // ── Helper: Input Decoration ──────────────────
  InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppTheme.hintColor(context)),
    filled: true,
    fillColor: AppTheme.inputBg(context),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      borderSide: BorderSide(color: AppTheme.borderColor(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      borderSide: BorderSide(color: AppTheme.borderColor(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}
  // ── Date Picker ───────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  // ── Time Picker ───────────────────────────────
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 14, minute: 0),
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  // ── Linked Tasks Selector ─────────────────────
  Widget _buildLinkedTasksSelector() {
    final taskProvider = context.read<TaskProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    // Get all kanban tasks except current one
    final allTasks = taskProvider.allActiveTasks
        .where((t) => t.id != widget.taskId)
        .where((t) {
      final cat = categoryProvider.getById(t.categoryId);
      return cat != null && cat.type == 'kanban';
    }).toList();

    if (allTasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBg(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Text(
          'No other tasks to link',
          style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
        ),
      );
    }

    // Group by category
    final grouped = <String, List<TaskModel>>{};
    for (final task in allTasks) {
      grouped.putIfAbsent(task.categoryId, () => []).add(task);
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBg(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: grouped.entries.map((entry) {
            final cat = categoryProvider.getById(entry.key);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${cat?.icon ?? "📋"} ${cat?.name ?? "Unknown"}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
                ...entry.value.map((task) => GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedLinkedTaskIds.contains(task.id)) {
                            _selectedLinkedTaskIds.remove(task.id);
                          } else {
                            _selectedLinkedTaskIds.add(task.id);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _selectedLinkedTaskIds.contains(task.id),
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedLinkedTaskIds.add(task.id);
                                    } else {
                                      _selectedLinkedTaskIds.remove(task.id);
                                    }
                                  });
                                },
                                activeColor: AppTheme.primary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSubtasksSection() {
    int completed = _subtasks.where((s) => s.completed).length;
    int total = _subtasks.length;
    double progress = total > 0 ? completed / total : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBg(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtasks',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => _addSubtask(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '+ Add',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Subtask items
          for (int i = 0; i < _subtasks.length; i++)
            SubtaskItem(
              controller: _subtasks[i].controller,
              completed: _subtasks[i].completed,
              onCompletedChanged: (val) {
                setState(() => _subtasks[i].completed = val ?? false);
              },
              onDelete: () {
                setState(() {
                  _subtasks[i].controller.dispose();
                  _subtasks.removeAt(i);
                });
              },
            ),

          // Progress bar
          if (total > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AppProgressBar(progress: progress),
            const SizedBox(height: 4),
            Text(
              '$completed/$total subtasks completed',
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  // ── Add Subtask ───────────────────────────────
  void _addSubtask() {
    setState(() {
      _subtasks.add(_SubtaskFormItem(
        id: AppUtils.generateId('sub'),
        controller: TextEditingController(),
        completed: false,
      ));
    });
  }

  // ── Show Add Link Dialog ──────────────────────
  void _showAddLinkDialog() {
    final labelController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text('Add Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'e.g., Lecture Video',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final label = labelController.text.trim();
              final url = urlController.text.trim();

              if (label.isEmpty || url.isEmpty) return;

              // Validate URL
              try {
                Uri.parse(url);
              } catch (e) {
                return;
              }

              final detected = AppUtils.detectLinkType(url);

              setState(() {
                _links.add(TaskLinkModel(
                  id: AppUtils.generateId('link'),
                  taskId: widget.taskId ?? '',
                  label: label,
                  url: url,
                  linkType: detected['type'],
                ));
              });

              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ── Save Task ─────────────────────────────────
  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    // Generate task ID for new tasks FIRST
    // so subtasks and links can reference it
    final taskId = widget.taskId ?? AppUtils.generateId('task');

    // Build due date from date + time
    DateTime? dueDate;
    if (_dueDate != null) {
      dueDate = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime?.hour ?? 23,
        _dueTime?.minute ?? 59,
      );
    }

    final notifyBefore = double.tryParse(_notifyController.text) ?? 3.0;

    // Build subtask models with correct taskId
    final subtasks = _subtasks
        .where((s) => s.controller.text.trim().isNotEmpty)
        .map((s) => SubtaskModel(
              id: s.id,
              taskId: taskId, // Use the generated taskId
              title: s.controller.text.trim(),
              completed: s.completed,
            ))
        .toList();

    // Build links with correct taskId
    final links = _links.map((link) {
      return TaskLinkModel(
        id: link.id,
        taskId: taskId, // Use the generated taskId
        label: link.label,
        url: link.url,
        linkType: link.linkType,
        addedAt: link.addedAt,
        sortOrder: link.sortOrder,
      );
    }).toList();

    // Set completedAt when status changes to completed
    DateTime? completedAt;
    if (_status == 'completed') {
      if (_existingTask != null && _existingTask!.completedAt != null) {
        completedAt = _existingTask!.completedAt;
      } else {
        completedAt = DateTime.now();
      }
    }

    // Check if due date changed (for notification reset)
    final dueDateChanged = _isEditing &&
        _existingTask != null &&
        _existingTask!.dueDate?.toIso8601String() != dueDate?.toIso8601String();

    final task = TaskModel(
      id: taskId,
      categoryId: widget.categoryId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      status: _status,
      estimatedTime: _durationController.text.trim().isEmpty
          ? null
          : _durationController.text.trim(),
      dueDate: dueDate,
      notifyBefore: notifyBefore,
      notified: dueDateChanged ? false : (_existingTask?.notified ?? false),
      completedAt: completedAt,
      archivedAt: _existingTask?.archivedAt,
      createdAt: _existingTask?.createdAt ?? DateTime.now(),
      subtasks: subtasks,
      links: links,
      linkedTaskIds: _selectedLinkedTaskIds.toList(),
    );

    final taskProvider = context.read<TaskProvider>();

    if (_isEditing) {
      taskProvider.update(task);
      if (dueDateChanged) {
        taskProvider.resetNotified(task.id);
        context.read<NotificationProvider>().resetForTask(task.id);
      }
    } else {
      taskProvider.add(task);
    }

    // Reload the category tasks to ensure everything shows
    taskProvider.loadByCategory(widget.categoryId);

    AppRouter.pop(context);
  }

  // ── Delete Task ───────────────────────────────
  void _deleteTask() {
    ConfirmationDialog.show(
      context,
      title: 'Delete Task',
      message: 'Delete this task permanently? This cannot be undone.',
      confirmText: 'Delete',
      onConfirm: () {
        final taskProvider = context.read<TaskProvider>();
        taskProvider.delete(widget.taskId!);
        context.read<NotificationProvider>().deleteForTask(widget.taskId!);
        AppRouter.pop(context);
      },
    );
  }
}

// ── Helper class for subtask form state ──────────
class _SubtaskFormItem {
  final String id;
  final TextEditingController controller;
  bool completed;

  _SubtaskFormItem({
    required this.id,
    required this.controller,
    required this.completed,
  });
}
