import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/eligibility_checklist.dart';
import 'package:beacon_app/features/auth/presentation/widgets/onboarding_scaffold.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Finishes the location step of onboarding by moving on to the last one,
/// [EligibilityOnboardingPage]. Pushed rather than swapped in, so its back
/// button returns to the location the person just gave.
void finishLocationOnboarding(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => const EligibilityOnboardingPage(),
    ),
  );
}

/// Last onboarding step, for guests and signed-in users alike: what the
/// person can provide. The answers filter the map and stay editable on the
/// Profile tab — on the device for a guest, with the account otherwise.
///
/// "Continue" turns the filter on, even with nothing checked (that is an
/// answer: I have none of these). "Skip for now" leaves it off, so nothing is
/// hidden on the strength of a question nobody answered.
class EligibilityOnboardingPage extends StatefulWidget {
  const EligibilityOnboardingPage({super.key});

  @override
  State<EligibilityOnboardingPage> createState() =>
      _EligibilityOnboardingPageState();
}

class _EligibilityOnboardingPageState extends State<EligibilityOnboardingPage> {
  late EligibilityState _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft = EligibilityPreferencesService().eligibility;
  }

  Future<void> _finish({required bool applyToSearch}) async {
    setState(() => _saving = true);
    await EligibilityPreferencesService()
        .updateEligibility(_draft.copyWith(applyToSearch: applyToSearch));
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const MainNavBar()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return OnboardingScaffold(
      step: 2,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: _saving ? null : () => _finish(applyToSearch: true),
            style: AppTheme.secondaryFilledButton(context),
            child: _saving
                ? SizedBox.square(
                    dimension: AppIconSize.md,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onSecondary,
                    ),
                  )
                : Text(l10n.onboardingContinue),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: _saving ? null : () => _finish(applyToSearch: false),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.secondary,
            ),
            child: Text(l10n.onboardingSkip),
          ),
        ],
      ),
      children: [
        OnboardingHeading(
          title: l10n.onboardingEligibilityTitle,
          subtitle: l10n.onboardingEligibilitySubtitle,
        ),
        const SizedBox(height: AppSpacing.xl),
        EligibilityChecklist(
          value: _draft,
          showExamples: true,
          onChanged: (next) => setState(() => _draft = next),
        ),
      ],
    );
  }
}
