/// =============================================
/// CONSTANTS.DART
/// App-wide constant values
/// Equivalent to CSS variables and JS constants
/// =============================================

import 'package:flutter/material.dart';

class AppConstants {
  // ── App Info ─────────────────────────────
  static const String appName = 'Productivity';
  static const String appVersion = '3.0.0';
  static const String defaultGoal = 'Bioinformatics';

  // ── Database ────────────────────────────
  static const String dbName = 'productivity_app.db';
  static const int dbVersion = 1;

  // ── Default Settings ────────────────────
  static const double defaultNotifyBefore = 3.0; // hours
  static const int defaultArchiveDays = 7;

  // ── Task Statuses ───────────────────────
  static const String statusTodo = 'todo';
  static const String statusInProgress = 'inProgress';
  static const String statusCompleted = 'completed';

  // ── Category Types ──────────────────────
  static const String typeKanban = 'kanban';
  static const String typeNotes = 'notes';

  // ── Link Limit ──────────────────────────
  static const int maxLinksPerTask = 10;

  // ── Colors ──────────────────────────────
  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color secondaryColor = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentCyan = Color(0xFF06B6D4);

  // ── Urgency Colors ──────────────────────
  static const Color urgencyOverdue = Color(0xFFEF4444);
  static const Color urgencyCritical = Color(0xFFF97316);
  static const Color urgencyWarning = Color(0xFFEAB308);
  static const Color urgencyUpcoming = Color(0xFF3B82F6);
  static const Color urgencyNormal = Color(0xFF10B981);
  static const Color urgencyNone = Color(0xFF94A3B8);

  // ── Urgency Types ───────────────────────
  static const String urgencyOverdueType = 'overdue';
  static const String urgencyCriticalType = 'critical';
  static const String urgencyWarningType = 'warning';
  static const String urgencyUpcomingType = 'upcoming';
  static const String urgencyNormalType = 'normal';
  static const String urgencyNoneType = 'none';

  static const String typeChecklist =
      'notes'; // Internal value stays 'notes' for DB compatibility
  static const String typeChecklistLabel = 'Checklist'; // Display label
}
