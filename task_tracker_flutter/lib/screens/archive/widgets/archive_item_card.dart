// =============================================
// ARCHIVE_ITEM_CARD.DART
// Shows archived task with clickable links
// Tap link to open, long press to copy
// =============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../models/task_model.dart';

class ArchiveItemCard extends StatelessWidget {
  final TaskModel task;
  final String? categoryName;
  final String? categoryIcon;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const ArchiveItemCard({
    super.key,
    required this.task,
    this.categoryName,
    this.categoryIcon,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border(
          left: BorderSide(color: AppTheme.secondary, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Title + Date ──────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ),
              if (task.completedAt != null)
                Text(
                  AppUtils.formatDate(task.completedAt!),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.hintColor(context),
                  ),
                ),
            ],
          ),

          // ── Category ──────────────────────────
          if (categoryName != null) ...[
            const SizedBox(height: 4),
            Text(
              '${categoryIcon ?? "📋"} $categoryName',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.hintColor(context),
              ),
            ),
          ],

          // ── Description ───────────────────────
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.subtextColor(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ── Links (clickable) ─────────────────
          if (task.links.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: task.links.map((link) {
                final detected = AppUtils.detectLinkType(link.url);
                return GestureDetector(
                  onTap: () => _openUrl(context, link.url),
                  onLongPress: () => _copyUrl(context, link.url),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceBg(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          detected['icon']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          link.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.open_in_new,
                          size: 12,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // ── Actions ───────────────────────────
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onRestore,
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('Restore', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.secondary,
                ),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.overdue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Open URL in external browser
  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      // Auto-add https if missing
      String finalUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        finalUrl = 'https://$url';
      }

      final uri = Uri.parse(finalUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open: $url'),
              action: SnackBarAction(
                label: 'Copy',
                onPressed: () => _copyUrl(context, url),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () => _copyUrl(context, url),
            ),
          ),
        );
      }
    }
  }

  /// Copy URL to clipboard
  Future<void> _copyUrl(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Link copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}