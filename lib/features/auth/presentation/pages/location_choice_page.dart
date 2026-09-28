import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/coverage_notice.dart';
import 'package:beacon_app/features/auth/presentation/pages/eligibility_onboarding_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/zip_entry_page.dart';
import 'package:beacon_app/features/map/presentation/services/location_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Asks how to locate facilities: GPS or ZIP. Granting GPS goes straight to
/// [MainNavBar]; denial falls back to [ZipEntryPage].
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

    if (result.status == LocationStatus.granted) {
      await ZipCodeService().setCurrentLocation(
        latitude: result.latitude,
        longitude: result.longitude,
      );
      if (!mounted) return;
      _goToMain();
      return;
    }

    setState(() => _isResolvingLocation = false);
    _goToZipEntry();
  }

  void _onEnterZip() => _goToZipEntry();

  void _goToZipEntry() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ZipEntryPage(prefilledZip: widget.prefilledZip),
      ),
    );
  }

  void _goToMain() {
    // Signed-in users get the required Eligibility step next; guests go
    // straight to the app.
    finishLocationOnboarding(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.onboarding(context),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.onboardingGutter,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              Center(
                child: Image.asset(
                  'assets/beacon-logo.png',
                  width: AppSizes.logoMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                l10n.locationChoiceTitle,
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.locationChoiceSubtitle,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              _ChoiceCard(
                icon: Icons.my_location,
                title: l10n.locationChoiceUseLocation,
                description: l10n.locationChoiceUseLocationDesc,
                onTap: _isResolvingLocation ? null : _onUseLocation,
                isLoading: _isResolvingLocation,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ChoiceCard(
                icon: Icons.location_on_outlined,
                title: l10n.locationChoiceEnterZip,
                description: l10n.locationChoiceEnterZipDesc,
                onTap: _isResolvingLocation ? null : _onEnterZip,
              ),
              const SizedBox(height: AppSpacing.xxl),
              const CoverageNotice(),
              const Spacer(),
            ],
          ),
        ),
      ),
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
    return Material(
      color: theme.cardTheme.color,
      borderRadius: AppRadii.lgAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lgAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Container(
                width: AppSizes.avatar,
                height: AppSizes.avatar,
                decoration: const BoxDecoration(
                  color: AppColors.honeydew,
                  borderRadius: AppRadii.mdAll,
                ),
                // Fixed pairing on the fixed honeydew tile, in both modes.
                child: Icon(
                  icon,
                  color: AppColors.paynesGray,
                  size: AppIconSize.xl,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceSecondary,
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
