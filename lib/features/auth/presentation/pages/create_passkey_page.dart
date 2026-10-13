import 'package:beacon_app/core/services/passkey_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Offers a signed-in person a passkey: what it is for, an optional name,
/// and "Not now". Pops `true` once one has been created.
///
/// Shown after the first Apple or Google sign-in and from Profile. The
/// system's own sheet does the creating; this page only leads up to it.
class CreatePasskeyPage extends StatefulWidget {
  const CreatePasskeyPage({super.key});

  @override
  State<CreatePasskeyPage> createState() => _CreatePasskeyPageState();
}

class _CreatePasskeyPageState extends State<CreatePasskeyPage> {
  final TextEditingController _name = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final outcome = await PasskeyService.instance.create(name: _name.text);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    switch (outcome) {
      case PasskeyOutcome.success:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.passkeyCreated)),
        );
        Navigator.pop(context, true);
      // Closing the system sheet is a choice: stay here, say nothing.
      case PasskeyOutcome.cancelled:
        setState(() => _busy = false);
      case PasskeyOutcome.unavailable:
        setState(() {
          _busy = false;
          _error = l10n.authPasskeyUnavailable;
        });
      case PasskeyOutcome.noPasskey:
      case PasskeyOutcome.failed:
        setState(() {
          _busy = false;
          _error = l10n.passkeyCreateFailed;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget benefit(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.secondary),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
            ],
          ),
        );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppGradients.onboarding(context)),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.sm,
                    top: AppSpacing.sm,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: _busy ? null : () => Navigator.pop(context),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.onboardingGutter,
                    AppSpacing.lg,
                    AppSpacing.onboardingGutter,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.key,
                        size: AppIconSize.hero,
                        color: scheme.secondary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.passkeyCreateTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: scheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      benefit(Icons.fingerprint, l10n.passkeyBenefitFast),
                      benefit(
                        Icons.password_outlined,
                        l10n.passkeyBenefitNoPassword,
                      ),
                      benefit(Icons.lock_outline, l10n.passkeyBenefitPrivate),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _name,
                        enabled: !_busy,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: l10n.passkeyNameLabel,
                          helperText: l10n.passkeyNameHelper,
                          errorText: _error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.onboardingGutter,
                  AppSpacing.sm,
                  AppSpacing.onboardingGutter,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _busy ? null : _create,
                      child: _busy
                          ? SizedBox.square(
                              dimension: AppIconSize.md,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : Text(l10n.passkeyCreate),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.secondary,
                      ),
                      child: Text(l10n.passkeyNotNow),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
