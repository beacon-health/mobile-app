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
    expect(find.text(_l10n(tester).cardDirections), findsNothing);
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

  testWidgets('expanded card puts directions under the name, then hours',
      (tester) async {
    await _pumpCard(tester, createTestFacility(), isExpanded: true);
    final l10n = _l10n(tester);
    expect(find.text(l10n.cardDirections), findsOneWidget);
    expect(find.text(l10n.cardHours), findsOneWidget);
    expect(find.text(l10n.cardContactForHours), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(l10n.cardDirections)).dy,
      lessThan(tester.getTopLeft(find.text(l10n.cardHours)).dy),
    );
  });

  testWidgets('call and website appear only when the facility has them',
      (tester) async {
    await _pumpCard(tester, createTestFacility(), isExpanded: true);
    var l10n = _l10n(tester);
    expect(find.text(l10n.cardCall), findsNothing);
    expect(find.text(l10n.cardWebsite), findsNothing);

    final launched = <String>[];
    final semantics = tester.ensureSemantics();
    mockPlatformServices();
    await pumpThemed(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: FacilityCard(
            facility: createTestFacility(
              phones: const [PhoneContact(number: '3125550100')],
              website: 'https://example.org',
            ),
            isExpanded: true,
            onToggleExpand: () {},
            onToggleFavorite: () {},
            buildCategoryIcon: FacilityCategoryIcons.buildCategoryIcon,
            onLaunchUrl: (url) async => launched.add(url),
          ),
        ),
      ),
    );
    l10n = _l10n(tester);
    await tester.tap(find.text(l10n.cardCall));
    await tester.tap(find.text(l10n.cardWebsite));
    expect(launched, ['tel:3125550100', 'https://example.org']);
    // A screen reader hears the number, not just "Call".
    expect(
      find.bySemanticsLabel(l10n.cardCallNumber('(312) 555-0100')),
      findsOneWidget,
    );
    semantics.dispose();
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

  testWidgets('the heart and the expand control are full-size and named',
      (tester) async {
    await _pumpCard(tester, createTestFacility(name: 'CARPLS'));
    final l10n = _l10n(tester);
    for (final tooltip in [l10n.cardSave('CARPLS'), l10n.cardShowDetails]) {
      final button = find.byTooltip(tooltip);
      expect(button, findsOneWidget, reason: tooltip);
      final size = tester.getSize(
        find.ancestor(of: button, matching: find.byType(IconButton)).first,
      );
      expect(size.width, greaterThanOrEqualTo(48), reason: tooltip);
      expect(size.height, greaterThanOrEqualTo(48), reason: tooltip);
    }
  });

  testWidgets('a saved facility offers to remove it', (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(name: 'CARPLS', isFavorite: true),
    );
    expect(
      find.byTooltip(_l10n(tester).cardUnsave('CARPLS')),
      findsOneWidget,
    );
  });

  testWidgets('the heart reports taps', (tester) async {
    var toggles = 0;
    await _pumpCard(
      tester,
      createTestFacility(),
      onToggleFavorite: () => toggles++,
    );
    await tester.tap(find.byIcon(Icons.favorite_border));
    expect(toggles, 1);
  });

  testWidgets('a collapsed row shows the address above the description',
      (tester) async {
    // The address used to be reachable only by asking for directions.
    await _pumpCard(
      tester,
      createTestFacility(
        address: '35 E Wacker Dr, Chicago, IL 60601',
        description: 'Free legal aid',
      ),
    );

    expect(find.text('35 E Wacker Dr, Chicago, IL 60601'), findsOneWidget);
    expect(find.text('Free legal aid'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('35 E Wacker Dr, Chicago, IL 60601')).dy,
      lessThan(tester.getTopLeft(find.text('Free legal aid')).dy),
    );
  });

  testWidgets('an expanded card keeps the address in its header',
      (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(address: '35 E Wacker Dr, Chicago, IL 60601'),
      isExpanded: true,
    );

    expect(find.text('35 E Wacker Dr, Chicago, IL 60601'), findsOneWidget);
  });

  testWidgets('a record with no address falls back to city and state',
      (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(
        address: Facility.addressUnavailable,
        city: 'Tulsa',
        state: 'OK',
      ),
    );

    expect(find.text('Tulsa, OK'), findsOneWidget);
    expect(find.text(Facility.addressUnavailable), findsNothing);
  });

  testWidgets('Medicaid shows as a chip only when accepted', (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(
        eligibility: const FacilityEligibility(
          acceptsMedicaid: EligibilityValue.yes,
        ),
      ),
      isExpanded: true,
    );
    expect(
      find.widgetWithText(TagChip, _l10n(tester).chipMedicaid),
      findsOneWidget,
    );

    for (final value in [EligibilityValue.no, EligibilityValue.unknown]) {
      await _pumpCard(
        tester,
        createTestFacility(
          eligibility: FacilityEligibility(acceptsMedicaid: value),
        ),
        isExpanded: true,
      );
      expect(
        find.widgetWithText(TagChip, _l10n(tester).chipMedicaid),
        findsNothing,
        reason: value.name,
      );
    }
  });

  testWidgets('income limit and service area show as labelled lines',
      (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(
        eligibility: const FacilityEligibility(
          incomeLimit: 'At or below 200% of the Federal Poverty Level',
          serviceArea: 'DeKalb County residents only',
        ),
      ),
      isExpanded: true,
    );
    final l10n = _l10n(tester);

    expect(find.text(l10n.cardAtAGlance), findsOneWidget);
    expect(
      find.textContaining(
        'Income limit: At or below 200% of the Federal Poverty Level',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Service area: DeKalb County residents only',
        findRichText: true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('a facility with none of the new fields shows no empty section',
      (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(eligibility: const FacilityEligibility()),
      isExpanded: true,
    );

    expect(find.text(_l10n(tester).cardAtAGlance), findsNothing);
    expect(
        find.textContaining('Income limit', findRichText: true), findsNothing);
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
