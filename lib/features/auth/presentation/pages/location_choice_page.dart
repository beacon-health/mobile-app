import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/app_gradients.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/core/theme/color_scheme_ext.dart';
import 'package:beacon_app/features/auth/presentation/pages/eligibility_onboarding_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/zip_entry_page.dart';
import 'package:beacon_app/features/map/presentation/services/location_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Asks the user how they want to locate facilities: GPS or zip code.
///
/// Shown after sign-in / guest-continue. If the user picks GPS and grants
/// permission, we store coordinates via [ZipCodeService.setCurrentLocation]
/// and head straight to [MainNavBar]. If permission is denied, we navigate to
/// [ZipEntryPage] as the fallback.
class LocationChoicePage extends StatefulWidget {
  const LocationChoicePage({super.key, this.prefilledZip});

  /// Optional ZIP code to pre-fill the [ZipEntryPage] when chosen.
  ///
  /// Used during the guest → signed-in upgrade flow so the user doesn't have
  /// to re-enter their ZIP.
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.onboarding(context),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Image.asset('assets/beacon-logo.png', width: 180),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.locationChoiceTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.paynesGray,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.locationChoiceSubtitle,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurfaceSecondary,
                ),
              ),
              const SizedBox(height: 36),
              _ChoiceCard(
                icon: Icons.my_location,
                title: l10n.locationChoiceUseLocation,
                description: l10n.locationChoiceUseLocationDesc,
                onTap: _isResolvingLocation ? null : _onUseLocation,
                isLoading: _isResolvingLocation,
              ),
              const SizedBox(height: 16),
              _ChoiceCard(
                icon: Icons.location_on_outlined,
                title: l10n.locationChoiceEnterZip,
                description: l10n.locationChoiceEnterZipDesc,
                onTap: _isResolvingLocation ? null : _onEnterZip,
              ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.honeydew,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.paynesGray, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right, color: AppTheme.paynesGray),
            ],
          ),
        ),
      ),
    );
  }
}
