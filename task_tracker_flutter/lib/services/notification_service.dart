// =============================================
// NOTIFICATION_SERVICE.DART
// TRUE background notifications using
// flutter_local_notifications package
//
// This is the BIG advantage over the web app:
// - Notifications fire even when app is closed
// - Shows in Android notification shade
// - Persists until user dismisses
// - Can schedule exact future times
// =============================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task_model.dart';
import '../core/utils.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Plugin instance
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Track if initialized
  bool _initialized = false;

  /// Initialize notification system
  /// Must be called once before any notifications
  Future<void> initialize() async {
    // Skip on web - notifications don't work on Chrome
    if (kIsWeb) {
      debugPrint('⚠️ Notifications not available on web');
      return;
    }

    if (_initialized) return;

    try {
      // Initialize timezone data (needed for scheduling)
      tz_data.initializeTimeZones();

      // Android settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher', // Uses default app icon
      );

      // Combined settings
      const initSettings = InitializationSettings(
        android: androidSettings,
      );

      // Initialize plugin
      await _plugin.initialize(
        initSettings,
        // Called when user taps a notification
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request notification permission (Android 13+)
      await _requestPermission();

      _initialized = true;
      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('❌ Notification init error: $e');
    }
  }

  /// Request notification permission
  Future<bool> _requestPermission() async {
    if (kIsWeb) return false;

    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        debugPrint('🔔 Notification permission: $granted');
        return granted ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Permission request error: $e');
      return false;
    }
  }

  /// Request permission explicitly (called from settings)
  Future<bool> requestPermission() async {
    return await _requestPermission();
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // The payload contains the task ID
    // Navigation is handled by the app when it opens
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Schedule a notification for a task's due date
  /// Fires [notifyBeforeHours] hours before the due date
  Future<void> scheduleTaskNotification({
    required TaskModel task,
    double? notifyBeforeHours,
  }) async {
    if (kIsWeb || !_initialized) return;
    if (task.dueDate == null) return;

    final hours = notifyBeforeHours ?? task.notifyBefore;
    final notifyTime = task.dueDate!.subtract(
      Duration(minutes: (hours * 60).round()),
    );

    // Don't schedule if notification time is in the past
    if (notifyTime.isBefore(DateTime.now())) {
      // But still show immediate notification if task is due soon or overdue
      if (task.dueDate!.isBefore(DateTime.now())) {
        await _showImmediateNotification(
          id: task.id.hashCode,
          title: '🔴 Overdue: ${task.title}',
          body: 'Was due ${AppUtils.formatDateTime(task.dueDate!)}',
          payload: task.id,
        );
      } else {
        await _showImmediateNotification(
          id: task.id.hashCode,
          title: '⏰ Due Soon: ${task.title}',
          body: 'Due ${AppUtils.formatDateTime(task.dueDate!)}',
          payload: task.id,
        );
      }
      return;
    }

    // Schedule future notification
    try {
      final scheduledDate = tz.TZDateTime.from(notifyTime, tz.local);

      await _plugin.zonedSchedule(
    task.id.hashCode,
    '⏰ Due Soon: ${task.title}',
    'Due in ${hours.round()} hours - ${AppUtils.formatDateTime(task.dueDate!)}',
    scheduledDate,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for upcoming task due dates',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: false,
        visibility: NotificationVisibility.public,
        color: const Color(0xFF4F46E5),
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    payload: task.id,
  );

      debugPrint('🔔 Scheduled notification for "${task.title}" at $notifyTime');
    } catch (e) {
      debugPrint('❌ Schedule error: $e');
    }
  }

  /// Show an immediate notification
  Future<void> _showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || !_initialized) return;

    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for task due dates',
            importance: Importance.high,
            priority: Priority.high,
            ongoing: false,
            autoCancel: false,
            visibility: NotificationVisibility.public,
            color: const Color(0xFF4F46E5),
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Show notification error: $e');
    }
  }

  /// Cancel a scheduled notification for a task
  Future<void> cancelTaskNotification(String taskId) async {
    if (kIsWeb || !_initialized) return;

    try {
      await _plugin.cancel(taskId.hashCode);
      debugPrint('🔕 Cancelled notification for task $taskId');
    } catch (e) {
      debugPrint('❌ Cancel error: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;

    try {
      await _plugin.cancelAll();
      debugPrint('🔕 All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Cancel all error: $e');
    }
  }

  /// Check all tasks and schedule/update notifications
  Future<void> checkAndScheduleAll(List<TaskModel> tasks) async {
    if (kIsWeb || !_initialized) return;

    for (final task in tasks) {
      // Only process active tasks with due dates
      if (task.dueDate == null) continue;
      if (task.status == 'completed') continue;
      if (task.archivedAt != null) continue;

      // Schedule notification
      await scheduleTaskNotification(task: task);
    }
  }
}