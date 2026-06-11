import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/settings_provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../archive/archive_screen.dart';
import '../../database/database_helper.dart';
import '../../services/export_service.dart';
import '../../services/import_service.dart';
import '../../database/task_dao.dart';
import '../../database/note_dao.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: 'General'),
            _SettingsCard(
              child: Column(
                children: [
                  _SettingsField(
                    label: 'Final Goal',
                    child: TextFormField(
                      initialValue: settingsProvider.finalGoal,
                      decoration: _inputDeco(context, 'Your ultimate goal'),
                      style: TextStyle(color: AppTheme.textColor(context)),
                      onChanged: (v) {
                        if (v.trim().isNotEmpty) {
                          settingsProvider.updateFinalGoal(v.trim());
                        }
                      },
                    ),
                  ),
                  const Divider(height: 24),
                  _SettingsField(
                    label: 'Theme',
                    child: DropdownButtonFormField<String>(
                      initialValue: settingsProvider.theme,
                      decoration: _inputDeco(context, ''),
                      dropdownColor: AppTheme.cardBg(context),
                      style: TextStyle(color: AppTheme.textColor(context)),
                      items: const [
                        DropdownMenuItem(value: 'light', child: Text('Light')),
                        DropdownMenuItem(value: 'dark', child: Text('Dark')),
                        DropdownMenuItem(value: 'auto', child: Text('Auto')),
                      ],
                      onChanged: (v) {
                        if (v != null) settingsProvider.updateTheme(v);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _SectionTitle(title: '🔔 Notifications'),
            _SettingsCard(
              child: Column(
                children: [
                  _SettingsField(
                    label: 'Notifications',
                    child: DropdownButtonFormField<bool>(
                      initialValue: settingsProvider.notificationsEnabled,
                      decoration: _inputDeco(context, ''),
                      dropdownColor: AppTheme.cardBg(context),
                      style: TextStyle(color: AppTheme.textColor(context)),
                      items: const [
                        DropdownMenuItem(value: true, child: Text('Enabled')),
                        DropdownMenuItem(value: false, child: Text('Disabled')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          settingsProvider.updateNotificationsEnabled(v);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 24),
                  _SettingsField(
                    label: 'Default Notify Before (hours)',
                    child: TextFormField(
                      initialValue: settingsProvider.defaultNotifyBefore.toString(),
                      decoration: _inputDeco(context, 'Hours before due date'),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppTheme.textColor(context)),
                      onChanged: (v) {
                        final hours = double.tryParse(v);
                        if (hours != null && hours > 0) {
                          settingsProvider.updateDefaultNotifyBefore(hours);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _SectionTitle(title: '📋 Tasks'),
            _SettingsCard(
              child: _SettingsField(
                label: 'Auto-Archive After (days)',
                child: TextFormField(
                  initialValue: settingsProvider.autoArchiveDays.toString(),
                  decoration: _inputDeco(context, 'Days after completion'),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppTheme.textColor(context)),
                  onChanged: (v) {
                    final days = int.tryParse(v);
                    if (days != null && days > 0) {
                      settingsProvider.updateAutoArchiveDays(days);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            _SectionTitle(title: '📦 Data Management'),
            _SettingsCard(
              child: Column(
                children: [
                  _SettingsButton(
                    icon: '💾',
                    title: 'Export JSON',
                    subtitle: 'Backup file (can be imported)',
                    onTap: () => _exportJSON(context),
                  ),
                  const SizedBox(height: 8),
                  _SettingsButton(
                    icon: '📄',
                    title: 'Export PDF',
                    subtitle: 'Progress report',
                    onTap: () => _exportPDF(context),
                  ),
                  const SizedBox(height: 8),
                  _SettingsButton(
                    icon: '📥',
                    title: 'Import JSON',
                    subtitle: 'Restore from backup',
                    onTap: () => _importJSON(context),
                  ),
                  const SizedBox(height: 8),
                  _SettingsButton(
                    icon: '📦',
                    title: 'View Archive',
                    subtitle: 'Browse completed tasks',
                    onTap: () {
                      AppRouter.push(context, const ArchiveScreen());
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _SectionTitle(title: '⚠️ Danger Zone'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ConfirmationDialog.show(
                          context,
                          title: 'Reset All Data',
                          message: 'This will delete EVERYTHING permanently. Are you sure?',
                          confirmText: 'Reset Everything',
                          onConfirm: () async {
                            await DatabaseHelper.instance.deleteDatabase();
                            if (context.mounted) {
                              context.read<AppProvider>().refreshAll();
                              AppRouter.pop(context);
                            }
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.overdue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('🗑️ Reset All Data'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This will delete everything permanently!',
                    style: TextStyle(fontSize: 12, color: AppTheme.overdue),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.hintColor(context)),
      filled: true,
      fillColor: AppTheme.inputBg(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide(color: AppTheme.borderColor(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide(color: AppTheme.borderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  void _exportJSON(BuildContext context) async {
    try {
      final appProvider = context.read<AppProvider>();
      await ExportService.exportJSON(
        categories: appProvider.categories.categories,
        tasks: appProvider.tasks.allActiveTasks + (await TaskDao().getArchived()),
        notes: await NoteDao().getAll(),
        checkpoints: appProvider.roadmap.checkpoints,
        settings: appProvider.settings.settings,
        finalGoal: appProvider.settings.finalGoal,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _exportPDF(BuildContext context) async {
    try {
      final appProvider = context.read<AppProvider>();
      await ExportService.exportPDF(
        categories: appProvider.categories.categories,
        tasks: appProvider.tasks.allActiveTasks,
        notes: await NoteDao().getAll(),
        checkpoints: appProvider.roadmap.checkpoints,
        finalGoal: appProvider.settings.finalGoal,
        overallProgress: appProvider.overallProgress,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e')),
        );
      }
    }
  }

  void _importJSON(BuildContext context) async {
    try {
      final data = await ImportService.pickAndParseFile();
      if (data == null) return;

      final preview = ImportService.getPreviewInfo(data);

      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📁 ${preview['categories']} categories'),
              Text('📋 ${preview['tasks']} tasks'),
              Text('📝 ${preview['notes']} checklist items'),
              Text('🎯 ${preview['checkpoints']} checkpoints'),
              const SizedBox(height: 12),
              Text(
                'Exported: ${preview['exportedAt']}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.subtextColor(context),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ This will REPLACE all existing data!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      await ImportService.executeImport(data);

      if (context.mounted) {
        await context.read<AppProvider>().refreshAll();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Data imported successfully!')),
          );
          AppRouter.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.subtextColor(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecorationThemed(context),
      child: child,
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String label;
  final Widget child;
  const _SettingsField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.subtextColor(context),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SettingsButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBg(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.cardBg(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.hintColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.hintColor(context)),
          ],
        ),
      ),
    );
  }
}