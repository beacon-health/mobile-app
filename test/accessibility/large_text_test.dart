import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/widgets/sign_in_prompt_dialog.dart';
import 'package:beacon_app/features/ask/presentation/pages/ask_page.dart';
import 'package:beacon_app/features/ask/presentation/widgets/ask_messages.dart';
import 'package:beacon_app/features/auth/presentation/pages/eligibility_onboarding_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/location_choice_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/login_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/zip_entry_page.dart';
import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/domain/models/eligibility_model.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_card.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_modal.dart';
import 'package:beacon_app/features/profile/presentation/pages/profile_page.dart';
import 'package:beacon_app/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../helpers/app_shell.dart';
import '../helpers/fake_assistant.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_facility.dart';

/// Every screen, at the text sizes people actually set: 200% (Android's
/// largest) and 310% (iOS's largest accessibility size), on a small phone and
/// in the language with the longest strings.
///
/// A layout that can't hold its text throws an overflow error, which fails
/// the test. The test font is also wider than Inter, so a screen that passes
/// here has room to spare on a device.
void main() {
  const smallPhone = Size(360, 640);
  // A saved location a little off the map's built-in default, so the map
  // goes to it at street zoom as it does for a real user.
  const home = LatLng(41.8850, -87.6220);
  const scales = [2.0, 3.1];

  /// A facility with every section the card can show.
  final busy = createTestFacility(
    id: 'busy',
    name: 'First Baptist Congregational Church of Chicago Community Pantry',
    description: 'Food pantry and hot meals, with referrals to housing help.',
    address: '1613 W Washington Blvd, Chicago, IL 60612',
    categoryBroad: FacilityCategories.categoryBroadValues.first,
    website: 'https://example.org',
    phones: const [PhoneContact(number: '3125550100')],
    services: const ['Food pantry', 'Hot meals', 'Housing referrals'],
    servicesSummary: 'Groceries twice a month and a hot lunch on weekdays.',
    otherEligibilitySummary: 'Bring a bag. Open to anyone in Cook County.',
    hours: const [
      OperatingHours(day: 'mon', opensAt: '09:00', closesAt: '17:00'),
      OperatingHours(day: 'wed', opensAt: '09:00', closesAt: '17:00'),
      OperatingHours(day: 'sat'),
    ],
    eligibility: const FacilityEligibility(
      acceptsMedicaid: EligibilityValue.yes,
      acceptsWalkins: EligibilityValue.yes,
      freeServicesAvailable: EligibilityValue.yes,
      otherLanguages: EligibilityValue.yes,
      incomeLimit: 'At or below 200% of the Federal Poverty Level',
      serviceArea: 'Cook County residents',
    ),
    location: LatLng(home.latitude + 0.001, home.longitude),
  );

  void useTextScale(WidgetTester tester, double scale) {
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  for (final scale in scales) {
    group('at ${(scale * 100).round()}% text', () {
      for (final locale in const [Locale('en'), Locale('es')]) {
        final language = locale.languageCode;

        Future<void> pumpPage(WidgetTester tester, Widget page) async {
          useTextScale(tester, scale);
          await pumpThemed(tester, page, size: smallPhone, locale: locale);
        }

        testWidgets('onboarding fits ($language)', (tester) async {
          await resetAppState(tester);
          const steps = [
            LocationChoicePage(),
            ZipEntryPage(locationOff: true),
          ];
          for (final Widget page in [const LoginPage(), ...steps]) {
            await pumpPage(tester, page);
            expect(tester.takeException(), isNull, reason: '$page');
          }

          // Signed in, the steps carry a count and one more follows.
          GuestModeService().debugUser = testUser();
          for (final Widget page in [
            ...steps,
            const EligibilityOnboardingPage(),
          ]) {
            await pumpPage(tester, page);
            expect(tester.takeException(), isNull, reason: '$page');
          }
        });

        testWidgets('Settings fits ($language)', (tester) async {
          await resetAppState(tester);
          await pumpPage(tester, const SettingsPage());
          await tester.drag(find.byType(ListView), const Offset(0, -2000));
          await tester.pumpAndSettle();
        });

        testWidgets('Profile fits, guest and signed in ($language)',
            (tester) async {
          await resetAppState(tester);
          await pumpPage(tester, const ProfilePage());
          await tester.drag(find.byType(ListView), const Offset(0, -3000));
          await tester.pumpAndSettle();

          GuestModeService().debugUser = testUser(
            email: 'a.very.long.address@example.org',
            name: 'Maria Guadalupe Rodriguez Hernandez',
          );
          await EligibilityPreferencesService().updateEligibility(
            const EligibilityState(applyToSearch: true),
            syncToCloud: false,
          );
          await pumpPage(tester, const ProfilePage());
          await tester.drag(find.byType(ListView), const Offset(0, -6000));
          await tester.pumpAndSettle();
        });

        testWidgets('the sign-in prompt fits ($language)', (tester) async {
          await resetAppState(tester);
          await pumpPage(
            tester,
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showSignInPromptDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          expect(find.byType(Dialog), findsOneWidget);
        });

        testWidgets('the filter sheet fits ($language)', (tester) async {
          await resetAppState(tester);
          await pumpPage(
            tester,
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => FilterModal(
                      selectedCategories: const {'Medical Care'},
                      availableCategories:
                          FacilityCategories.categoryBroadValues,
                      selectedPreferenceRequirements: const {},
                      showFavoritesOnly: false,
                      showOpenNowOnly: true,
                      resultCount: (_) => 128,
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          expect(find.byType(FilterModal), findsOneWidget);
        });
      }

      testWidgets('Ask fits: the start, an answer, and a hand-off',
          (tester) async {
        useTextScale(tester, scale);
        await resetAppState(tester);
        await saveLocation(home);
        final model = await useAssistant();
        await pumpAppShell(
          tester,
          repository: FakeFacilityRepository([busy]),
          size: smallPhone,
        );
        await openTab(tester, 'Ask');

        Future<void> ask(String text, String reply) async {
          model.filtersReply = reply;
          await tester.enterText(find.byType(TextField).last, text);
          await tester.tap(find.byTooltip('Send'));
          await settle(tester);
        }

        // A crisis card and a refusal, an answer with a card, a hand-off
        // with its filters. Every one is laid out; an overflow fails the
        // test.
        // The list keeps its newest message in view; drag back through the
        // conversation so everything above it is laid out too.
        Future<void> scrollBackTo(Finder finder) async {
          final list = find.descendant(
            of: find.byType(AskPage),
            matching: find.byType(ListView),
          );
          for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
            await tester.drag(list, const Offset(0, 150));
            await tester.pumpAndSettle();
          }
          expect(finder, findsOneWidget);
        }

        await ask('I want to die', '{"intent":"off_topic"}');
        await scrollBackTo(find.byType(AskCrisisCard));

        await ask('someone to talk to', '{"categories":["mental_health"]}');
        await scrollBackTo(find.byType(AskFacilityCard));

        await ask('a shelter', '{"categories":["housing"],"open_now":true}');
        expect(find.byType(AskHandoff), findsWidgets);
      });

      testWidgets('Home and Map fit, with a facility open', (tester) async {
        useTextScale(tester, scale);
        await resetAppState(tester);
        await saveLocation(home);
        final maps = await pumpAppShell(
          tester,
          repository: FakeFacilityRepository([
            busy,
            createTestFacility(
              id: 'other',
              name: 'Near North Health Service',
              location: LatLng(home.latitude + 0.004, home.longitude),
            ),
          ]),
          size: smallPhone,
        );
        final map = maps.mapStartingAtZoom(12);

        // Home, top to bottom.
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -2000),
        );
        await settle(tester);

        // Map: the list, a row opened in place, then the facility sheet.
        await openTab(tester, 'Map');
        // The expand control, not the name: an open row's name can sit below
        // the fold of the panel.
        await tester.tap(find.byTooltip('Show details').first);
        await settle(tester);
        expect(find.text('Directions'), findsOneWidget);
        await tester.tap(find.byTooltip('Hide details'));
        await settle(tester);

        maps.tapMarker(map, const MarkerId('busy'));
        await settle(tester);
        expect(find.byType(FacilityCard), findsOneWidget);
        expect(find.textContaining('200%'), findsOneWidget);
      });
    });
  }
}
