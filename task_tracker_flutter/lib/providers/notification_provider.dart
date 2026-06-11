// =============================================
// NOTIFICATION_PROVIDER.DART
// Manages in-app notification state
//
// Handles:
// - Loading notifications from DB
// - Creating notifications for due tasks
// - Dismissing notifications
// - Clearing all notifications
// - Badge count for notification bell
// =============================================

import 'package:flutter/material.dart';
import '../database/notification_dao.dart';
import '../models/notification_model.dart';
import '../models/task_model.dart';
import '../core/utils.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationDao _dao = NotificationDao();

  // ── State ─────────────────────────────────
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  // ── Getters ───────────────────────────────
  bool get isLoading => _isLoading;

  // Only active (undismissed) notifications
  List<NotificationModel> get activeNotifications =>
      _notifications.where((n) => !n.dismissed).toList()
        ..sort((a, b) {
          // Sort by urgency: overdue first
          final urgencyOrder = {
            'overdue': 0,
            'critical': 1,
            'warning': 2,
            'upcoming': 3,
            'normal': 4,
          };
          final aOrder = urgencyOrder[a.type] ?? 5;
          final bOrder = urgencyOrder[b.type] ?? 5;
          if (aOrder != bOrder) return aOrder.compareTo(bOrder);
          if (a.dueDate != null && b.dueDate != null) {
            return a.dueDate!.compareTo(b.dueDate!);
          }
          return 0;
        });

  // Badge count for bell icon
  int get activeCount => activeNotifications.length;

  // ── LOAD NOTIFICATIONS ────────────────────
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _dao.getActive();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── CHECK TASKS FOR DUE DATES ─────────────
  // Called every 60 seconds and on app start
  // Creates notifications for tasks that are due soon
  Future<void> checkTasks(
    List<TaskModel> tasks, {
    required double defaultNotifyHours,
  }) async {
    final now = DateTime.now();
    bool changed = false;

    for (final task in tasks) {
      if (task.dueDate == null) continue;
      if (task.status == 'completed') continue;

      final notifyHours = task.notifyBefore;
      final notifyTime = task.dueDate!.subtract(
        Duration(minutes: (notifyHours * 60).round()),
      );

      // Should we fire a notification?
      if (now.isAfter(notifyTime) && !task.notified) {
        await _createOrUpdateNotification(task);
        changed = true;
      }

      // Ensure overdue tasks always have a notification
      if (now.isAfter(task.dueDate!)) {
        await _ensureOverdueNotification(task);
        changed = true;
      }
    }

    if (changed) {
      // Reload notifications
      _notifications = await _dao.getActive();
      notifyListeners();
    }
  }

  // ── CREATE OR UPDATE NOTIFICATION ─────────
  Future<void> _createOrUpdateNotification(TaskModel task) async {
    final urgency = AppUtils.getUrgency(task.dueDate);
    final message = AppUtils.getUrgencyText(task.dueDate);

    // Check if notification already exists
    final existing = await _dao.getByTaskId(task.id);

    final notification = NotificationModel(
      id: existing?.id ?? AppUtils.generateId('notif'),
      taskId: task.id,
      taskTitle: task.title,
      categoryName: null, // Will be populated by UI
      categoryIcon: null,
      type: urgency,
      dueDate: task.dueDate,
      message: message,
    );

    await _dao.upsert(notification);

    // Update local list
    _notifications.removeWhere((n) => n.taskId == task.id && !n.dismissed);
    _notifications.add(notification);
  }

  // ── ENSURE OVERDUE NOTIFICATION ───────────
  Future<void> _ensureOverdueNotification(TaskModel task) async {
    final existing = _notifications.firstWhere(
      (n) => n.taskId == task.id && !n.dismissed,
      orElse: () => NotificationModel(
        id: '',
        taskId: '',
        taskTitle: '',
      ),
    );

    if (existing.id.isEmpty) {
      await _createOrUpdateNotification(task);
      return;
    }

    // Update to overdue if type changed
    if (existing.type != 'overdue') {
      final updated = existing.copyWith(
        type: 'overdue',
        message: AppUtils.getUrgencyText(task.dueDate),
      );
      await _dao.upsert(updated);
      final index = _notifications.indexOf(existing);
      if (index != -1) _notifications[index] = updated;
    }
  }

  // ── DISMISS A NOTIFICATION ────────────────
  Future<void> dismiss(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;

    _notifications[index] = _notifications[index].copyWith(dismissed: true);
    notifyListeners();

    await _dao.dismiss(notificationId);
  }

  // ── CLEAR ALL NOTIFICATIONS ───────────────
  Future<void> clearAll() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(dismissed: true);
    }
    notifyListeners();

    await _dao.dismissAll();
  }

  // ── DELETE NOTIFICATIONS FOR TASK ─────────
  // Called when a task is deleted
  Future<void> deleteForTask(String taskId) async {
    _notifications.removeWhere((n) => n.taskId == taskId);
    notifyListeners();
    await _dao.deleteForTask(taskId);
  }

  // ── RESET TASK NOTIFICATION ───────────────
  // Called when due date changes
  Future<void> resetForTask(String taskId) async {
    _notifications.removeWhere((n) => n.taskId == taskId && !n.dismissed);
    notifyListeners();
    await _dao.deleteForTask(taskId);
  }
}