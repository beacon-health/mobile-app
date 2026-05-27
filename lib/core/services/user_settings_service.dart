import 'dart:async';

import 'package:beacon_app/core/services/demo_mode_service.dart';
import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/theme_mode_provider.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bridges local user preferences (ZIP, theme, locale, location-search opt-in)
/// with the Supabase `user_settings` row for the signed-in user.
///
/// Listens to Supabase auth state changes:
///  - On `signedIn`: fetches the user's row and applies it to local providers,
///    or inserts a row using current local values if none exists.
///  - On `signedOut`: stops syncing; local providers retain their last values.
///
/// Once a user is signed in, [pushLocal] should be called after any local
/// settings change so the row stays in sync.
class UserSettingsService {
  UserSettingsService._();
  static final UserSettingsService instance = UserSettingsService._();

  static const String _table = 'user_settings';
  static const String _logContext = 'UserSettingsService';

  StreamSubscription<AuthState>? _authSubscription;

  /// Starts listening to auth state changes. Idempotent.
  Future<void> init() async {
    if (DemoModeService().isDemoMode) return;
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser != null) {
        await syncOnSignIn();
      }
      _authSubscription?.cancel();
      _authSubscription = client.auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.initialSession ||
            state.event == AuthChangeEvent.userUpdated) {
          unawaited(syncOnSignIn());
        }
      });
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(e, stackTrace, context: '$_logContext.init');
    }
  }

  /// Loads the signed-in user's settings (if any) and applies them locally.
  /// If no row exists, inserts one with the current local values.
  Future<void> syncOnSignIn() async {
    final userId = _currentUserId();
    if (userId == null) return;

    try {
      final client = Supabase.instance.client;
      final row = await client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) {
        await _insertCurrent(userId);
        return;
      }

      await _applyToLocal(row);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: '$_logContext.syncOnSignIn',
      );
    }
  }

  /// Pushes the current local provider values to Supabase via upsert.
  ///
  /// No-op if the user is not signed in.
  Future<void> pushLocal() async {
    final userId = _currentUserId();
    if (userId == null) return;
    try {
      await Supabase.instance.client.from(_table).upsert(
        _payload(userId),
        onConflict: 'user_id',
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: '$_logContext.pushLocal',
      );
    }
  }

  Future<void> _insertCurrent(String userId) async {
    try {
      await Supabase.instance.client
          .from(_table)
          .insert(_payload(userId, includeCreatedAt: true));
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: '$_logContext._insertCurrent',
      );
    }
  }

  Future<void> _applyToLocal(Map<String, dynamic> row) async {
    final zip = row['zip_code'] as String?;
    final themeMode = row['theme_mode'] as String?;
    final locale = row['locale'] as String?;
    final locationSearchEnabled = row['location_search_enabled'] as bool?;
    final eligibilityJson = row['eligibility'];
    final preferencesJson = row['preferences'];

    // Lat/lng are no longer stored in the cloud — we re-derive them locally
    // by geocoding the ZIP on apply. This keeps the cloud row free of
    // device-derived coordinates and avoids stale coords if a user moves.
    if (zip != null && zip.isNotEmpty) {
      // `setZipCode` performs geocoding + persistence. It calls
      // notifyListeners() and (when syncToCloud is true) re-uploads.
      // We don't want that uploadback here.
      final ok = await ZipCodeService().setZipCode(zip, syncToCloud: false);
      if (!ok) {
        ErrorReporter.instance.report(
          Exception('Could not geocode cloud-stored ZIP: $zip'),
          StackTrace.current,
          context: '$_logContext._applyToLocal',
        );
      }
    }
    if (locationSearchEnabled != null) {
      await ZipCodeService()
          .setLocationSearchEnabled(locationSearchEnabled, syncToCloud: false);
    }
    if (themeMode != null) {
      final mode = _parseThemeMode(themeMode);
      if (mode != null) {
        await ThemeModeProvider().setThemeMode(mode, syncToCloud: false);
      }
    }
    if (locale != null && locale.isNotEmpty) {
      await LocaleProvider().setLocale(Locale(locale), syncToCloud: false);
    }
    await EligibilityPreferencesService().applyFromCloud(
      eligibility: eligibilityJson is Map<String, dynamic>
          ? EligibilityState.fromJson(eligibilityJson)
          : null,
      preferences: preferencesJson is Map<String, dynamic>
          ? PreferencesState.fromJson(preferencesJson)
          : null,
    );
  }

  Map<String, dynamic> _payload(
    String userId, {
    bool includeCreatedAt = false,
  }) {
    final zip = ZipCodeService();
    final ep = EligibilityPreferencesService();
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'user_id': userId,
      'zip_code': zip.zipCode,
      'theme_mode': _themeModeName(ThemeModeProvider().themeMode),
      'locale': LocaleProvider().locale.languageCode,
      'location_search_enabled': zip.locationSearchEnabled,
      'eligibility': ep.eligibility.toJson(),
      'preferences': ep.preferences.toJson(),
      'updated_at': now,
      if (includeCreatedAt) 'created_at': now,
    };
  }

  String? _currentUserId() {
    if (DemoModeService().isDemoMode) return null;
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  static String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode? _parseThemeMode(String raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
    }
    return null;
  }

  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
  }
}
