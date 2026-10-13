import 'dart:async';

import 'package:beacon_app/core/services/accessibility_settings.dart';
import 'package:beacon_app/core/services/coverage_service.dart';
import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:beacon_app/core/services/theme_mode_provider.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/features/ask/data/assistant_service.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:beacon_app/features/map/data/facility_repository.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/providers/facility_provider.dart';
import 'package:beacon_app/features/map/presentation/widgets/markers/marker_icon_factory.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'fake_google_maps.dart';
import 'pump_app.dart';

/// The Chicago Loop — where the app's tests "live".
const chicago = LatLng(41.8781, -87.6298);

/// A facility source for tests. Answers every proximity query with
/// [facilities] and records what was asked.
class FakeFacilityRepository implements FacilityRepositoryBase {
  FakeFacilityRepository([List<Facility>? facilities])
      : facilities = facilities ?? [];

  /// What the next query returns. Reassign to change the "database".
  List<Facility> facilities;

  /// Center of each proximity query, oldest first.
  final List<LatLng> queries = [];

  /// While set, queries wait on it — for holding the app in its loading
  /// state.
  Completer<void>? gate;

  @override
  Future<List<Facility>> loadFacilitiesWithDistance({
    required double latitude,
    required double longitude,
    required double radiusMiles,
  }) async {
    queries.add(LatLng(latitude, longitude));
    await gate?.future;
    return List.of(facilities);
  }

  @override
  Future<List<Facility>> loadFacilitiesNearLocation({
    required double latitude,
    required double longitude,
    double radiusInKm = 50.0,
  }) =>
      loadFacilitiesWithDistance(
        latitude: latitude,
        longitude: longitude,
        radiusMiles: radiusInKm / 1.60934,
      );

  @override
  Future<List<Facility>> loadFacilities() async => List.of(facilities);

  @override
  Stream<List<Facility>> getFacilitiesStream() =>
      Stream.value(List.of(facilities));

  @override
  Future<List<Facility>> searchFacilities(
    String query, {
    double? latitude,
    double? longitude,
    double? radiusMiles,
  }) async =>
      [
        for (final f in facilities)
          if (f.name.toLowerCase().contains(query.toLowerCase())) f,
      ];

  @override
  Future<List<Facility>> getFacilitiesByIds(List<String> ids) async => [
        for (final f in facilities)
          if (ids.contains(f.id)) f,
      ];

  @override
  Future<Facility?> getFacilityById(String id) async =>
      facilities.where((f) => f.id == id).firstOrNull;
}

/// What the platform was told while a test ran.
class PlatformLog {
  /// Times the app asked the OS to close it (`SystemNavigator.pop`) — what a
  /// back press does when nothing in the app takes it.
  int exits = 0;

  /// The latest answer to "will Flutter handle the back button?", which is
  /// how Android's predictive back decides between the app and the launcher.
  bool? frameworkHandlesBack;

  /// Every URL handed to the OS to open, oldest first.
  final List<String> launchedUrls = [];

  /// Schemes the OS "fails" to open, for testing fallbacks.
  final Set<String> unlaunchableSchemes = {};
}

/// A signed-in user for tests, as Supabase would describe one.
User testUser({String provider = 'google', String? email, String? name}) =>
    User(
      id: 'user-1',
      appMetadata: {'provider': provider},
      userMetadata: {if (name != null) 'name': name},
      aud: 'authenticated',
      email: email,
      createdAt: '2026-01-01T00:00:00Z',
    );

const _geolocator = MethodChannel('flutter.baseflow.com/geolocator');
const _urlLauncher = MethodChannel('plugins.flutter.io/url_launcher');

