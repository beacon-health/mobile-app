import 'dart:async';

import 'package:beacon_app/core/services/user_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and persists theme mode; read by [MaterialApp.themeMode].
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

  // Light for first-launch / signed-out users; Settings can change it.
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

  /// Set [syncToCloud] false when applying a value that came from the cloud,
  /// to avoid a redundant write back.
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
