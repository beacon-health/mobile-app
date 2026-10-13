import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/empty_state.dart';
import 'package:beacon_app/features/manager/data/manager_repository.dart';
import 'package:beacon_app/features/manager/domain/managed_facility.dart';
import 'package:beacon_app/features/map/utils/facility_formatting.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "Your facilities": every facility the signed-in person manages or has
/// asked to, with what is waiting on them.
///
/// Reached from Profile, which shows the way in only to someone who has at
/// least one. Verification is done by hand by the Beacon team, so a new
/// request sits here as pending until it is.
class ManagedFacilitiesPage extends StatefulWidget {
  const ManagedFacilitiesPage({super.key});

  @override
  State<ManagedFacilitiesPage> createState() => _ManagedFacilitiesPageState();
}

class _ManagedFacilitiesPageState extends State<ManagedFacilitiesPage> {
  late final Future<List<ManagedFacility>> _facilities =
      context.read<ManagerRepository>().myFacilities();

  void _requestAccess() {
    // The request flow needs the backend this feature is waiting on.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.managerComingSoon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.managerTitle)),
      body: FutureBuilder<List<ManagedFacility>>(
        future: _facilities,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final facilities = snapshot.data ?? const <ManagedFacility>[];
          final request = OutlinedButton.icon(
            onPressed: _requestAccess,
            icon: const Icon(Icons.add_business_outlined),
            label: Text(l10n.managerRequestAccess),
          );

          if (facilities.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.storefront_outlined,
                  title: l10n.managerEmptyTitle,
                  message: l10n.managerEmptyBody,
                  action: request,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: [
              for (final managed in facilities) ...[
                _ManagedFacilityCard(managed: managed),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.sm),
              request,
            ],
          );
        },
      ),
    );
  }
}

class _ManagedFacilityCard extends StatelessWidget {
  const _ManagedFacilityCard({required this.managed});

  final ManagedFacility managed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final muted = scheme.onSurfaceVariant;
    final facility = managed.facility;

    final (statusIcon, statusText) = switch (managed.status) {
      ManagerStatus.verified => (
          Icons.verified_outlined,
          l10n.managerVerified(managed.managerCount),
        ),
      ManagerStatus.pending => (
          Icons.hourglass_empty,
          l10n.managerPending,
        ),
      ManagerStatus.revoked => (Icons.block, l10n.managerRevoked),
    };

    // What a verified manager sees under the name: what is waiting on them,
    // or how far the facility is from having feedback to read.
    final String? detail = switch (managed.status) {
      ManagerStatus.pending => l10n.managerPendingBody,
      ManagerStatus.revoked => null,
      ManagerStatus.verified => managed.needsAttention > 0
          ? l10n.managerNeedsAttention(managed.needsAttention)
          : FeedbackVisibility.isVisible(managed.feedbackPeople)
              ? l10n.managerFeedbackReady
              : l10n.managerFeedbackHidden(
                  managed.feedbackPeople,
                  FeedbackVisibility.minimumPeople,
                ),
    };

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FacilityCategoryIcons.buildCategoryIcon(facility.primaryCategory),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(facility.name, style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(statusIcon, size: AppIconSize.sm, color: muted),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          statusText,
                          style:
                              theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ),
                    ],
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(detail, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
