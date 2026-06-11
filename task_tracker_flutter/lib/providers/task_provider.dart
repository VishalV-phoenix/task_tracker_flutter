// =============================================
// TASK_PROVIDER.DART
// Manages all task state
//
// Most complex provider - handles:
// - Active tasks per category (kanban board)
// - Archived tasks
// - Bulk operations (select, move, delete)
// - Progress calculation with linked tasks
// - Due date urgency
// - Auto-archive checking
// =============================================

import 'package:flutter/material.dart';
import '../database/task_dao.dart';
import '../models/task_model.dart';
import '../core/utils.dart';

class TaskProvider extends ChangeNotifier {
  // ── DAO Instance ──────────────────────────
  final TaskDao _dao = TaskDao();

  // ── State ─────────────────────────────────
  // All active tasks loaded (indexed by category for quick lookup)
  List<TaskModel> _allActiveTasks = [];

  // Archived tasks (loaded separately for archive screen)
  List<TaskModel> _archivedTasks = [];

  // Currently open category's tasks
  

  // Bulk selection state
  bool _selectionMode = false;
  Set<String> _selectedTaskIds = {};

  // Loading and error states
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get selectionMode => _selectionMode;
  Set<String> get selectedTaskIds => Set.unmodifiable(_selectedTaskIds);
  int get selectedCount => _selectedTaskIds.length;
  List<TaskModel> get archivedTasks => _archivedTasks;

  // All active tasks
  List<TaskModel> get allActiveTasks => _allActiveTasks;

  // Get tasks for a specific category
  List<TaskModel> getTasksByCategory(String categoryId) =>
      _allActiveTasks.where((t) => t.categoryId == categoryId).toList();

  // Get tasks by status for a category (for kanban columns)
  List<TaskModel> getByStatus(String categoryId, String status) =>
      _allActiveTasks
          .where((t) => t.categoryId == categoryId && t.status == status)
          .toList();

