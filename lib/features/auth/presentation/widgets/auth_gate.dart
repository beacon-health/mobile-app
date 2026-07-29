import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/features/auth/presentation/pages/onboarding_page.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Root gate that picks the initial screen based on onboarding state.
///
/// Supabase session persistence keeps signed-in users on MainNavBar across
/// restarts; the `hasCompletedOnboarding` SharedPreferences flag is what
/// determines whether a user needs to walk through the auth + location flow.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final zipService = context.watch<ZipCodeService>();
    if (zipService.hasCompletedOnboarding) {
      return const MainNavBar();
    }
    return const OnboardingPage();
  }
}
