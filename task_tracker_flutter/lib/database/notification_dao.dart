/// =============================================
/// NOTIFICATION_DAO.DART
/// Database Access Object for Notifications
/// =============================================

import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/notification_model.dart';

class NotificationDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get all active (undismissed) notifications
  Future<List<NotificationModel>> getActive() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notifications',
      where: 'dismissed = 0',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => NotificationModel.fromMap(m)).toList();
  }

  /// Get notification for a specific task (undismissed)
  Future<NotificationModel?> getByTaskId(String taskId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notifications',
      where: 'task_id = ? AND dismissed = 0',
      whereArgs: [taskId],
    );
    if (maps.isEmpty) return null;
    return NotificationModel.fromMap(maps.first);
  }

  /// Insert or update a notification
  Future<void> upsert(NotificationModel notification) async {
    final db = await _dbHelper.database;
    await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Dismiss a single notification
  Future<void> dismiss(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'notifications',
      {'dismissed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Dismiss all notifications
  Future<void> dismissAll() async {
    final db = await _dbHelper.database;
    await db.update('notifications', {'dismissed': 1});
  }

  /// Delete notifications for a specific task
  Future<void> deleteForTask(String taskId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'notifications',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  /// Get count of active notifications
  Future<int> getActiveCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE dismissed = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}