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

  ThemeMode _themeMode = ThemeMode.system;

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
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
    notifyListeners();
  }
}
