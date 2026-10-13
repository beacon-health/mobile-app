import 'dart:async';

import 'package:beacon_app/features/ask/data/assistant_model.dart';
import 'package:beacon_app/features/ask/data/assistant_service.dart';
import 'package:beacon_app/features/ask/presentation/pages/ask_page.dart';
import 'package:beacon_app/features/ask/presentation/widgets/ask_messages.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_card.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_list_panel.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../helpers/app_shell.dart';
import '../../helpers/fake_assistant.dart';
import '../../helpers/test_facility.dart';

/// The Ask tab inside the real tab shell, over a fake model.
void main() {
  const home = LatLng(41.8850, -87.6220);
  LatLng north(double degrees) =>
      LatLng(home.latitude + degrees, home.longitude);

  final clinic = createTestFacility(
    id: 'clinic',
    name: 'Loop Clinic',
    categoryBroad: 'Medical Care',
    location: north(0.001),
  );
  final pantry = createTestFacility(
    id: 'pantry',
    name: 'Corner Pantry',
    categoryBroad: 'Basic Needs',
    services: const ['Food'],
    location: north(0.002),
  );

  late PlatformLog platform;
  late FakeAssistantModel model;

  Future<void> pumpShell(
    WidgetTester tester, {
    AssistantAvailability? assistant = AssistantAvailability.available,
    Size? size,
    Locale locale = const Locale('en'),
  }) async {
    platform = await resetAppState(tester);
    await saveLocation(home);
    if (assistant != null) model = await useAssistant(status: assistant);
    await pumpAppShell(
      tester,
      repository: FakeFacilityRepository([clinic, pantry]),
      size: size ?? const Size(390, 844),
      locale: locale,
    );
  }

  List<String> tabLabels(WidgetTester tester) => [
        for (final destination in tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .destinations)
          (destination as NavigationDestination).label,
      ];

  Future<void> ask(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).last, text);
    await tester.tap(find.byTooltip('Send'));
    await settle(tester);
  }

  List<String> listedOnMap(WidgetTester tester) => [
        for (final facility in tester
            .widget<FacilityListPanel>(find.byType(FacilityListPanel))
            .facilities)
          facility.id,
      ];

  group('the tab', () {
    testWidgets('is in the middle of the bar on a phone with a model',
        (tester) async {
      await pumpShell(tester);

      expect(tabLabels(tester), ['Home', 'Map', 'Ask', 'Profile', 'Settings']);
    });

    testWidgets('is left out on a phone that can never run one',
        (tester) async {
      await pumpShell(tester, assistant: AssistantAvailability.unsupported);
      expect(tabLabels(tester), ['Home', 'Map', 'Profile', 'Settings']);

      await pumpShell(tester, assistant: null);
      expect(tabLabels(tester), ['Home', 'Map', 'Profile', 'Settings']);
    });

    testWidgets('five labels fit a narrow phone in Spanish', (tester) async {
      // The longest set of labels on the smallest screen the app supports.
      await pumpShell(
        tester,
        size: const Size(320, 640),
        locale: const Locale('es'),
      );

      expect(
        tabLabels(tester),
        ['Inicio', 'Mapa', 'Preguntar', 'Perfil', 'Ajustes'],
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('appears once the model becomes available', (tester) async {
      await pumpShell(tester, assistant: AssistantAvailability.unsupported);
      expect(tabLabels(tester), hasLength(4));
      await openTab(tester, 'Settings');

      model.status = AssistantAvailability.available;
      await AssistantService().refresh();
      await settle(tester);

      // The tab the person was on is still the one showing.
      expect(tabLabels(tester), hasLength(5));
      expect(find.text('Directions app'), findsOneWidget);
    });
  });

  group('before the first message', () {
    testWidgets('says what it is for, and where to turn in an emergency',
        (tester) async {
      await pumpShell(tester);
      await openTab(tester, 'Ask');

      expect(find.text('What do you need help finding?'), findsOneWidget);
      expect(find.textContaining('call 911'), findsOneWidget);
      expect(find.textContaining('988'), findsOneWidget);
      expect(
        find.text("Runs on this phone. Chats aren't sent anywhere."),
        findsOneWidget,
      );
    });

    testWidgets('a suggestion searches without asking the model to read it',
        (tester) async {
      await pumpShell(tester);
      await openTab(tester, 'Ask');

      await tester.tap(find.text('Someone to talk to'));
      await settle(tester);

      expect(model.filterPrompts, isEmpty);
      // Nothing in mental health nearby: straight to the hand-off.
      expect(find.byType(AskHandoff), findsOneWidget);
    });
  });

  group('an answer', () {
    testWidgets('shows the places as cards, and how the request was read',
        (tester) async {
      await pumpShell(tester);
      await openTab(tester, 'Ask');
      model.filtersReply = '{"categories":["health_care"]}';

      await ask(tester, 'I need a doctor');

      expect(find.text('I need a doctor'), findsOneWidget);
      expect(find.text('I found 1 place that matches.'), findsOneWidget);
      expect(find.byType(AskFacilityCard), findsOneWidget);
      expect(find.text('Loop Clinic'), findsOneWidget);
      expect(find.text('0.1 mi'), findsOneWidget);
      // The filters it used, in words — a wrong reading is plain to see.
      expect(find.text('What I searched for'), findsOneWidget);
      expect(find.text('Health care'), findsOneWidget);
      expect(
        find.text('AI read your request. Check details with the facility.'),
        findsOneWidget,
      );
    });

    testWidgets('says so when it shows places that are not open now',
        (tester) async {
      await pumpShell(tester);
      await openTab(tester, 'Ask');
      model.filtersReply = '{"categories":["health_care"],"open_now":true}';

      await ask(tester, 'a doctor tonight');

      expect(find.byType(AskFacilityCard), findsOneWidget);
      expect(
        find.textContaining('None of these are open right now.'),
        findsOneWidget,
      );
      // No point offering to narrow to "open now" again.
      expect(find.text('Only open now'), findsNothing);
    });

    testWidgets('a card has named, full-size Save and Directions buttons',
        (tester) async {
      await pumpShell(tester);
      await openTab(tester, 'Ask');
      model.filtersReply = '{"categories":["health_care"]}';
      await ask(tester, 'doctor');

      for (final tooltip in [
        'Save Loop Clinic',
        'Directions to Loop Clinic',
      ]) {
        final size = tester.getSize(
          find.ancestor(
            of: find.byTooltip(tooltip),
            matching: find.byType(IconButton),
          ),
        );
        expect(size.shortestSide, greaterThanOrEqualTo(48), reason: tooltip);
      }

      // Saving belongs to an account: a guest is offered sign-in.
      await tester.tap(find.byTooltip('Save Loop Clinic'));
      await settle(tester);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('tapping a card opens that facility on the Map',
        (tester) async {
      await pumpShell(tester);
      await openTab(tester, 'Ask');
      model.filtersReply = '{"categories":["health_care"]}';
      await ask(tester, 'doctor');

      await tester.tap(find.text('Loop Clinic'));
      await settle(tester);

      expect(selectedTab(tester), NavTab.map);
      expect(find.byType(FacilityCard), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
    });

    testWidgets('"Show on map" opens the Map with the same filters',
        (tester) async {
      await pumpShell(tester);
      await openTab(tester, 'Ask');
      model.filtersReply = '{"categories":["health_care"]}';
      await ask(tester, 'doctor');

      await tester.tap(find.text('Show on map'));
      await settle(tester);

      expect(selectedTab(tester), NavTab.map);
      expect(listedOnMap(tester), ['clinic']);
      // The Map's own Category chip shows the filter is on.
      final categoryChip = tester
          .widgetList<CustomFilterChip>(find.byType(CustomFilterChip))
          .firstWhere((chip) => chip.hasDropdown && !chip.isLocked);
      expect(categoryChip.isSelected, isTrue);
    });

    testWidgets('"Only open now" runs the same search again, narrowed',
        (tester) async {
      await pumpShell(tester);
      await openTab(tester, 'Ask');
      model.filtersReply = '{"categories":["health_care"]}';
      await ask(tester, 'doctor');

      await tester.tap(find.text('Only open now'));
      await settle(tester);

      // Its own entry in the conversation, answered without the model.
      expect(model.filterPrompts, hasLength(1));
      expect(
        find.widgetWithText(AskUserBubble, 'Only open now'),
        findsOneWidget,
      );
      expect(
        find.textContaining('None of these are open right now.'),
        findsOneWidget,
      );
    });
  });

  group('a hand-off', () {
    testWidgets('for no results, opens the Map with the filters it tried',
        (tester) async {
      await pumpShell(tester);
      await openTab(tester, 'Ask');
      model.filtersReply = '{"categories":["housing"]}';

      await ask(tester, 'a shelter');

      expect(
        find.textContaining("I didn't find anything nearby"),
        findsOneWidget,
      );
      expect(find.text('Housing & shelter'), findsOneWidget);

      await tester.tap(find.text('Open the map with these filters'));
      await settle(tester);

      expect(selectedTab(tester), NavTab.map);
      expect(listedOnMap(tester), isEmpty);
    });

    testWidgets('refuses medical advice and offers the plain Map',
        (tester) async {
      await pumpShell(tester);
      await openTab(tester, 'Ask');
      model.filtersReply = '{"intent":"medical_advice"}';

      await ask(tester, 'what should I take for a fever');

      expect(
          find.textContaining("I can't give medical advice"), findsOneWidget);
      await tester.tap(find.text('Open the map'));
      await settle(tester);

      expect(selectedTab(tester), NavTab.map);
      expect(listedOnMap(tester), ['clinic', 'pantry']);
    });

    testWidgets('for a reply it cannot read', (tester) async {
      await pumpShell(tester);
      await openTab(tester, 'Ask');
      model.filtersReply = 'Sorry, I am not sure.';

      await ask(tester, 'hmm');

      expect(
        find.textContaining("I couldn't work out what to search for"),
        findsOneWidget,
      );
    });
  });

  testWidgets('a crisis message shows 911 and 988 without waiting on the model',
      (tester) async {
    await pumpShell(tester);
    await openTab(tester, 'Ask');
    model.gate = Completer<void>();

    await tester.enterText(find.byType(TextField).last, 'I want to die');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();

    expect(find.byType(AskCrisisCard), findsOneWidget);
    expect(find.text('Looking…'), findsOneWidget);

    await tester.tap(find.text('Call 911'));
    await tester.pump();
    expect(platform.launchedUrls, ['tel:911']);

    model.gate!.complete();
    await settle(tester);
  });

  testWidgets('"New chat" starts over', (tester) async {
    await pumpShell(tester);
    await openTab(tester, 'Ask');
    model.filtersReply = '{"categories":["health_care"]}';
    await ask(tester, 'doctor');
    expect(find.byTooltip('New chat'), findsOneWidget);

    await tester.tap(find.byTooltip('New chat'));
    await settle(tester);

    expect(find.byType(AskFacilityCard), findsNothing);
    expect(find.text('What do you need help finding?'), findsOneWidget);
    expect(find.byTooltip('New chat'), findsNothing);
  });

  group('when the model is not ready', () {
    testWidgets('says so and offers the Map', (tester) async {
      await pumpShell(tester, assistant: AssistantAvailability.notReady);
      await openTab(tester, 'Ask');

      expect(find.text("The assistant isn't ready yet"), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Search the map'));
      await settle(tester);
      expect(selectedTab(tester), NavTab.map);
    });

    testWidgets('opening the tab asks the phone again', (tester) async {
      await pumpShell(tester, assistant: AssistantAvailability.notReady);
      model.status = AssistantAvailability.available;

      await openTab(tester, 'Ask');

      expect(find.text('What do you need help finding?'), findsOneWidget);
    });

    testWidgets('says when the model cannot use the language', (tester) async {
      await pumpShell(
        tester,
        assistant: AssistantAvailability.unsupportedLanguage,
      );
      await openTab(tester, 'Ask');

      expect(
        find.text("The assistant doesn't work in this language yet"),
        findsOneWidget,
      );
    });
  });

  group('Android back', () {
    testWidgets('from Ask returns to Home, then leaves', (tester) async {
      await pumpShell(tester);
      await openTab(tester, 'Ask');
      expect(find.byType(AskPage), findsOneWidget);

      await pressBack(tester);
      expect(selectedTab(tester), NavTab.home);
      expect(platform.exits, 0);

      await pressBack(tester);
      expect(platform.exits, 1);
    });

    testWidgets('from the Map after a hand-off goes Home, not back into Ask',
        (tester) async {
      await pumpShell(tester);
      await openTab(tester, 'Ask');
      model.filtersReply = '{"categories":["health_care"]}';
      await ask(tester, 'doctor');
      await tester.tap(find.text('Loop Clinic'));
      await settle(tester);
      expect(find.byType(FacilityCard), findsOneWidget);

      await pressBack(tester); // the facility sheet
      expect(find.byType(FacilityCard), findsWidgets);
      expect(selectedTab(tester), NavTab.map);

      await pressBack(tester); // the tab
      expect(selectedTab(tester), NavTab.home);
      expect(platform.exits, 0);
    });
  });

  test('the platform decides which model is used', () {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      expect(
        AssistantModelService.forPlatform(platform, isWeb: false),
        isA<MethodChannelAssistantModel>(),
        reason: platform.name,
      );
    }
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.fuchsia,
    ]) {
      expect(
        AssistantModelService.forPlatform(platform, isWeb: false),
        isNull,
        reason: platform.name,
      );
    }
    expect(
      AssistantModelService.forPlatform(TargetPlatform.iOS, isWeb: true),
      isNull,
    );
  });
}
