import 'package:beacon_app/core/services/coverage_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/features/auth/presentation/pages/zip_entry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';

import '../../helpers/pump_app.dart';

void main() {
  final zipService = ZipCodeService();
  final coverage = CoverageService();
  late int geocodeCalls;

  setUp(() async {
    mockPlatformServices();
    await zipService.clear();
    coverage
      ..debugReset()
      ..debugSetStates(['IL', 'OK']);
    geocodeCalls = 0;
    zipService.debugGeocode = (_) async {
      geocodeCalls++;
      return [
        Location(latitude: 41.88, longitude: -87.63, timestamp: DateTime(2026)),
      ];
    };
  });
  tearDown(() {
    zipService.debugGeocode = null;
    coverage.debugReset();
  });

  Future<void> submit(WidgetTester tester, String zip, {Locale? locale}) async {
    await pumpThemed(
      tester,
      const ZipEntryPage(),
      locale: locale ?? const Locale('en'),
    );
    await tester.enterText(find.byType(TextFormField), zip);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
  }

  testWidgets('a ZIP outside coverage is turned away with the reason',
      (tester) async {
    await submit(tester, '75001');

    expect(
      find.text(
        "Beacon isn't available in that area yet. It currently covers "
        'Illinois and Oklahoma.',
      ),
      findsOneWidget,
    );
    expect(zipService.zipCode, isNull);
    expect(zipService.hasCompletedOnboarding, isFalse);
    expect(geocodeCalls, 0);
  });

  testWidgets('the reason is translated', (tester) async {
    // This message was hardcoded English in 1.0.0.
    await submit(tester, '75001', locale: const Locale('es'));

    expect(
      find.text(
        'Beacon aún no está disponible en esa zona. Por ahora cubre '
        'Illinois y Oklahoma.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a ZIP that does not exist says it could not be found',
      (tester) async {
    await submit(tester, '00000');

    expect(
        find.text("Couldn't find that ZIP code. Try again."), findsOneWidget);
    expect(zipService.zipCode, isNull);
  });

  testWidgets('fewer than five digits never reaches the lookup',
      (tester) async {
    await submit(tester, '6060');

    expect(find.text('Please enter a 5-digit zip code'), findsOneWidget);
    expect(geocodeCalls, 0);
  });

  testWidgets('the field takes digits only, five at most', (tester) async {
    await pumpThemed(tester, const ZipEntryPage());

    await tester.enterText(find.byType(TextFormField), '6a0b6c0d1e99');

    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '60601',
    );
  });

  testWidgets('names the launched states under the field', (tester) async {
    await pumpThemed(tester, const ZipEntryPage());

    expect(
      find.textContaining('facilities in Illinois and Oklahoma.'),
      findsOneWidget,
    );
  });
}
