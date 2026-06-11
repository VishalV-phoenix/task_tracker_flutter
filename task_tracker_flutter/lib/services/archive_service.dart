// =============================================
// ARCHIVE_SERVICE.DART
// Handles auto-archiving completed tasks
// Called on app startup and periodically
// =============================================

import 'package:flutter/material.dart';
import '../database/task_dao.dart';

class ArchiveService {
  final TaskDao _taskDao = TaskDao();

  /// Run auto-archive check
  /// Moves completed tasks older than [days] to archive
  /// Returns count of newly archived tasks
  Future<int> runAutoArchive(int days) async {
    try {
      final tasksToArchive = await _taskDao.getTasksReadyToArchive(days);

      if (tasksToArchive.isEmpty) return 0;

      int count = 0;
      for (final task in tasksToArchive) {
        await _taskDao.archive(task.id);
        count++;
      }

      debugPrint('📦 Auto-archived $count task(s)');
      return count;
    } catch (e) {
      debugPrint('❌ Auto-archive error: $e');
      return 0;
    }
  }
}