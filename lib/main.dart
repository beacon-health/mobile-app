import 'package:beacon_app/app.dart';
import 'package:beacon_app/core/services/demo_mode_service.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/theme_mode_provider.dart';
import 'package:beacon_app/core/services/user_settings_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DemoModeService().init();
  await LocaleProvider().init();
  await ThemeModeProvider().init();

  if (!DemoModeService().isDemoMode) {
    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
      throw Exception(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
        'Pass them via --dart-define at build/run time.',
      );
    }
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      debug: kDebugMode,
    );
  } else {
    // Demo mode: init Supabase only if compile-time vars are available.
    if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
        debug: kDebugMode,
      );
    }
  }

  await GuestModeService().init();
  await ZipCodeService().init();
  await UserSettingsService.instance.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const BeaconApp());
}
