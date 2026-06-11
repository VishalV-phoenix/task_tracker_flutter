/// =============================================
/// TASK_DAO.DART
/// Database Access Object for Tasks
///
/// Most complex DAO because tasks have:
/// - Subtasks (separate table)
/// - Links/URLs (separate table)
/// - Linked task IDs (junction table)
///
/// All related data is loaded together
/// when fetching a task
/// =============================================

import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/task_model.dart';

class TaskDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ── FULL TASK LOADING ──────────────────────
  // Loads task + subtasks + links + linked IDs

  /// Get all active (non-archived) tasks for a category
  Future<List<TaskModel>> getByCategoryActive(String categoryId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'category_id = ? AND archived_at IS NULL',
      whereArgs: [categoryId],
      orderBy: 'created_at DESC',
    );

    final tasks = <TaskModel>[];
    for (final map in maps) {
      tasks.add(await _loadFullTask(db, map));
    }
    return tasks;
  }

  /// Get all archived tasks
  Future<List<TaskModel>> getArchived() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'archived_at IS NOT NULL',
      orderBy: 'archived_at DESC',
    );

    final tasks = <TaskModel>[];
    for (final map in maps) {
      tasks.add(await _loadFullTask(db, map));
    }
    return tasks;
  }

  /// Get all active tasks (across all categories)
  Future<List<TaskModel>> getAllActive() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'archived_at IS NULL',
      orderBy: 'created_at DESC',
    );

    final tasks = <TaskModel>[];
    for (final map in maps) {
      tasks.add(await _loadFullTask(db, map));
    }
    return tasks;
  }

  /// Get a single task by ID with all related data
  Future<TaskModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _loadFullTask(db, maps.first);
  }

  /// Load subtasks, links, and linked IDs for a task
  Future<TaskModel> _loadFullTask(Database db, Map<String, dynamic> taskMap) async {
    final taskId = taskMap['id'] as String;

    // Load subtasks from subtasks table
    final subtaskMaps = await db.query(
      'subtasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'sort_order',
    );
    final subtasks = subtaskMaps.map((m) => SubtaskModel.fromMap(m)).toList();

    // Load links from task_links table
    final linkMaps = await db.query(
      'task_links',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'sort_order',
    );
    final links = linkMaps.map((m) => TaskLinkModel.fromMap(m)).toList();

    // Load linked task IDs from junction table
    final linkedMaps = await db.query(
      'linked_tasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
    final linkedIds = linkedMaps
        .map((m) => m['linked_task_id'] as String)
        .toList();

    // Combine everything into one TaskModel
    final task = TaskModel.fromMap(taskMap);
    return TaskModel(
      id: task.id,
      categoryId: task.categoryId,
      title: task.title,
      description: task.description,
      status: task.status,
      estimatedTime: task.estimatedTime,
      dueDate: task.dueDate,
      notifyBefore: task.notifyBefore,
      notified: task.notified,
      completedAt: task.completedAt,
      archivedAt: task.archivedAt,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      subtasks: subtasks,
      links: links,
      linkedTaskIds: linkedIds,
    );
  }

  // ── INSERT ─────────────────────────────────

  /// Insert a new task with all related data
  Future<void> insert(TaskModel task) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Insert main task row
      await txn.insert('tasks', task.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      // Insert subtasks
      for (final sub in task.subtasks) {
        await txn.insert('subtasks', sub.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Insert links
      for (final link in task.links) {
        await txn.insert('task_links', link.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Insert linked task IDs
      for (final linkedId in task.linkedTaskIds) {
        await txn.insert('linked_tasks', {
          'task_id': task.id,
          'linked_task_id': linkedId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  // ── UPDATE ─────────────────────────────────

  /// Update a task and all its related data
  /// Replaces all subtasks, links, and linked IDs
  Future<void> update(TaskModel task) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Update main task row
      await txn.update('tasks', task.toMap(),
          where: 'id = ?', whereArgs: [task.id]);

      // Replace subtasks: delete old, insert new
      await txn.delete('subtasks',
          where: 'task_id = ?', whereArgs: [task.id]);
      for (final sub in task.subtasks) {
        await txn.insert('subtasks', sub.toMap());
      }

      // Replace links: delete old, insert new
      await txn.delete('task_links',
          where: 'task_id = ?', whereArgs: [task.id]);
      for (final link in task.links) {
        await txn.insert('task_links', link.toMap());
      }

      // Replace linked IDs: delete old, insert new
      await txn.delete('linked_tasks',
          where: 'task_id = ?', whereArgs: [task.id]);
      for (final linkedId in task.linkedTaskIds) {
        await txn.insert('linked_tasks', {
          'task_id': task.id,
          'linked_task_id': linkedId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  /// Quick status update without replacing subtasks/links
  Future<void> updateStatus(String taskId, String status,
      {DateTime? completedAt}) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {
        'status': status,
        'completed_at': completedAt?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Mark task as archived
  Future<void> archive(String taskId) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {'archived_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Restore task from archive
  Future<void> unarchive(String taskId) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {'archived_at': null},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Mark task as notified
  Future<void> markNotified(String taskId) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {'notified': 1},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Reset notification flag (when due date changes)
  Future<void> resetNotified(String taskId) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {'notified': 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // ── DELETE ─────────────────────────────────

  /// Delete a task (CASCADE deletes subtasks, links, linked refs)
  Future<void> delete(String taskId) async {
    final db = await _dbHelper.database;

    // Also remove from other tasks' linked_tasks entries
    await db.delete(
      'linked_tasks',
      where: 'linked_task_id = ?',
      whereArgs: [taskId],
    );

    // Delete the task (CASCADE handles subtasks, task_links, linked_tasks where task_id matches)
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Delete multiple tasks
  Future<void> deleteMultiple(List<String> taskIds) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      for (final id in taskIds) {
        await txn.delete('linked_tasks',
            where: 'linked_task_id = ?', whereArgs: [id]);
        await txn.delete('tasks', where: 'id = ?', whereArgs: [id]);
      }
    });
  }

  // ── QUERIES ────────────────────────────────

  /// Get tasks with due dates that need notification
  Future<List<TaskModel>> getTasksNeedingNotification() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'due_date IS NOT NULL AND notified = 0 AND archived_at IS NULL AND status != ?',
      whereArgs: ['completed'],
    );

    final tasks = <TaskModel>[];
    for (final map in maps) {
      tasks.add(await _loadFullTask(db, map));
    }
    return tasks;
  }

  /// Get overdue tasks
  Future<List<TaskModel>> getOverdueTasks() async {
    final now = DateTime.now().toIso8601String();
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'due_date < ? AND archived_at IS NULL AND status != ?',
      whereArgs: [now, 'completed'],
    );

    final tasks = <TaskModel>[];
    for (final map in maps) {
      tasks.add(await _loadFullTask(db, map));
    }
    return tasks;
  }

  /// Get tasks ready for auto-archive
  Future<List<TaskModel>> getTasksReadyToArchive(int daysOld) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: daysOld))
        .toIso8601String();
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'status = ? AND archived_at IS NULL AND completed_at IS NOT NULL AND completed_at < ?',
      whereArgs: ['completed', cutoff],
    );

    final tasks = <TaskModel>[];
    for (final map in maps) {
      tasks.add(await _loadFullTask(db, map));
    }
    return tasks;
  }

  /// Count archived tasks
  Future<int> getArchivedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE archived_at IS NOT NULL',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}