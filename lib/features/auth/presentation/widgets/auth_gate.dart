import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/features/auth/presentation/pages/onboarding_page.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Picks the initial screen from the `hasCompletedOnboarding` flag; Supabase
/// session persistence keeps signed-in users on MainNavBar across restarts.
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
