import 'dart:async';

import 'package:beacon_app/core/services/account_deletion_service.dart';
import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/local_user_data.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/apple_mark.dart';
import 'package:beacon_app/core/widgets/eligibility_checklist.dart';
import 'package:beacon_app/core/widgets/native_sign_in_button.dart';
import 'package:beacon_app/core/widgets/section_header.dart';
import 'package:beacon_app/features/auth/presentation/pages/login_page.dart';
import 'package:beacon_app/features/settings/presentation/pages/my_ratings_page.dart';
import 'package:beacon_app/features/settings/presentation/pages/my_requests_page.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Account + "what you can provide". Guests see a sign-in card only: both
/// belong to an account. Service Preferences live on the Map and app settings
/// under Settings.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isGuest = context.watch<GuestModeService>().isGuest;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: isGuest
          ? _buildGuestState(l10n)
          : ListView(
              children: [
                _buildIdentitySection(l10n),
                _buildAccountLinksSection(l10n),
                _buildEligibilitySection(l10n),
                _buildSignOutButton(l10n),
                _buildDeleteAccountButton(l10n),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
    );
  }

  // --- Guest ---------------------------------------------------------------

  Widget _buildGuestState(AppLocalizations l10n) {
    return ListView(
      children: [
        SectionHeader(l10n.settingsAccount),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: AppSizes.avatar,
                      height: AppSizes.avatar,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: AppRadii.mdAll,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: AppIconSize.xl,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        l10n.settingsSignInHint,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Builder(
                  builder: (innerContext) => NativeSignInButton(
                    onFailure: (msg) {
                      if (!innerContext.mounted) return;
                      ScaffoldMessenger.of(innerContext).showSnackBar(
                        SnackBar(content: Text(msg)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Identity ------------------------------------------------------------

  Widget _buildIdentitySection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.settingsAccount),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                _buildProviderBadge(),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: _buildSignedInIdentity()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Square badge showing the OAuth provider's logo (Apple/Google).
  Widget _buildProviderBadge() {
    final user = GuestModeService().currentUser;
    final provider = user?.appMetadata['provider'] as String?;

    Widget child;
    Color background;
    switch (provider) {
      case 'apple':
        background = AppColors.appleBlack;
        child = const AppleMark(size: AppIconSize.xl, color: Colors.white);
      case 'google':
        background = Colors.white;
        // Google's own "G", as on the sign-in button.
        child = Image.asset(
          'assets/google-g-logo.png',
          height: AppIconSize.lg,
          excludeFromSemantics: true,
        );
      default:
        background = AppColors.honeydew;
        child = const Icon(
          Icons.person,
          size: AppIconSize.xl,
          color: AppColors.paynesGray,
        );
    }
    return Container(
      width: AppSizes.avatar,
      height: AppSizes.avatar,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.mdAll,
        border: provider == 'google'
            ? Border.all(color: Theme.of(context).dividerColor)
            : null,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildSignedInIdentity() {
    final user = GuestModeService().currentUser;
    final providerLabel = _providerLabelFor(user);
    final email = _displayEmail(user);
    final name = _displayName(user);

    final l10n = AppLocalizations.of(context)!;
    final primary = name ??
        (providerLabel != null
            ? l10n.profileSignedInThrough(providerLabel)
            : l10n.profileSignedIn);

    final theme = Theme.of(context);
    final secondaryStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceMuted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          primary,
          style: theme.textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (email != null)
          Text(
            email,
            style: secondaryStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        else if (name != null && providerLabel != null)
          Text(
            l10n.profileSignedInThrough(providerLabel),
            style: secondaryStyle,
          ),
      ],
    );
  }

  String? _providerLabelFor(User? user) {
    final provider = user?.appMetadata['provider'] as String?;
    if (provider == null || provider.isEmpty) return null;
    if (provider == 'email') return null;
    return provider[0].toUpperCase() + provider.substring(1);
  }

  String? _displayEmail(User? user) {
    final email = user?.email;
    if (email == null || email.isEmpty) return null;
    return email;
  }

  String? _displayName(User? user) {
    final meta = user?.userMetadata;
    if (meta == null) return null;
    for (final key in const ['name', 'full_name', 'display_name']) {
      final value = meta[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  // --- Ratings / Requests --------------------------------------------------

  Widget _buildAccountLinksSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.thumbs_up_down_outlined),
              title: Text(l10n.settingsYourRatings),
              trailing: const Icon(Icons.chevron_right, size: AppIconSize.md),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MyRatingsPage()),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_business_outlined),
              title: Text(l10n.settingsYourRequests),
              trailing: const Icon(Icons.chevron_right, size: AppIconSize.md),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MyRequestsPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Eligibility ---------------------------------------------------------

  Widget _buildEligibilitySection(AppLocalizations l10n) {
    final epService = context.watch<EligibilityPreferencesService>();
    final state = epService.eligibility;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.settingsEligibility),
        // The switch in its own card, set apart from the answers it governs.
        Card(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
          child: SwitchListTile(
            title: Text(l10n.profileApplyEligibility),
            subtitle: Text(l10n.profileApplyEligibilityDesc),
            secondary: const Icon(Icons.filter_alt_outlined),
            value: state.applyToSearch,
            onChanged: (v) =>
                unawaited(epService.setApplyEligibilityToSearch(v)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageGutter,
          ),
          // Locked, not reset, while the filter is off.
          child: EligibilityChecklist(
            value: state,
            onChanged: state.applyToSearch
                ? (next) => unawaited(epService.updateEligibility(next))
                : null,
          ),
        ),
      ],
    );
  }

  // --- Sign out ------------------------------------------------------------

  Widget _buildSignOutButton(AppLocalizations l10n) {
    final secondary = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.xxl,
        AppSpacing.pageGutter,
        0,
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: Text(l10n.settingsSignOut),
          style: OutlinedButton.styleFrom(
            foregroundColor: secondary,
            side: BorderSide(color: secondary),
          ),
          onPressed: _isDeleting ? null : () => _confirmSignOut(l10n),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(AppLocalizations l10n) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsSignOutTitle),
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
        context: 'ProfilePage.signOut',
      );
    }
    await clearLocalUserData(logContext: 'ProfilePage.signOut');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsSignOutSuccess)),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // --- Delete account ------------------------------------------------------

  Widget _buildDeleteAccountButton(AppLocalizations l10n) {
    final destructive = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.md,
        AppSpacing.pageGutter,
        0,
      ),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          icon: _isDeleting
              ? SizedBox.square(
                  dimension: AppIconSize.md,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: destructive,
                  ),
                )
              : const Icon(Icons.delete_outline),
          label: Text(
            _isDeleting
                ? l10n.deleteAccountInProgress
                : l10n.settingsDeleteAccount,
          ),
          style: AppTheme.destructiveTextButton(context),
          onPressed: _isDeleting ? null : () => _confirmDeleteAccount(l10n),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(AppLocalizations l10n) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: AppTheme.destructiveFilledButton(ctx),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;
    await _performDeleteAccount(l10n);
  }

  Future<void> _performDeleteAccount(AppLocalizations l10n) async {
    setState(() => _isDeleting = true);
    final result = await AccountDeletionService().deleteAccount();
    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountFailed)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.deleteAccountSuccess)),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}
