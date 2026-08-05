import 'package:beacon_app/app.dart';
import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:beacon_app/core/services/theme_mode_provider.dart';
import 'package:beacon_app/core/services/user_settings_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocaleProvider().init();
  await ThemeModeProvider().init();

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

  await GuestModeService().init();
  await ZipCodeService().init();
  await EligibilityPreferencesService().init();
  await RecentFacilitiesService().init();
  await UserSettingsService.instance.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Debug skips Sentry so hot-reload exceptions don't burn the free-tier
  // quota; ErrorReporter no-ops its release path when disabled.
  final shouldEnableSentry = !kDebugMode && _sentryDsn.isNotEmpty;
  if (shouldEnableSentry) {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
        options.tracesSampleRate = 0.1;
        options.attachStacktrace = true;
        // Never let user emails/IPs into crash payloads.
        options.sendDefaultPii = false;
      },
      appRunner: () => runApp(const BeaconApp()),
    );
    return;
  }

  runApp(const BeaconApp());
}
