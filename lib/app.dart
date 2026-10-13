import 'package:beacon_app/core/constants/app_routes.dart';
import 'package:beacon_app/core/services/accessibility_settings.dart';
import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:beacon_app/core/services/theme_mode_provider.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/features/ask/data/assistant_service.dart';
import 'package:beacon_app/features/auth/presentation/pages/login_page.dart';
import 'package:beacon_app/features/auth/presentation/widgets/auth_gate.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:beacon_app/features/map/data/facility_repository.dart';
import 'package:beacon_app/features/map/presentation/providers/facility_provider.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

class BeaconApp extends StatelessWidget {
  const BeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // The one place the real repository is built. Home and Map read it
        // from here, which is also what lets tests hand them a fake.
        Provider<FacilityRepositoryBase>(create: (_) => FacilityRepository()),
        ChangeNotifierProvider<FacilityProvider>(
          create: (context) => FacilityProvider(
            repository: context.read<FacilityRepositoryBase>(),
          ),
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
        ChangeNotifierProvider<AccessibilitySettings>.value(
          value: AccessibilitySettings(),
        ),
        ChangeNotifierProvider<AssistantService>.value(
          value: AssistantService(),
        ),
      ],
      child: Consumer2<LocaleProvider, ThemeModeProvider>(
        builder: (context, localeProvider, themeModeProvider, _) {
          return MaterialApp(
            title: 'Beacon',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            // Picked by MaterialApp when the OS asks for more contrast.
            highContrastTheme: AppTheme.highContrastLightTheme,
            highContrastDarkTheme: AppTheme.highContrastDarkTheme,
            themeMode: themeModeProvider.themeMode,
            locale: localeProvider.locale,
            supportedLocales: LocaleProvider.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Status/nav-bar icons follow the in-app theme (which can differ
            // from the OS setting) on both platforms, including screens
            // without an AppBar. The theme itself is fitted to the reader
            // here, where the language and the OS's Bold Text setting are
            // known.
            builder: (context, child) => Theme(
              data: AppTheme.adapted(
                Theme.of(context),
                locale: Localizations.localeOf(context),
                boldText: MediaQuery.boldTextOf(context),
              ),
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: AppTheme.systemOverlayStyleFor(
                  Theme.of(context).brightness,
                ),
                child: child!,
              ),
            ),
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
