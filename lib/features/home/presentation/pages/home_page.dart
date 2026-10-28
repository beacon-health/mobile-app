import 'dart:async';

import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/beacon_logo.dart';
import 'package:beacon_app/core/widgets/native_sign_in_buttons.dart';
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

  /// See MapPageState: the blue dot needs both OS permission and the user
  /// having chosen GPS over a ZIP.
  bool _gpsMode = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _facilityRepository = context.read<FacilityRepositoryBase>();
    final zipService = ZipCodeService();
    _gpsMode = zipService.locationSearchEnabled;
    // This page stays alive in the IndexedStack, so initState runs once;
    // without listening, the map cutout kept showing the old location after
    // the user changed it in Settings.
    zipService.addListener(_onZipServiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _refreshLocationPermission();
    });
  }

  void _onZipServiceChanged() {
    if (!mounted) return;
    final zipService = ZipCodeService();
    final moved = zipService.latitude != _currentLocation.latitude ||
        zipService.longitude != _currentLocation.longitude;
    final gpsMode = zipService.locationSearchEnabled;
    if (gpsMode != _gpsMode) setState(() => _gpsMode = gpsMode);
    if (moved) {
      unawaited(_loadData());
      unawaited(_refreshLocationPermission());
    }
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
    ZipCodeService().removeListener(_onZipServiceChanged);
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
        await _recenterPreview(_mapController!);
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

  /// Points the preview at the saved location: a flight, or a cut for someone
  /// who has asked the OS to reduce motion.
  Future<void> _recenterPreview(GoogleMapController controller) {
    final update = CameraUpdate.newLatLngZoom(
      _currentLocation,
      MapConstants.homeCutoutZoom,
    );
    return AppMotion.reduced(context)
        ? controller.moveCamera(update)
        : controller.animateCamera(update);
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
        await _recenterPreview(controller);
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
    Widget sectionTitle(String text) => Semantics(
          header: true,
          child: Text(text, style: Theme.of(context).textTheme.titleLarge),
        );

    return Scaffold(
      // One page-level scroll view avoids nested-scroll conflicts between
      // Recently Viewed and Favorites.
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: statusBarHeight + AppSpacing.sm),
            const Center(
              child: BeaconLogo(height: AppSizes.logoCompact),
            ),
            const SizedBox(height: AppSpacing.lg),
            sectionTitle(l10n.homeGreeting),
            const SizedBox(height: AppSpacing.md),
            _buildMapPreview(l10n),
            const SizedBox(height: AppSpacing.sm),
            _buildCategoryGrid(l10n),
            const SizedBox(height: AppSpacing.xl),
            sectionTitle(l10n.homeRecentlyViewed),
            const SizedBox(height: AppSpacing.md),
            _buildRecentlyViewedSection(),
            const SizedBox(height: AppSpacing.xl),
            sectionTitle(l10n.homeFavorites),
            const SizedBox(height: AppSpacing.md),
            _buildFavoritesSection(l10n, isGuest: isGuest),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// Height of the map preview, and the least a quick-action tile stands.
  static const double _mapPreviewHeight = 120;
  static const double _tileMinHeight = 76;

  /// The map as a button: a live preview with an "Open map" label, so it
  /// reads as something to tap and has a name for screen readers.
  Widget _buildMapPreview(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: l10n.homeOpenMap,
      onTap: _navigateToMapPage,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _navigateToMapPage,
        child: Container(
          height: _mapPreviewHeight,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: AppRadii.mdAll,
            boxShadow: AppShadows.card,
            border: switch (theme.colorScheme.cardOutline) {
              final side? => Border.fromBorderSide(side),
              null => null,
            },
          ),
          child: Stack(
            children: [
              Positioned.fill(
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
                      myLocationEnabled: _locationGranted && _gpsMode,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                      minMaxZoomPreference: const MinMaxZoomPreference(12, 18),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                end: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.md,
                    end: AppSpacing.lg,
                    top: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: AppRadii.pillAll,
                    boxShadow: AppShadows.raised,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map,
                        size: AppIconSize.md,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.homeOpenMap,
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The six quick actions. Driven off the shared taxonomy so labels, icons,
  /// and the resulting map filter stay in sync with the markers.
  ///
  /// Three across at ordinary text sizes; fewer as the text grows, so a label
  /// gets the width it needs instead of breaking mid-word.
  Widget _buildCategoryGrid(AppLocalizations l10n) {
    final brightness = Theme.of(context).brightness;
    final textScale = MediaQuery.textScalerOf(context).scale(100) / 100;
    final columns = textScale < 1.25 ? 3 : (textScale < 1.8 ? 2 : 1);
    final actions = [
      for (final group in FacilityCategories.quickActionGroups)
        _QuickAction(
          icon: MarkerUtils.getIconForCategory(group),
          label: FacilityCategoryIcons.groupLabel(l10n, group),
          color: MarkerUtils.getColorForCategory(group, brightness: brightness),
          category: group,
        ),
    ];

    return Column(
      children: [
        for (var start = 0; start < actions.length; start += columns) ...[
          if (start > 0) const SizedBox(height: AppSpacing.sm),
          // Tiles in a row share the height of the tallest label.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = start; i < start + columns; i++) ...[
                  if (i > start) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: i < actions.length
                        ? _buildCategoryButton(actions[i])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryButton(_QuickAction action) {
    final theme = Theme.of(context);
    return Material(
      color: action.color.tint,
      borderRadius: AppRadii.mdAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToMapWithCategory(action.category),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _tileMinHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The color belongs to the icon; the words stay in the text
                // color, which is the one that's readable.
                Icon(action.icon, color: action.color, size: AppIconSize.lg),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
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
    final muted = theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppRadii.mdAll,
        border: _cardBorder(theme),
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

  /// The hairline dark mode draws around a card in place of its shadow.
  BoxBorder? _cardBorder(ThemeData theme) =>
      switch (theme.colorScheme.cardOutline) {
        final side? => Border.fromBorderSide(side),
        null => null,
      };

  /// Rounded, shadowed container for the populated Home lists. The
  /// transparent Material lets ListTile ink paint above the background.
  Widget _buildListCard({required Widget child, double? maxHeight}) {
    final theme = Theme.of(context);
    return Container(
      constraints:
          maxHeight == null ? null : BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppRadii.mdAll,
        boxShadow: AppShadows.card,
        border: _cardBorder(theme),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.mdAll,
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }

  /// "Recently Viewed Facilities". Height is bounded so this never pushes the
  /// Favorites section off-screen.
  Widget _buildRecentlyViewedSection() {
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
                  onTap: () => _openRecentFacility(recent[i]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// One row of the Recently viewed and Favorites lists: the name and the
  /// address, a line each, as in the Map's list; the card shows it in full.
  Widget _buildFacilityRow(Facility facility, {required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(
        start: AppSpacing.md,
        end: AppSpacing.sm,
      ),
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
        style: theme.textTheme.bodySmall?.copyWith(color: muted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.chevron_right, size: AppIconSize.md, color: muted),
      onTap: onTap,
    );
  }

  /// Opens a recently viewed facility's card on the Map, as Favorites do;
  /// feedback is given from the card. The device keeps only a short record
  /// of each (name, address, location), so the full one is found first —
  /// among what the Map has loaded, else from the database. Offline, the
  /// short record still opens, with its name and directions.
  Future<void> _openRecentFacility(Facility recent) async {
    final full = context.read<FacilityProvider>().getFacilityById(recent.id) ??
        await _facilityRepository.getFacilityById(recent.id);
    if (!mounted) return;
    _navigateToFacility(full ?? recent);
  }

  Widget _buildFavoritesSection(AppLocalizations l10n,
      {required bool isGuest}) {
    if (isGuest) {
      final theme = Theme.of(context);
      final muted = theme.colorScheme.onSurfaceVariant;
      return Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: AppRadii.mdAll,
              border: _cardBorder(theme),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: AppIconSize.xxl, color: muted),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.homeFavoritesSignInTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.homeFavoritesSignInHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
                const SizedBox(height: AppSpacing.md),
                Builder(
                  builder: (innerContext) => NativeSignInButtons(
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
