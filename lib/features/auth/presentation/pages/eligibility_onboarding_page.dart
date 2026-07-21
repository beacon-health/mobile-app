import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/theme/app_gradients.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/core/theme/color_scheme_ext.dart';
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

/// Required onboarding step (signed-in users only): pick the eligibility gates
/// that apply to you. These auto-filter the map and are editable later on the
/// Profile tab. The user can continue with none selected, but must proceed
/// through this screen.
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppGradients.onboarding(context)),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.onboardingEligibilityTitle,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.paynesGray,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.onboardingEligibilitySubtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurfaceSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.paynesGray,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
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
      secondary: Icon(icon, color: AppTheme.paynesGray),
      value: value,
      activeThumbColor: AppTheme.resedaGreen,
      onChanged: onChanged,
    );
  }
}
