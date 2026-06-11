// =============================================
// APP_PROVIDER.DART
// Master provider that coordinates all others
//
// This is the equivalent of App.init() in your
// web app. It:
// - Initializes all providers in correct order
// - Runs startup tasks (auto-archive, check notifs)
// - Provides global stats for the header
// - Handles data reset
// =============================================

import 'package:flutter/material.dart';
import 'settings_provider.dart';
import 'category_provider.dart';
import 'task_provider.dart';
import 'note_provider.dart';
import 'roadmap_provider.dart';
import 'notification_provider.dart';
// Add this import at the top of app_provider.dart
import '../services/notification_service.dart';


class AppProvider extends ChangeNotifier {
  // ── All Sub-Providers ─────────────────────
  // AppProvider holds references to all others
  // so it can coordinate between them
  final SettingsProvider settings;
  final CategoryProvider categories;
  final TaskProvider tasks;
  final NoteProvider notes;
  final RoadmapProvider roadmap;
  final NotificationProvider notifications;

  // ── State ─────────────────────────────────
  bool _initialized = false;
  bool _isLoading = true;
  String? _error;

  // ── Getters ───────────────────────────────
  bool get initialized => _initialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Constructor ───────────────────────────
  AppProvider({
    required this.settings,
    required this.categories,
    required this.tasks,
    required this.notes,
    required this.roadmap,
    required this.notifications,
  });

  // ── INITIALIZE APP ────────────────────────
  // Called once when app starts
  // Loads all data in the correct order
  Future<void> initialize() async {
    if (_initialized) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('=== App Initializing ===');

      // 1. Load settings first (other providers may need them)
      await settings.load();
      debugPrint('✅ Settings loaded');

      // 2. Load categories
      await categories.loadAll();
      debugPrint('✅ Categories loaded: ${categories.categories.length}');

      // 3. Load all active tasks
      await tasks.loadAll();
      debugPrint('✅ Tasks loaded: ${tasks.allActiveTasks.length}');

      // 4. Load all notes
      await notes.loadAll();
      debugPrint('✅ Notes loaded');

      // 5. Load roadmap
      await roadmap.loadAll();
      debugPrint('✅ Roadmap loaded: ${roadmap.totalCount} checkpoints');

      // 6. Load existing notifications
      await notifications.load();
      debugPrint('✅ Notifications loaded: ${notifications.activeCount}');

      // 7. Run auto-archive (moves completed tasks older than X days)
      final archived = await tasks.autoArchive(settings.autoArchiveDays);
      if (archived > 0) {
        debugPrint('📦 Auto-archived $archived task(s)');
      }

      // 8. Check for due date notifications
      await notifications.checkTasks(
        tasks.allActiveTasks,
        defaultNotifyHours: settings.defaultNotifyBefore,
      );
      debugPrint('🔔 Notification check complete');

      // 9. Initialize system notification service (Android only)
      await NotificationService().initialize();

// 10. Schedule system notifications for all tasks with due dates
      await NotificationService().checkAndScheduleAll(tasks.allActiveTasks);
      debugPrint('📱 System notifications scheduled');

      _initialized = true;
      debugPrint('=== App Ready ===');
    } catch (e) {
      _error = 'Failed to initialize app: $e';
      debugPrint('❌ Init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── PERIODIC NOTIFICATION CHECK ───────────
  // Called every 60 seconds to check due dates
  Future<void> runNotificationCheck() async {
    if (!_initialized) return;

    await notifications.checkTasks(
      tasks.allActiveTasks,
      defaultNotifyHours: settings.defaultNotifyBefore,
    );
  }

  // ── GLOBAL STATS (for header) ─────────────

  // Total tasks + notes across all categories
  int get totalItems {
    return tasks.allActiveTasks.length +
        notes
            .getByCategory(
              categories.notesCategories.map((c) => c.id).join(','),
            )
            .length;
  }

  // Overall progress across all categories
  int get overallProgress {
    int totalCompleted = 0;
    int totalItems = 0;

    // From kanban tasks
    for (final task in tasks.allActiveTasks) {
      if (task.subtasks.isNotEmpty) {
        totalItems += task.subtasks.length;
        totalCompleted += task.subtasks.where((s) => s.completed).length;
      } else {
        totalItems += 1;
        if (task.status == 'completed') totalCompleted += 1;
      }
    }

    // From notes (each note counts as 1 item)
    for (final cat in categories.notesCategories) {
      final catNotes = notes.getByCategory(cat.id);
      totalItems += catNotes.length;
      totalCompleted += catNotes.where((n) => n.completed).length;
    }

    if (totalItems == 0) return 0;
    return ((totalCompleted / totalItems) * 100).round();
  }

  // Count of completed tasks
  int get completedCount => tasks.completedCount;

  // Count of overdue tasks
  int get overdueCount => tasks.overdueCount;

  // ── REFRESH ALL DATA ──────────────────────
  // Call after data import
  Future<void> refreshAll() async {
    _initialized = false;
    await initialize();
  }

  // ── RESET ALL DATA ────────────────────────
// Called from settings (danger zone)
// Reinitializes all data to defaults
  Future<void> resetAllData() async {
    try {
      // Just reinitialize - actual data clearing
      // will be handled by the settings screen
      // which calls DatabaseHelper.deleteDatabase()
      _initialized = false;
      await initialize();
    } catch (e) {
      _error = 'Failed to reset: $e';
      debugPrint(_error);
    }
  }
}
