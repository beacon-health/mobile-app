import 'package:beacon_app/core/constants/app_routes.dart';
import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:beacon_app/core/services/theme_mode_provider.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/features/auth/presentation/pages/login_page.dart';
import 'package:beacon_app/features/auth/presentation/widgets/auth_gate.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:beacon_app/features/map/presentation/providers/facility_provider.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

class BeaconApp extends StatelessWidget {
  const BeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FacilityProvider>(
          create: (_) => FacilityProvider(),
        ),
        ChangeNotifierProvider<GuestModeService>.value(
          value: GuestModeService(),
        ),
        ChangeNotifierProvider<ZipCodeService>.value(
          value: ZipCodeService(),
        ),
        ChangeNotifierProvider<LocaleProvider>.value(
          value: LocaleProvider(),
        ),
        ChangeNotifierProvider<ThemeModeProvider>.value(
          value: ThemeModeProvider(),
        ),
        ChangeNotifierProvider<RecentFacilitiesService>.value(
          value: RecentFacilitiesService(),
        ),
        ChangeNotifierProvider<EligibilityPreferencesService>.value(
          value: EligibilityPreferencesService(),
        ),
      ],
      child: Consumer2<LocaleProvider, ThemeModeProvider>(
        builder: (context, localeProvider, themeModeProvider, _) {
          return MaterialApp(
            title: 'Beacon',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeModeProvider.themeMode,
            locale: localeProvider.locale,
            supportedLocales: LocaleProvider.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AuthGate(),
            routes: {
              AppRoutes.login: (context) => const LoginPage(),
              AppRoutes.main: (context) => const MainNavBar(),
            },
          );
        },
      ),
    );
  }
}
