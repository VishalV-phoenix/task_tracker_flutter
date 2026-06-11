// =============================================
// ROADMAP_PROVIDER.DART
// Manages roadmap and checkpoint state
//
// Handles:
// - Loading checkpoints
// - CRUD for checkpoints
// - Progress calculation toward final goal
// - Linked task progress integration
// =============================================

import 'package:flutter/material.dart';
import '../database/roadmap_dao.dart';
import '../models/roadmap_model.dart';
import '../core/utils.dart';

class RoadmapProvider extends ChangeNotifier {
  final RoadmapDao _dao = RoadmapDao();

  // ── State ─────────────────────────────────
  List<CheckpointModel> _checkpoints = [];
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────
  List<CheckpointModel> get checkpoints =>
      [..._checkpoints]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Overall roadmap progress (based on completed checkpoints)
  int get overallProgress {
    if (_checkpoints.isEmpty) return 0;
    final completed = _checkpoints.where((cp) => cp.completed).length;
    return AppUtils.calculateProgress(completed, _checkpoints.length);
  }

  // Count of completed checkpoints
  int get completedCount => _checkpoints.where((cp) => cp.completed).length;

  // Total checkpoints
  int get totalCount => _checkpoints.length;

  // Get the current active checkpoint (first incomplete)
  CheckpointModel? get currentCheckpoint {
    final sorted = checkpoints;
    try {
      return sorted.firstWhere((cp) => !cp.completed);
    } catch (e) {
      return null; // All completed!
    }
  }

  // Find checkpoint by ID
  CheckpointModel? getById(String id) {
    try {
      return _checkpoints.firstWhere((cp) => cp.id == id);
    } catch (e) {
      return null;
    }
  }

  // ── LOAD ALL CHECKPOINTS ──────────────────
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _checkpoints = await _dao.getAll();
    } catch (e) {
      _error = 'Failed to load roadmap: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── ADD CHECKPOINT ────────────────────────
  Future<void> add({
    required String title,
    String? description,
    String? notes,
    List<String>? linkedTaskIds,
  }) async {
    final checkpoint = CheckpointModel(
      id: AppUtils.generateId('cp'),
      title: title,
      description: description,
      notes: notes,
      sortOrder: _checkpoints.length,
      linkedTaskIds: linkedTaskIds ?? [],
    );

    try {
      _checkpoints.add(checkpoint);
      notifyListeners();
      await _dao.insert(checkpoint);
    } catch (e) {
      _checkpoints.removeWhere((cp) => cp.id == checkpoint.id);
      _error = 'Failed to add checkpoint: $e';
      notifyListeners();
      debugPrint(_error);
    }
  }

  // ── UPDATE CHECKPOINT ─────────────────────
  Future<void> update(CheckpointModel updated) async {
    final index = _checkpoints.indexWhere((cp) => cp.id == updated.id);
    if (index == -1) return;

    final old = _checkpoints[index];

    try {
      _checkpoints[index] = updated;
      notifyListeners();
      await _dao.update(updated);
    } catch (e) {
      _checkpoints[index] = old;
      _error = 'Failed to update checkpoint: $e';
      notifyListeners();
      debugPrint(_error);
    }
  }

  // ── TOGGLE COMPLETION ─────────────────────
  Future<void> toggleCompleted(String id) async {
    final index = _checkpoints.indexWhere((cp) => cp.id == id);
    if (index == -1) return;

    final newCompleted = !_checkpoints[index].completed;
    _checkpoints[index] = _checkpoints[index].copyWith(completed: newCompleted);
    notifyListeners();

    await _dao.toggleCompleted(id, newCompleted);
  }

  // ── DELETE CHECKPOINT ─────────────────────
  Future<void> delete(String id) async {
    final index = _checkpoints.indexWhere((cp) => cp.id == id);
    if (index == -1) return;

    final deleted = _checkpoints[index];

    try {
      _checkpoints.removeAt(index);

      // Re-number sort order
      for (int i = 0; i < _checkpoints.length; i++) {
        _checkpoints[i] = _checkpoints[i].copyWith(sortOrder: i);
      }

      notifyListeners();
      await _dao.delete(id);
    } catch (e) {
      _checkpoints.insert(index, deleted);
      _error = 'Failed to delete checkpoint: $e';
      notifyListeners();
      debugPrint(_error);
    }
  }

  // ── REORDER CHECKPOINTS ───────────────────
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    final sorted = checkpoints;
    final item = sorted.removeAt(oldIndex);
    sorted.insert(newIndex, item);

    // Update sort order
    for (int i = 0; i < sorted.length; i++) {
      sorted[i] = sorted[i].copyWith(sortOrder: i);
    }

    _checkpoints = sorted;
    notifyListeners();
    await _dao.updateOrder(_checkpoints);
  }

  // ── CALCULATE CHECKPOINT PROGRESS ─────────
  // Based on linked tasks' subtask completion
  Map<String, int> calculateCheckpointProgress(
    CheckpointModel checkpoint,
    List<dynamic> allTasks, // TaskModel list passed from TaskProvider
  ) {
    if (checkpoint.linkedTaskIds.isEmpty) {
      return {'completed': 0, 'total': 0};
    }

    int completed = 0;
    int total = 0;

    for (final taskId in checkpoint.linkedTaskIds) {
      try {
        final task = allTasks.firstWhere((t) => t.id == taskId);
        if (task.subtasks.isNotEmpty) {
          total += task.subtasks.length as int;
          completed +=
              (task.subtasks as List).where((s) => s.completed).length;
        }
      } catch (e) {
        // Task not found, skip
      }
    }

    return {'completed': completed, 'total': total};
  }

  // ── CLEAR ERROR ───────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }
}