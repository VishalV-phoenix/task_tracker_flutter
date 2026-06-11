// =============================================
// ARCHIVE_SCREEN.DART
// Browse archived tasks with search/sort
// Links remain clickable in archived tasks
// =============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirmation_dialog.dart';
import 'widgets/archive_item_card.dart';

class ArchiveScreen extends StatefulWidget {
  final String? categoryId;
  const ArchiveScreen({super.key, this.categoryId});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  String _searchQuery = '';
  String _sortOrder = 'newest';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadArchived();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    // Filter and sort archived tasks
    var archived = taskProvider.archivedTasks;

    // Filter by category if specified
    if (widget.categoryId != null) {
      archived = archived
          .where((t) => t.categoryId == widget.categoryId)
          .toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      archived = archived
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (t.description ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              t.links.any((l) =>
                  l.label.toLowerCase().contains(_searchQuery.toLowerCase())))
          .toList();
    }

    // Apply sort
    switch (_sortOrder) {
      case 'newest':
        archived.sort((a, b) =>
            (b.archivedAt ?? DateTime(2000))
                .compareTo(a.archivedAt ?? DateTime(2000)));
        break;
      case 'oldest':
        archived.sort((a, b) =>
            (a.archivedAt ?? DateTime(2000))
                .compareTo(b.archivedAt ?? DateTime(2000)));
        break;
      case 'name':
        archived.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.pop(context),
        ),
        title: Text(
          '📦 Archive (${archived.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // ── Search + Sort ─────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: '🔍 Search archive...',
                      filled: true,
                      fillColor: AppTheme.bgSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(color: AppTheme.borderLight),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: DropdownButton<String>(
                    value: _sortOrder,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('Newest', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'oldest', child: Text('Oldest', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'name', child: Text('Name', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (v) => setState(() => _sortOrder = v ?? 'newest'),
                  ),
                ),
              ],
            ),
          ),

          // ── Archive List ──────────────────────
          Expanded(
            child: archived.isEmpty
                ? EmptyState(
                    icon: '📦',
                    title: _searchQuery.isEmpty
                        ? 'No archived tasks'
                        : 'No matching tasks',
                    subtitle: 'Completed tasks are archived automatically',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: archived.length,
                    itemBuilder: (context, index) {
                      final task = archived[index];
                      final cat = categoryProvider.getById(task.categoryId);

                      return ArchiveItemCard(
                        task: task,
                        categoryName: cat?.name,
                        categoryIcon: cat?.icon,
                        onRestore: () {
                          taskProvider.restore(task.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('"${task.title}" restored'),
                            ),
                          );
                        },
                        onDelete: () {
                          ConfirmationDialog.show(
                            context,
                            title: 'Delete Permanently',
                            message: 'This cannot be undone.',
                            confirmText: 'Delete',
                            onConfirm: () {
                              taskProvider.deleteArchived(task.id);
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}