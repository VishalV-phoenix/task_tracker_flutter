// =============================================
// NOTE_PROVIDER.DART
// Manages simple notes state
// For notes-type categories (checkbox lists)
// =============================================

import 'package:flutter/material.dart';
import '../database/note_dao.dart';
import '../models/note_model.dart';
import '../core/utils.dart';

class NoteProvider extends ChangeNotifier {
  final NoteDao _dao = NoteDao();

  // ── State ─────────────────────────────────
  // Notes grouped by category ID
  Map<String, List<NoteModel>> _notesByCategory = {};
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get notes for a specific category
  List<NoteModel> getByCategory(String categoryId) =>
      _notesByCategory[categoryId] ?? [];

  // Get completion count for a category
  int getCompletedCount(String categoryId) =>
      getByCategory(categoryId).where((n) => n.completed).length;

  // Get total count for a category
  int getTotalCount(String categoryId) => getByCategory(categoryId).length;

  // Get progress percentage for a category
  int getCategoryProgress(String categoryId) {
    final notes = getByCategory(categoryId);
    if (notes.isEmpty) return 0;
    final completed = notes.where((n) => n.completed).length;
    return AppUtils.calculateProgress(completed, notes.length);
  }

  // ── LOAD ALL NOTES ────────────────────────
  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      final allNotes = await _dao.getAll();

      // Group by category
      _notesByCategory = {};
      for (final note in allNotes) {
        _notesByCategory.putIfAbsent(note.categoryId, () => []).add(note);
      }
    } catch (e) {
      _error = 'Failed to load notes: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── LOAD NOTES FOR ONE CATEGORY ───────────
  Future<void> loadByCategory(String categoryId) async {
    try {
      final notes = await _dao.getByCategory(categoryId);
      _notesByCategory[categoryId] = notes;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load notes: $e';
      debugPrint(_error);
    }
  }

  // ── ADD NOTE ──────────────────────────────
  Future<void> add({
    required String categoryId,
    required String title,
    String? content,
  }) async {
    final note = NoteModel(
      id: AppUtils.generateId('note'),
      categoryId: categoryId,
      title: title,
      content: content,
    );

    try {
      // Add to local state
      _notesByCategory.putIfAbsent(categoryId, () => []).insert(0, note);
      notifyListeners();

      // Save to database
      await _dao.insert(note);
    } catch (e) {
      // Rollback
      _notesByCategory[categoryId]?.removeWhere((n) => n.id == note.id);
      _error = 'Failed to add note: $e';
      notifyListeners();
      debugPrint(_error);
    }
  }

  // ── UPDATE NOTE ───────────────────────────
  Future<void> update(NoteModel updatedNote) async {
    final list = _notesByCategory[updatedNote.categoryId];
    if (list == null) return;

    final index = list.indexWhere((n) => n.id == updatedNote.id);
    if (index == -1) return;

    final old = list[index];

    try {
      list[index] = updatedNote;
      notifyListeners();
      await _dao.update(updatedNote);
    } catch (e) {
      list[index] = old;
      _error = 'Failed to update note: $e';
      notifyListeners();
      debugPrint(_error);
    }
  }

  // ── TOGGLE COMPLETION ─────────────────────
  Future<void> toggleCompleted(String noteId, String categoryId) async {
    final list = _notesByCategory[categoryId];
    if (list == null) return;

    final index = list.indexWhere((n) => n.id == noteId);
    if (index == -1) return;

    final newCompleted = !list[index].completed;
    list[index] = list[index].copyWith(completed: newCompleted);
    notifyListeners();

    await _dao.toggleCompleted(noteId, newCompleted);
  }

  // ── DELETE NOTE ───────────────────────────
  Future<void> delete(String noteId, String categoryId) async {
    final list = _notesByCategory[categoryId];
    if (list == null) return;

    final index = list.indexWhere((n) => n.id == noteId);
    if (index == -1) return;

    final deleted = list[index];

    try {
      list.removeAt(index);
      notifyListeners();
      await _dao.delete(noteId);
    } catch (e) {
      list.insert(index, deleted);
      _error = 'Failed to delete note: $e';
      notifyListeners();
      debugPrint(_error);
    }
  }

  // ── CLEAR ERROR ───────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }
}