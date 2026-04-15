import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:beacon_app/core/models/demo_user.dart';
import 'package:beacon_app/core/services/demo_mode_service.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/theme_mode_provider.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/core/constants/app_routes.dart';
import 'package:beacon_app/features/map/presentation/providers/facility_provider.dart';
import 'package:beacon_app/l10n/app_localizations.dart';

/// Settings page with account info, language selector, eligibility
/// preferences, about section, and a hidden developer toggle for demo mode.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _showDeveloperSection = false;

  late TextEditingController _zipController;
  bool _proofOfIncome = DemoUser.proofOfIncomeAvailable;
  bool _proofOfResidency = false;
  bool _insuranceRequired = false;
  bool _referralRequired = false;
  bool _acceptsWalkIns = DemoUser.acceptsWalkIns;
  bool _appointmentOnly = false;
  bool _openToImmigrants = false;
  bool _freeServices = false;
  bool _slidingScale = false;
  bool _otherLanguages = false;
  bool _telehealthPreference = DemoUser.telehealthPreference;
  bool _wheelchairAccessible = DemoUser.wheelchairAccessible;
  bool _servesOutsideArea = false;

  @override
  void initState() {
    super.initState();
    _zipController = TextEditingController(text: DemoUser.zipCode);
  }

  @override
  void dispose() {
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final demoMode = context.watch<DemoModeService>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: ListView(
          children: [
            _buildAccountSection(l10n, demoMode),
            _buildAppSection(l10n),
            _buildEligibilitySection(l10n),
            _buildAboutSection(l10n),
            if (_showDeveloperSection)
              _buildDeveloperSection(l10n, demoMode),
            _buildSignOutButton(l10n),
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

  Widget _buildAccountSection(AppLocalizations l10n, DemoModeService demo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.settingsAccount),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.honeydew,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.apple,
                    size: 28,
                    color: AppTheme.paynesGray,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DemoUser.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DemoUser.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.paynesGray,
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
                        child: Text(
                          l10n.settingsSignedInWith(DemoUser.authProvider),
                          style: const TextStyle(
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
        ),
      ],
    );
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
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
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

  Widget _buildEligibilitySection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.settingsEligibility),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _zipController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    labelText: l10n.settingsZipCode,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const Divider(height: 1),
              _eligToggle(
                'Proof of income required',
                Icons.attach_money,
                _proofOfIncome,
                (v) => setState(() => _proofOfIncome = v),
              ),
              const Divider(height: 1),
              _eligToggle(
                'Proof of residency required',
                Icons.home_outlined,
                _proofOfResidency,
                (v) => setState(() => _proofOfResidency = v),
              ),
              const Divider(height: 1),
              _eligToggle(
                'Insurance required',
                Icons.health_and_safety,
                _insuranceRequired,
                (v) => setState(() => _insuranceRequired = v),
              ),
              const Divider(height: 1),
              _eligToggle(
                'Referral required',
                Icons.assignment_ind_outlined,
                _referralRequired,
                (v) => setState(() => _referralRequired = v),
              ),
              const Divider(height: 1),
              _eligToggle(
                'Accepts walk-ins',
                Icons.directions_walk,
                _acceptsWalkIns,
                (v) => setState(() => _acceptsWalkIns = v),
              ),
              const Divider(height: 1),
              _eligToggle(
                'Appointment only',
                Icons.calendar_today,
                _appointmentOnly,
                (v) => setState(() => _appointmentOnly = v),
              ),
              const Divider(height: 1),
              _eligToggle(
                'Open to immigrants',
                Icons.public,
                _openToImmigrants,
                (v) => setState(() => _openToImmigrants = v),
              ),
              const Divider(height: 1),
              _eligToggle(
                'Free services available',
                Icons.money_off,
                _freeServices,
                (v) => setState(() => _freeServices = v),
              ),
              const Divider(height: 1),
              _eligToggle(
                'Sliding scale available',
                Icons.tune,
                _slidingScale,
                (v) => setState(() => _slidingScale = v),
              ),
              const Divider(height: 1),
              _eligToggle(
                'Other languages available',
                Icons.translate,
                _otherLanguages,
                (v) => setState(() => _otherLanguages = v),
              ),
              const Divider(height: 1),
              _eligToggle(
                'Telehealth available',
                Icons.videocam_outlined,
                _telehealthPreference,
                (v) => setState(() => _telehealthPreference = v),
              ),
              const Divider(height: 1),
              _eligToggle(
                'Wheelchair accessible',
                Icons.accessible,
                _wheelchairAccessible,
                (v) => setState(() => _wheelchairAccessible = v),
              ),
              const Divider(height: 1),
              _eligToggle(
                'Serves outside area',
                Icons.map_outlined,
                _servesOutsideArea,
                (v) => setState(() => _servesOutsideArea = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _eligToggle(
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

  Widget _buildAboutSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.settingsAbout),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              GestureDetector(
                onLongPress: () {
                  setState(() {
                    _showDeveloperSection = !_showDeveloperSection;
                  });
                  if (_showDeveloperSection) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Developer options enabled'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.settingsVersion),
                  trailing: const Text('0.0.1+1'),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.settingsPrivacyPolicy),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.settingsTermsOfService),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperSection(
    AppLocalizations l10n,
    DemoModeService demoMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.settingsDeveloper),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: AppTheme.honeydew,
          child: Column(
            children: [
              SwitchListTile(
                title: Text(l10n.settingsDemoMode),
                subtitle: Text(
                  l10n.settingsDemoModeDesc,
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.paynesGray),
                ),
                secondary: const Icon(Icons.science_outlined,
                    color: AppTheme.resedaGreen),
                activeThumbColor: AppTheme.resedaGreen,
                value: demoMode.isDemoMode,
                onChanged: (value) => _confirmDemoToggle(l10n, value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDemoToggle(
    AppLocalizations l10n,
    bool newValue,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsDemoMode),
        content: Text(l10n.settingsDemoModeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonContinue),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Clear cached facility data so the new mode loads fresh
      Provider.of<FacilityProvider>(context, listen: false).setFacilities([]);

      await DemoModeService().setDemoMode(newValue);

      // Push a fresh MainNavBar and remove all previous routes so
      // MapPage and HomePage are rebuilt with the correct repository.
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.main,
          (_) => false,
        );
      }
    }
  }

  Widget _buildSignOutButton(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showSignOutDialog(l10n),
          icon: const Icon(Icons.logout),
          label: Text(l10n.settingsSignOut),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.bittersweet,
            side: const BorderSide(color: AppTheme.bittersweet),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Future<void> _showSignOutDialog(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsSignOut),
        content: Text(l10n.settingsSignOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsSignOut),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
