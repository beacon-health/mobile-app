import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Finishes the location step of onboarding, routing to the required
/// Eligibility step for **signed-in** users and straight to the app for guests
/// (who can't set eligibility — the Profile tab is gated).
void finishLocationOnboarding(BuildContext context) {
  final isSignedIn = Supabase.instance.client.auth.currentUser != null;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          isSignedIn ? const EligibilityOnboardingPage() : const MainNavBar(),
    ),
    (route) => false,
  );
}

/// Required onboarding step for signed-in users: pick eligibility gates. They
/// auto-filter the map and stay editable on the Profile tab; selecting none is
/// allowed, skipping the screen is not.
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

  Future<void> _continue() async {
    setState(() => _saving = true);
    // Persist (and sync) the picks; eligibility applies to search by default.
    await EligibilityPreferencesService()
        .updateEligibility(_draft.copyWith(applyToSearch: true));
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppGradients.onboarding(context)),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.onboardingGutter,
                  AppSpacing.xxxl,
                  AppSpacing.onboardingGutter,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.onboardingEligibilityTitle,
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.onboardingEligibilitySubtitle,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.onboardingGutter,
                  ),
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _toggle(
                            l10n.eligProofOfIncome,
                            Icons.attach_money,
                            _draft.proofOfIncome,
                            (v) => setState(
                              () => _draft = _draft.copyWith(proofOfIncome: v),
                            ),
                          ),
                          const Divider(height: 1),
                          _toggle(
                            l10n.eligProofOfResidency,
                            Icons.home_outlined,
                            _draft.proofOfResidency,
                            (v) => setState(
                              () =>
                                  _draft = _draft.copyWith(proofOfResidency: v),
                            ),
                          ),
                          const Divider(height: 1),
                          _toggle(
                            l10n.eligInsuranceRequired,
                            Icons.health_and_safety,
                            _draft.insuranceRequired,
                            (v) => setState(
                              () => _draft =
                                  _draft.copyWith(insuranceRequired: v),
                            ),
                          ),
                          const Divider(height: 1),
                          _toggle(
                            l10n.eligReferralRequired,
                            Icons.assignment_ind_outlined,
                            _draft.referralRequired,
                            (v) => setState(
                              () =>
                                  _draft = _draft.copyWith(referralRequired: v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.onboardingGutter,
                  AppSpacing.sm,
                  AppSpacing.onboardingGutter,
                  AppSpacing.onboardingGutter,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _continue,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggle(
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      secondary: Icon(icon),
      value: value,
      onChanged: onChanged,
    );
  }
}
