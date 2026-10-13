import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/map_launcher_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/sign_in_prompt_dialog.dart';
import 'package:beacon_app/core/widgets/tag_chip.dart';
import 'package:beacon_app/features/ask/domain/ask_request.dart';
import 'package:beacon_app/features/ask/presentation/ask_controller.dart';
import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/constants/filter_l10n.dart';
import 'package:beacon_app/features/map/domain/models/eligibility_model.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/providers/facility_provider.dart';
import 'package:beacon_app/features/map/presentation/services/url_launcher_service.dart';
import 'package:beacon_app/features/map/utils/facility_formatting.dart';
import 'package:beacon_app/features/map/utils/map_geometry.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// What the person typed, as a bubble at the trailing edge.
class AskUserBubble extends StatelessWidget {
  const AskUserBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsetsDirectional.only(start: AppSpacing.huge),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: scheme.secondary,
          borderRadius: AppRadii.mdAll,
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSecondary),
        ),
      ),
    );
  }
}

/// 911 and 988, as two buttons that dial. Shown for a message that may come
/// from someone in danger, whatever else Ask goes on to say.
class AskCrisisCard extends StatelessWidget {
  const AskCrisisCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mdAll,
          side: BorderSide(color: scheme.error, width: AppSizes.borderSelected),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.emergency_outlined, color: scheme.error),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.askCrisisTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.askCrisisNote,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                style: AppTheme.destructiveFilledButton(context),
                onPressed: () =>
                    UrlLauncherService.launchUrlString('tel:911', context),
                icon: const Icon(Icons.call),
                label: Text(l10n.askCall911),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () =>
                    UrlLauncherService.launchUrlString('tel:988', context),
                icon: const Icon(Icons.call),
                label: Text(l10n.askCall988),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An answer: how the request was read, the places that match, and what to
/// do next. Nothing here is written by the model.
class AskAnswer extends StatelessWidget {
  const AskAnswer({
    super.key,
    required this.message,
    required this.onShowFacility,
    required this.onShowOnMap,
    required this.onOnlyOpenNow,
  });

  final AskAnswerMessage message;
  final ValueChanged<Facility> onShowFacility;
  final VoidCallback onShowOnMap;

  /// Narrows the same search to places open now. Null when that was already
  /// asked for.
  final VoidCallback? onOnlyOpenNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final muted = theme.colorScheme.onSurfaceVariant;
    final searchedFor = askFilterLabels(l10n, message.filters);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            [
              l10n.askFoundSummary(message.totalCount),
              if (message.noneOpenNow) l10n.askNoneOpenNow,
            ].join(' '),
            style: theme.textTheme.bodyLarge,
          ),
        ),
        // How the request was read, so a wrong reading is plain to see.
        if (searchedFor.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.askSearchedFor,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final label in searchedFor)
                TagChip(label: label, color: theme.colorScheme.secondary),
            ],
          ),
        ],
        for (final facility in message.facilities) ...[
          const SizedBox(height: AppSpacing.sm),
          AskFacilityCard(
            facility: facility,
            origin: message.origin,
            onTap: () => onShowFacility(facility),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: AppIconSize.sm,
              color: muted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.askAiNote,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: onShowOnMap,
              icon: const Icon(Icons.map_outlined),
              label: Text(l10n.askShowOnMap),
            ),
            if (onOnlyOpenNow != null)
              OutlinedButton.icon(
                onPressed: onOnlyOpenNow,
                icon: const Icon(Icons.schedule),
                label: Text(l10n.askOnlyOpenNow),
              ),
          ],
        ),
      ],
    );
  }
}

/// One result. Everything on it comes from the facility record.
class AskFacilityCard extends StatelessWidget {
  const AskFacilityCard({
    super.key,
    required this.facility,
    required this.origin,
    required this.onTap,
  });

  final Facility facility;
  final LatLng origin;

  /// Opens the facility on the Map.
  final VoidCallback onTap;

  static const double _metersPerMile = 1609.344;

  String _distance(BuildContext context) {
    final miles =
        MapGeometry.distanceMeters(origin, facility.location) / _metersPerMile;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return AppLocalizations.of(context)!.askDistanceMiles(
      NumberFormat('0.0', locale).format(miles < 0.1 ? 0.1 : miles),
    );
  }

