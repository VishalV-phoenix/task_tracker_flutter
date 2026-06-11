// =============================================
// DASHBOARD_SCREEN.DART
// Main home screen - shows all categories,
// stats, and roadmap preview
// This is the first screen user sees
// =============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/app_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/roadmap_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/category_model.dart';
import 'widgets/quick_stats_bar.dart';
import 'widgets/category_card.dart';
import 'widgets/roadmap_preview_card.dart';
import '../tasks/task_board_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../notes/notes_screen.dart';
import '../roadmap/roadmap_screen.dart';
import '../notifications/notification_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/confirmation_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    // Run periodic notification check every 60 seconds
    _startNotificationTimer();
  }

  void _startNotificationTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 60));
      if (!mounted) return false;
      context.read<AppProvider>().runNotificationCheck();
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final noteProvider = context.watch<NoteProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final roadmapProvider = context.watch<RoadmapProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── App Bar with Stats ──────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                    child: QuickStatsBar(
                      totalTasks: taskProvider.allActiveTasks.length,
                      completed: taskProvider.completedCount,
                      overdue: taskProvider.overdueCount,
                      progress: appProvider.overallProgress,
                    ),
                  ),
                ),
              ),
            ),
            title: const Row(
              children: [
                Text('⚡', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text(
                  'Trackeon',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            actions: [
              // Notification bell
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      AppRouter.push(context, const NotificationScreen());
                    },
                  ),
                  if (notifProvider.activeCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppTheme.overdue,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${notifProvider.activeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Settings
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  AppRouter.push(context, const SettingsScreen());
                },
              ),
            ],
          ),

          // ── Categories Section ──────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddCategoryDialog(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Category Cards Grid ─────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cat = categoryProvider.categories[index];
                  final isKanban = cat.type == 'kanban';

                  final catTasks = isKanban
                      ? taskProvider.getTasksByCategory(cat.id)
                      : <dynamic>[];
                  final progress = isKanban
                      ? taskProvider.calculateCategoryProgress(cat.id)
                      : noteProvider.getCategoryProgress(cat.id);

                  return CategoryCard(
                    category: cat,
                    tasks: isKanban ? catTasks.cast() : [],
                    noteCount:
                        isKanban ? 0 : noteProvider.getTotalCount(cat.id),
                    noteCompletedCount:
                        isKanban ? 0 : noteProvider.getCompletedCount(cat.id),
                    progress: progress,
                    onTap: () => _openCategory(context, cat),
                    onMenuTap: () => _showEditCategoryDialog(context, cat),
                    onQuickAdd: () => _quickAdd(context, cat),
                  );
                },
                childCount: categoryProvider.categories.length,
              ),
            ),
          ),

          // ── Roadmap Preview ─────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: RoadmapPreviewCard(
                goalName: settingsProvider.finalGoal,
                progress: roadmapProvider.overallProgress,
                completed: roadmapProvider.completedCount,
                total: roadmapProvider.totalCount,
                onTap: () {
                  AppRouter.push(context, const RoadmapScreen());
                },
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  // ── Open category (kanban or notes) ─────────
  void _openCategory(BuildContext context, CategoryModel cat) {
    if (cat.type == 'kanban') {
      AppRouter.push(context, TaskBoardScreen(categoryId: cat.id));
    } else {
      AppRouter.push(context, NotesScreen(categoryId: cat.id));
    }
  }

  // ── Quick add (task or note) ────────────────
  void _quickAdd(BuildContext context, CategoryModel cat) {
    if (cat.type == 'kanban') {
      AppRouter.push(
        context,
        TaskDetailScreen(categoryId: cat.id),
      );
    } else {
      AppRouter.push(context, NotesScreen(categoryId: cat.id));
    }
  }

  // ── Show add category dialog ────────────────
  void _showAddCategoryDialog(BuildContext context) {
    _showCategoryFormDialog(context, null);
  }

  // ── Show edit category dialog ───────────────
  void _showEditCategoryDialog(BuildContext context, CategoryModel cat) {
    _showCategoryFormDialog(context, cat);
  }

  // ── Category form dialog ────────────────────
  void _showCategoryFormDialog(BuildContext context, CategoryModel? existing) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final iconController = TextEditingController(text: existing?.icon ?? '📁');
    String selectedType = existing?.type ?? 'kanban';
    Color selectedColor = existing != null
        ? AppTheme.colorFromHex(existing.color)
        : AppTheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          title: Text(existing != null ? 'Edit Category' : 'Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Icon field
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(
                    labelText: 'Icon (Emoji)',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 4,
                ),
                const SizedBox(height: 8),
                // Type selection
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedType = 'kanban'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedType == 'kanban'
                                  ? AppTheme.primary
                                  : AppTheme.borderLight,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            children: [
                              Text('📋', style: TextStyle(fontSize: 20)),
                              SizedBox(height: 4),
                              Text('Kanban', style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedType = 'notes'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedType == 'notes'
                                  ? AppTheme.primary
                                  : AppTheme.borderLight,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            children: [
                              Text('📝', style: TextStyle(fontSize: 20)),
                              SizedBox(height: 4),
                              Text('Checklist', style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            // Delete button (only for existing)
            if (existing != null)
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ConfirmationDialog.show(
                    context,
                    title: 'Delete Category',
                    message:
                        'Delete "${existing.name}"? All items will be deleted.',
                    confirmText: 'Delete',
                    onConfirm: () {
                      context.read<CategoryProvider>().delete(existing.id);
                      // Reload tasks/notes after category delete
                      context.read<TaskProvider>().loadAll();
                      context.read<NoteProvider>().loadAll();
                    },
                  );
                },
                style: TextButton.styleFrom(foregroundColor: AppTheme.overdue),
                child: const Text('Delete'),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final icon = iconController.text.trim().isEmpty
                    ? '📁'
                    : iconController.text.trim();
                final colorHex =
                    '#${selectedColor.red.toRadixString(16).padLeft(2, '0')}${selectedColor.green.toRadixString(16).padLeft(2, '0')}${selectedColor.blue.toRadixString(16).padLeft(2, '0')}';

                if (existing != null) {
                  context.read<CategoryProvider>().update(
                        existing.copyWith(
                          name: name,
                          icon: icon,
                          color: colorHex,
                          type: selectedType,
                        ),
                      );
                } else {
                  context.read<CategoryProvider>().add(
                        name: name,
                        icon: icon,
                        color: colorHex,
                        type: selectedType,
                      );
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
