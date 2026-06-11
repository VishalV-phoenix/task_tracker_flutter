// =============================================
// THEME.DART
// Centralized theme constants and helpers
//
// SAFE DARK MODE FIX:
// - keeps static colors for places that need them
// - adds theme-aware helpers for backgrounds/text
// =============================================

import 'package:flutter/material.dart';

class AppTheme {
  // ── Primary Colors ─────────────────────
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryDark = Color(0xFF059669);

  // ── Urgency Colors ─────────────────────
  static const Color overdue = Color(0xFFEF4444);
  static const Color critical = Color(0xFFF97316);
  static const Color warning = Color(0xFFEAB308);
  static const Color upcoming = Color(0xFF3B82F6);
  static const Color normal = Color(0xFF10B981);

  // ── Static Light Colors (fallback/default) ──
  static const Color bgPrimary = Color(0xFFF8FAFC);
  static const Color bgSecondary = Color(0xFFFFFFFF);
  static const Color bgTertiary = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderMedium = Color(0xFFCBD5E1);

  // ── Border Radius ──────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  // ── Theme-aware helpers ─────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffoldBg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color cardBg(BuildContext context) =>
      Theme.of(context).cardColor;

  static Color surfaceBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF334155) : bgTertiary;

  static Color textColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color subtextColor(BuildContext context) =>
      isDark(context) ? const Color(0xFFCBD5E1) : textSecondary;

  static Color hintColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF94A3B8) : textTertiary;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF475569) : borderLight;

  static Color inputBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF334155) : Colors.white;

  // ── Decorations ─────────────────────────
  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: bgSecondary,
      borderRadius: BorderRadius.circular(radiusLg),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration cardDecorationThemed(BuildContext context, {Color? borderColor}) {
    return BoxDecoration(
      color: cardBg(context),
      borderRadius: BorderRadius.circular(radiusLg),
      boxShadow: [
        BoxShadow(
          color: isDark(context)
              ? Colors.black.withValues(alpha: 0.24)
              : Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: borderColor != null ? Border.all(color: borderColor) : null,
    );
  }

  // ── Color from hex string ──────────────
  static Color colorFromHex(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return primary;
    }
  }

  // ── Urgency helpers ────────────────────
  static Color urgencyColor(String urgency) {
    switch (urgency) {
      case 'overdue':
        return overdue;
      case 'critical':
        return critical;
      case 'warning':
        return warning;
      case 'upcoming':
        return upcoming;
      case 'normal':
        return normal;
      default:
        return textTertiary;
    }
  }

  static Color urgencyBgColor(String urgency) {
    switch (urgency) {
      case 'overdue':
        return const Color(0xFFFEE2E2);
      case 'critical':
        return const Color(0xFFFFEDD5);
      case 'warning':
        return const Color(0xFFFEF9C3);
      case 'upcoming':
        return const Color(0xFFDBEAFE);
      case 'normal':
        return const Color(0xFFD1FAE5);
      default:
        return bgTertiary;
    }
  }
}