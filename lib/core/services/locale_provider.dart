import 'dart:async';
import 'dart:ui';

import 'package:beacon_app/core/services/user_settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the current app locale and persists the user's language choice.
///
/// Provided at the app root. [MaterialApp.locale] reads from this provider
/// so that language changes take effect immediately.
class LocaleProvider extends ChangeNotifier {
  static const String _key = 'app_locale';

  static final LocaleProvider _instance = LocaleProvider._();
  factory LocaleProvider() => _instance;
  LocaleProvider._();

  /// Supported locales in the app.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('zh'),
  ];

  /// Display names for supported locales.
  static const Map<String, String> localeDisplayNames = {
    'en': 'English',
    'es': 'Español',
    'zh': '中文',
  };

  Locale _locale = const Locale('en');

  /// The currently active locale.
  Locale get locale => _locale;

  /// Loads persisted locale from [SharedPreferences].
  ///
  /// Call during app initialization before [runApp].
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      _locale = Locale(code);
    }
  }

  /// Changes the app locale and persists the choice.
  ///
  /// When [syncToCloud] is true (the default), pushes the change to the
  /// signed-in user's `user_settings` row. Set to false when applying a value
  /// that just came from the cloud to avoid a redundant write.
  Future<void> setLocale(Locale locale, {bool syncToCloud = true}) async {
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    notifyListeners();
    if (syncToCloud) {
      unawaited(UserSettingsService.instance.pushLocal());
    }
  }
}
