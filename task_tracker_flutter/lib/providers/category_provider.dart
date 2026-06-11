// =============================================
// CATEGORY_PROVIDER.DART
// Manages category list state
//
// Equivalent to Dashboard.js category management
// Handles: loading, adding, editing, deleting,
//          reordering categories
// =============================================

import 'package:flutter/material.dart';
import '../database/category_dao.dart';
import '../models/category_model.dart';
import '../core/utils.dart';

class CategoryProvider extends ChangeNotifier {
  // ── DAO Instance ──────────────────────────
  final CategoryDao _dao = CategoryDao();

  // ── State ─────────────────────────────────
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get only kanban-type categories
  List<CategoryModel> get kanbanCategories =>
      _categories.where((c) => c.type == 'kanban').toList();

  // Get only notes-type categories
  List<CategoryModel> get notesCategories =>
      _categories.where((c) => c.type == 'notes').toList();

  // Find a category by ID
  CategoryModel? getById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // ── LOAD ALL CATEGORIES ───────────────────
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _dao.getAll();
    } catch (e) {
      _error = 'Failed to load categories: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── ADD CATEGORY ──────────────────────────
  Future<void> add({
    required String name,
    required String icon,
    required String color,
    required String type,
  }) async {
    final category = CategoryModel(
      id: AppUtils.generateId('cat'),
      name: name,
      icon: icon,
      color: color,
      type: type,
      sortOrder: _categories.length,
    );

    try {
      // Optimistic update: add to list immediately
      _categories.add(category);
      notifyListeners();

      // Then save to database
      await _dao.insert(category);
    } catch (e) {
      // Rollback if save fails
      _categories.removeWhere((c) => c.id == category.id);
      _error = 'Failed to add category: $e';
      notifyListeners();
      debugPrint(_error);
    }
  }

  // ── UPDATE CATEGORY ───────────────────────
  Future<void> update(CategoryModel updatedCategory) async {
    final index = _categories.indexWhere((c) => c.id == updatedCategory.id);
    if (index == -1) return;

    final oldCategory = _categories[index];

    try {
      // Optimistic update
      _categories[index] = updatedCategory;
      notifyListeners();

      // Save to database
      await _dao.update(updatedCategory);
    } catch (e) {
      // Rollback
      _categories[index] = oldCategory;
      _error = 'Failed to update category: $e';
      notifyListeners();
      debugPrint(_error);
    }
  }

  // ── DELETE CATEGORY ───────────────────────
  // Note: CASCADE in DB deletes tasks/notes too
  Future<void> delete(String id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final deletedCategory = _categories[index];

    try {
      // Optimistic update
      _categories.removeAt(index);
      notifyListeners();

      // Delete from database (CASCADE handles tasks/notes)
      await _dao.delete(id);
    } catch (e) {
      // Rollback
      _categories.insert(index, deletedCategory);
      _error = 'Failed to delete category: $e';
      notifyListeners();
      debugPrint(_error);
    }
  }

  // ── REORDER CATEGORIES ────────────────────
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    final item = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, item);

    // Update order numbers
    for (int i = 0; i < _categories.length; i++) {
      _categories[i] = _categories[i].copyWith(sortOrder: i);
    }

    notifyListeners();
    await _dao.updateOrder(_categories);
  }

  // ── CLEAR ERROR ───────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }
}