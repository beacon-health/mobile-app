import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_card.dart';
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
            if (isPanelOpen || isFullyExpanded) _buildFacilityList(),
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
            const Text(
              'Swipe up to view resources',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            )
          else
            Text(
              'Resources near you',
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

  Widget _buildFacilityList() {
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
                    );
                  },
                ),
        ),
      ),
    );
  }
}