/// Puts every singleton the shell reads back to a known state: a guest who
/// finished onboarding with a Chicago ZIP, light theme, English, Illinois
/// live, location permission denied, no map apps installed.
Future<PlatformLog> resetAppState(
  WidgetTester tester, {
  LocationPermission locationPermission = LocationPermission.denied,
  Set<String> installedUrlSchemes = const {},
}) async {
  mockPlatformServices();
  GuestModeService().debugUser = null;
  CoverageService().debugReset();
  CoverageService().debugSetStates(['IL']);
  await EligibilityPreferencesService().clear();
  // A phone with no language model, so no Ask tab, unless a test gives it
  // one (see `useAssistant`).
  AssistantService()
    ..debugReset()
    ..debugNoModel = true;
  await AssistantService().refresh();
  await AccessibilitySettings().setOpenMapAsList(false);
  await AccessibilitySettings().setLargerMapPins(false);
  RecentFacilitiesService().clear();
  final zip = ZipCodeService();
  await zip.clear();
  await zip.setZipAndLocation(
    '60601',
    chicago.latitude,
    chicago.longitude,
    syncToCloud: false,
  );

  // The framework only reports its back-button intent to a running app.
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

  final log = PlatformLog();
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger
    ..setMockMethodCallHandler(_geolocator, (call) async {
      return switch (call.method) {
        'checkPermission' || 'requestPermission' => locationPermission.index,
        'isLocationServiceEnabled' => true,
        'getCurrentPosition' => {'latitude': 41.9, 'longitude': -87.65},
        _ => null,
      };
    })
    ..setMockMethodCallHandler(_urlLauncher, (call) async {
      final url = (call.arguments as Map<Object?, Object?>?)?['url'];
      switch (call.method) {
        case 'canLaunch':
          return url is String &&
              installedUrlSchemes.contains(Uri.parse(url).scheme);
        case 'launch':
          final launched = url! as String;
          log.launchedUrls.add(launched);
          return !log.unlaunchableSchemes.contains(Uri.parse(launched).scheme);
        default:
          return null;
      }
    })
    ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'SystemNavigator.pop':
          log.exits++;
        case 'SystemNavigator.setFrameworkHandlesBack':
          log.frameworkHandlesBack = call.arguments as bool;
      }
      return null;
    });
  addTearDown(() {
    messenger
      ..setMockMethodCallHandler(_geolocator, null)
      ..setMockMethodCallHandler(_urlLauncher, null)
      ..setMockMethodCallHandler(SystemChannels.platform, null);
    GuestModeService().debugUser = null;
    CoverageService().debugReset();
  });
  return log;
}

/// Makes [point] the user's saved location, as if they had entered a ZIP
/// there.
Future<void> saveLocation(LatLng point, {String zip = '60601'}) =>
    ZipCodeService().setZipAndLocation(
      zip,
      point.latitude,
      point.longitude,
      syncToCloud: false,
    );

/// Pumps the real tab shell — Home, Map, Profile, Settings — over a
/// [FakeGoogleMaps] and [repository], and waits for both maps to load.
///
/// Pass a single page as [home] to test it signed in: the Profile tab reads
/// the Supabase session directly, so the whole shell can only run as a guest.
Future<FakeGoogleMaps> pumpAppShell(
  WidgetTester tester, {
  required FakeFacilityRepository repository,
  Size size = phoneSize,
  Widget home = const MainNavBar(),
  Locale locale = const Locale('en'),
}) async {
  final maps = FakeGoogleMaps.install();
  MarkerUtils.debugDescriptorOverride = BitmapDescriptor.defaultMarker;
  addTearDown(() => MarkerUtils.debugDescriptorOverride = null);

  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<FacilityRepositoryBase>.value(value: repository),
        ChangeNotifierProvider<FacilityProvider>(
          create: (_) => FacilityProvider(repository: repository),
        ),
        ChangeNotifierProvider<GuestModeService>.value(
          value: GuestModeService(),
        ),
        ChangeNotifierProvider<ZipCodeService>.value(value: ZipCodeService()),
        ChangeNotifierProvider<LocaleProvider>.value(value: LocaleProvider()),
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
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: locale,
        supportedLocales: LocaleProvider.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    ),
  );
  await settle(tester);
  return maps;
}

/// Lets the shell finish what it starts on a timer — marker refreshes, the
/// Home map's delayed camera move, the card's slide-out — then settles.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

/// Presses Android's back button.
Future<void> pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await settle(tester);
}

/// Opens a tab by its bottom-bar label.
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    ),
  );
  await settle(tester);
}

int selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;
