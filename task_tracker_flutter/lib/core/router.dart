// =============================================
// ROUTER.DART
// Navigation helper for screen transitions
// Provides smooth page transitions
// =============================================

import 'package:flutter/material.dart';

class AppRouter {
  // ── Push screen with slide animation ──────
  static void push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // ── Push and replace current screen ───────
  static void pushReplacement(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // ── Go back ───────────────────────────────
  static void pop(BuildContext context) {
    Navigator.of(context).pop();
  }

  // ── Show modal bottom sheet ───────────────
  static Future<T?> showBottomSheet<T>(
    BuildContext context,
    Widget child, {
    bool isDismissible = true,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: child,
      ),
    );
  }

  // ── Show dialog ───────────────────────────
  static Future<T?> showAppDialog<T>(
    BuildContext context,
    Widget dialog,
  ) {
    return showDialog<T>(
      context: context,
      builder: (_) => dialog,
    );
  }
}