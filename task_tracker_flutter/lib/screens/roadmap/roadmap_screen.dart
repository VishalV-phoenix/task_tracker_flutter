// =============================================
// ROADMAP_SCREEN.DART
// Full roadmap view with visual path
// Shows all checkpoints + final goal
// =============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/router.dart';

import '../../providers/roadmap_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/settings_provider.dart';

import '../../models/roadmap_model.dart';
import '../../widgets/confirmation_dialog.dart';
import 'widgets/checkpoint_card.dart';

class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roadmapProvider = context.watch<RoadmapProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final checkpoints = roadmapProvider.checkpoints;

    return Scaffold(
     backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.pop(context),
        ),
        title: const Text(
          '🎯 Roadmap',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Goal Header ───────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.secondary, AppTheme.secondaryDark],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  Text(
                    'Goal: ${settingsProvider.finalGoal}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${roadmapProvider.completedCount}/${roadmapProvider.totalCount} checkpoints • ${roadmapProvider.overallProgress}%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: roadmapProvider.overallProgress / 100,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Roadmap Path ──────────────────────
            Stack(
              children: [
                // Vertical line
                Positioned(
                  left: 55,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.secondary,
                          AppTheme.primary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Checkpoint cards
                Column(
                  children: [
                    ...checkpoints.asMap().entries.map((entry) {
                      final index = entry.key;
                      final cp = entry.value;
                      final isCurrent = !cp.completed &&
                          (index == 0 || checkpoints[index - 1].completed);

                      // Calculate progress from linked tasks
                      int progressPercent = 0;
                      if (cp.linkedTaskIds.isNotEmpty) {
                        int total = 0;
                        int completed = 0;
                        for (final taskId in cp.linkedTaskIds) {
                          final task = taskProvider.getById(taskId);
                          if (task != null) {
                            total += task.subtasks.length;
                            completed += task.subtasks
                                .where((s) => s.completed)
                                .length;
                          }
                        }
                        if (total > 0) {
                          progressPercent = ((completed / total) * 100).round();
                        }
                      }

                      return CheckpointCard(
                        checkpoint: cp,
                        index: index,
                        isCurrent: isCurrent,
                        linkedTaskCount: cp.linkedTaskIds.length,
                        progressPercent: progressPercent,
                        onTap: () => _showCheckpointDialog(context, cp),
                      );
                    }),

                    // Final goal
                    CheckpointCard(
                      checkpoint: CheckpointModel(
                        id: 'final',
                        title: settingsProvider.finalGoal,
                        description: 'Your ultimate goal!',
                      ),
                      index: checkpoints.length,
                      isCurrent: false,
                      isFinalGoal: true,
                      linkedTaskCount: 0,
                      progressPercent: 0,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Add Checkpoint Button ─────────────
            GestureDetector(
              onTap: () => _showCheckpointDialog(context, null),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.borderMedium,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 18, color: AppTheme.textSecondary),
                    SizedBox(width: 8),
                    Text(
                      'Add Checkpoint',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Checkpoint Add/Edit Dialog ──────────────
  void _showCheckpointDialog(BuildContext context, CheckpointModel? existing) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(existing != null ? 'Edit Checkpoint' : 'Add Checkpoint'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ConfirmationDialog.show(
                  context,
                  title: 'Delete Checkpoint',
                  message: 'Delete "${existing.title}"?',
                  confirmText: 'Delete',
                  onConfirm: () {
                    context.read<RoadmapProvider>().delete(existing.id);
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

              final provider = context.read<RoadmapProvider>();
              if (existing != null) {
                provider.update(existing.copyWith(
                  title: title,
                  description: descController.text.trim(),
                  notes: notesController.text.trim(),
                ));
              } else {
                provider.add(
                  title: title,
                  description: descController.text.trim(),
                  notes: notesController.text.trim(),
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
