import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/theme_mode_provider.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/core/theme/color_scheme_ext.dart';
import 'package:beacon_app/core/widgets/apple_sign_in_button.dart';
import 'package:beacon_app/core/widgets/locked_section_overlay.dart';
import 'package:beacon_app/features/auth/presentation/pages/login_page.dart';
import 'package:beacon_app/features/map/presentation/services/location_service.dart';
import 'package:beacon_app/features/map/presentation/services/url_launcher_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Settings page with account info, language selector, eligibility
/// preferences, about section, and a hidden developer toggle for demo mode.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _versionString = '';

  // Eligibility preferences (hard gates — what the user needs from a facility)
  bool _proofOfIncome = false;
  bool _proofOfResidency = false;
  bool _insuranceRequired = false;
  bool _referralRequired = false;

  // Service preferences (nice-to-have attributes)
  bool _acceptsWalkIns = false;
  bool _appointmentOnly = false;
  bool _openToImmigrants = false;
  bool _freeServices = false;
  bool _slidingScale = false;
  bool _otherLanguages = false;
  bool _telehealthPreference = false;
  bool _wheelchairAccessible = false;
  bool _servesOutsideArea = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        // Show only the semantic version to users. The buildNumber is for
        // App Store / TestFlight bookkeeping, not end-user consumption.
        setState(() => _versionString = info.version);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isGuest = context.watch<GuestModeService>().isGuest;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: ListView(
          children: [
            _buildAccountSection(l10n, isGuest: isGuest),
            _buildAppSection(l10n),
            _buildEligibilitySection(l10n, isGuest: isGuest),
            _buildPreferencesSection(l10n, isGuest: isGuest),
            _buildAboutSection(l10n),
            if (!isGuest) _buildSignOutButton(l10n),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.paynesGray,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAccountSection(AppLocalizations l10n, {required bool isGuest}) {
    final zipService = context.watch<ZipCodeService>();
    final zipCode = zipService.zipCode;
    final locationEnabled = zipService.locationSearchEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.settingsAccount),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: isGuest
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.lock_outline,
                                  size: 26,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceFaded,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Sign in to store favorites, filter by '
                                  'preferences, and more!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (innerContext) => AppleSignInButton(
                              onFailure: (msg) {
                                if (!innerContext.mounted) return;
                                ScaffoldMessenger.of(innerContext).showSnackBar(
                                  SnackBar(content: Text(msg)),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.honeydew,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 28,
                              color: AppTheme.paynesGray,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Signed In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.honeydew,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Your account',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.resedaGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              const Divider(height: 1),
              ListTile(
                enabled: !locationEnabled,
                leading: Icon(
                  Icons.location_on_outlined,
                  color: locationEnabled
                      ? Theme.of(context).colorScheme.onSurfaceFaded
                      : AppTheme.paynesGray,
                ),
                title: Text(l10n.settingsZipCode),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      locationEnabled
                          ? (l10n.locationCurrentLocation)
                          : (zipCode ?? '—'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (!locationEnabled)
                      const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                onTap: locationEnabled ? null : _showZipEditDialog,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(
                  Icons.my_location,
                  color: AppTheme.paynesGray,
                ),
                title: Text(l10n.settingsUseMyLocation),
                subtitle: Text(l10n.settingsUseMyLocationDesc),
                value: locationEnabled,
                activeThumbColor: AppTheme.resedaGreen,
                onChanged: (value) => _onUseMyLocationChanged(value, l10n),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onUseMyLocationChanged(
    bool enabled,
    AppLocalizations l10n,
  ) async {
    final zipService = ZipCodeService();
    if (!enabled) {
      // If we have a stored ZIP to fall back on, just restore it silently.
      if (zipService.previousZipCode != null) {
        await zipService.disableLocationSearch();
        return;
      }
      // No prior ZIP — prompt for one. Only commit the toggle off if the
      // user actually enters a valid ZIP; cancelling leaves GPS on.
      final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => const _ZipEditDialog(),
      );
      if (!mounted) return;
      if (saved == true) {
        // ZipEditDialog already called setZipCode → setZipAndLocation, which
        // sets `_locationSearchEnabled` implicitly back to whatever it was.
        // Explicitly flip it off so the toggle reflects ZIP-mode.
        await zipService.setLocationSearchEnabled(false);
      }
      return;
    }

    final result = await LocationService.getCurrentLocation();
    if (!mounted) return;
    if (result.status == LocationStatus.granted) {
      await zipService.setCurrentLocation(
        latitude: result.latitude,
        longitude: result.longitude,
        displayName: l10n.locationCurrentLocation,
      );
      return;
    }

    await _showLocationDeniedDialog(l10n);
  }

  Future<void> _showLocationDeniedDialog(AppLocalizations l10n) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.locationPermissionDeniedTitle),
        content: Text(l10n.locationPermissionDeniedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
        ],
      ),
    );
  }

  Future<void> _showZipEditDialog() async {
    final initialZip = ZipCodeService().zipCode;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ZipEditDialog(initialZip: initialZip),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ZIP code updated')),
      );
    }
  }

  Widget _buildAppSection(AppLocalizations l10n) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeModeProvider = context.watch<ThemeModeProvider>();
    final currentCode = localeProvider.locale.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.settingsApp),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.language,
                  color: AppTheme.paynesGray,
                ),
                title: Text(l10n.settingsLanguage),
                trailing: DropdownButton<String>(
                  value: currentCode,
                  underline: const SizedBox.shrink(),
                  items: LocaleProvider.supportedLocales.map((locale) {
                    final code = locale.languageCode;
                    final name =
                        LocaleProvider.localeDisplayNames[code] ?? code;
                    return DropdownMenuItem(value: code, child: Text(name));
                  }).toList(),
                  onChanged: (code) {
                    if (code != null) {
                      localeProvider.setLocale(Locale(code));
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.brightness_6,
                  color: AppTheme.paynesGray,
                ),
                title: Text(l10n.settingsAppearance),
                trailing: DropdownButton<ThemeMode>(
                  value: themeModeProvider.themeMode,
                  underline: const SizedBox.shrink(),
                  items: ThemeModeProvider.themeModeNames.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (mode) {
                    if (mode != null) {
                      themeModeProvider.setThemeMode(mode);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEligibilitySection(AppLocalizations l10n, {required bool isGuest}) {
    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _eligToggle(
            'Proof of income required',
            Icons.attach_money,
            _proofOfIncome,
            isGuest ? null : (v) => setState(() => _proofOfIncome = v),
          ),
          const Divider(height: 1),
          _eligToggle(
            'Proof of residency required',
            Icons.home_outlined,
            _proofOfResidency,
            isGuest ? null : (v) => setState(() => _proofOfResidency = v),
          ),
          const Divider(height: 1),
          _eligToggle(
            'Insurance required',
            Icons.health_and_safety,
            _insuranceRequired,
            isGuest ? null : (v) => setState(() => _insuranceRequired = v),
          ),
          const Divider(height: 1),
          _eligToggle(
            'Referral required',
            Icons.assignment_ind_outlined,
            _referralRequired,
            isGuest ? null : (v) => setState(() => _referralRequired = v),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.settingsEligibility),
        if (isGuest)
          LockedSectionOverlay(
            message: 'Sign in to set preferences',
            cta: Builder(
              builder: (innerContext) => AppleSignInButton(
                onFailure: (msg) {
                  if (!innerContext.mounted) return;
                  ScaffoldMessenger.of(innerContext).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                },
              ),
            ),
            child: card,
          )
        else
          card,
      ],
    );
  }

  Widget _buildPreferencesSection(AppLocalizations l10n, {required bool isGuest}) {
    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _eligToggle(
            'Accepts walk-ins',
            Icons.directions_walk,
            _acceptsWalkIns,
            isGuest ? null : (v) => setState(() => _acceptsWalkIns = v),
          ),
          const Divider(height: 1),
          _eligToggle(
            'Appointment only',
            Icons.calendar_today,
            _appointmentOnly,
            isGuest ? null : (v) => setState(() => _appointmentOnly = v),
          ),
          const Divider(height: 1),
          _eligToggle(
            'Open to immigrants',
            Icons.public,
            _openToImmigrants,
            isGuest ? null : (v) => setState(() => _openToImmigrants = v),
          ),
          const Divider(height: 1),
          _eligToggle(
            'Free services available',
            Icons.money_off,
            _freeServices,
            isGuest ? null : (v) => setState(() => _freeServices = v),
          ),
          const Divider(height: 1),
          _eligToggle(
            'Sliding scale available',
            Icons.tune,
            _slidingScale,
            isGuest ? null : (v) => setState(() => _slidingScale = v),
          ),
          const Divider(height: 1),
          _eligToggle(
            'Other languages available',
            Icons.translate,
            _otherLanguages,
            isGuest ? null : (v) => setState(() => _otherLanguages = v),
          ),
          const Divider(height: 1),
          _eligToggle(
            'Telehealth available',
            Icons.videocam_outlined,
            _telehealthPreference,
            isGuest ? null : (v) => setState(() => _telehealthPreference = v),
          ),
          const Divider(height: 1),
          _eligToggle(
            'Wheelchair accessible',
            Icons.accessible,
            _wheelchairAccessible,
            isGuest ? null : (v) => setState(() => _wheelchairAccessible = v),
          ),
          const Divider(height: 1),
          _eligToggle(
            'Serves outside area',
            Icons.map_outlined,
            _servesOutsideArea,
            isGuest ? null : (v) => setState(() => _servesOutsideArea = v),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Preferences'),
        if (isGuest)
          LockedSectionOverlay(
            message: 'Sign in to set preferences',
            cta: Builder(
              builder: (innerContext) => AppleSignInButton(
                onFailure: (msg) {
                  if (!innerContext.mounted) return;
                  ScaffoldMessenger.of(innerContext).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                },
              ),
            ),
            child: card,
          )
        else
          card,
      ],
    );
  }

  Widget _eligToggle(
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      secondary: Icon(icon, color: AppTheme.paynesGray),
      value: value,
      activeThumbColor: AppTheme.resedaGreen,
      onChanged: onChanged,
    );
  }

  Widget _buildAboutSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.settingsAbout),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // TODO(post-MVP): re-evaluate long-press dev option trigger.
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.settingsVersion),
                trailing: Text(
                  _versionString.isEmpty ? '—' : _versionString,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.settingsPrivacyPolicy),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => UrlLauncherService.launchUrlString(
                  'https://beacon-website-pied.vercel.app/privacy-policy',
                  context,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.settingsTermsOfService),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => UrlLauncherService.launchUrlString(
                  'https://beacon-website-pied.vercel.app/terms-of-use',
                  context,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // TODO(post-MVP): restore _buildDeveloperSection and _confirmDemoToggle
  // once the in-app demo mode toggle is re-evaluated for post-launch use.

  Widget _buildSignOutButton(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.logout, color: AppTheme.paynesGray),
          label: Text(
            l10n.settingsSignOut,
            style: const TextStyle(
              color: AppTheme.paynesGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppTheme.paynesGray),
          ),
          onPressed: () => _confirmSignOut(l10n),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(AppLocalizations l10n) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsSignOut),
        content: Text(l10n.settingsSignOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsSignOut),
          ),
        ],
      ),
    );

    if (shouldSignOut != true || !mounted) return;
    await _performSignOut(l10n);
  }

  Future<void> _performSignOut(AppLocalizations l10n) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'SettingsPage.signOut',
      );
    }
    await ZipCodeService().clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsSignOutSuccess)),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

/// Standalone dialog for editing the user's ZIP code.
///
/// Owns the [TextEditingController] so its lifecycle is bound to the dialog's
/// own [State] (rather than being shared across an async/StatefulBuilder
/// boundary, which previously caused "used after dispose" / "_dependents not
/// empty" crashes when ZipCodeService.notifyListeners fired mid-dispose).
///
/// Pops with `true` on a successful update so the caller can show feedback.
class _ZipEditDialog extends StatefulWidget {
  const _ZipEditDialog({this.initialZip});

  final String? initialZip;

  @override
  State<_ZipEditDialog> createState() => _ZipEditDialogState();
}

class _ZipEditDialogState extends State<_ZipEditDialog> {
  late final TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialZip ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ZipCodeService().setZipCode(_controller.text.trim());
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't find that ZIP code. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update ZIP Code'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '60601',
                labelText: 'ZIP Code',
              ),
              style: const TextStyle(fontSize: 18, letterSpacing: 4),
              validator: (value) {
                if ((value ?? '').trim().length != 5) {
                  return 'Please enter a 5-digit ZIP code';
                }
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _onSave,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
