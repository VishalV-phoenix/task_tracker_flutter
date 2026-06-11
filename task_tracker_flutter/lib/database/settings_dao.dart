// =============================================
// SETTINGS_DAO.DART
// Database Access Object for Settings
// Single-row table - always ID = 1
// =============================================

import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/settings_model.dart';

class SettingsDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get current settings (always row 1)
  Future<SettingsModel> get() async {
    final db = await _dbHelper.database;
    final maps = await db.query('settings', where: 'id = 1');
    if (maps.isEmpty) return SettingsModel();
    return SettingsModel.fromMap(maps.first);
  }

  /// Update settings (upsert row 1)
  Future<void> update(SettingsModel settings) async {
    final db = await _dbHelper.database;
    await db.insert(
      'settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}