/// =============================================
/// CATEGORY_DAO.DART
/// Database Access Object for Categories
///
/// DAO = Data Access Object
/// All database operations for categories go here
/// UI never touches the database directly
/// =============================================

import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/category_model.dart';

class CategoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get all categories sorted by order
  Future<List<CategoryModel>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('categories', orderBy: 'sort_order');
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  /// Get a single category by ID
  Future<CategoryModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CategoryModel.fromMap(maps.first);
  }

  /// Insert a new category
  Future<void> insert(CategoryModel category) async {
    final db = await _dbHelper.database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing category
  Future<void> update(CategoryModel category) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Delete a category (CASCADE deletes tasks/notes too)
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get count of categories
  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Update sort order for multiple categories
  Future<void> updateOrder(List<CategoryModel> categories) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (int i = 0; i < categories.length; i++) {
      batch.update(
        'categories',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [categories[i].id],
      );
    }
    await batch.commit(noResult: true);
  }
}