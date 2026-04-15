import 'package:flutter_test/flutter_test.dart';

import 'package:beacon_app/app.dart';

void main() {
  testWidgets('App starts and shows home page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BeaconApp());

    // Verify that the home page is shown
    expect(find.text('Welcome to Beacon!'), findsOneWidget);
  });
}
