// =============================================
// NOTE_ITEM.DART - Fixed for dark mode
// =============================================

import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/note_model.dart';

class NoteItem extends StatelessWidget {
  final NoteModel note;
  final Color accentColor;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const NoteItem({
    super.key,
    required this.note,
    required this.accentColor,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use theme-aware colors
    final cardColor = AppTheme.cardBg(context);
    final titleColor = note.completed
        ? AppTheme.textTertiary
        : AppTheme.textColor(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border(
            left: BorderSide(color: accentColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Checkbox ─────────────────────────
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(right: 12, top: 2),
                decoration: BoxDecoration(
                  color: note.completed
                      ? AppTheme.secondary
                      : Colors.transparent,
                  border: Border.all(
                    color: note.completed
                        ? AppTheme.secondary
                        : AppTheme.borderMedium,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: note.completed
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),

            // ── Content ─────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                      decoration: note.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (note.content != null && note.content!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      note.content!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.subtextColor(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}