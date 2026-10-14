import 'package:beacon_app/features/map/presentation/widgets/search/facility_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  late TextEditingController controller;
  late FocusNode focusNode;

  setUp(() {
    mockPlatformServices();
    controller = TextEditingController();
    focusNode = FocusNode();
  });
  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  Future<void> pumpSearch(WidgetTester tester, {VoidCallback? onClear}) =>
      pumpThemed(
        tester,
        Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FacilitySearch(
              controller: controller,
              focusNode: focusNode,
              onChanged: () => setState(() {}),
              onClear: onClear ?? () {},
              onUseMyLocation: () {},
            ),
          ),
        ),
      );

  testWidgets('draws no outline of its own inside the search pill',
      (tester) async {
    // The app-wide outlined input style would put a box inside the pill.
    await pumpSearch(tester);

    final decoration =
        tester.widget<TextField>(find.byType(TextField)).decoration!;
    expect(decoration.enabledBorder, InputBorder.none);
    expect(decoration.focusedBorder, InputBorder.none);
    expect(decoration.border, InputBorder.none);
  });

  testWidgets('both of its icon buttons have names', (tester) async {
    var cleared = 0;
    await pumpSearch(tester, onClear: () => cleared++);
    expect(find.byTooltip('Use my location'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'clinic');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear text'));

    expect(cleared, 1);
    expect(controller.text, isEmpty);
  });
}
