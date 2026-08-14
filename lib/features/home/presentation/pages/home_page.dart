import 'dart:async';

import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/widgets/apple_sign_in_button.dart';
import 'package:beacon_app/core/widgets/facility_rating_dialog.dart';
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

    return Scaffold(
      // One page-level scroll view avoids nested-scroll conflicts between
      // Recently Viewed and Favorites.
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: statusBarHeight + 8),
            Center(
              child: Image.asset(
                'assets/beacon-logo.png',
                height: 70,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.homeGreeting,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMapAndCategories(),
            const SizedBox(height: 20),
            Text(
              l10n.homeRecentlyViewed,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildRecentlyViewedSection(isGuest: isGuest),
            const SizedBox(height: 20),
            Text(
              l10n.homeFavorites,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildFavoritesSection(l10n, isGuest: isGuest),
            const SizedBox(height: 16),
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                for (var row = 0; row < 2; row++) ...[
                  if (row > 0) const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        for (var col = 0; col < 3; col++) ...[
                          if (col > 0) const SizedBox(width: 6),
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
            color: action.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                action.icon,
                color: action.color,
                size: 20,
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
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
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
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

  /// "Recently Viewed Facilities". Height is bounded so this never pushes the
  /// Favorites section off-screen.
  Widget _buildRecentlyViewedSection({required bool isGuest}) {
    return Consumer<RecentFacilitiesService>(
      builder: (context, service, _) {
        final recent = service.recentFacilities;
        if (recent.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, size: 24, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.homeNoRecentlyViewed,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.homeNoRecentlyViewedHint,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Rows render inline so the whole page scrolls as one unit.
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // Transparent Material so ListTile ink paints above the
            // Container's background, which would otherwise hide it.
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  for (var i = 0; i < recent.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: Colors.grey[200]),
                    _buildRecentRow(recent[i], isGuest: isGuest),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Single compact row used for both the Recently Viewed and Favorites
  /// populated lists. Kept dense so the Home page stays usable when both
  /// sections have items.
  Widget _buildRecentRow(Facility facility, {required bool isGuest}) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 2,
      ),
      visualDensity: VisualDensity.compact,
      leading: FacilityCategoryIcons.buildCategoryIcon(
        facility.primaryCategory,
      ),
      title: Text(
        facility.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        facility.address,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => _onRecentFacilityTap(facility, isGuest: isGuest),
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
      return Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
                const SizedBox(height: 10),
                const Text(
                  'Sign in to access Favorites',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Save your favorite facilities by signing in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                Builder(
                  builder: (innerContext) => AppleSignInButton(
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
          return Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 28,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.homeNoFavorites,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.homeNoFavoritesHint,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Cap the height so favorites scroll internally past ~4 items
        // instead of pushing the rest of the page down indefinitely.
        return Container(
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // Transparent Material so ListTile ink paints above the
            // Container's background, which would otherwise hide it.
            child: Material(
              type: MaterialType.transparency,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: favoriteFacilities.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, i) => ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  visualDensity: VisualDensity.compact,
                  leading: FacilityCategoryIcons.buildCategoryIcon(
                    favoriteFacilities[i].primaryCategory,
                  ),
                  title: Text(
                    favoriteFacilities[i].name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    favoriteFacilities[i].address,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => _navigateToFacility(favoriteFacilities[i]),
                ),
              ),
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
