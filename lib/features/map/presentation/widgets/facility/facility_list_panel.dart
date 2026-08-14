import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/core/widgets/coverage_notice.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_card.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FacilityListPanel extends StatelessWidget {
  final List<Facility> facilities;
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
    this.onPanelStateChange,
    this.canFavorite = true,
    this.onRequestFacility,
    this.onRateFacility,
    this.onCorrectFacility,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;
    const minHeight = MapConstants.panelMinHeight;
    final defaultHeight = screenHeight * MapConstants.panelDefaultHeightRatio;
    final maxHeight = screenHeight -
        (MapConstants.searchBarAreaHeight +
            topPadding +
            kToolbarHeight +
            MapConstants.panelBottomOffset);

    final double targetHeight;
    if (isSearchActive) {
      targetHeight = defaultHeight;
    } else if (!isPanelOpen) {
      targetHeight = minHeight;
    } else if (isFullyExpanded) {
      targetHeight = maxHeight;
    } else {
      targetHeight = defaultHeight;
    }

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
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(MapConstants.panelBorderRadius),
            topRight: Radius.circular(MapConstants.panelBorderRadius),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10.0,
              offset: Offset(0, -2),
            ),
          ],
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
    return Container(
      height: MapConstants.panelHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: MapConstants.panelHandleWidth,
            height: MapConstants.panelHandleHeight,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          if (!isPanelOpen && !isFullyExpanded)
            Text(
              AppLocalizations.of(context)!.mapSwipeUpToView,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            )
          else
            Text(
              AppLocalizations.of(context)!.mapResourcesNearYou,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
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
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : facilities.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      controller: scrollController,
                      physics: isFullyExpanded
                          ? const ClampingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            )
                          : const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8.0, bottom: 100.0),
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

  Widget _buildEmptyState(BuildContext context) {
    // Scrollable + top-aligned so it never overflows when the panel is short
    // (collapsed, or mid drag/animation the Expanded height can be ~0).
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.mapNoFacilitiesInArea,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.mapCantFindFacility,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const CoverageNotice(),
            if (onRequestFacility != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => onRequestFacility!(),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.resedaGreen,
                ),
                icon: const Icon(Icons.add_business_outlined, size: 18),
                label: Text(AppLocalizations.of(context)!.mapRequestFacility),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
