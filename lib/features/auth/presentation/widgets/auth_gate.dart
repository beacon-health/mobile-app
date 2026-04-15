import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beacon_app/core/services/demo_mode_service.dart';
import 'package:beacon_app/features/auth/presentation/pages/login_page.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:beacon_app/l10n/app_localizations.dart';

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

    // Normal Supabase auth flow
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    if (session != null) {
      return const MainNavBar();
    }

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        final event = snapshot.data!.event;
        final session = snapshot.data!.session;

        if (event == AuthChangeEvent.signedIn && session != null) {
          return const MainNavBar();
        }

        return const LoginPage();
      },
    );
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