  void _toggleFavorite(BuildContext context) {
    // Favorites live with an account.
    if (GuestModeService().isGuest) {
      showSignInPromptDialog(context);
      return;
    }
    context.read<FacilityProvider>().toggleFavoriteOf(facility);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final muted = scheme.onSurfaceVariant;
    final isFavorite =
        context.watch<FacilityProvider>().favoriteIds.contains(facility.id);
    final eligibility = facility.eligibility;
    final chips = [
      if (eligibility?.freeServicesAvailable == EligibilityValue.yes)
        TagChip(
          label: l10n.chipFree,
          icon: Icons.money_off,
          color: scheme.primaryText,
        ),
      if (eligibility?.acceptsWalkins == EligibilityValue.yes)
        TagChip(
          label: l10n.chipWalkIns,
          icon: Icons.directions_walk,
          color: scheme.primaryText,
        ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.facilityCard,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.md,
            top: AppSpacing.md,
            bottom: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FacilityCategoryIcons.buildCategoryIcon(facility.primaryCategory),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      [
                        _distance(context),
                        if (facility.isOpenNow) l10n.filterOpenNow,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    if (facility.hasAddress) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        facility.address,
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: chips,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: isFavorite
                        ? l10n.cardUnsave(facility.name)
                        : l10n.cardSave(facility.name),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.favorite : muted,
                    ),
                    onPressed: () => _toggleFavorite(context),
                  ),
                  if (facility.hasAddress)
                    IconButton(
                      tooltip: l10n.askDirectionsTo(facility.name),
                      icon: Icon(Icons.directions, color: scheme.primary),
                      onPressed: () => MapLauncherService.openDirections(
                        context,
                        address: facility.address,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ask couldn't answer: says why, and offers the Map with whatever filters it
/// did work out.
class AskHandoff extends StatelessWidget {
  const AskHandoff({super.key, required this.message, required this.onOpenMap});

  final AskHandoffMessage message;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final filters = message.filters;
    final chips = askFilterLabels(l10n, filters);
    final text = switch (message.reason) {
      AskHandoffReason.unclear => l10n.askHandoffUnclear,
      AskHandoffReason.noResults => l10n.askHandoffNoResults,
      AskHandoffReason.medicalAdvice => l10n.askHandoffMedical,
      AskHandoffReason.offTopic => l10n.askHandoffOffTopic,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(text, style: theme.textTheme.bodyLarge),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpenMap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.map, color: theme.colorScheme.secondary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          chips.isEmpty
                              ? l10n.askOpenMap
                              : l10n.askOpenMapWithFilters,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final chip in chips)
                          TagChip(
                            label: chip,
                            color: theme.colorScheme.secondary,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The filters in words, for the hand-off card.
List<String> askFilterLabels(AppLocalizations l10n, AskFilters filters) => [
      for (final group in FacilityCategories.quickActionGroups)
        if (filters.groups.contains(group))
          switch (group) {
            FacilityCategories.groupHealthCare => l10n.homeCategoryHealthCare,
            FacilityCategories.groupMentalHealth =>
              l10n.homeCategoryMentalHealth,
            FacilityCategories.groupHousingShelter => l10n.homeCategoryHousing,
            FacilityCategories.groupBasicNeeds => l10n.homeCategoryBasicNeeds,
            FacilityCategories.groupCommunity => l10n.homeCategoryCommunity,
            _ => l10n.homeCategorySpecialized,
          },
      if (filters.openNow) l10n.filterOpenNow,
      for (final need in PreferenceRequirement.values)
        if (filters.preferences.contains(need))
          switch (need) {
            PreferenceRequirement.freeServicesAvailable => l10n.chipFree,
            PreferenceRequirement.slidingScaleAvailable =>
              l10n.chipSlidingScale,
            PreferenceRequirement.acceptsWalkins => l10n.chipWalkIns,
            PreferenceRequirement.telehealthAvailable => l10n.chipTelehealth,
            PreferenceRequirement.wheelchairAccessible => l10n.chipAccessible,
            PreferenceRequirement.otherLanguages => l10n.chipOtherLanguages,
            PreferenceRequirement.openToImmigrants => l10n.chipImmigrants,
            PreferenceRequirement.appointmentOnly ||
            PreferenceRequirement.servesOutsideArea =>
              need.localizedName(l10n),
          },
      if (filters.keyword.isNotEmpty) '“${filters.keyword}”',
    ];
