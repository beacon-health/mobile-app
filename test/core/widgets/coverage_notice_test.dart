import 'package:beacon_app/core/services/coverage_service.dart';
import 'package:beacon_app/core/widgets/coverage_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  final coverage = CoverageService();

  setUp(() {
    mockPlatformServices();
    coverage.debugReset();
  });
  tearDown(coverage.debugReset);

  Future<void> pumpNotice(WidgetTester tester) => pumpThemed(
        tester,
        const Scaffold(body: CoverageNotice()),
      );

  testWidgets('names the one launched state', (tester) async {
    await pumpNotice(tester);

    expect(
      find.text(
        'Beacon currently shows facilities in Illinois. '
        "We're adding more states over time.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('follows the list when another state launches', (tester) async {
    await pumpNotice(tester);

    coverage.debugSetStates(['IL', 'OK']);
    await tester.pump();

    expect(
      find.textContaining('facilities in Illinois and Oklahoma.'),
      findsOneWidget,
    );
  });

  testWidgets('disappears once every state is live', (tester) async {
    coverage.debugSetStates([CoverageService.nationwideCode]);

    await pumpNotice(tester);

    expect(find.byType(Text), findsNothing);
    expect(find.byIcon(Icons.info_outline), findsNothing);
  });
}
