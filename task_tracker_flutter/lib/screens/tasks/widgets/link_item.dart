// =============================================
// LINK_ITEM.DART
// Shows a link row in task detail form
// Tap the entire row to open the link
// Delete button to remove
// Long press to copy URL
// =============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../models/task_model.dart';

class LinkItem extends StatelessWidget {
  final TaskLinkModel link;
  final VoidCallback onDelete;
  final bool readOnly;

  const LinkItem({
    super.key,
    required this.link,
    required this.onDelete,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final detected = AppUtils.detectLinkType(link.url);

    return GestureDetector(
      // Tap anywhere on the link row to open it
      onTap: () => _openUrl(context, link.url),
      // Long press to copy URL
      onLongPress: () => _copyUrl(context, link.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Row(
          children: [
            // ── Icon ────────────────────────────
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBg(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  detected['icon']!,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // ── Label + URL ─────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    link.url,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Open Button (explicit) ──────────
            IconButton(
              onPressed: () => _openUrl(context, link.url),
              icon: const Icon(
                Icons.open_in_new,
                size: 20,
                color: AppTheme.primary,
              ),
              tooltip: 'Open link',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),

            // ── Delete Button (not in read-only) ──
            if (!readOnly)
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppTheme.hintColor(context),
                ),
                tooltip: 'Remove link',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Open URL in external browser
  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      // Make sure URL has a scheme
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