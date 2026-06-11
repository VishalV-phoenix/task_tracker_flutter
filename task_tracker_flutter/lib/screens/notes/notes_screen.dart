// =============================================
// NOTES_SCREEN.DART
// Simple notes list for notes-type categories
// Shows checkbox list, add/edit/delete notes
// =============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/router.dart';

import '../../providers/note_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/note_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirmation_dialog.dart';
import 'widgets/note_item.dart';

class NotesScreen extends StatefulWidget {
  final String categoryId;
  const NotesScreen({super.key, required this.categoryId});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteProvider>().loadByCategory(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final noteProvider = context.watch<NoteProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final category = categoryProvider.getById(widget.categoryId);

    if (category == null) {
      return const Scaffold(body: Center(child: Text('Category not found')));
    }

    final notes = noteProvider.getByCategory(widget.categoryId);
    final accentColor = AppTheme.colorFromHex(category.color);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.pop(context),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: notes.isEmpty
          ? const EmptyState(
              icon: '📝',
              title: 'No notes yet',
              subtitle: 'Tap + to add a note',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return NoteItem(
                  note: note,
                  accentColor: accentColor,
                  onToggle: () {
                    noteProvider.toggleCompleted(note.id, widget.categoryId);
                  },
                  onTap: () => _showNoteDialog(context, note),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _showNoteDialog(context, null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Add/Edit Note Dialog ──────────────────────
  void _showNoteDialog(BuildContext context, NoteModel? existing) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(text: existing?.content ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(existing != null ? 'Edit Note' : 'Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Content (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          // Delete button for existing notes
          if (existing != null)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ConfirmationDialog.show(
                  context,
                  title: 'Delete Note',
                  message: 'Delete "${existing.title}"?',
                  confirmText: 'Delete',
                  onConfirm: () {
                    context
                        .read<NoteProvider>()
                        .delete(existing.id, widget.categoryId);
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
              final title = titleController.text.trim();
              if (title.isEmpty) return;

              final content = contentController.text.trim();
              final noteProvider = context.read<NoteProvider>();

              if (existing != null) {
                noteProvider.update(existing.copyWith(
                  title: title,
                  content: content.isEmpty ? null : content,
                ));
              } else {
                noteProvider.add(
                  categoryId: widget.categoryId,
                  title: title,
                  content: content.isEmpty ? null : content,
                );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}