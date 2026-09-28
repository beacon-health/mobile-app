import 'package:beacon_app/core/widgets/tag_chip.dart';
import 'package:beacon_app/features/map/domain/models/eligibility_model.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_card.dart';
import 'package:beacon_app/features/map/utils/facility_formatting.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_facility.dart';

Future<void> _pumpCard(
  WidgetTester tester,
  Facility facility, {
  bool isExpanded = false,
  bool canFavorite = true,
  VoidCallback? onToggleExpand,
  VoidCallback? onToggleFavorite,
  VoidCallback? onRate,
  VoidCallback? onSubmitCorrection,
}) {
  mockPlatformServices();
  return pumpThemed(
    tester,
    Scaffold(
      body: SingleChildScrollView(
        child: FacilityCard(
          facility: facility,
          isExpanded: isExpanded,
          canFavorite: canFavorite,
          onToggleExpand: onToggleExpand ?? () {},
          onToggleFavorite: onToggleFavorite ?? () {},
          buildCategoryIcon: FacilityCategoryIcons.buildCategoryIcon,
          onLaunchUrl: (_) async {},
          onRate: onRate,
          onSubmitCorrection: onSubmitCorrection,
        ),
      ),
    ),
  );
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(FacilityCard)))!;

void main() {
  testWidgets('collapsed card previews the description, not the details',
      (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(name: 'Near North Health', description: 'Clinic'),
    );
    expect(find.text('Near North Health'), findsOneWidget);
    expect(find.text('Clinic'), findsOneWidget);
    expect(find.text(_l10n(tester).cardNextSteps), findsNothing);
  });

  testWidgets('the expand control reports taps', (tester) async {
    var toggles = 0;
    await _pumpCard(
      tester,
      createTestFacility(),
      onToggleExpand: () => toggles++,
    );
    await tester.tap(find.byIcon(Icons.expand_more));
    expect(toggles, 1);
  });

  testWidgets('expanded card shows next steps and hours', (tester) async {
    await _pumpCard(tester, createTestFacility(), isExpanded: true);
    final l10n = _l10n(tester);
    expect(find.text(l10n.cardNextSteps), findsOneWidget);
    expect(find.text(l10n.cardHours), findsOneWidget);
    expect(find.text(l10n.cardWebsiteNotAvailable), findsOneWidget);
    expect(find.text(l10n.cardContactForHours), findsOneWidget);
  });

  testWidgets('only "yes" eligibility attributes become chips', (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(
        services: const [],
        eligibility: const FacilityEligibility(
          acceptsWalkins: EligibilityValue.yes,
          telehealthAvailable: EligibilityValue.yes,
          wheelchairAccessible: EligibilityValue.no,
        ),
      ),
      isExpanded: true,
    );
    final l10n = _l10n(tester);
    expect(find.text(l10n.cardAtAGlance), findsOneWidget);
    expect(find.byType(TagChip), findsNWidgets(2));
    expect(find.text(l10n.chipWalkIns), findsOneWidget);
    expect(find.text(l10n.chipTelehealth), findsOneWidget);
    expect(find.text(l10n.chipAccessible), findsNothing);
  });

  testWidgets('services render as chips without a summary', (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(services: const ['Primary Care', 'Dental']),
      isExpanded: true,
    );
    expect(find.byType(TagChip), findsNWidgets(2));
    expect(find.text('Dental'), findsOneWidget);
  });

  testWidgets('a services summary replaces the chips and adds a disclaimer',
      (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(
        services: const ['Primary Care'],
        servicesSummary: 'Free checkups for adults.',
      ),
      isExpanded: true,
    );
    expect(find.text('Free checkups for adults.'), findsOneWidget);
    expect(
      find.text(_l10n(tester).cardServicesAiDisclaimer),
      findsOneWidget,
    );
    expect(find.byType(TagChip), findsNothing);
  });

  testWidgets('guests see a disabled favorite button', (tester) async {
    await _pumpCard(tester, createTestFacility(), canFavorite: false);
    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.favorite_border),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('signed-in users can toggle the favorite', (tester) async {
    var toggles = 0;
    await _pumpCard(
      tester,
      createTestFacility(),
      onToggleFavorite: () => toggles++,
    );
    await tester.tap(find.byIcon(Icons.favorite_border));
    expect(toggles, 1);
  });

  testWidgets('rate and correction rows appear only with their callbacks',
      (tester) async {
    await _pumpCard(tester, createTestFacility(), isExpanded: true);
    final l10n = _l10n(tester);
    expect(
        find.text(l10n.cardRatePromptAction, findRichText: true), findsNothing);

    var rated = 0;
    var corrected = 0;
    await _pumpCard(
      tester,
      createTestFacility(),
      isExpanded: true,
      onRate: () => rated++,
      onSubmitCorrection: () => corrected++,
    );
    await tester.tap(find.byIcon(Icons.thumbs_up_down_outlined));
    await tester.tap(find.byIcon(Icons.edit_note_outlined));
    expect((rated, corrected), (1, 1));
  });
}
