@Tags(['golden'])
library;

import 'package:beacon_app/features/auth/presentation/pages/eligibility_onboarding_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/location_choice_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/login_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/zip_entry_page.dart';
import 'package:beacon_app/features/profile/presentation/pages/profile_page.dart';
import 'package:beacon_app/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// A full screen captured at phone size.
///
/// [perPlatform] screens contain something intentionally native — the
/// Apple/Google sign-in button, or the platform text cursor — so each
/// platform gets its own image. Every other screen must render identically
/// on iOS and Android: both variants compare against one shared image.
///
/// Home and Map aren't covered: they need Google Maps and a Supabase client,
/// which the app doesn't inject yet.
class _Screen {
  const _Screen(
    this.name,
    this.build, {
    this.perPlatform = false,
    this.brightnesses = Brightness.values,
  });

  final String name;
  final Widget Function() build;
  final bool perPlatform;
  final List<Brightness> brightnesses;
}

final _screens = [
  _Screen('login', () => const LoginPage(), perPlatform: true),
  _Screen('location_choice', () => const LocationChoicePage()),
  _Screen('zip_entry', () => const ZipEntryPage(), perPlatform: true),
  _Screen('eligibility_onboarding', () => const EligibilityOnboardingPage()),
  _Screen('settings', () => const SettingsPage()),
  _Screen(
    'profile_guest',
    () => const ProfilePage(),
    perPlatform: true,
    brightnesses: const [Brightness.light],
  ),
];

void main() {
  setUp(mockPlatformServices);

  for (final screen in _screens) {
    for (final brightness in screen.brightnesses) {
      testWidgets(
        '${screen.name} (${brightness.name})',
        (tester) async {
          // Hold the text cursor solid so autofocused fields don't blink
          // (which would also keep pumpAndSettle from ever settling).
          EditableText.debugDeterministicCursor = true;
          try {
            await pumpThemed(tester, screen.build(), brightness: brightness);
            await precacheImages(tester);

            final platform =
                screen.perPlatform ? '_${defaultTargetPlatform.name}' : '';
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                'images/${screen.name}$platform'
                '_${brightness.name}.png',
              ),
            );
          } finally {
            EditableText.debugDeterministicCursor = false;
          }
        },
        variant: shippingPlatforms,
        skip: goldensSkipped,
      );
    }
  }
}
