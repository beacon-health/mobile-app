import 'dart:io';

import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/theme_mode_provider.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Logical size of an iPhone 13/14 — the common phone size in Sentry data.
const phoneSize = Size(390, 844);

/// Golden images are canonical on Linux (CI's runner): macOS rasterizes
/// glyphs with CoreText and Linux with FreeType, so the same widget differs
/// by a few percent of pixels between them. Elsewhere golden tests skip —
/// which also stops a local `--update-goldens` from writing macOS images.
/// Refresh them from CI with `tool/update_goldens_from_ci.sh`.
final bool goldensSkipped = !Platform.isLinux;

/// Runs a test once per shipping platform. Pointing both runs at the same
/// golden file is what enforces "iOS and Android look the same".
const shippingPlatforms = TargetPlatformVariant(
  {TargetPlatform.android, TargetPlatform.iOS},
);

/// Stubs the plugins that screens touch during their first build.
void mockPlatformServices() {
  SharedPreferences.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'Beacon',
    packageName: 'org.beaconhealth.app',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
}

/// Pumps [child] inside a [MaterialApp] carrying the real app theme,
/// localizations, and the providers screens read, at phone size. Pick the
/// platform with a test `variant` (see [shippingPlatforms]).
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  Size size = phoneSize,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<GuestModeService>.value(
          value: GuestModeService(),
        ),
        ChangeNotifierProvider<ZipCodeService>.value(value: ZipCodeService()),
        ChangeNotifierProvider<LocaleProvider>.value(value: LocaleProvider()),
        ChangeNotifierProvider<ThemeModeProvider>.value(
          value: ThemeModeProvider(),
        ),
        ChangeNotifierProvider<EligibilityPreferencesService>.value(
          value: EligibilityPreferencesService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode:
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        locale: const Locale('en'),
        supportedLocales: LocaleProvider.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Decodes every on-screen [Image] so goldens don't capture them blank.
Future<void> precacheImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}
