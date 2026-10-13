import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/coverage_notice.dart';
import 'package:beacon_app/features/auth/presentation/pages/eligibility_onboarding_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/login_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/zip_entry_page.dart';
import 'package:beacon_app/features/auth/presentation/widgets/onboarding_scaffold.dart';
import 'package:beacon_app/features/map/presentation/services/location_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// First onboarding step: how to locate facilities, GPS or ZIP. Granting GPS
/// goes on to the eligibility step; denial falls back to [ZipEntryPage].
class LocationChoicePage extends StatefulWidget {
  const LocationChoicePage({super.key, this.prefilledZip});

  /// Pre-fills [ZipEntryPage] during the guest → signed-in upgrade.
  final String? prefilledZip;

  @override
  State<LocationChoicePage> createState() => _LocationChoicePageState();
}

class _LocationChoicePageState extends State<LocationChoicePage> {
  bool _isResolvingLocation = false;

  Future<void> _onUseLocation() async {
    setState(() => _isResolvingLocation = true);
    final result = await LocationService.getCurrentLocation();
    if (!mounted) return;

    final granted = result.status == LocationStatus.granted;
    if (granted) {
      await ZipCodeService().setCurrentLocation(
        latitude: result.latitude,
        longitude: result.longitude,
      );
      if (!mounted) return;
    }

    // Cleared before leaving: the next step's back button returns here.
    setState(() => _isResolvingLocation = false);
    if (granted) {
      finishLocationOnboarding(context);
    } else {
      _goToZipEntry(locationOff: true);
    }
  }

  void _goToZipEntry({bool locationOff = false}) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ZipEntryPage(
          prefilledZip: widget.prefilledZip,
          locationOff: locationOff,
        ),
      ),
    );
  }

  /// This page replaced the sign-in screen, so going back means putting that
  /// screen in its place again.
  void _backToSignIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Someone who has signed in has nothing to go back to: the sign-in screen
    // would only ask them to sign in again.
    final isGuest = GuestModeService().isGuest;
    final canPop = Navigator.of(context).canPop();

    return OnboardingScaffold(
      step: 1,
      onBack: isGuest && !canPop ? _backToSignIn : null,
      children: [
        OnboardingHeading(
          title: l10n.locationChoiceTitle,
          subtitle: l10n.locationChoiceSubtitle,
        ),
        const SizedBox(height: AppSpacing.xxl),
        _ChoiceCard(
          icon: Icons.my_location,
          title: l10n.locationChoiceUseLocation,
          description: l10n.locationChoiceUseLocationDesc,
          onTap: _isResolvingLocation ? null : _onUseLocation,
          isLoading: _isResolvingLocation,
        ),
        const SizedBox(height: AppSpacing.md),
        _ChoiceCard(
          icon: Icons.location_on_outlined,
          title: l10n.locationChoiceEnterZip,
          description: l10n.locationChoiceEnterZipDesc,
          onTap: _isResolvingLocation ? null : _goToZipEntry,
        ),
        const SizedBox(height: AppSpacing.xl),
        const CoverageNotice(),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: AppSizes.avatar,
                height: AppSizes.avatar,
                // Honeydew is the brightest thing on a dark screen; there the
                // tile takes a tone of the surface instead.
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.secondaryContainer
                      : AppColors.honeydew,
                  borderRadius: AppRadii.mdAll,
                ),
                child: Icon(
                  icon,
                  color: isDark
                      ? colorScheme.onSecondaryContainer
                      : AppColors.paynesGray,
                  size: AppIconSize.xl,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isLoading)
                const SizedBox.square(
                  dimension: AppIconSize.md,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right, color: colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
