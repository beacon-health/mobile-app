import 'package:beacon_app/core/constants/legal_urls.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/native_sign_in_button.dart';
import 'package:beacon_app/features/auth/presentation/pages/location_choice_page.dart';
import 'package:beacon_app/features/map/presentation/services/url_launcher_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Sign-in entry point: the platform's native provider (Apple on iOS, Google
/// on Android) + Continue as Guest. [isGuestUpgrade]
/// routes through [LocationChoicePage] with the guest's ZIP pre-filled and
/// replaces the navigation stack.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.isGuestUpgrade = false});

  final bool isGuestUpgrade;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  String? _errorMessage;

  void _continueAsGuest() {
    _goToLocationChoice();
  }

  void _goToLocationChoice() {
    final prefilledZip =
        widget.isGuestUpgrade ? ZipCodeService().zipCode : null;
    if (widget.isGuestUpgrade) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LocationChoicePage(prefilledZip: prefilledZip),
        ),
        (route) => false,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LocationChoicePage(prefilledZip: prefilledZip),
        ),
      );
    }
  }

  Future<void> _showLanguagePicker() async {
    final localeProvider = context.read<LocaleProvider>();
    final currentCode = localeProvider.locale.languageCode;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sheetGutter,
                  AppSpacing.xs,
                  AppSpacing.sheetGutter,
                  AppSpacing.md,
                ),
                child: Text(
                  AppLocalizations.of(ctx)?.authSelectLanguage ??
                      'Select a language',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              for (final locale in LocaleProvider.supportedLocales)
                ListTile(
                  title: Text(
                    LocaleProvider.localeDisplayNames[locale.languageCode] ??
                        locale.languageCode,
                  ),
                  trailing: locale.languageCode == currentCode
                      ? Icon(
                          Icons.check,
                          color: Theme.of(ctx).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, locale.languageCode),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null && selected != currentCode) {
      await localeProvider.setLocale(Locale(selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceMuted;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.onboarding(context),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.onboardingGutter,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: AppSpacing.xxxl),
                          Image.asset(
                            'assets/beacon-logo.png',
                            width: AppSizes.logoHero,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          Text(
                            l10n.onboardingTagline,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(
                            height: AppSpacing.huge + AppSpacing.xxl,
                          ),
                          NativeSignInButton(
                            onSuccess: _goToLocationChoice,
                            onFailure: (message) =>
                                setState(() => _errorMessage = message),
                            onLoadingChanged: (loading) => setState(() {
                              _isLoading = loading;
                              if (loading) _errorMessage = null;
                            }),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _errorMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xxl),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                child: Text(
                                  l10n.authOr,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: muted,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _continueAsGuest,
                              style: AppTheme.secondaryFilledButton(context),
                              child: Text(l10n.authContinueAsGuest),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          Text.rich(
                            TextSpan(
                              text: l10n.authTermsPrefix,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                              children: [
                                TextSpan(
                                  text: l10n.authTermsOfService,
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () =>
                                        UrlLauncherService.launchUrlString(
                                          LegalUrls.termsOfUse,
                                          context,
                                        ),
                                ),
                                TextSpan(text: l10n.authAnd),
                                TextSpan(
                                  text: l10n.authPrivacyPolicy,
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () =>
                                        UrlLauncherService.launchUrlString(
                                          LegalUrls.privacyPolicy,
                                          context,
                                        ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextButton(
                            onPressed: _isLoading ? null : _showLanguagePicker,
                            child: Text(l10n.authSelectLanguage),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
