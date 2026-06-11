// =============================================
// URL_SERVICE.DART
// Opens URLs in external browser
// Used by link items in tasks and archive
// =============================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlService {
  /// Open a URL in the device's default browser
  /// Returns true if successful
  static Future<bool> open(String url) async {
    try {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return true;
      } else {
        debugPrint('Cannot launch URL: $url');
        return false;
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      return false;
    }
  }

  /// Open a URL and show a snackbar on failure
  static Future<void> openWithFeedback(
    BuildContext context,
    String url,
  ) async {
    final success = await open(url);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open link'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Validate if a string is a valid URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}