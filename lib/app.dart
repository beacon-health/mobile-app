import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/core/constants/app_routes.dart';
import 'package:beacon_app/core/services/demo_mode_service.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/theme_mode_provider.dart';
import 'package:beacon_app/features/auth/presentation/pages/login_page.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:beacon_app/features/auth/presentation/pages/criteria_page.dart';
import 'package:beacon_app/features/auth/presentation/widgets/auth_gate.dart';
import 'package:beacon_app/features/map/presentation/providers/facility_provider.dart';

class BeaconApp extends StatelessWidget {
  const BeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FacilityProvider>(
          create: (_) => FacilityProvider(),
        ),
        ChangeNotifierProvider<DemoModeService>.value(
          value: DemoModeService(),
        ),
        ChangeNotifierProvider<LocaleProvider>.value(
          value: LocaleProvider(),
        ),
        ChangeNotifierProvider<ThemeModeProvider>.value(
          value: ThemeModeProvider(),
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
              AppRoutes.criteria: (context) => const CriteriaPage(),
              AppRoutes.main: (context) => const MainNavBar(),
            },
          );
        },
      ),
    );
  }
}
