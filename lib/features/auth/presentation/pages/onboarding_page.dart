import 'package:beacon_app/core/constants/legal_urls.dart';
import 'package:beacon_app/core/theme/app_gradients.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/core/theme/color_scheme_ext.dart';
import 'package:beacon_app/features/auth/presentation/pages/login_page.dart';
import 'package:beacon_app/features/map/presentation/services/url_launcher_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// First-launch welcome screen. Surfaces the app value proposition and a
/// single CTA to the auth flow.
///
/// Shown by [AuthGate] when `hasCompletedOnboarding` is false. Tapping
/// "Get Started" pushes [LoginPage]; after sign-in (or guest continue), the
/// user reaches [LocationChoicePage] and ultimately [MainNavBar].
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.onboarding(context),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/beacon-logo.png', width: 240),
                    const SizedBox(height: 32),
                    Text(
                      l10n.onboardingTagline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: AppTheme.paynesGray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.onboardingSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurfaceSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppTheme.paynesGray,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        child: Text(l10n.onboardingGetStarted),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Builder(
                  builder: (innerContext) => Text.rich(
                    TextSpan(
                      text: l10n.authTermsPrefix,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: l10n.authTermsOfService,
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => UrlLauncherService.launchUrlString(
                                  LegalUrls.termsOfUse,
                                  innerContext,
                                ),
                        ),
                        TextSpan(text: l10n.authAnd),
                        TextSpan(
                          text: l10n.authPrivacyPolicy,
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => UrlLauncherService.launchUrlString(
                                  LegalUrls.privacyPolicy,
                                  innerContext,
                                ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
