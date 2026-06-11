// =============================================
// IMPORT_SERVICE.DART
// Handles JSON import with data migration
// Supports both old (web app) and new formats
// =============================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';
import '../database/category_dao.dart';
import '../database/task_dao.dart';
import '../database/note_dao.dart';
import '../database/roadmap_dao.dart';
import '../database/settings_dao.dart';
import '../models/category_model.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';
import '../models/roadmap_model.dart';
import '../models/settings_model.dart';
import '../core/utils.dart';

class ImportService {
  /// Pick a JSON file and return parsed data
  /// Returns null if user cancels or file is invalid
  static Future<Map<String, dynamic>?> pickAndParseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return null;

      String jsonString;

      if (kIsWeb) {
        // Web: read from bytes
        final bytes = result.files.first.bytes;
        if (bytes == null) return null;
        jsonString = utf8.decode(bytes);
      } else {
        // Mobile: read from file path
        final path = result.files.first.path;
        if (path == null) return null;
        final file = File(path);
        jsonString = await file.readAsString();
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate basic structure
      if (!_validateStructure(data)) {
        debugPrint('❌ Invalid backup file structure');
        return null;
      }

      return data;
    } catch (e) {
      debugPrint('❌ Import file error: $e');
      return null;
    }
  }

  /// Validate the backup file has required fields
  static bool _validateStructure(Map<String, dynamic> data) {
    if (!data.containsKey('categories')) return false;
    if (data['categories'] is! List) return false;
    if (!data.containsKey('tasks')) return false;
    if (data['tasks'] is! List) return false;
    return true;
  }

  /// Get import preview info
  static Map<String, dynamic> getPreviewInfo(Map<String, dynamic> data) {
    return {
      'categories': (data['categories'] as List).length,
      'tasks': (data['tasks'] as List).length,
      'notes': data.containsKey('notes') ? (data['notes'] as List).length : 0,
      'checkpoints': data.containsKey('roadmap') &&
              data['roadmap'] is Map &&
              data['roadmap'].containsKey('checkpoints')
          ? (data['roadmap']['checkpoints'] as List).length
          : 0,
      'exportedAt': data['exportedAt'] ?? 'Unknown',
      'appVersion': data['appVersion'] ?? 'Unknown',
    };
  }

  /// Execute the import - replace all data
  static Future<void> executeImport(
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      final categoryDao = CategoryDao();
      final taskDao = TaskDao();
      final noteDao = NoteDao();
      final roadmapDao = RoadmapDao();
      final settingsDao = SettingsDao();

      // ── Parse Categories ──────────────────
      final categories = (data['categories'] as List).map((c) {
        final map = c as Map<String, dynamic>;
        return CategoryModel(
          id: map['id'] ?? AppUtils.generateId('cat'),
          name: map['name'] ?? 'Unnamed',
          icon: map['icon'] ?? '📁',
          color: map['color'] ?? '#4F46E5',
          type: map['type'] ?? 'kanban',
          sortOrder: map['sort_order'] ?? map['order'] ?? 0,
        );
      }).toList();

      // ── Parse Tasks (with migration) ──────
      final tasks = <TaskModel>[];
      for (final t in data['tasks'] as List) {
        final map = t as Map<String, dynamic>;

        // Migrate old linkedTaskId to linkedTaskIds
        List<String> linkedIds = [];
        if (map.containsKey('linkedTaskIds') && map['linkedTaskIds'] is List) {
          linkedIds = (map['linkedTaskIds'] as List).cast<String>();
        } else if (map.containsKey('linkedTaskId') && map['linkedTaskId'] != null) {
          linkedIds = [map['linkedTaskId'] as String];
        }

        // Parse subtasks
        final subtasks = <SubtaskModel>[];
        if (map.containsKey('subtasks') && map['subtasks'] is List) {
          for (final s in map['subtasks'] as List) {
            final sMap = s as Map<String, dynamic>;
            subtasks.add(SubtaskModel(
              id: sMap['id'] ?? AppUtils.generateId('sub'),
              taskId: map['id'] ?? '',
              title: sMap['title'] ?? '',
              completed: sMap['completed'] == true || sMap['completed'] == 1,
            ));
          }
        }

        // Parse links
        final links = <TaskLinkModel>[];
        if (map.containsKey('links') && map['links'] is List) {
          for (final l in map['links'] as List) {
            final lMap = l as Map<String, dynamic>;
            links.add(TaskLinkModel(
              id: lMap['id'] ?? AppUtils.generateId('link'),
              taskId: map['id'] ?? '',
              label: lMap['label'] ?? 'Link',
              url: lMap['url'] ?? '',
              linkType: lMap['type'] ?? lMap['link_type'],
            ));
          }
        }

        tasks.add(TaskModel(
          id: map['id'] ?? AppUtils.generateId('task'),
          categoryId: map['categoryId'] ?? map['category_id'] ?? '',
          title: map['title'] ?? 'Untitled',
          description: map['description'],
          status: map['status'] ?? 'todo',
          estimatedTime: map['estimatedTime'] ?? map['estimated_time'],
          dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate']) : null,
          notifyBefore: (map['notifyBefore'] as num?)?.toDouble() ?? 3.0,
          notified: map['notified'] == true || map['notified'] == 1,
          completedAt: map['completedAt'] != null
              ? DateTime.tryParse(map['completedAt'])
              : null,
          archivedAt: map['archivedAt'] != null
              ? DateTime.tryParse(map['archivedAt'])
              : null,
          subtasks: subtasks,
          links: links,
          linkedTaskIds: linkedIds,
        ));
      }

      // ── Parse Notes ───────────────────────
      final notes = <NoteModel>[];
      if (data.containsKey('notes') && data['notes'] is List) {
        for (final n in data['notes'] as List) {
          final map = n as Map<String, dynamic>;
          notes.add(NoteModel(
            id: map['id'] ?? AppUtils.generateId('note'),
            categoryId: map['categoryId'] ?? map['category_id'] ?? '',
            title: map['title'] ?? 'Untitled',
            content: map['content'],
            completed: map['completed'] == true || map['completed'] == 1,
          ));
        }
      }

      // ── Parse Checkpoints ─────────────────
      final checkpoints = <CheckpointModel>[];
      if (data.containsKey('roadmap') && data['roadmap'] is Map) {
        final roadmap = data['roadmap'] as Map<String, dynamic>;
        if (roadmap.containsKey('checkpoints') && roadmap['checkpoints'] is List) {
          for (final cp in roadmap['checkpoints'] as List) {
            final map = cp as Map<String, dynamic>;

            List<String> linkedTasks = [];
            if (map.containsKey('linkedTasks') && map['linkedTasks'] is List) {
              linkedTasks = (map['linkedTasks'] as List).cast<String>();
            }

            checkpoints.add(CheckpointModel(
              id: map['id'] ?? AppUtils.generateId('cp'),
              title: map['title'] ?? 'Untitled',
              description: map['description'],
              notes: map['notes'],
              sortOrder: map['order'] ?? map['sort_order'] ?? 0,
              completed: map['completed'] == true || map['completed'] == 1,
              linkedTaskIds: linkedTasks,
            ));
          }
        }
      }

      // ── Save to Database ──────────────────
      if (!merge) {
        // Replace mode: delete existing data first
        final db = await DatabaseHelper.instance.database;
        await db.delete('categories');
        // CASCADE deletes tasks, subtasks, links, etc.
      }

      // Insert categories
      for (final cat in categories) {
        await categoryDao.insert(cat);
      }

      // Insert tasks with all related data
      for (final task in tasks) {
        await taskDao.insert(task);
      }

      // Insert notes
      for (final note in notes) {
        await noteDao.insert(note);
      }

      // Insert checkpoints
      for (final cp in checkpoints) {
        await roadmapDao.insert(cp);
      }

      // Update settings if present
      if (data.containsKey('settings') && data['settings'] is Map) {
        final s = data['settings'] as Map<String, dynamic>;
        await settingsDao.update(SettingsModel(
          theme: s['theme'] ?? 'light',
          finalGoal: s['finalGoal'] ?? s['final_goal'] ?? 'Bioinformatics',
          defaultNotifyBefore:
              (s['defaultNotifyBefore'] as num?)?.toDouble() ?? 3.0,
          autoArchiveDays: s['autoArchiveDays'] ?? s['auto_archive_days'] ?? 7,
          notificationsEnabled:
              s['notificationsEnabled'] ?? s['notifications_enabled'] ?? true,
        ));
      }

      debugPrint('✅ Import completed successfully');
    } catch (e) {
      debugPrint('❌ Import error: $e');
      rethrow;
    }
  }
}