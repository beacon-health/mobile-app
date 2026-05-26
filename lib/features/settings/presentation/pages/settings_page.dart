import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/theme_mode_provider.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/core/theme/color_scheme_ext.dart';
import 'package:beacon_app/core/widgets/locked_section_overlay.dart';
import 'package:beacon_app/features/map/presentation/services/url_launcher_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

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
        setState(() {
          _versionString = '${info.version}+${info.buildNumber}';
        });
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
            // TODO(post-MVP): re-enable developer section after evaluating
            // whether in-app demo mode toggle is needed post-launch.
            // if (kDebugMode && _showDeveloperSection)
            //   _buildDeveloperSection(l10n, demoMode),
            // Sign out is not available in the guest-only MVP flow.
            // TODO(post-MVP): re-enable once OAuth sign-in is wired.
            // _buildSignOutButton(l10n),
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
    final zipCode = context.watch<ZipCodeService>().zipCode;

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
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isGuest
                            ? Theme.of(context).colorScheme.surfaceContainerHighest
                            : AppTheme.honeydew,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isGuest ? Icons.lock_outline : Icons.person,
                        size: isGuest ? 26 : 28,
                        color: isGuest
                            ? Theme.of(context).colorScheme.onSurfaceFaded
                            : AppTheme.paynesGray,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: isGuest
                          ? Text(
                              'Sign in to store favorites, filter by preferences, and more!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceSecondary,
                              ),
                            )
                          : Column(
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
                leading: const Icon(Icons.location_on_outlined, color: AppTheme.paynesGray),
                title: Text(l10n.settingsZipCode),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      zipCode ?? '—',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                onTap: _showZipEditDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showZipEditDialog() async {
    final zipService = ZipCodeService();
    final controller = TextEditingController(text: zipService.zipCode ?? '');
    final formKey = GlobalKey<FormState>();
    var isLoading = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Update ZIP Code'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller,
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
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      final success = await zipService.setZipCode(
                        controller.text.trim(),
                      );
                      if (!ctx.mounted) return;
                      if (success) {
                        Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ZIP code updated')),
                          );
                        }
                      } else {
                        setDialogState(() {
                          isLoading = false;
                          errorMessage = "Couldn't find that ZIP code. Try again.";
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
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
}
