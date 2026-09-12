import 'package:beacon_app/core/constants/legal_urls.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/app_gradients.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  AppLocalizations.of(ctx)?.authSelectLanguage ??
                      'Select a language',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final locale in LocaleProvider.supportedLocales)
                ListTile(
                  title: Text(
                    LocaleProvider.localeDisplayNames[locale.languageCode] ??
                        locale.languageCode,
                  ),
                  trailing: locale.languageCode == currentCode
                      ? const Icon(Icons.check, color: AppTheme.resedaGreen)
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.onboarding(context),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
                          const SizedBox(height: 32),
                          Image.asset('assets/beacon-logo.png', width: 240),
                          const SizedBox(height: 24),
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
                          const SizedBox(height: 72),
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
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: Colors.black26),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  l10n.authOr,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: Colors.black26),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _continueAsGuest,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                backgroundColor: AppTheme.paynesGray,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              child: Text(l10n.authContinueAsGuest),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          Text.rich(
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
                                    fontWeight: FontWeight.bold,
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
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isLoading ? null : _showLanguagePicker,
                            child: Text(
                              l10n.authSelectLanguage,
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
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
