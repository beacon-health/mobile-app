import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  static Future<void> launchUrlString(String url, BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        if (url.startsWith('tel:')) {
          if (!await launchUrl(uri)) {
            throw 'Could not launch $url';
          }
        } else if (url.startsWith('http') && url.contains('maps')) {
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            throw 'Could not launch $url';
          }
        } else if (url.startsWith('http')) {
          if (!await launchUrl(uri)) {
            throw 'Could not launch $url';
          }
        } else {
          if (!await launchUrl(uri)) {
            throw 'Could not launch $url';
          }
        }
      } catch (e) {
        debugPrint('Error launching URL: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch: $uri')),
          );
        }
      }
    }
  }
}
