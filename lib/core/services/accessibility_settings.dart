import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Beacon's own accessibility choices (Settings → Accessibility). They
/// describe how one person uses one phone, so they stay on the device.
///
/// What the OS already knows — text size, bold text, contrast, reduced
/// motion — is read from `MediaQuery`, not stored here.
class AccessibilitySettings extends ChangeNotifier {
  factory AccessibilitySettings() => _instance;
  AccessibilitySettings._();
  static final AccessibilitySettings _instance = AccessibilitySettings._();

  static const _keyMapAsList = 'a11y.map_as_list';
  static const _keyLargerPins = 'a11y.larger_pins';

  /// How much bigger pins and their names draw with [largerMapPins] on —
  /// enough to bring a pin's name up to the app's smallest text size.
  static const double largerPinScale = 1.4;

  bool _openMapAsList = false;
  bool _largerMapPins = false;

  /// Open the Map tab with the results list raised over the map: the list is
  /// the part a screen reader can read.
  bool get openMapAsList => _openMapAsList;

  bool get largerMapPins => _largerMapPins;

  /// The factor pins are drawn at.
  double get pinScale => _largerMapPins ? largerPinScale : 1;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _openMapAsList = prefs.getBool(_keyMapAsList) ?? false;
    _largerMapPins = prefs.getBool(_keyLargerPins) ?? false;
    notifyListeners();
  }

  Future<void> setOpenMapAsList(bool value) async {
    if (_openMapAsList == value) return;
    _openMapAsList = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMapAsList, value);
  }

  Future<void> setLargerMapPins(bool value) async {
    if (_largerMapPins == value) return;
    _largerMapPins = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLargerPins, value);
  }
}
