/// =============================================
/// ROADMAP_DAO.DART
/// Database Access Object for Roadmap Checkpoints
/// =============================================

import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/roadmap_model.dart';

class RoadmapDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get all checkpoints with their linked task IDs
  Future<List<CheckpointModel>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('checkpoints', orderBy: 'sort_order');

    final checkpoints = <CheckpointModel>[];
    for (final map in maps) {
      final cpId = map['id'] as String;

      // Load linked task IDs from junction table
      final linkedMaps = await db.query(
        'checkpoint_tasks',
        where: 'checkpoint_id = ?',
        whereArgs: [cpId],
      );
      final linkedIds = linkedMaps
          .map((m) => m['task_id'] as String)
          .toList();

      final cp = CheckpointModel.fromMap(map);
      checkpoints.add(CheckpointModel(
        id: cp.id,
        title: cp.title,
        description: cp.description,
        notes: cp.notes,
        sortOrder: cp.sortOrder,
        completed: cp.completed,
        createdAt: cp.createdAt,
        linkedTaskIds: linkedIds,
      ));
    }
    return checkpoints;
  }

  /// Insert a checkpoint with linked tasks
  Future<void> insert(CheckpointModel checkpoint) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.insert('checkpoints', checkpoint.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      for (final taskId in checkpoint.linkedTaskIds) {
        await txn.insert('checkpoint_tasks', {
          'checkpoint_id': checkpoint.id,
          'task_id': taskId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  /// Update a checkpoint and its linked tasks
  Future<void> update(CheckpointModel checkpoint) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.update('checkpoints', checkpoint.toMap(),
          where: 'id = ?', whereArgs: [checkpoint.id]);

      // Replace linked tasks
      await txn.delete('checkpoint_tasks',
          where: 'checkpoint_id = ?', whereArgs: [checkpoint.id]);
      for (final taskId in checkpoint.linkedTaskIds) {
        await txn.insert('checkpoint_tasks', {
          'checkpoint_id': checkpoint.id,
          'task_id': taskId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  /// Toggle checkpoint completion
  Future<void> toggleCompleted(String id, bool completed) async {
    final db = await _dbHelper.database;
    await db.update(
      'checkpoints',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a checkpoint
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('checkpoints', where: 'id = ?', whereArgs: [id]);
  }

  /// Update sort order for all checkpoints
  Future<void> updateOrder(List<CheckpointModel> checkpoints) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (int i = 0; i < checkpoints.length; i++) {
      batch.update(
        'checkpoints',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [checkpoints[i].id],
      );
    }
    await batch.commit(noResult: true);
  }
}