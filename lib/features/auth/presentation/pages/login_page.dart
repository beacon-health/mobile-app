import 'package:beacon_app/core/constants/legal_urls.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/passkey_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/native_sign_in_button.dart';
import 'package:beacon_app/features/auth/presentation/pages/create_passkey_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/location_choice_page.dart';
import 'package:beacon_app/features/map/presentation/services/url_launcher_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Sign-in entry point: a language picker, then up to three ways in, in this
/// order — a passkey (where `PasskeyService` offers one), the platform's
/// native provider (Apple on iOS, Google on Android), and Continue as guest.
/// There is no email or password. [isGuestUpgrade]
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

  // Owned here, not built inline: a recognizer made in `build` is never
  // disposed.
  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => _openLegal(LegalUrls.termsOfUse);
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => _openLegal(LegalUrls.privacyPolicy);

  void _openLegal(String url) =>
      UrlLauncherService.launchUrlString(url, context);

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _continueAsGuest() {
    _goToLocationChoice();
  }

  bool get _offersPasskey => PasskeyService.isOfferedOn(defaultTargetPlatform);

  Future<void> _signInWithPasskey() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final outcome = await PasskeyService.instance.signIn();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = false;
      _errorMessage = switch (outcome) {
        // Closing the sheet is a choice, not an error.
        PasskeyOutcome.success || PasskeyOutcome.cancelled => null,
        PasskeyOutcome.noPasskey => l10n.authNoPasskey,
        PasskeyOutcome.unavailable => l10n.authPasskeyUnavailable,
        PasskeyOutcome.failed => l10n.authSignInError,
      };
    });
    if (outcome == PasskeyOutcome.success) _goToLocationChoice();
  }

  /// After a first Apple or Google sign-in: offer a passkey for next time,
  /// once, then carry on whatever the answer.
  Future<void> _afterNativeSignIn() async {
    if (_offersPasskey && !await PasskeyService.instance.hasPasskey()) {
      if (!mounted) return;
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const CreatePasskeyPage()),
      );
    }
    if (mounted) _goToLocationChoice();
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
                  // Each language under its own name, not the current one's.
                  title: Text(
                    LocaleProvider.localeDisplayNames[locale.languageCode] ??
                        locale.languageCode,
                    locale: locale,
                  ),
                  selected: locale.languageCode == currentCode,
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
    final muted = theme.colorScheme.onSurfaceVariant;
    final languageCode = context.watch<LocaleProvider>().locale.languageCode;
    final language =
        LocaleProvider.localeDisplayNames[languageCode] ?? languageCode;
    final legalLink = TextStyle(
      color: theme.colorScheme.onSurface,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.onboarding(context),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.onboardingGutter,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          // First thing on the first screen, and in the
                          // language itself, so nobody has to read English to
                          // find it.
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton.icon(
                              onPressed:
                                  _isLoading ? null : _showLanguagePicker,
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.secondary,
                              ),
                              icon: const Icon(Icons.language),
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      language,
                                      // "Language: English. Change language"
                                      semanticsLabel:
                                          l10n.authLanguageButton(language),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Image.asset(
                            'assets/beacon-logo.png',
                            width: AppSizes.logoHero,
                            excludeFromSemantics: true,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            l10n.onboardingTagline,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.huge),
                          if (_offersPasskey) ...[
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                    _isLoading ? null : _signInWithPasskey,
                                style: AppTheme.secondaryFilledButton(context),
                                icon: const Icon(Icons.key),
                                label: Text(l10n.authSignInWithPasskey),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          NativeSignInButton(
                            onSuccess: _afterNativeSignIn,
                            onFailure: (message) =>
                                setState(() => _errorMessage = message),
                            onLoadingChanged: (loading) => setState(() {
                              _isLoading = loading;
                              if (loading) _errorMessage = null;
                            }),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                child: Text(
                                  l10n.authOr,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: muted,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _continueAsGuest,
                              style: AppTheme.secondaryOutlinedButton(context),
                              child: Text(l10n.authContinueAsGuest),
                            ),
                          ),
                          if (_offersPasskey) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.authPasskeyHint,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xxl,
                        ),
                        child: Text.rich(
                          TextSpan(
                            text: l10n.authTermsPrefix,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: muted,
                            ),
                            children: [
                              TextSpan(
                                text: l10n.authTermsOfService,
                                style: legalLink,
                                recognizer: _termsTap,
                              ),
                              TextSpan(text: l10n.authAnd),
                              TextSpan(
                                text: l10n.authPrivacyPolicy,
                                style: legalLink,
                                recognizer: _privacyTap,
                              ),
                              TextSpan(text: l10n.authTermsSuffix),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
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
