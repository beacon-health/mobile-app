import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/dashed_vertical_divider.dart';
import 'package:beacon_app/core/widgets/tag_chip.dart';
import 'package:beacon_app/features/map/domain/models/eligibility_model.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_card.dart';
import 'package:beacon_app/features/map/utils/facility_formatting.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Size size = phoneSize,
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
    size: size,
  );
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(FacilityCard)))!;

void main() {
  testWidgets('a collapsed row is the name, then city, state and kind',
      (tester) async {
    // Less to read on the Map: no street address, no description preview.
    await _pumpCard(
      tester,
      createTestFacility(
        name: 'Near North Health',
        description: 'Clinic for the whole family',
        address: '1276 N Clybourn Ave, Chicago, IL 60610',
        categoryDetail: 'Community Health Center',
      ),
    );

    expect(find.text('Near North Health'), findsOneWidget);
    expect(find.text('Chicago, IL • Community Health Center'), findsOneWidget);
    expect(find.textContaining('Clybourn'), findsNothing);
    expect(find.text('Clinic for the whole family'), findsNothing);
    expect(find.text(_l10n(tester).cardDirections), findsNothing);
  });

  testWidgets('the second line drops whichever part is missing',
      (tester) async {
    await _pumpCard(tester, createTestFacility());
    expect(find.text('Chicago, IL'), findsOneWidget);

    await _pumpCard(
      tester,
      createTestFacility(city: '', state: '', categoryDetail: 'Food Pantry'),
    );
    expect(find.text('Food Pantry'), findsOneWidget);
  });

  testWidgets('expanded, the street address sits under Directions',
      (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(
        address: '35 E Wacker Dr, Chicago, IL 60601',
        categoryDetail: 'Legal Aid',
      ),
      isExpanded: true,
    );

    final address = find.text('35 E Wacker Dr, Chicago, IL 60601');
    expect(address, findsOneWidget);
    expect(
      tester.getTopLeft(address).dy,
      greaterThan(
        tester.getTopLeft(find.text(_l10n(tester).cardDirections)).dy,
      ),
    );
    // The header keeps its short line.
    expect(find.text('Chicago, IL • Legal Aid'), findsOneWidget);
  });

  testWidgets('a tap copies the street address and says so on iOS',
      (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await _pumpCard(
      tester,
      createTestFacility(address: '35 E Wacker Dr, Chicago, IL 60601'),
      isExpanded: true,
    );
    final l10n = _l10n(tester);

    // The copy icon is the cue; the whole row is the target.
    expect(find.byIcon(Icons.content_copy_outlined), findsOneWidget);
    await tester.tap(find.text('35 E Wacker Dr, Chicago, IL 60601'));
    await tester.pump();

    expect(copied, '35 E Wacker Dr, Chicago, IL 60601');
    expect(find.text(l10n.cardAddressCopied), findsOneWidget);
    expect(
      tester.getSemantics(find.text('35 E Wacker Dr, Chicago, IL 60601')),
      isSemantics(onTapHint: l10n.cardCopyAddress),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('a one-line address sits midway between buttons and divider',
      (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(
        address: '35 E Wacker Dr, Chicago, IL 60601',
        description: 'Free legal aid',
      ),
      isExpanded: true,
      size: const Size(1200, 844),
    );
    final address =
        tester.getRect(find.text('35 E Wacker Dr, Chicago, IL 60601'));
    final buttons = tester.getRect(
      find
          .ancestor(
            of: find.text(_l10n(tester).cardDirections),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          )
          .first,
    );
    // The divider's line is drawn at the middle of its box.
    final divider = tester
        .widgetList<Divider>(find.byType(Divider))
        .map((d) => tester.getRect(find.byWidget(d)))
        .where((r) => r.top > address.bottom)
        .reduce((a, b) => a.top < b.top ? a : b);

    final above = address.top - buttons.bottom;
    final below = divider.center.dy - address.bottom;
    expect((above - below).abs(), lessThanOrEqualTo(AppSpacing.xs));
  });

  testWidgets('the free chip says what is free', (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(
        eligibility: const FacilityEligibility(
          freeServicesAvailable: EligibilityValue.yes,
        ),
      ),
      isExpanded: true,
    );
    expect(find.text('Free services available'), findsOneWidget);
    expect(find.text('Free'), findsNothing);
  });

  test('only iOS gets the app\'s own "copied" message', () {
    expect(FacilityCard.confirmsCopy(TargetPlatform.iOS), isTrue);
    expect(FacilityCard.confirmsCopy(TargetPlatform.android), isFalse);
  });

  testWidgets('shows when the listing was last checked, and only then',
      (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(lastCheckedAt: DateTime(2026, 10, 3, 12)),
      isExpanded: true,
    );
    expect(find.text('Last updated: 10/03/2026'), findsOneWidget);

    await _pumpCard(tester, createTestFacility(), isExpanded: true);
    expect(find.textContaining('Last updated'), findsNothing);
  });

  testWidgets('the whole row shows the details, the arrow included',
      (tester) async {
    var toggles = 0;
    await _pumpCard(
      tester,
      createTestFacility(name: 'CARPLS'),
      onToggleExpand: () => toggles++,
    );
    await tester.tap(find.text('CARPLS'));
    // The arrow is only a cue: a tap on it lands on the row beneath.
    await tester.tap(find.byIcon(Icons.expand_more));
    expect(toggles, 2);
  });

  testWidgets('a row is one button that says what it will do', (tester) async {
    await _pumpCard(tester, createTestFacility(name: 'CARPLS'));
    final l10n = _l10n(tester);

    expect(
      tester.getSemantics(find.text('CARPLS')),
      isSemantics(isButton: true, onTapHint: l10n.cardShowDetails),
    );
    // The arrow isn't a second control to find.
    expect(find.byTooltip(l10n.cardShowDetails), findsNothing);

    await _pumpCard(
      tester,
      createTestFacility(name: 'CARPLS'),
      isExpanded: true,
    );
    expect(
      tester.getSemantics(find.text('CARPLS')),
      isSemantics(isButton: true, onTapHint: l10n.cardHideDetails),
    );
  });

  testWidgets('a long name is one line until the row opens', (tester) async {
    const name = 'Public Health Institute Of Metropolitan Chicago Downtown';
    Text nameText() => tester.widget<Text>(find.text(name));

    await _pumpCard(tester, createTestFacility(name: name));
    expect(nameText().maxLines, 1);
    expect(nameText().overflow, TextOverflow.ellipsis);

    await _pumpCard(tester, createTestFacility(name: name), isExpanded: true);
    expect(nameText().maxLines, isNull);
  });

  testWidgets('the arrow sits at the bottom-right of a longer header',
      (tester) async {
    // A name that wraps once the row opens: the arrow follows it down rather
    // than sitting halfway up the text.
    const name = 'Public Health Institute Of Metropolitan Chicago Downtown';
    await _pumpCard(
      tester,
      createTestFacility(name: name, categoryDetail: 'Community Clinic'),
      isExpanded: true,
    );
    final caption = tester.getRect(
      find.text('Chicago, IL • Community Clinic'),
    );
    final arrow = tester.getRect(find.byIcon(Icons.expand_less));
    final card = tester.getRect(find.byType(Card));

    expect(arrow.bottom, greaterThanOrEqualTo(caption.bottom));
    expect(card.right - arrow.right, lessThan(AppSizes.minTouchTarget / 2));
    expect(
      arrow.bottom,
      lessThanOrEqualTo(tester.getTopLeft(find.text('Directions')).dy),
    );
  });

  testWidgets('the arrow tucks under the heart, keeping a short row short',
      (tester) async {
    await _pumpCard(
      tester,
      createTestFacility(name: 'CARPLS', categoryDetail: 'Legal'),
    );
    final heart = tester.getRect(
      find.ancestor(
        of: find.byTooltip(_l10n(tester).cardSave('CARPLS')),
        matching: find.byType(IconButton),
      ),
    );
    final arrow = tester.getRect(find.byIcon(Icons.expand_more));

    expect(arrow.center.dx, closeTo(heart.center.dx, 1));
    expect(arrow.top, greaterThan(heart.top));
    // It was 72 tall when the arrow was a button of its own.
    expect(
      tester.getSize(find.byType(Card)).height,
      lessThan(AppSizes.minTouchTarget + AppIconSize.lg + 2 * AppSpacing.xs),
    );
  });

  group('hours', () {
    const week = [
      OperatingHours(day: 'mon', opensAt: '09:00', closesAt: '17:00'),
      OperatingHours(day: 'tue', opensAt: '09:00', closesAt: '17:00'),
      OperatingHours(day: 'wed', opensAt: '09:00', closesAt: '17:00'),
      OperatingHours(day: 'thu', opensAt: '09:00', closesAt: '17:00'),
      OperatingHours(day: 'fri', opensAt: '09:00', closesAt: '16:00'),
    ];

    testWidgets('a week sits in two columns, read down then across',
        (tester) async {
      // One column left half the card empty beside it. The test font is
      // about twice as wide as Inter, so the screen is too.
      await _pumpCard(
        tester,
        createTestFacility(hours: week),
        isExpanded: true,
        size: const Size(780, 844),
      );

      final mon = tester.getTopLeft(find.text('Mon'));
      final wed = tester.getTopLeft(find.text('Wed'));
      final thu = tester.getTopLeft(find.text('Thu'));
      expect(wed.dx, mon.dx);
      expect(wed.dy, greaterThan(mon.dy));
      expect(thu.dy, mon.dy);
      expect(thu.dx, greaterThan(mon.dx));
    });

    testWidgets('stays in one column when two would not fit', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 3.1;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpCard(
        tester,
        createTestFacility(hours: week),
        isExpanded: true,
      );

      expect(
        tester.getTopLeft(find.text('Thu')).dx,
        tester.getTopLeft(find.text('Mon')).dx,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a rule runs between the two columns, and none beside one',
        (tester) async {
      await _pumpCard(
        tester,
        createTestFacility(hours: week),
        isExpanded: true,
        size: const Size(780, 844),
      );
      final rule = tester.getRect(find.byType(DashedVerticalDivider));
      expect(rule.left, greaterThan(tester.getTopLeft(find.text('Mon')).dx));
      expect(
        rule.right,
        lessThanOrEqualTo(tester.getTopLeft(find.text('Thu')).dx),
      );
      // As tall as the longer column.
      expect(rule.top, lessThanOrEqualTo(tester.getRect(find.text('Mon')).top));
      expect(
        rule.bottom,
        greaterThanOrEqualTo(tester.getRect(find.text('Wed')).bottom),
      );

      await _pumpCard(
        tester,
        createTestFacility(hours: week.sublist(0, 3)),
        isExpanded: true,
      );
      expect(find.byType(DashedVerticalDivider), findsNothing);
    });

    testWidgets('a closed day and an unknown day say which they are',
        (tester) async {
      await _pumpCard(
        tester,
        createTestFacility(
          hours: const [
            OperatingHours(day: 'mon', opensAt: '09:00', closesAt: '17:00'),
            OperatingHours(day: 'sat'),
            OperatingHours(day: 'sun', isClosed: true),
          ],
        ),
        isExpanded: true,
      );
      final l10n = _l10n(tester);

      double rowOf(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(rowOf(l10n.cardHoursUnknown), rowOf('Sat'));
      expect(rowOf(l10n.cardHoursClosed), rowOf('Sun'));
    });

    testWidgets('a divider closes the section before the links under it',
        (tester) async {
      await _pumpCard(
        tester,
        createTestFacility(hours: week),
        isExpanded: true,
        onRate: () {},
      );
      final l10n = _l10n(tester);
      final hours = tester.getTopLeft(find.text(l10n.cardHours)).dy;
      final rate = tester
          .getTopLeft(find.textContaining(l10n.cardRatePromptAction).last)
          .dy;

      final between =
          tester.widgetList<Divider>(find.byType(Divider)).where((divider) {
        final y = tester.getTopLeft(find.byWidget(divider)).dy;
        return y > hours && y < rate;
      });
      expect(between, hasLength(1));
    });

    testWidgets('a few days stay in one column', (tester) async {
      await _pumpCard(
        tester,
        createTestFacility(hours: week.sublist(0, 3)),
        isExpanded: true,
      );

      expect(
        tester.getTopLeft(find.text('Wed')).dx,
        tester.getTopLeft(find.text('Mon')).dx,
      );
    });
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

  testWidgets('the heart is full-size and named', (tester) async {
    await _pumpCard(tester, createTestFacility(name: 'CARPLS'));
    final heart = find.byTooltip(_l10n(tester).cardSave('CARPLS'));
    expect(heart, findsOneWidget);
    final size = tester.getSize(
      find.ancestor(of: heart, matching: find.byType(IconButton)).first,
    );
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
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
