/// =============================================
/// UTILS.DART
/// Shared helper functions used across the app
/// Equivalent to Utils object in JavaScript
/// =============================================

import 'package:intl/intl.dart';
import 'constants.dart';

class AppUtils {
  /// Generate unique ID with prefix
  /// Same as Utils.generateId() in JavaScript
  static String generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode.toRadixString(36);
    return '${prefix}_${timestamp}_$random';
  }

  /// Format date: Mon, Dec 25
  static String formatDate(DateTime date) {
    return DateFormat('E, MMM d').format(date);
  }

  /// Format date with time: Dec 25, 2024, 02:30 PM
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, y, hh:mm a').format(date);
  }

  /// Format date long: December 25, 2024
  static String formatDateLong(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  /// Format time only: 02:30 PM
  static String formatTime12(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  /// Calculate progress percentage safely
  /// Returns 0-100 integer
  static int calculateProgress(int completed, int total) {
    if (total == 0) return 0;
    return ((completed / total) * 100).round();
  }

  /// Get human-readable status label
  static String getStatusLabel(String status) {
    switch (status) {
      case AppConstants.statusTodo:
        return 'To Do';
      case AppConstants.statusInProgress:
        return 'In Progress';
      case AppConstants.statusCompleted:
        return 'Completed';
      default:
        return status;
    }
  }

  /// Determine urgency level from due date
  /// Returns: overdue, critical, warning, upcoming, normal, none
  static String getUrgency(DateTime? dueDate) {
    if (dueDate == null) return AppConstants.urgencyNoneType;

    final now = DateTime.now();
    final hoursLeft = dueDate.difference(now).inMinutes / 60.0;

    if (hoursLeft < 0) return AppConstants.urgencyOverdueType;
    if (hoursLeft < 6) return AppConstants.urgencyCriticalType;
    if (hoursLeft < 24) return AppConstants.urgencyWarningType;
    if (hoursLeft < 72) return AppConstants.urgencyUpcomingType;
    return AppConstants.urgencyNormalType;
  }

  /// Get human-readable urgency text
  static String getUrgencyText(DateTime? dueDate) {
    if (dueDate == null) return '';

    final now = DateTime.now();
    final diff = dueDate.difference(now);
    final hoursLeft = diff.inMinutes / 60.0;

    if (hoursLeft < 0) {
      final overdue = hoursLeft.abs();
      if (overdue < 24) return 'Overdue by ${overdue.floor()}h';
      return 'Overdue by ${(overdue / 24).floor()}d';
    }
    if (hoursLeft < 1) return 'Due in ${diff.inMinutes}min';
    if (hoursLeft < 24) return 'Due in ${hoursLeft.floor()}h';
    if (hoursLeft < 48) return 'Due tomorrow';
    return 'Due in ${(hoursLeft / 24).floor()}d';
  }

  /// Get urgency icon emoji
  static String getUrgencyIcon(String urgency) {
    switch (urgency) {
      case AppConstants.urgencyOverdueType:
        return '🔴';
      case AppConstants.urgencyCriticalType:
        return '🟠';
      case AppConstants.urgencyWarningType:
        return '🟡';
      case AppConstants.urgencyUpcomingType:
        return '🔵';
      case AppConstants.urgencyNormalType:
        return '🟢';
      default:
        return '';
    }
  }

  /// Auto-detect link type from URL
  /// Returns map with 'type' and 'icon'
  static Map<String, String> detectLinkType(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      if (host.contains('youtube') || host.contains('youtu.be')) {
        return {'type': 'video', 'icon': '📺'};
      }
      if (host.contains('github')) return {'type': 'github', 'icon': '💻'};
      if (host.contains('drive.google')) return {'type': 'drive', 'icon': '📁'};
      if (host.contains('docs.google')) return {'type': 'docs', 'icon': '📄'};
      if (host.contains('sheets.google')) return {'type': 'sheets', 'icon': '📊'};
      if (host.contains('figma')) return {'type': 'figma', 'icon': '🎨'};
      if (host.contains('notion')) return {'type': 'notion', 'icon': '📓'};
      if (host.contains('stackoverflow')) return {'type': 'stackoverflow', 'icon': '🔍'};
      if (host.contains('medium')) return {'type': 'article', 'icon': '📰'};
      if (host.contains('coursera') || host.contains('udemy')) {
        return {'type': 'course', 'icon': '🎓'};
      }
      if (host.contains('wikipedia')) return {'type': 'wiki', 'icon': '📚'};
      if (host.contains('twitter') || host.contains('x.com')) {
        return {'type': 'twitter', 'icon': '🐦'};
      }
      if (host.contains('linkedin')) return {'type': 'linkedin', 'icon': '💼'};

      return {'type': 'link', 'icon': '🔗'};
    } catch (e) {
      return {'type': 'link', 'icon': '🔗'};
    }
  }

  /// Parse hex color string to Color
  /// Handles formats: #4F46E5, 4F46E5, 0xFF4F46E5
  static int parseColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return int.parse(hex, radix: 16);
    } catch (e) {
      return 0xFF4F46E5; // Default purple
    }
  }
}