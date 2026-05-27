import 'package:beacon_app/app.dart';
import 'package:beacon_app/core/services/demo_mode_service.dart';
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
  await EligibilityPreferencesService().init();
  await RecentFacilitiesService().init();
  await UserSettingsService.instance.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Sentry is only initialized when:
  //   1. We're not in debug mode (in debug, `ErrorReporter` uses developer.log
  //      and we don't want every hot-reload exception going to Sentry).
  //   2. A DSN was supplied via --dart-define=SENTRY_DSN=<dsn>.
  // When either condition fails, `Sentry.isEnabled` is false and
  // `ErrorReporter` silently no-ops the release path.
  final shouldEnableSentry = !kDebugMode && _sentryDsn.isNotEmpty;
  if (shouldEnableSentry) {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
        // Reasonable defaults for a free-tier MVP. Tune post-launch.
        options.tracesSampleRate = 0.1;
        options.attachStacktrace = true;
        // Send PII off — we never want user emails/IPs in crash payloads.
        options.sendDefaultPii = false;
      },
      appRunner: () => runApp(const BeaconApp()),
    );
    return;
  }

  runApp(const BeaconApp());
}
