// =============================================
// EXPORT_SERVICE.DART
// Handles JSON and PDF export
// JSON: Full backup that can be imported back
// PDF: Printable progress report
// =============================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/category_model.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';
import '../models/roadmap_model.dart';
import '../models/settings_model.dart';
import '../core/utils.dart';

class ExportService {
  /// Export all data as JSON file and share it
  static Future<void> exportJSON({
    required List<CategoryModel> categories,
    required List<TaskModel> tasks,
    required List<NoteModel> notes,
    required List<CheckpointModel> checkpoints,
    required SettingsModel settings,
    required String finalGoal,
  }) async {
    try {
      // Build export data structure
      final data = {
        'appVersion': '3.0.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'settings': {
          'theme': settings.theme,
          'finalGoal': finalGoal,
          'defaultNotifyBefore': settings.defaultNotifyBefore,
          'autoArchiveDays': settings.autoArchiveDays,
          'notificationsEnabled': settings.notificationsEnabled,
        },
        'categories': categories.map((c) => c.toJson()).toList(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'notes': notes.map((n) => n.toJson()).toList(),
        'roadmap': {
          'finalGoal': finalGoal,
          'checkpoints': checkpoints.map((cp) => cp.toJson()).toList(),
        },
      };

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      if (kIsWeb) {
        debugPrint('JSON export not supported on web');
        return;
      }

      // Save to temp file
      final dir = await getTemporaryDirectory();
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File('${dir.path}/productivity_backup_$date.json');
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Productivity Backup - $date',
      );

      debugPrint('✅ JSON exported successfully');
    } catch (e) {
      debugPrint('❌ JSON export error: $e');
      rethrow;
    }
  }

  /// Export progress report as PDF and share/print it
  static Future<void> exportPDF({
    required List<CategoryModel> categories,
    required List<TaskModel> tasks,
    required List<NoteModel> notes,
    required List<CheckpointModel> checkpoints,
    required String finalGoal,
    required int overallProgress,
  }) async {
    try {
      final pdf = pw.Document();
      final date = DateFormat('MMMM d, y').format(DateTime.now());

      // Separate active and archived tasks
      final activeTasks = tasks.where((t) => t.archivedAt == null).toList();
      final completedTasks = activeTasks.where((t) => t.status == 'completed').length;
      final overdueTasks = activeTasks.where((t) =>
          t.dueDate != null &&
          t.status != 'completed' &&
          t.dueDate!.isBefore(DateTime.now())).length;

      // ── Page 1: Overview ─────────────────────
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _pdfHeader(date),
          build: (context) => [
            // Stats
            pw.Text('Overview',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfStatBox('${activeTasks.length}', 'Active Tasks'),
                _pdfStatBox('$completedTasks', 'Completed'),
                _pdfStatBox('$overdueTasks', 'Overdue'),
                _pdfStatBox('$overallProgress%', 'Progress'),
              ],
            ),
            pw.SizedBox(height: 24),

            // Categories summary
            pw.Text('Categories',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            ...categories.map((cat) {
              final catTasks = activeTasks.where((t) => t.categoryId == cat.id).toList();
              final catNotes = notes.where((n) => n.categoryId == cat.id).toList();
              final isKanban = cat.type == 'kanban';

              int total = isKanban ? catTasks.length : catNotes.length;
              int done = isKanban
                  ? catTasks.where((t) => t.status == 'completed').length
                  : catNotes.where((n) => n.completed).length;

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Text('${cat.icon} ${cat.name}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Spacer(),
                    pw.Text('$done/$total ${isKanban ? "tasks" : "items"}'),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 24),

            // Roadmap
            pw.Text('Roadmap to $finalGoal',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            ...checkpoints.map((cp) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: cp.completed ? PdfColors.green50 : PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(cp.completed ? '✓' : '○',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 8),
                      pw.Expanded(child: pw.Text(cp.title)),
                    ],
                  ),
                )),
            pw.SizedBox(height: 24),

            // Detailed tasks
            pw.Text('All Tasks',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            ...categories.where((c) => c.type == 'kanban').map((cat) {
              final catTasks = activeTasks.where((t) => t.categoryId == cat.id).toList();
              if (catTasks.isEmpty) return pw.SizedBox();

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${cat.icon} ${cat.name}',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ...catTasks.map((task) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 4),
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey200),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.Text(
                                  task.status == 'completed'
                                      ? '✅'
                                      : task.status == 'inProgress'
                                          ? '🔄'
                                          : '📋',
                                ),
                                pw.SizedBox(width: 6),
                                pw.Expanded(
                                  child: pw.Text(task.title,
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 12)),
                                ),
                              ],
                            ),
                            if (task.dueDate != null)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 4),
                                child: pw.Text(
                                  'Due: ${AppUtils.formatDateTime(task.dueDate!)}',
                                  style: const pw.TextStyle(
                                      fontSize: 10, color: PdfColors.grey600),
                                ),
                              ),
                            if (task.links.isNotEmpty)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 4),
                                child: pw.Text(
                                  'Links: ${task.links.map((l) => l.label).join(", ")}',
                                  style: const pw.TextStyle(
                                      fontSize: 10, color: PdfColors.blue),
                                ),
                              ),
                          ],
                        ),
                      )),
                  pw.SizedBox(height: 16),
                ],
              );
            }),
          ],
          footer: (context) => pw.Center(
            child: pw.Text(
              'Generated by Productivity App v3.0',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ),
        ),
      );

      // Print or share the PDF
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Productivity Report - $date',
      );

      debugPrint('✅ PDF exported successfully');
    } catch (e) {
      debugPrint('❌ PDF export error: $e');
      rethrow;
    }
  }

  // ── PDF Helper Widgets ─────────────────────
  static pw.Widget _pdfHeader(String date) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo, width: 3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('Productivity Report',
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo)),
          pw.SizedBox(height: 4),
          pw.Text('Generated on $date',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static pw.Widget _pdfStatBox(String value, String label) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo)),
          pw.SizedBox(height: 4),
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ],
      ),
    );
  }
}