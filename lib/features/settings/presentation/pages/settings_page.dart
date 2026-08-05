import 'package:beacon_app/core/constants/legal_urls.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/map_launcher_service.dart';
import 'package:beacon_app/core/services/theme_mode_provider.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/core/theme/color_scheme_ext.dart';
import 'package:beacon_app/features/map/presentation/services/location_service.dart';
import 'package:beacon_app/features/map/presentation/services/url_launcher_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

/// App settings: language, appearance, location (ZIP / GPS), directions app,
/// and About. Account, Ratings/Requests, and Eligibility now live on the
/// Profile tab; service Preferences are Map filters.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _versionString = '';

  /// Remembered "Get Directions" app; null = ask on next use.
  MapApp? _preferredMapApp;

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
    MapLauncherService.preferredApp().then((app) {
      if (mounted) setState(() => _preferredMapApp = app);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: ListView(
          children: [
            _buildAppSection(l10n),
            _buildAboutSection(l10n),
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

  Widget _buildAppSection(AppLocalizations l10n) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeModeProvider = context.watch<ThemeModeProvider>();
    final currentCode = localeProvider.locale.languageCode;

    final zipService = context.watch<ZipCodeService>();
    final zipCode = zipService.zipCode;
    final locationEnabled = zipService.locationSearchEnabled;

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
                          ? l10n.locationCurrentLocation
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
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.directions_outlined,
                  color: AppTheme.paynesGray,
                ),
                title: Text(l10n.settingsDirectionsApp),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _preferredMapApp?.displayName ?? l10n.settingsAskEachTime,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                onTap: _pickDirectionsApp,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Bottom-sheet picker of installed map apps + an "ask each time" reset.
  Future<void> _pickDirectionsApp() async {
    final installed = await MapLauncherService.installedApps();
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    final choice = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            for (final app in installed)
              ListTile(
                leading: const Icon(Icons.directions_outlined),
                title: Text(app.displayName),
                trailing: _preferredMapApp == app
                    ? const Icon(Icons.check, color: AppTheme.resedaGreen)
                    : null,
                onTap: () => Navigator.pop(ctx, app),
              ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(AppLocalizations.of(context)!.settingsAskEachTime),
              trailing: _preferredMapApp == null
                  ? const Icon(Icons.check, color: AppTheme.resedaGreen)
                  : null,
              onTap: () => Navigator.pop(ctx, 'ask'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice is MapApp) {
      await MapLauncherService.setPreferredApp(choice);
      if (mounted) setState(() => _preferredMapApp = choice);
    } else {
      await MapLauncherService.clearPreferredApp();
      if (mounted) setState(() => _preferredMapApp = null);
    }
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.settingsZipUpdated),
        ),
      );
    }
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
                  LegalUrls.privacyPolicy,
                  context,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.settingsTermsOfService),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => UrlLauncherService.launchUrlString(
                  LegalUrls.termsOfUse,
                  context,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ZIP editing dialog. Owns its [TextEditingController] so the lifecycle is
/// bound to this [State] — sharing one across a StatefulBuilder boundary
/// caused "used after dispose" crashes. Pops `true` on success.
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
        _errorMessage = AppLocalizations.of(context)!.settingsZipNotFoundError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.settingsUpdateZipTitle),
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
              decoration: InputDecoration(
                hintText: '00000',
                hintStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.35),
                  letterSpacing: 4,
                ),
                labelText: AppLocalizations.of(context)!.settingsZipCode,
              ),
              style: const TextStyle(fontSize: 18, letterSpacing: 4),
              validator: (value) {
                if ((value ?? '').trim().length != 5) {
                  return AppLocalizations.of(context)!.settingsZipValidation;
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
          child: Text(AppLocalizations.of(context)!.commonCancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _onSave,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppLocalizations.of(context)!.commonSave),
        ),
      ],
    );
  }
}
