import 'package:beacon_app/core/constants/legal_urls.dart';
import 'package:beacon_app/core/services/accessibility_settings.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/services/map_launcher_service.dart';
import 'package:beacon_app/core/services/theme_mode_provider.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/utils/coverage_text.dart';
import 'package:beacon_app/core/widgets/section_header.dart';
import 'package:beacon_app/features/map/presentation/services/location_service.dart';
import 'package:beacon_app/features/map/presentation/services/url_launcher_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

/// App settings: language, appearance, location (ZIP / GPS), directions app,
/// Beacon's own accessibility options, and About. Account, Ratings/Requests,
/// and what you can provide live on the Profile tab; service Preferences are
/// Map filters.
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
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: ListView(
          children: [
            _buildAppSection(l10n),
            _buildAccessibilitySection(l10n),
            _buildAboutSection(l10n),
            // The version is information, not a row to tap.
            if (_versionString.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  l10n.settingsVersionFooter(_versionString),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  /// The most of the screen's width a row gives to its trailing value.
  static const double _valueWidthFraction = 0.4;

  /// A row that shows its current [value] and opens something to change it.
  /// The value sits at the trailing edge with a chevron; at large text sizes
  /// it moves under the title, where it has the whole width.
  Widget _valueTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final stacked = MediaQuery.textScalerOf(context).scale(100) / 100 > 1.5;
    final chevron = onTap == null
        ? null
        : Icon(Icons.chevron_right, size: AppIconSize.md, color: muted);
    return ListTile(
      enabled: onTap != null,
      leading: Icon(icon),
      title: Text(title),
      subtitle: stacked ? Text(value) : null,
      trailing: stacked
          ? chevron
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Capped, so a long value (a language that runs long, a long
                // app name) wraps instead of pushing the title off the row.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.sizeOf(context).width * _valueWidthFraction,
                  ),
                  child: Text(value, textAlign: TextAlign.end),
                ),
                if (chevron != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  chevron,
                ],
              ],
            ),
      onTap: onTap,
    );
  }

  String _themeModeName(AppLocalizations l10n, ThemeMode mode) =>
      switch (mode) {
        ThemeMode.system => l10n.settingsAppearanceSystem,
        ThemeMode.light => l10n.settingsAppearanceLight,
        ThemeMode.dark => l10n.settingsAppearanceDark,
      };

  /// Bottom-sheet list of [options] with the [current] one checked.
  Future<T?> _pickOption<T>({
    required String title,
    required List<T> options,
    required T current,
    required String Function(T) labelOf,
    Locale? Function(T)? localeOf,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sheetGutter,
                  AppSpacing.xs,
                  AppSpacing.sheetGutter,
                  AppSpacing.md,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ),
              ),
              for (final option in options)
                ListTile(
                  title: Text(labelOf(option), locale: localeOf?.call(option)),
                  selected: option == current,
                  trailing: option == current
                      ? Icon(
                          Icons.check,
                          color: Theme.of(ctx).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, option),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppSection(AppLocalizations l10n) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeModeProvider = context.watch<ThemeModeProvider>();
    final currentCode = localeProvider.locale.languageCode;
    String languageName(String code) =>
        LocaleProvider.localeDisplayNames[code] ?? code;

    final zipService = context.watch<ZipCodeService>();
    final zipCode = zipService.zipCode;
    final locationEnabled = zipService.locationSearchEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.settingsApp),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _valueTile(
                icon: Icons.language,
                title: l10n.settingsLanguage,
                value: languageName(currentCode),
                onTap: () async {
                  final code = await _pickOption<String>(
                    title: l10n.authSelectLanguage,
                    options: [
                      for (final locale in LocaleProvider.supportedLocales)
                        locale.languageCode,
                    ],
                    current: currentCode,
                    // Each language under its own name.
                    labelOf: languageName,
                    localeOf: Locale.new,
                  );
                  if (code != null) {
                    await localeProvider.setLocale(Locale(code));
                  }
                },
              ),
              const Divider(height: 1),
              _valueTile(
                icon: Icons.brightness_6,
                title: l10n.settingsAppearance,
                value: _themeModeName(l10n, themeModeProvider.themeMode),
                onTap: () async {
                  final mode = await _pickOption<ThemeMode>(
                    title: l10n.settingsAppearance,
                    options: ThemeMode.values,
                    current: themeModeProvider.themeMode,
                    labelOf: (mode) => _themeModeName(l10n, mode),
                  );
                  if (mode != null) {
                    await themeModeProvider.setThemeMode(mode);
                  }
                },
              ),
              const Divider(height: 1),
              _valueTile(
                icon: Icons.location_on_outlined,
                title: l10n.settingsZipCode,
                value: locationEnabled
                    ? l10n.locationCurrentLocation
                    : (zipCode ?? l10n.commonNotSet),
                onTap: locationEnabled ? null : _showZipEditDialog,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.my_location),
                title: Text(l10n.settingsUseMyLocation),
                subtitle: Text(l10n.settingsUseMyLocationDesc),
                value: locationEnabled,
                onChanged: (value) => _onUseMyLocationChanged(value, l10n),
              ),
              const Divider(height: 1),
              _valueTile(
                icon: Icons.directions_outlined,
                title: l10n.settingsDirectionsApp,
                value:
                    _preferredMapApp?.displayName ?? l10n.settingsAskEachTime,
                onTap: _pickDirectionsApp,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilitySection(AppLocalizations l10n) {
    final settings = context.watch<AccessibilitySettings>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.settingsAccessibility),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.view_list_outlined),
                title: Text(l10n.settingsMapAsList),
                subtitle: Text(l10n.settingsMapAsListDesc),
                value: settings.openMapAsList,
                onChanged: settings.setOpenMapAsList,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.zoom_in),
                title: Text(l10n.settingsLargerPins),
                subtitle: Text(l10n.settingsLargerPinsDesc),
                value: settings.largerMapPins,
                onChanged: settings.setLargerMapPins,
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
    final selectedIcon = Icon(
      Icons.check,
      color: Theme.of(context).colorScheme.primary,
    );
    final choice = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final app in installed)
              ListTile(
                leading: const Icon(Icons.directions_outlined),
                title: Text(app.displayName),
                trailing: _preferredMapApp == app ? selectedIcon : null,
                onTap: () => Navigator.pop(ctx, app),
              ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(AppLocalizations.of(context)!.settingsAskEachTime),
              trailing: _preferredMapApp == null ? selectedIcon : null,
              onTap: () => Navigator.pop(ctx, 'ask'),
            ),
            const SizedBox(height: AppSpacing.sm),
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
      // No display name: the service stores its language-neutral sentinel, and
      // a translated label here would later be mistaken for a ZIP.
      await zipService.setCurrentLocation(
        latitude: result.latitude,
        longitude: result.longitude,
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
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final chevron =
        Icon(Icons.chevron_right, size: AppIconSize.md, color: muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.settingsAbout),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.settingsPrivacyPolicy),
                trailing: chevron,
                onTap: () => UrlLauncherService.launchUrlString(
                  LegalUrls.privacyPolicy,
                  context,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.settingsTermsOfService),
                trailing: chevron,
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

    final result = await ZipCodeService().setZipCode(_controller.text.trim());
    if (!mounted) return;
    if (result == ZipResult.saved) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = zipErrorMessage(AppLocalizations.of(context)!, result);
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
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.postalCode],
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.settingsZipCode,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                helperText: AppLocalizations.of(context)!.zipEntryHelper,
                errorText: _errorMessage,
              ),
              style: AppTypography.zipInput,
              validator: (value) {
                if ((value ?? '').trim().length != 5) {
                  return AppLocalizations.of(context)!.settingsZipValidation;
                }
                return null;
              },
            ),
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
              ? const SizedBox.square(
                  dimension: AppIconSize.sm,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppLocalizations.of(context)!.commonSave),
        ),
      ],
    );
  }
}
