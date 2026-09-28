import 'package:beacon_app/features/map/presentation/services/url_launcher_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

/// Drives UrlLauncherService through url_launcher's method channel, the
/// implementation plugins fall back to under `flutter test`.
void main() {
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  final launches = <Map<Object?, Object?>>[];

  /// Answers each launch with [inApp] when it asks for the in-app browser
  /// and [external] otherwise.
  void mockLauncher({required bool inApp, required bool external}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'launch') return null;
      final args = call.arguments as Map<Object?, Object?>;
      launches.add(args);
      return args['useSafariVC'] == true ? inApp : external;
    });
  }

  setUp(() {
    launches.clear();
    mockPlatformServices();
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  Future<void> open(WidgetTester tester, String url) async {
    await pumpThemed(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => UrlLauncherService.launchUrlString(url, context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  String linkFailed(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold)))!
          .commonLinkFailed;

  testWidgets('websites open in the in-app browser first', (tester) async {
    mockLauncher(inApp: true, external: true);
    await open(tester, 'https://example.org');
    expect(launches, hasLength(1));
    expect(launches.single['useSafariVC'], isTrue);
  });

  // BEACON-8: SFSafariViewController reported a failed first load for a
  // site Safari opens fine, and the user got "Could not open that link".
  testWidgets('falls back to the external browser when in-app fails',
      (tester) async {
    mockLauncher(inApp: false, external: true);
    await open(tester, 'http://www.maryvilleacademy.org');
    expect(launches.map((a) => a['useSafariVC']), [true, false]);
    expect(find.text(linkFailed(tester)), findsNothing);
  });

  testWidgets('tells the user when neither browser can open the link',
      (tester) async {
    mockLauncher(inApp: false, external: false);
    await open(tester, 'https://example.org');
    expect(launches, hasLength(2));
    expect(find.text(linkFailed(tester)), findsOneWidget);
  });

  testWidgets('map links go straight to the external app', (tester) async {
    mockLauncher(inApp: true, external: true);
    await open(tester, 'https://maps.google.com/?q=Chicago');
    expect(launches, hasLength(1));
    expect(launches.single['useSafariVC'], isFalse);
  });
}
