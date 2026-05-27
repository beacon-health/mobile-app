import 'package:beacon_app/core/services/demo_mode_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/features/auth/presentation/pages/onboarding_page.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Root gate that picks the initial screen based on demo + onboarding state.
///
/// Routing:
///   demo mode                 → MainNavBar (with brief splash)
///   hasCompletedOnboarding    → MainNavBar
///   else                      → OnboardingPage (welcome → LoginPage → …)
///
/// Supabase session persistence keeps signed-in users on MainNavBar across
/// restarts; the `hasCompletedOnboarding` SharedPreferences flag is what
/// determines whether a user needs to walk through the auth + location flow.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _demoLoading = true;

  @override
  void initState() {
    super.initState();
    final demoMode = context.read<DemoModeService>();
    if (demoMode.isDemoMode) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _demoLoading = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final demoMode = context.watch<DemoModeService>();

    if (demoMode.isDemoMode) {
      if (_demoLoading) {
        return _buildDemoLoadingScreen(context);
      }
      return const MainNavBar();
    }

    final zipService = context.watch<ZipCodeService>();
    if (zipService.hasCompletedOnboarding) {
      return const MainNavBar();
    }

    return const OnboardingPage();
  }

  Widget _buildDemoLoadingScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/beacon-logo.png', width: 200),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n?.authSigningIn ?? 'Signing in...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
