import 'dart:async';

import 'package:beacon_app/core/services/user_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's theme mode (light/dark/system) and persists the choice.
///
/// Provided at the app root. [MaterialApp.themeMode] reads from this provider
/// so that theme changes take effect immediately.
class ThemeModeProvider extends ChangeNotifier {
  static const String _key = 'app_theme_mode';

  static final ThemeModeProvider _instance = ThemeModeProvider._();
  factory ThemeModeProvider() => _instance;
  ThemeModeProvider._();

  /// Display names for theme mode options.
  static const Map<ThemeMode, String> themeModeNames = {
    ThemeMode.system: 'Auto',
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
  };

  // Default to light mode for first-launch / signed-out users. The user can
  // switch to dark or system via Settings; that choice persists in prefs and
  // also syncs to `user_settings.theme_mode` for signed-in users.
  ThemeMode _themeMode = ThemeMode.light;

  /// The currently active theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Loads persisted theme mode from [SharedPreferences].
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_key);
    if (modeIndex != null && modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    }
  }

  /// Changes the app theme mode and persists the choice.
  ///
  /// When [syncToCloud] is true (the default), pushes the change to the
  /// signed-in user's `user_settings` row. Set to false when applying a value
  /// that just came from the cloud to avoid a redundant write.
  Future<void> setThemeMode(ThemeMode mode, {bool syncToCloud = true}) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
    notifyListeners();
    if (syncToCloud) {
      unawaited(UserSettingsService.instance.pushLocal());
    }
  }
}
