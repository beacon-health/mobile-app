import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  static Future<void> launchUrlString(String url, BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final l10n = AppLocalizations.of(context);
    try {
      // Map links must leave the app; anything else may use an in-app view.
      final isMapLink = url.startsWith('http') && url.contains('maps');
      final launched = await launchUrl(
        uri,
        mode: isMapLink
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );
      if (!launched) {
        throw Exception('launchUrl returned false for $uri');
      }
    } catch (e, stack) {
      ErrorReporter.instance.report(e, stack, context: 'UrlLauncherService');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(l10n?.commonLinkFailed ?? 'Could not open that link.'),
          ),
        );
      }
    }
  }
}
