import 'dart:async';

import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/facility_rating_dialog.dart';
import 'package:beacon_app/core/widgets/native_sign_in_button.dart';
import 'package:beacon_app/core/widgets/sign_in_prompt_dialog.dart';
import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/data/facility_repository.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/providers/facility_provider.dart';
import 'package:beacon_app/features/map/presentation/services/location_service.dart';
import 'package:beacon_app/features/map/presentation/services/map_style_service.dart';
import 'package:beacon_app/features/map/presentation/widgets/markers/marker_icon_factory.dart';
import 'package:beacon_app/features/map/utils/facility_formatting.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final Function(int, Facility?, {String? categoryFilter})? onNavigateToMap;

  const HomePage({super.key, this.onNavigateToMap});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage> {
  late final FacilityRepositoryBase _facilityRepository;
  LatLng _currentLocation =
      const LatLng(MapConstants.defaultLatitude, MapConstants.defaultLongitude);
  GoogleMapController? _mapController;
  String? _mapStyle;
  Set<Marker> _markers = {};
  Brightness? _lastBrightness;
  bool _locationGranted = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _facilityRepository = FacilityRepository();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _refreshLocationPermission();
    });
  }

  Future<void> _refreshLocationPermission() async {
    final granted = await LocationService.hasPermission();
    if (mounted && granted != _locationGranted) {
      setState(() => _locationGranted = granted);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (brightness != _lastBrightness) {
      _lastBrightness = brightness;
      _loadMapStyle();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final facilityProvider = context.read<FacilityProvider>();

    try {
      facilityProvider.setLoading(true);

      final zipService = ZipCodeService();
      final double latitude = zipService.latitude;
      final double longitude = zipService.longitude;

      final facilities = await _facilityRepository
          .loadFacilitiesWithDistance(
        latitude: latitude,
        longitude: longitude,
        radiusMiles: MapConstants.defaultRadiusMiles,
      )
          .timeout(
        MapConstants.facilityQueryTimeout,
        onTimeout: () {
          return [];
        },
      );

      if (!mounted) {
        return;
      }

      final newLocation = LatLng(latitude, longitude);

      facilityProvider.setFacilities(facilities);

      // The marker factory yields inside this loop, so `mounted` must be
      // re-checked before the trailing setState.
      final markers = <Marker>{};
      for (final facility in facilities) {
        if (facility.location.latitude == 0.0 &&
            facility.location.longitude == 0.0) {
          continue;
        }
        final icon = await MarkerUtils.createFacilityMarker(
          '',
          facility.isFavorite,
          facility.primaryCategory,
          context,
          showName: false,
        );
        markers.add(
          Marker(
            markerId: MarkerId(facility.id),
            position: facility.location,
            icon: icon,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _markers = markers;
        _currentLocation = newLocation;
      });

      await Future.delayed(const Duration(milliseconds: 300));
      // Re-checked after the delay, not before: the user can leave the tab
      // while it's pending, disposing the controller mid-flight.
      if (!mounted || _mapController == null) return;

      try {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            _currentLocation,
            MapConstants.homeCutoutZoom,
          ),
        );
      } catch (e, stackTrace) {
        // A dispose mid-flight throws here; that race is expected, so only
        // report if the widget is somehow still alive.
        if (!mounted) return;
        ErrorReporter.instance.report(
          e,
          stackTrace,
          context: 'HomePage.cameraAnimate',
        );
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance
          .report(e, stackTrace, context: 'HomePage._loadData');
      if (mounted) {
        facilityProvider.setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.mapLoadFailed),
          ),
        );
      }
    }
  }

  Future<void> _loadMapStyle() async {
    final brightness = _lastBrightness ?? Brightness.light;
    final style = await MapStyleService.loadMapStyle(brightness: brightness);
    if (mounted) {
      setState(() => _mapStyle = style);
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    final facilityProvider = context.read<FacilityProvider>();

    _mapController = controller;
    if (!mounted) return;

    if (facilityProvider.facilities.isEmpty) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (_currentLocation.latitude != MapConstants.defaultLatitude) {
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            _currentLocation,
            MapConstants.homeCutoutZoom,
          ),
        );
      } catch (e, stackTrace) {
        if (!mounted) return;
        ErrorReporter.instance.report(
          e,
          stackTrace,
          context: 'HomePage._onMapCreated.animateCamera',
        );
      }
    }
  }

  void _navigateToMapPage() {
    if (widget.onNavigateToMap != null) {
      widget.onNavigateToMap!(1, null);
    }
  }

  void _navigateToFacility(Facility facility) {
    if (widget.onNavigateToMap != null) {
      widget.onNavigateToMap!(1, facility);
    }
  }

  void _navigateToMapWithCategory(String category) {
    if (widget.onNavigateToMap != null) {
      widget.onNavigateToMap!(1, null, categoryFilter: category);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final isGuest = context.watch<GuestModeService>().isGuest;
    final sectionTitle = Theme.of(context).textTheme.titleLarge;

    return Scaffold(
      // One page-level scroll view avoids nested-scroll conflicts between
      // Recently Viewed and Favorites.
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: statusBarHeight + AppSpacing.sm),
            Center(
              child: Image.asset(
                'assets/beacon-logo.png',
                height: AppSizes.logoCompact,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(l10n.homeGreeting, style: sectionTitle),
            const SizedBox(height: AppSpacing.lg),
            _buildMapAndCategories(),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.homeRecentlyViewed, style: sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            _buildRecentlyViewedSection(isGuest: isGuest),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.homeFavorites, style: sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            _buildFavoritesSection(l10n, isGuest: isGuest),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// Localized label for a quick-action group. The group constant itself stays
  /// canonical English — it's the filter value and the icon/color key — so only
  /// the display string is translated.
  String _groupLabel(AppLocalizations l10n, String group) => switch (group) {
        FacilityCategories.groupHealthCare => l10n.homeCategoryHealthCare,
        FacilityCategories.groupMentalHealth => l10n.homeCategoryMentalHealth,
        FacilityCategories.groupHousingShelter => l10n.homeCategoryHousing,
        FacilityCategories.groupBasicNeeds => l10n.homeCategoryBasicNeeds,
        FacilityCategories.groupCommunity => l10n.homeCategoryCommunity,
        FacilityCategories.groupSpecialized => l10n.homeCategorySpecialized,
        _ => group,
      };

  Widget _buildMapAndCategories() {
    // Driven off the shared taxonomy so labels, icons, and the resulting map
    // filter stay in sync with the markers.
    final l10n = AppLocalizations.of(context)!;
    final actions = [
      for (final group in FacilityCategories.quickActionGroups)
        _QuickAction(
          icon: MarkerUtils.getIconForCategory(group),
          label: _groupLabel(l10n, group),
          color: MarkerUtils.getColorForCategory(group),
          category: group,
        ),
    ];

    return SizedBox(
      height: 160,
      child: Row(
        children: [
          // 2:3 split — the map gives up width so the 3-column quick-action
          // grid has room for readable labels.
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _navigateToMapPage,
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  borderRadius: AppRadii.lgAll,
                  boxShadow: AppShadows.raised,
                ),
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      style: _mapStyle,
                      initialCameraPosition: CameraPosition(
                        target: _currentLocation,
                        zoom: MapConstants.homeCutoutZoom,
                      ),
                      markers: _markers,
                      myLocationEnabled: _locationGranted,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                      minMaxZoomPreference: const MinMaxZoomPreference(12, 18),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                for (var row = 0; row < 2; row++) ...[
                  if (row > 0) const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: Row(
                      children: [
                        for (var col = 0; col < 3; col++) ...[
                          if (col > 0) const SizedBox(width: AppSpacing.sm),
                          _buildCategoryButton(actions[row * 3 + col]),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(_QuickAction action) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _navigateToMapWithCategory(action.category),
        child: Container(
          decoration: BoxDecoration(
            color: action.color.tint,
            borderRadius: AppRadii.mdAll,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: action.color, size: AppIconSize.md),
              const SizedBox(height: AppSpacing.xxs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                // Tiles are ~58pt wide on the smallest device. The SizedBox
                // pins the width so the label wraps to two lines first;
                // FittedBox only shrinks it if that still overflows.
                child: LayoutBuilder(
                  builder: (context, constraints) => FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Text(
                        action.label,
                        textAlign: TextAlign.center,
                        style: AppTypography.quickActionLabel.copyWith(
                          color: action.color,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Icon + title + hint card shown when a Home list has nothing in it.
  Widget _buildEmptyStateRow({
    required IconData icon,
    required String title,
    required String hint,
  }) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceMuted;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppRadii.mdAll,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.lg, color: muted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(color: muted),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Rounded, shadowed container for the populated Home lists. The
  /// transparent Material lets ListTile ink paint above the background.
  Widget _buildListCard({required Widget child, double? maxHeight}) {
    return Container(
      constraints:
          maxHeight == null ? null : BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: AppRadii.mdAll,
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.mdAll,
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }

  /// "Recently Viewed Facilities". Height is bounded so this never pushes the
  /// Favorites section off-screen.
  Widget _buildRecentlyViewedSection({required bool isGuest}) {
    return Consumer<RecentFacilitiesService>(
      builder: (context, service, _) {
        final recent = service.recentFacilities;
        if (recent.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return _buildEmptyStateRow(
            icon: Icons.history,
            title: l10n.homeNoRecentlyViewed,
            hint: l10n.homeNoRecentlyViewedHint,
          );
        }

        // Rows render inline so the whole page scrolls as one unit.
        return _buildListCard(
          child: Column(
            children: [
              for (var i = 0; i < recent.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _buildFacilityRow(
                  recent[i],
                  onTap: () => _onRecentFacilityTap(
                    recent[i],
                    isGuest: isGuest,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Single compact row used for both the Recently Viewed and Favorites
  /// populated lists. Kept dense so the Home page stays usable when both
  /// sections have items.
  Widget _buildFacilityRow(Facility facility, {required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      visualDensity: VisualDensity.compact,
      leading: FacilityCategoryIcons.buildCategoryIcon(
        facility.primaryCategory,
      ),
      title: Text(
        facility.name,
        style: theme.textTheme.titleSmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        facility.address,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceMuted,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, size: AppIconSize.md),
      onTap: onTap,
    );
  }

  /// Routes a tap on a recently-viewed facility:
  ///   - guest → sign-in prompt
  ///   - signed in → rating dialog
  void _onRecentFacilityTap(
    Facility facility, {
    required bool isGuest,
  }) {
    if (isGuest) {
      showSignInPromptDialog(context);
      return;
    }
    showFacilityRatingDialog(context, facility: facility);
  }

  Widget _buildFavoritesSection(AppLocalizations l10n,
      {required bool isGuest}) {
    if (isGuest) {
      final theme = Theme.of(context);
      final muted = theme.colorScheme.onSurfaceMuted;
      return Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: AppRadii.mdAll,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: AppIconSize.xxl, color: muted),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.homeFavoritesSignInTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(color: muted),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.homeFavoritesSignInHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
                const SizedBox(height: AppSpacing.md),
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
      );
    }

    return Consumer<FacilityProvider>(
      builder: (context, facilityProvider, child) {
        if (facilityProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final favoriteFacilities = facilityProvider.favoriteFacilities;

        if (favoriteFacilities.isEmpty) {
          // Kept short: available height shrinks a lot when Recently Viewed
          // is populated above.
          return _buildEmptyStateRow(
            icon: Icons.favorite_border,
            title: l10n.homeNoFavorites,
            hint: l10n.homeNoFavoritesHint,
          );
        }

        // Cap the height so favorites scroll internally past ~4 items
        // instead of pushing the rest of the page down indefinitely.
        return _buildListCard(
          maxHeight: 280,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: favoriteFacilities.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _buildFacilityRow(
              favoriteFacilities[i],
              onTap: () => _navigateToFacility(favoriteFacilities[i]),
            ),
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String category;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.category,
  });
}
