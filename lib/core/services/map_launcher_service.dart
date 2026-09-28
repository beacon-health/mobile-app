import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Map apps supported for "Get Directions".
enum MapApp { appleMaps, googleMaps, waze }

extension MapAppInfo on MapApp {
  String get displayName => switch (this) {
        MapApp.appleMaps => 'Apple Maps',
        MapApp.googleMaps => 'Google Maps',
        MapApp.waze => 'Waze',
      };

  /// Scheme probed with `canLaunchUrl` to detect installation. Must be listed
  /// under `LSApplicationQueriesSchemes` in Info.plist.
  String? get probeScheme => switch (this) {
        MapApp.appleMaps => null, // always present on iOS
        MapApp.googleMaps => 'comgooglemaps://',
        MapApp.waze => 'waze://',
      };

  String _storageKey() => name;
}

/// Opens directions in the user's preferred map app. iOS exposes no API for
/// the system default, so the first tap shows a chooser of installed apps and
/// remembers the pick (changeable in Settings → Directions app).
class MapLauncherService {
  MapLauncherService._();

  static const String _prefsKey = 'preferred_map_app_v1';

  /// Returns the remembered map app, or null when the user hasn't chosen yet.
  static Future<MapApp?> preferredApp() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == null) return null;
    for (final app in MapApp.values) {
      if (app._storageKey() == stored) return app;
    }
    return null;
  }

  static Future<void> setPreferredApp(MapApp app) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, app._storageKey());
  }

  /// Forgets the remembered app — the next "Get Directions" tap shows the
  /// chooser again.
  static Future<void> clearPreferredApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Map apps actually installed on this device (Apple Maps always included).
  static Future<List<MapApp>> installedApps() async {
    final apps = <MapApp>[MapApp.appleMaps];
    for (final app in [MapApp.googleMaps, MapApp.waze]) {
      try {
        if (await canLaunchUrl(Uri.parse(app.probeScheme!))) {
          apps.add(app);
        }
      } catch (_) {
        // Scheme not queryable — treat as not installed.
      }
    }
    return apps;
  }

  /// Resolves through: remembered choice (if still installed) → single
  /// installed app → chooser sheet.
  static Future<void> openDirections(
    BuildContext context, {
    required String address,
  }) async {
    try {
      final installed = await installedApps();

      var app = await preferredApp();
      if (app != null && !installed.contains(app)) {
        app = null; // Previously chosen app was uninstalled.
      }

      if (app == null && installed.length == 1) {
        app = installed.single;
      }

      if (app == null) {
        if (!context.mounted) return;
        app = await _showChooser(context, installed);
        if (app == null) return; // dismissed
        await setPreferredApp(app);
      }

      await _launch(app, address);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'MapLauncherService.openDirections',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.directionsOpenFailed ??
                  "Couldn't open directions.",
            ),
          ),
        );
      }
    }
  }

  static Future<void> _launch(MapApp app, String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = switch (app) {
      MapApp.appleMaps => Uri.parse('https://maps.apple.com/?daddr=$encoded'),
      MapApp.googleMaps =>
        Uri.parse('comgooglemaps://?daddr=$encoded&directionsmode=driving'),
      MapApp.waze => Uri.parse('waze://?q=$encoded&navigate=yes'),
    };
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch ${app.displayName}');
    }
  }

  static Future<MapApp?> _showChooser(
    BuildContext context,
    List<MapApp> installed,
  ) {
    final theme = Theme.of(context);
    return showModalBottomSheet<MapApp>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sheetGutter,
              ),
              child: Text(
                AppLocalizations.of(context)?.directionsOpenWith ??
                    'Open directions with',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final app in installed)
              ListTile(
                leading: const Icon(Icons.directions_outlined),
                title: Text(app.displayName),
                onTap: () => Navigator.pop(ctx, app),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sheetGutter,
                0,
                AppSpacing.sheetGutter,
                AppSpacing.sm,
              ),
              child: Text(
                AppLocalizations.of(context)?.directionsChangeLater ??
                    'You can change this later in Settings.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
