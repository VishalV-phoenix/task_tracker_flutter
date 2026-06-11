/// =============================================
/// NOTE_DAO.DART
/// Database Access Object for Notes
/// =============================================

import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/note_model.dart';

class NoteDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<NoteModel>> getByCategory(String categoryId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notes',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'completed ASC, created_at DESC',
    );
    return maps.map((m) => NoteModel.fromMap(m)).toList();
  }

  Future<List<NoteModel>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('notes', orderBy: 'created_at DESC');
    return maps.map((m) => NoteModel.fromMap(m)).toList();
  }

  Future<void> insert(NoteModel note) async {
    final db = await _dbHelper.database;
    await db.insert('notes', note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(NoteModel note) async {
    final db = await _dbHelper.database;
    await db.update('notes', note.toMap(),
        where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleCompleted(String id, bool completed) async {
    final db = await _dbHelper.database;
    await db.update(
      'notes',
      {
        'completed': completed ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}