  // Find task by ID
  TaskModel? getById(String id) {
    try {
      return _allActiveTasks.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // Count archived tasks
  int get archivedCount => _archivedTasks.length;

  // Count overdue tasks
  int get overdueCount => _allActiveTasks
      .where((t) =>
          t.dueDate != null &&
          t.status != 'completed' &&
          AppUtils.getUrgency(t.dueDate) == 'overdue')
      .length;

  // Count completed tasks
  int get completedCount =>
      _allActiveTasks.where((t) => t.status == 'completed').length;

  // ── LOAD ALL TASKS ────────────────────────
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allActiveTasks = await _dao.getAllActive();
    } catch (e) {
      _error = 'Failed to load tasks: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── LOAD TASKS FOR ONE CATEGORY ───────────
  // Called when opening a kanban board
  Future<void> loadByCategory(String categoryId) async {  
    _isLoading = true;
    notifyListeners();

    try {
      // Load fresh tasks for this category from DB
      final categoryTasks = await _dao.getByCategoryActive(categoryId);

      // Update our list: remove old tasks for this category
      // and add fresh ones
      _allActiveTasks.removeWhere((t) => t.categoryId == categoryId);
      _allActiveTasks.addAll(categoryTasks);
    } catch (e) {
      _error = 'Failed to load tasks: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── LOAD ARCHIVED TASKS ───────────────────
  Future<void> loadArchived() async {
    _isLoading = true;
    notifyListeners();

    try {
      _archivedTasks = await _dao.getArchived();
    } catch (e) {
      _error = 'Failed to load archive: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── ADD TASK ──────────────────────────────
  Future<void> add(TaskModel task) async {
    try {
      // Add to local list immediately
      _allActiveTasks.add(task);
      notifyListeners();

      // Save to database with all subtasks, links, linked IDs
      await _dao.insert(task);
    } catch (e) {
      // Rollback
      _allActiveTasks.removeWhere((t) => t.id == task.id);
      _error = 'Failed to add task: $e';
      notifyListeners();
      debugPrint(_error);
    }
  }

  // ── UPDATE TASK ───────────────────────────
  Future<void> update(TaskModel updatedTask) async {
    final index = _allActiveTasks.indexWhere((t) => t.id == updatedTask.id);
    if (index == -1) return;

    final oldTask = _allActiveTasks[index];

    try {
      _allActiveTasks[index] = updatedTask;
      notifyListeners();

      // Update in database (replaces all subtasks, links, etc.)
      await _dao.update(updatedTask);
    } catch (e) {
      _allActiveTasks[index] = oldTask;
      _error = 'Failed to update task: $e';
      notifyListeners();
      debugPrint(_error);
    }
  }

  // ── DELETE TASK ───────────────────────────
  Future<void> delete(String taskId) async {
    final index = _allActiveTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final deletedTask = _allActiveTasks[index];

    try {
      _allActiveTasks.removeAt(index);

      // Also remove this task from other tasks' linkedTaskIds
      for (int i = 0; i < _allActiveTasks.length; i++) {
        if (_allActiveTasks[i].linkedTaskIds.contains(taskId)) {
          final updated = _allActiveTasks[i].copyWith(
            linkedTaskIds: _allActiveTasks[i]
                .linkedTaskIds
                .where((id) => id != taskId)
                .toList(),
          );
          _allActiveTasks[i] = updated;
        }
      }

      notifyListeners();
      await _dao.delete(taskId);
    } catch (e) {
      _allActiveTasks.insert(index, deletedTask);
      _error = 'Failed to delete task: $e';
      notifyListeners();
      debugPrint(_error);
    }
  }

  // ── UPDATE TASK STATUS ────────────────────
  // Called when dragging between kanban columns
  Future<void> updateStatus(String taskId, String newStatus) async {
    final index = _allActiveTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final now = DateTime.now();

    // Determine completedAt
    DateTime? completedAt;
    if (newStatus == 'completed') {
      completedAt = _allActiveTasks[index].completedAt ?? now;
    }

    final updatedTask = _allActiveTasks[index].copyWith(
      status: newStatus,
      completedAt: completedAt,
      clearCompletedAt: newStatus != 'completed',
    );

    _allActiveTasks[index] = updatedTask;
    notifyListeners();

    await _dao.updateStatus(
      taskId,
      newStatus,
      completedAt: newStatus == 'completed' ? completedAt : null,
    );
  }

  // ── AUTO ARCHIVE ──────────────────────────
  // Moves completed tasks older than X days to archive
  Future<int> autoArchive(int archiveDays) async {
    final tasks = await _dao.getTasksReadyToArchive(archiveDays);
    int count = 0;

    for (final task in tasks) {
      await _dao.archive(task.id);
      _allActiveTasks.removeWhere((t) => t.id == task.id);
      count++;
    }

    if (count > 0) notifyListeners();
    return count;
  }

  // ── RESTORE FROM ARCHIVE ──────────────────
  Future<void> restore(String taskId) async {
    try {
      await _dao.unarchive(taskId);

      // Reload the task back into active list
      final task = await _dao.getById(taskId);
      if (task != null) {
        _allActiveTasks.add(task);
      }

      // Remove from archived list
      _archivedTasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to restore task: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  // ── DELETE ARCHIVED TASK ──────────────────
  Future<void> deleteArchived(String taskId) async {
    try {
      _archivedTasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
      await _dao.delete(taskId);
    } catch (e) {
      _error = 'Failed to delete archived task: $e';
      debugPrint(_error);
    }
  }

  // ── DELETE OLD ARCHIVES ───────────────────
  Future<int> deleteOldArchives(int olderThanDays) async {
    final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));
    final toDelete = _archivedTasks
        .where((t) => t.archivedAt != null && t.archivedAt!.isBefore(cutoff))
        .map((t) => t.id)
        .toList();

    if (toDelete.isEmpty) return 0;

    _archivedTasks.removeWhere((t) => toDelete.contains(t.id));
    notifyListeners();

    await _dao.deleteMultiple(toDelete);
    return toDelete.length;
  }

  // ── PROGRESS CALCULATION ──────────────────
  // Calculate progress for a task including linked tasks
  // Prevents infinite loops with visited set
  Map<String, int> calculateProgress(TaskModel task,
      {Set<String>? visited}) {
    visited ??= {};

    if (visited.contains(task.id)) {
      return {'completed': 0, 'total': 0};
    }
    visited.add(task.id);

    int completed = 0;
    int total = 0;

    // Own subtasks
    if (task.subtasks.isNotEmpty) {
      total += task.subtasks.length;
      completed += task.subtasks.where((s) => s.completed).length;
    }

    // Linked task subtasks (recursive)
    for (final linkedId in task.linkedTaskIds) {
      final linked = getById(linkedId);
      if (linked != null && !visited.contains(linkedId)) {
        final linkedProgress = calculateProgress(linked, visited: visited);
        completed += linkedProgress['completed']!;
        total += linkedProgress['total']!;
      }
    }

    return {'completed': completed, 'total': total};
  }

  // Calculate progress percentage for a category
  int calculateCategoryProgress(String categoryId) {
    final tasks = getTasksByCategory(categoryId);
    if (tasks.isEmpty) return 0;

    int totalCompleted = 0;
    int totalItems = 0;

    for (final task in tasks) {
      if (task.subtasks.isNotEmpty) {
        totalItems += task.subtasks.length;
        totalCompleted += task.subtasks.where((s) => s.completed).length;
      } else {
        totalItems += 1;
        if (task.status == 'completed') totalCompleted += 1;
      }
    }

    return AppUtils.calculateProgress(totalCompleted, totalItems);
  }

  // ── GET TASKS NEEDING NOTIFICATION ────────
  Future<List<TaskModel>> getTasksNeedingNotification() async {
    return await _dao.getTasksNeedingNotification();
  }

  // ── MARK TASK AS NOTIFIED ─────────────────
  Future<void> markNotified(String taskId) async {
    final index = _allActiveTasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _allActiveTasks[index] = _allActiveTasks[index].copyWith(notified: true);
    }
    await _dao.markNotified(taskId);
  }

  // ── RESET NOTIFICATION FLAG ───────────────
  // Called when due date changes
  Future<void> resetNotified(String taskId) async {
    final index = _allActiveTasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _allActiveTasks[index] = _allActiveTasks[index].copyWith(notified: false);
    }
    await _dao.resetNotified(taskId);
  }

  // ── SELECTION MODE ────────────────────────

  /// Enter bulk selection mode
  void enterSelectionMode() {
    _selectionMode = true;
    _selectedTaskIds.clear();
    notifyListeners();
  }

  /// Exit bulk selection mode
  void exitSelectionMode() {
    _selectionMode = false;
    _selectedTaskIds.clear();
    notifyListeners();
  }

  /// Toggle task selection
  void toggleSelection(String taskId) {
    if (_selectedTaskIds.contains(taskId)) {
      _selectedTaskIds.remove(taskId);
    } else {
      _selectedTaskIds.add(taskId);
    }
    notifyListeners();
  }

  /// Select all tasks in current category
  void selectAll(String categoryId) {
    final tasks = getTasksByCategory(categoryId);
    _selectedTaskIds = tasks.map((t) => t.id).toSet();
    notifyListeners();
  }

  /// Deselect all
  void deselectAll() {
    _selectedTaskIds.clear();
    notifyListeners();
  }

  // ── BULK MOVE ────────────────────────────
  Future<void> bulkMoveToStatus(String newStatus) async {
    final now = DateTime.now();

    for (final taskId in _selectedTaskIds) {
      final index = _allActiveTasks.indexWhere((t) => t.id == taskId);
      if (index == -1) continue;

      DateTime? completedAt;
      if (newStatus == 'completed') {
        completedAt = _allActiveTasks[index].completedAt ?? now;
      }

      _allActiveTasks[index] = _allActiveTasks[index].copyWith(
        status: newStatus,
        completedAt: completedAt,
        clearCompletedAt: newStatus != 'completed',
      );

      await _dao.updateStatus(taskId, newStatus, completedAt: completedAt);
    }

    exitSelectionMode();
    notifyListeners();
  }

  // ── BULK SET DUE DATE ─────────────────────
  Future<void> bulkSetDueDate(
    DateTime dueDate,
    double notifyBefore,
  ) async {
    for (final taskId in _selectedTaskIds) {
      final index = _allActiveTasks.indexWhere((t) => t.id == taskId);
      if (index == -1) continue;

      final updated = _allActiveTasks[index].copyWith(
        dueDate: dueDate,
        notifyBefore: notifyBefore,
        notified: false,
      );
      _allActiveTasks[index] = updated;

      await _dao.update(updated);
    }

    exitSelectionMode();
    notifyListeners();
  }

  // ── BULK DELETE ───────────────────────────
  Future<void> bulkDelete() async {
    final ids = _selectedTaskIds.toList();

    _allActiveTasks.removeWhere((t) => ids.contains(t.id));

    // Clean up linked references
    for (int i = 0; i < _allActiveTasks.length; i++) {
      if (_allActiveTasks[i].linkedTaskIds.any((id) => ids.contains(id))) {
        _allActiveTasks[i] = _allActiveTasks[i].copyWith(
          linkedTaskIds: _allActiveTasks[i]
              .linkedTaskIds
              .where((id) => !ids.contains(id))
              .toList(),
        );
      }
    }

    exitSelectionMode();
    notifyListeners();

    await _dao.deleteMultiple(ids);
  }

  // ── CLEAR ERROR ───────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }
}