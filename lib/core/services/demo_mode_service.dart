import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton service that manages the demo mode feature flag.
///
/// Persists demo mode state to [SharedPreferences] so it survives
/// app restarts. Provided at the app root via [ChangeNotifierProvider].
class DemoModeService extends ChangeNotifier {
  static const String _key = 'demo_mode_enabled';

  static final DemoModeService _instance = DemoModeService._();
  factory DemoModeService() => _instance;
  DemoModeService._();

  bool _isDemoMode = false;

  /// Whether demo mode is currently active.
  bool get isDemoMode => _isDemoMode;

  /// Loads persisted demo mode state from [SharedPreferences].
  ///
  /// Call this once during app initialization before [runApp].
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDemoMode = prefs.getBool(_key) ?? false;
  }

  /// Sets demo mode on or off and persists the choice.
  Future<void> setDemoMode(bool value) async {
    if (_isDemoMode == value) return;
    _isDemoMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    notifyListeners();
  }
}
