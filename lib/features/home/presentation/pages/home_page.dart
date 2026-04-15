import 'dart:async';

import 'package:beacon_app/core/services/demo_mode_service.dart';
import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/widgets/sign_in_prompt_dialog.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/data/demo_facility_repository.dart';
import 'package:beacon_app/features/map/data/facility_repository.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/providers/facility_provider.dart';
import 'package:beacon_app/features/map/presentation/services/location_service.dart';
import 'package:beacon_app/features/map/presentation/services/map_style_service.dart';
import 'package:beacon_app/features/map/presentation/widgets/markers/marker_utils.dart';
import 'package:beacon_app/features/map/utils/facility_display_utils.dart';
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final isDemoMode = DemoModeService().isDemoMode;
    _facilityRepository =
        isDemoMode ? DemoFacilityRepository() : FacilityRepository();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _loadMapStyle();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final facilityProvider =
        Provider.of<FacilityProvider>(context, listen: false);

    try {
      facilityProvider.setLoading(true);

      double latitude = MapConstants.defaultLatitude;
      double longitude = MapConstants.defaultLongitude;

      try {
        final locationResult =
            await LocationService.getCurrentLocation().timeout(
          const Duration(seconds: 10),
        );
        latitude = locationResult.latitude;
        longitude = locationResult.longitude;
      } catch (e, stackTrace) {
        // Location unavailable — use defaults above.
        ErrorReporter.instance.report(
          e,
          stackTrace,
          context: 'HomePage._loadData.location',
        );
      }

      final facilities = await _facilityRepository
          .loadFacilitiesWithDistance(
        latitude: latitude,
        longitude: longitude,
        radiusMiles: 5.0,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          return [];
        },
      );

      if (!mounted) {
        return;
      }

      final newLocation = LatLng(latitude, longitude);

      facilityProvider.setFacilities(facilities);

      // Build custom markers matching the map page style
      if (mounted) {
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
        });
      }

      setState(() {
        _currentLocation = newLocation;
      });

      if (_mapController != null && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));

        try {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation, 14.0),
          );
        } catch (e, stackTrace) {
          // Camera animation failure is non-critical.
          ErrorReporter.instance.report(
            e,
            stackTrace,
            context: 'HomePage.cameraAnimate',
          );
        }
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(e, stackTrace, context: 'HomePage._loadData');
      if (mounted) {
        facilityProvider.setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't load facilities — try again")),
        );
      }
    }
  }

  Future<void> _loadMapStyle() async {
    _mapStyle ??= await MapStyleService.loadMapStyle();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    final facilityProvider =
        Provider.of<FacilityProvider>(context, listen: false);

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
          CameraUpdate.newLatLngZoom(_currentLocation, 14.0),
        );
      } catch (_) {
        // Camera animation failure is non-critical.
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
      body: Padding(
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
            const SizedBox(height: 30),
            Text(
              l10n.homeGreeting,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMapAndCategories(l10n),
            const SizedBox(height: 20),
            Text(
              l10n.homeFavorites,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildFavoritesSection(l10n, isGuest: isGuest)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMapAndCategories(AppLocalizations l10n) {
    final actions = [
      _QuickAction(
        icon: Icons.local_hospital,
        label: l10n.homeUrgentCare,
        color: MarkerUtils.getColorForCategory('Health Care'),
        category: 'Health Care',
      ),
      _QuickAction(
        icon: Icons.night_shelter,
        label: l10n.homeHousing,
        color: MarkerUtils.getColorForCategory('Housing & Shelter'),
        category: 'Housing & Shelter',
      ),
      _QuickAction(
        icon: Icons.medical_services,
        label: l10n.homeFreeClinics,
        color: MarkerUtils.getColorForCategory('Health Care'),
        category: 'Health Care',
      ),
      _QuickAction(
        icon: Icons.volunteer_activism,
        label: l10n.homeFoodPantry,
        color: MarkerUtils.getColorForCategory('Basic Needs'),
        category: 'Basic Needs',
      ),
    ];

    return SizedBox(
      height: 160,
      child: Row(
        children: [
          Expanded(
            flex: 1,
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
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    style: _mapStyle,
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation,
                      zoom: 14.0,
                    ),
                    markers: _markers,
                    // TODO: re-enable when location permission is added back post-MVP
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    minMaxZoomPreference: const MinMaxZoomPreference(10, 18),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildCategoryButton(actions[0]),
                      const SizedBox(width: 8),
                      _buildCategoryButton(actions[1]),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      _buildCategoryButton(actions[2]),
                      const SizedBox(width: 8),
                      _buildCategoryButton(actions[3]),
                    ],
                  ),
                ),
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
                size: 22,
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  action.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: action.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesSection(AppLocalizations l10n, {required bool isGuest}) {
    if (isGuest) {
      return GestureDetector(
        onTap: () => showSignInPromptDialog(context),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Sign in to access Favorites',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Save your favorite facilities by signing in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
          return Center(
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.homeNoFavorites,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.homeNoFavoritesHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: favoriteFacilities.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final facility = favoriteFacilities[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: FacilityCategoryIcons.buildCategoryIcon(
                    facility.primaryCategory,
                  ),
                  title: Text(
                    facility.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    facility.address,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    size: 20,
                  ),
                  onTap: () => _navigateToFacility(facility),
                );
              },
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
