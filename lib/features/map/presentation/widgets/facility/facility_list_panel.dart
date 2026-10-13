import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/coverage_notice.dart';
import 'package:beacon_app/core/widgets/drag_handle.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_card.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FacilityListPanel extends StatelessWidget {
  /// The facilities to list: the ones on screen, nearest the middle of the
  /// map first.
  final List<Facility> facilities;

  /// How many facilities match the current filters across the whole loaded
  /// area. When this is above zero but [facilities] is empty, the matches are
  /// simply off screen, and the panel says so instead of "no facilities".
  final int totalMatches;
  final ScrollController scrollController;
  final bool isLoading;
  final bool isPanelOpen;
  final bool isFullyExpanded;
  final bool isSearchActive;
  final String? expandedFacilityId;
  final Function(String) onToggleFacilityExpansion;
  final Function(String) onToggleFavorite;
  final Future<void> Function(String) onLaunchUrl;
  final Widget Function(String?) buildCategoryIcon;
  final Function(bool isPanelOpen, bool isFullyExpanded)? onPanelStateChange;

  /// When false, every rendered [FacilityCard] disables its heart icon (used
  /// in guest mode where favorites require sign-in).
  final bool canFavorite;

  /// Opens the "request a facility" flow from the empty state ("Can't find a
  /// facility? Submit a request to add one").
  final void Function()? onRequestFacility;

  /// Opens the rating flow for a facility (expanded cards show an
  /// "Already visited? Rate your experience" row when non-null).
  final void Function(Facility)? onRateFacility;

  /// Opens the corrections flow for a facility (expanded cards show an
  /// "Incorrect info?" row when non-null).
  final void Function(Facility)? onCorrectFacility;

  const FacilityListPanel({
    super.key,
    required this.facilities,
    required this.scrollController,
    required this.isLoading,
    required this.isPanelOpen,
    required this.isFullyExpanded,
    required this.isSearchActive,
    required this.expandedFacilityId,
    required this.onToggleFacilityExpansion,
    required this.onToggleFavorite,
    required this.onLaunchUrl,
    required this.buildCategoryIcon,
    this.totalMatches = 0,
    this.onPanelStateChange,
    this.canFavorite = true,
    this.onRequestFacility,
    this.onRateFacility,
    this.onCorrectFacility,
  });

  /// The panel's height in each of its states. Shared with the map, which
  /// needs to know how much of itself the panel covers.
  static double heightFor(
    MediaQueryData mediaQuery, {
    required bool isPanelOpen,
    required bool isFullyExpanded,
    required bool isSearchActive,
  }) {
    final screenHeight = mediaQuery.size.height;
    final defaultHeight = screenHeight * MapConstants.panelDefaultHeightRatio;
    if (isSearchActive) return defaultHeight;
    if (!isPanelOpen) return MapConstants.panelMinHeight;
    if (!isFullyExpanded) return defaultHeight;
    return screenHeight -
        (MapConstants.searchBarAreaHeight +
            mediaQuery.padding.top +
            kToolbarHeight +
            MapConstants.panelBottomOffset);
  }

  @override
  Widget build(BuildContext context) {
    final targetHeight = heightFor(
      MediaQuery.of(context),
      isPanelOpen: isPanelOpen,
      isFullyExpanded: isFullyExpanded,
      isSearchActive: isSearchActive,
    );

    return GestureDetector(
      onVerticalDragEnd: isSearchActive
          ? null
          : (details) {
              final double velocity = details.primaryVelocity ?? 0;
              const double minFlickVelocity = MapConstants.minFlickVelocity;

              if (velocity < -minFlickVelocity) {
                // Swipe up
                if (!isPanelOpen) {
                  // From collapsed to default
                  onPanelStateChange?.call(true, false);
                } else if (!isFullyExpanded) {
                  // From default to expanded
                  onPanelStateChange?.call(true, true);
                }
              } else if (velocity > minFlickVelocity) {
                // Swipe down
                if (isFullyExpanded) {
                  // From expanded to default
                  onPanelStateChange?.call(true, false);
                } else if (isPanelOpen) {
                  // From default to collapsed
                  onPanelStateChange?.call(false, false);
                }
              }
            },
      child: AnimatedContainer(
        duration: MapConstants.animationDuration,
        curve: MapConstants.animationCurve,
        height: targetHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: AppRadii.sheetTop,
          boxShadow: AppShadows.sheet,
        ),
        child: Column(
          children: [
            _buildPanelHeader(context),
            if (isPanelOpen || isFullyExpanded) _buildFacilityList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MapConstants.panelHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          const DragHandle(),
          const SizedBox(height: AppSpacing.sm),
          if (!isPanelOpen && !isFullyExpanded)
            Text(
              AppLocalizations.of(context)!.mapSwipeUpToView,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceMuted,
              ),
            )
          else
            Text(
              // The count ties the list to the map: it is what's on screen.
              isLoading || facilities.isEmpty
                  ? AppLocalizations.of(context)!.mapResourcesNearYou
                  : AppLocalizations.of(context)!
                      .mapResourcesInView(facilities.length),
              style: theme.textTheme.titleLarge,
            ),
        ],
      ),
    );
  }

  Widget _buildFacilityList(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onPanUpdate: (details) {
          if (isFullyExpanded &&
              scrollController.hasClients &&
              scrollController.position.pixels <= 0 &&
              details.delta.dy > 0) {
            if (details.delta.dy > MapConstants.panelDragThreshold) {
              // Pull down from expanded to default
              onPanelStateChange?.call(true, false);
            }
          }
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (isFullyExpanded &&
                notification is OverscrollNotification &&
                notification.overscroll < 0 &&
                notification.dragDetails != null) {
              // Overscroll from expanded to default
              onPanelStateChange?.call(true, false);
              return true;
            }
            return false;
          },
          child: isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxxl),
                    child: CircularProgressIndicator(),
                  ),
                )
              : facilities.isEmpty
                  ? (totalMatches > 0
                      ? _buildNothingInView(context)
                      : _buildEmptyState(context))
                  : ListView.builder(
                      controller: scrollController,
                      physics: isFullyExpanded
                          ? const ClampingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            )
                          : const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: MapConstants.listBottomInset,
                      ),
                      itemCount: facilities.length,
                      itemBuilder: (context, index) {
                        final facility = facilities[index];
                        final isExpanded = facility.id == expandedFacilityId;
                        return FacilityCard(
                          facility: facility,
                          isExpanded: isExpanded,
                          onToggleExpand: () =>
                              onToggleFacilityExpansion(facility.id),
                          onToggleFavorite: () => onToggleFavorite(facility.id),
                          onLaunchUrl: onLaunchUrl,
                          buildCategoryIcon: buildCategoryIcon,
                          canFavorite: canFavorite,
                          onRate: onRateFacility == null
                              ? null
                              : () => onRateFacility!(facility),
                          onSubmitCorrection: onCorrectFacility == null
                              ? null
                              : () => onCorrectFacility!(facility),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  /// There are matches nearby, just none where the map is looking. Distinct
  /// from [_buildEmptyState] so nobody is told to request a facility, or that
  /// Beacon doesn't cover them, when all they need to do is zoom out.
  Widget _buildNothingInView(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.zoom_out_map,
              size: AppIconSize.xxl,
              color: theme.colorScheme.onSurfaceMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.mapNothingInView, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.mapNothingInViewHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // Scrollable + top-aligned so it never overflows when the panel is short
    // (collapsed, or mid drag/animation the Expanded height can be ~0).
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: AppIconSize.xxl,
              color: theme.colorScheme.onSurfaceMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context)!.mapNoFacilitiesInArea,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppLocalizations.of(context)!.mapCantFindFacility,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const CoverageNotice(),
            if (onRequestFacility != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: () => onRequestFacility!(),
                icon: const Icon(
                  Icons.add_business_outlined,
                  size: AppIconSize.md,
                ),
                label: Text(AppLocalizations.of(context)!.mapRequestFacility),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
