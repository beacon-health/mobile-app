import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
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

  String _storageKey() => name;
}

/// Opens directions in the user's preferred map app. Neither platform lets an
/// app read the system default, so the first tap shows a chooser of installed
/// apps and remembers the pick (changeable in Settings → Directions app).
///
/// Which apps exist, how each is detected, and what URL each takes all differ
/// by platform. Those rules live in [appsFor], [probeUri], and
/// [directionsUri], which take the platform as an argument so they can be
/// tested for both.
class MapLauncherService {
  MapLauncherService._();

  static const String _prefsKey = 'preferred_map_app_v1';

  /// Map apps offered on [platform], in menu order. Apple Maps is iOS-only;
  /// platforms the app doesn't ship to get none.
  static List<MapApp> appsFor(TargetPlatform platform) => switch (platform) {
        TargetPlatform.iOS => const [
            MapApp.appleMaps,
            MapApp.googleMaps,
            MapApp.waze,
          ],
        TargetPlatform.android => const [MapApp.googleMaps, MapApp.waze],
        TargetPlatform.fuchsia ||
        TargetPlatform.linux ||
        TargetPlatform.macOS ||
        TargetPlatform.windows =>
          const [],
      };

  /// URL handed to `canLaunchUrl` to detect [app], or null when the app ships
  /// with the OS. iOS schemes must be listed under
  /// `LSApplicationQueriesSchemes` in Info.plist, Android ones under
  /// `<queries>` in AndroidManifest.xml; unlisted schemes always report "not
  /// installed".
  static Uri? probeUri(MapApp app, TargetPlatform platform) {
    final isAndroid = platform == TargetPlatform.android;
    return switch (app) {
      MapApp.appleMaps => null,
      MapApp.googleMaps =>
        Uri.parse(isAndroid ? 'google.navigation:q=0,0' : 'comgooglemaps://'),
      MapApp.waze => Uri.parse('waze://'),
    };
  }

  /// The URL that opens directions to [address] in [app].
  static Uri directionsUri(
    MapApp app,
    String address,
    TargetPlatform platform,
  ) {
    final encoded = Uri.encodeComponent(address);
    return switch (app) {
      MapApp.appleMaps => Uri.parse('https://maps.apple.com/?daddr=$encoded'),
      // Android's Google Maps has no comgooglemaps scheme; its universal link
      // opens the app with the route laid out and the travel mode unchosen.
      MapApp.googleMaps => platform == TargetPlatform.android
          ? _googleMapsWebDirections(encoded)
          : Uri.parse('comgooglemaps://?daddr=$encoded&directionsmode=driving'),
      MapApp.waze => Uri.parse('waze://?q=$encoded&navigate=yes'),
    };
  }

  /// Tried in order when no known map app is installed: any app that handles
  /// `geo:` links, then Google Maps in the browser.
  static List<Uri> fallbackUris(String address) {
    final encoded = Uri.encodeComponent(address);
    return [
      Uri.parse('geo:0,0?q=$encoded'),
      _googleMapsWebDirections(encoded),
    ];
  }

  static Uri _googleMapsWebDirections(String encodedAddress) => Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress',
      );

  static Future<MapApp?> _storedApp() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == null) return null;
    for (final app in MapApp.values) {
      if (app._storageKey() == stored) return app;
    }
    return null;
  }

  /// The remembered map app, or null when the user hasn't chosen yet or the
  /// choice is no longer installed (or was never real on this platform).
  static Future<MapApp?> preferredApp() async {
    final stored = await _storedApp();
    if (stored == null) return null;
    final installed = await installedApps();
    return installed.contains(stored) ? stored : null;
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

  /// Map apps actually installed on this device, in menu order.
  static Future<List<MapApp>> installedApps() async {
    final platform = defaultTargetPlatform;
    final apps = <MapApp>[];
    for (final app in appsFor(platform)) {
      final probe = probeUri(app, platform);
      if (probe == null) {
        apps.add(app);
        continue;
      }
      try {
        if (await canLaunchUrl(probe)) apps.add(app);
      } catch (_) {
        // Scheme not queryable — treat as not installed.
      }
    }
    return apps;
  }

  /// Resolves through: remembered choice (if still installed) → single
  /// installed app → chooser sheet. With no known app installed, hands the
  /// address to whatever the device has.
  static Future<void> openDirections(
    BuildContext context, {
    required String address,
  }) async {
    try {
      final installed = await installedApps();
      if (installed.isEmpty) {
        await _launchFallback(address);
        return;
      }

      var app = await _storedApp();
      if (app != null && !installed.contains(app)) app = null;

      if (app == null && installed.length == 1) {
        app = installed.single;
      }

      if (app == null) {
        if (!context.mounted) return;
        app = await _showChooser(context, installed);
        if (app == null) return; // dismissed
        await setPreferredApp(app);
      }

      final uri = directionsUri(app, address, defaultTargetPlatform);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch ${app.displayName}');
      }
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

  static Future<void> _launchFallback(String address) async {
    for (final uri in fallbackUris(address)) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {
        // Nothing handles this link; try the next one.
      }
    }
    throw Exception('No app could open directions');
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
