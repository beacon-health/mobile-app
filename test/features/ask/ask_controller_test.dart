import 'dart:async';

import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/features/ask/domain/ask_request.dart';
import 'package:beacon_app/features/ask/presentation/ask_controller.dart';
import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../helpers/app_shell.dart';
import '../../helpers/fake_assistant.dart';
import '../../helpers/test_facility.dart';

/// The assistant's two steps, over a fake model and a fake data source.
void main() {
  LatLng north(double degrees) =>
      LatLng(chicago.latitude + degrees, chicago.longitude);

  final clinicFar = createTestFacility(
    id: 'clinic-far',
    name: 'Far Clinic',
    categoryBroad: 'Medical Care',
    services: const ['Primary Care'],
    location: north(0.02),
  );
  final dental = createTestFacility(
    id: 'dental',
    name: 'Loop Dental',
    categoryBroad: 'Medical Care',
    services: const ['Dental'],
    location: north(0.005),
  );
  final pantry = createTestFacility(
    id: 'pantry',
    name: 'Corner Pantry',
    categoryBroad: 'Basic Needs',
    services: const ['Food'],
    location: north(0.001),
  );

  late FakeAssistantModel model;
  late FakeFacilityRepository repository;
  late AskController controller;

  Future<void> setUpAsk(
    WidgetTester tester, {
    List<Facility>? facilities,
  }) async {
    await resetAppState(tester);
    model = FakeAssistantModel();
    repository = FakeFacilityRepository(
      facilities ?? [clinicFar, dental, pantry],
    );
    controller = AskController(model: model, repository: repository);
    addTearDown(controller.dispose);
  }

  Future<void> ask(String text) => controller.send(text);

  T last<T extends AskMessage>() => controller.messages.last as T;

  testWidgets('turns a request into filters, then into the nearest places',
      (tester) async {
    await setUpAsk(tester);
    model.filtersReply = '{"intent":"search","categories":["health_care"]}';

    await ask('I need a doctor');

    final answer = last<AskAnswerMessage>();
    expect(answer.facilities.map((f) => f.id), ['dental', 'clinic-far']);
    expect(answer.totalCount, 2);
    expect(answer.filters.groups, {FacilityCategories.groupHealthCare});
    // The Map's query, around the saved location.
    expect(repository.queries, [chicago]);
    expect(controller.messages.first, isA<AskUserMessage>());
  });

  testWidgets('the model sees the request, quoted, and nothing about the user',
      (tester) async {
    await setUpAsk(tester);
    model.filtersReply = '{"categories":["health_care"]}';

    await ask('I need a doctor');

    expect(model.filterPrompts.single, 'Request: "I need a doctor"');
  });

  testWidgets('shows at most five places and says how many matched',
      (tester) async {
    await setUpAsk(
      tester,
      facilities: [
        for (var i = 0; i < 9; i++)
          createTestFacility(
            id: 'c$i',
            name: 'Clinic $i',
            categoryBroad: 'Medical Care',
            location: north(0.001 * (i + 1)),
          ),
      ],
    );
    model.filtersReply = '{"categories":["health_care"]}';

    await ask('clinic');

    final answer = last<AskAnswerMessage>();
    expect(answer.facilities, hasLength(AskController.maxFacilities));
    expect(answer.facilities.first.id, 'c0');
    expect(answer.totalCount, 9);
  });

  testWidgets("the model's keyword is loosened before it is given up",
      (tester) async {
    // The model says "dentist"; the listing says "Dental".
    await setUpAsk(tester);
    model.filtersReply = '{"categories":["health_care"],"keyword":"dentist"}';

    await ask('I need a dentist');

    final answer = last<AskAnswerMessage>();
    expect(answer.facilities.single.id, 'dental');
    // What it actually searched for, which is what the page shows.
    expect(answer.filters.keyword, 'dent');
  });

  testWidgets('a keyword that matches nothing at all is dropped',
      (tester) async {
    await setUpAsk(tester);
    model.filtersReply = '{"categories":["health_care"],"keyword":"podiatry"}';

    await ask('a foot doctor');

    final answer = last<AskAnswerMessage>();
    expect(answer.facilities, hasLength(2));
    expect(answer.filters.keyword, isEmpty);
  });

  test('the keyword ladder goes from exact to none', () {
    expect(AskController.keywordLadder(''), ['']);
    expect(AskController.keywordLadder('dental'), ['dental', 'dent', '']);
    expect(
      AskController.keywordLadder('food pantry'),
      ['food pantry', 'food', ''],
    );
    expect(AskController.keywordLadder('std'), ['std', '']);
  });

  testWidgets('a keyword that does match narrows the results', (tester) async {
    await setUpAsk(tester);
    model.filtersReply = '{"categories":["health_care"],"keyword":"dental"}';

    await ask('dental care');

    final answer = last<AskAnswerMessage>();
    expect(answer.facilities.single.id, 'dental');
    expect(answer.filters.keyword, 'dental');
  });

  testWidgets('when nothing is open now, shows the matches and says so',
      (tester) async {
    // The test facilities list no hours, so none counts as open.
    await setUpAsk(tester);
    model.filtersReply = '{"categories":["basic_needs"],"open_now":true}';

    await ask('food tonight');

    final answer = last<AskAnswerMessage>();
    expect(answer.facilities.single.id, 'pantry');
    expect(answer.noneOpenNow, isTrue);
    expect(answer.filters.openNow, isFalse);
  });

  group('hands off to the Map', () {
    testWidgets('when nothing matches, with the filters it worked out',
        (tester) async {
      await setUpAsk(tester);
      model.filtersReply = '{"categories":["housing"],"open_now":true}';

      await ask('shelter tonight');

      final handoff = last<AskHandoffMessage>();
      expect(handoff.reason, AskHandoffReason.noResults);
      expect(handoff.filters.groups, {FacilityCategories.groupHousingShelter});
      expect(handoff.filters.openNow, isTrue);
    });

    testWidgets('when the reply cannot be read', (tester) async {
      await setUpAsk(tester);
      model.filtersReply = 'I would suggest visiting a clinic!';

      await ask('help');

      expect(last<AskHandoffMessage>().reason, AskHandoffReason.unclear);
      expect(repository.queries, isEmpty);
    });

    testWidgets('when the filters come back empty', (tester) async {
      await setUpAsk(tester);
      model.filtersReply = '{"intent":"search","categories":[]}';

      await ask('something');

      expect(last<AskHandoffMessage>().reason, AskHandoffReason.unclear);
    });

    testWidgets('when the model fails outright', (tester) async {
      await setUpAsk(tester);
      model.filtersError = StateError('model crashed');

      await ask('clinic');

      expect(last<AskHandoffMessage>().reason, AskHandoffReason.unclear);
      expect(controller.isThinking, isFalse);
    });

    testWidgets('for medical advice, without searching', (tester) async {
      await setUpAsk(tester);
      model.filtersReply =
          '{"intent":"medical_advice","categories":["health_care"]}';

      await ask('what should I take for a fever');

      final handoff = last<AskHandoffMessage>();
      expect(handoff.reason, AskHandoffReason.medicalAdvice);
      expect(handoff.filters.isEmpty, isTrue);
      expect(repository.queries, isEmpty);
    });

    testWidgets('for anything off topic', (tester) async {
      await setUpAsk(tester);
      model.filtersReply = '{"intent":"off_topic"}';

      await ask('tell me a joke');

      expect(last<AskHandoffMessage>().reason, AskHandoffReason.offTopic);
    });
  });

  testWidgets('the model is asked one thing: to read the request',
      (tester) async {
    await setUpAsk(tester);
    model.filtersReply = '{"categories":["basic_needs"]}';

    await ask('food');

    // One call, for filters. Nothing the person reads is written by it.
    expect(model.filterPrompts, hasLength(1));
    expect(model.filterInstructions.single, contains('"basic_needs"'));
  });

  testWidgets('a crisis message gets 911 and 988 before the model answers',
      (tester) async {
    await setUpAsk(tester);
    model.gate = Completer<void>();

    unawaited(ask('I want to kill myself'));
    await tester.pump();

    // Shown while the model is still thinking.
    expect(controller.isThinking, isTrue);
    expect(controller.messages.last, isA<AskCrisisMessage>());

    model.gate!.complete();
    await tester.pump();
    await tester.pump();
    expect(controller.messages[1], isA<AskCrisisMessage>());
  });

  testWidgets('applies what the person can provide, as the Map does',
      (tester) async {
    final needsReferral = createTestFacility(
      id: 'referral',
      name: 'Referral Clinic',
      categoryBroad: 'Medical Care',
      eligibilityRequirements: const {'referral_required': true},
      location: north(0.001),
    );
    await setUpAsk(tester, facilities: [needsReferral, dental]);
    await EligibilityPreferencesService().updateEligibility(
      const EligibilityState(applyToSearch: true),
      syncToCloud: false,
    );
    model.filtersReply = '{"categories":["health_care"]}';

    await ask('doctor');

    expect(last<AskAnswerMessage>().facilities.map((f) => f.id), ['dental']);
  });

  testWidgets('preference filters need an account, as on the Map',
      (tester) async {
    final notFree = createTestFacility(
      id: 'paid',
      name: 'Paid Clinic',
      categoryBroad: 'Medical Care',
      eligibilityRequirements: const {'free_services_available': false},
      location: north(0.001),
    );
    final free = createTestFacility(
      id: 'free',
      name: 'Free Clinic',
      categoryBroad: 'Medical Care',
      eligibilityRequirements: const {'free_services_available': true},
      location: north(0.002),
    );
    await setUpAsk(tester, facilities: [notFree, free]);
    model.filtersReply = '{"categories":["health_care"],"needs":["free"]}';

    await ask('free clinic');
    expect(
      last<AskAnswerMessage>().facilities.map((f) => f.id),
      ['paid', 'free'],
      reason: 'a guest',
    );

    GuestModeService().debugUser = testUser();
    await ask('free clinic');
    expect(
      last<AskAnswerMessage>().facilities.map((f) => f.id),
      ['free'],
      reason: 'signed in',
    );
    expect(
      last<AskAnswerMessage>().filters.preferences,
      {PreferenceRequirement.freeServicesAvailable},
    );
  });

  testWidgets("a ready-made search skips the model's reading", (tester) async {
    await setUpAsk(tester);

    await controller.search(
      'Food pantries',
      const AskFilters(groups: {FacilityCategories.groupBasicNeeds}),
    );

    expect(model.filterPrompts, isEmpty);
    expect(last<AskAnswerMessage>().facilities.single.id, 'pantry');
  });

  testWidgets('"New chat" clears it, and drops an answer still on its way',
      (tester) async {
    await setUpAsk(tester);
    model
      ..filtersReply = '{"categories":["basic_needs"]}'
      ..gate = Completer<void>();

    unawaited(ask('food'));
    await tester.pump();
    controller.clear();
    model.gate!.complete();
    await tester.pump();
    await tester.pump();

    expect(controller.messages, isEmpty);
    expect(controller.isThinking, isFalse);
  });

  testWidgets('ignores an empty message, and a second one while thinking',
      (tester) async {
    await setUpAsk(tester);
    await ask('   ');
    expect(controller.messages, isEmpty);

    model
      ..filtersReply = '{"categories":["basic_needs"]}'
      ..gate = Completer<void>();
    unawaited(ask('food'));
    await tester.pump();
    await ask('clinic');

    expect(controller.messages.whereType<AskUserMessage>(), hasLength(1));
    model.gate!.complete();
    await tester.pump();
  });
}
