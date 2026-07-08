import 'dart:async';
import 'dart:math' as math;

import 'package:beacon_app/core/services/demo_mode_service.dart';
import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/core/widgets/facility_rating_dialog.dart';
import 'package:beacon_app/core/widgets/facility_request_dialog.dart';
import 'package:beacon_app/core/widgets/sign_in_prompt_dialog.dart';
import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/data/demo_facility_repository.dart';
import 'package:beacon_app/features/map/data/facility_repository.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/providers/facility_provider.dart';
import 'package:beacon_app/features/map/presentation/services/facility_filter_service.dart';
import 'package:beacon_app/features/map/presentation/services/location_service.dart';
import 'package:beacon_app/features/map/presentation/services/map_style_service.dart';
import 'package:beacon_app/features/map/presentation/services/marker_management_service.dart';
import 'package:beacon_app/features/map/presentation/services/url_launcher_service.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_card.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_list_panel.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_bar.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_modal.dart';
import 'package:beacon_app/features/map/presentation/widgets/search/facility_search.dart';
import 'package:beacon_app/features/map/utils/facility_formatting.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage>
    with
        AutomaticKeepAliveClientMixin,
        TickerProviderStateMixin,
        WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  GoogleMapController? _googleMapController;
  bool _isMapCreated = false;
  List<Facility> _allFacilities = [];
  List<Facility> _filteredFacilities = [];

  bool _isPanelOpen = false;
  bool _isFullyExpanded = false;
  bool _isSearchActive = false;
  bool _isKeyboardVisible = false;
  Timer? _keyboardHideDebounce;
  bool _showSingleFacility = false;
  Facility? _selectedFacility;
  late final FacilityRepositoryBase _facilityRepository;
  bool _isLoading = true;
  String? _error;
  final Set<Marker> _markers = {};
  double _currentZoom = MapConstants.defaultZoom;
  double _previousZoom = MapConstants.defaultZoom;
  bool get _showFacilityNames => _currentZoom >= MapConstants.detailZoom;
  final Set<String> _selectedCategories = {};
  Map<EligibilityRequirement, bool?> _selectedEligibilityRequirements = {};
  Map<PreferenceRequirement, bool?> _selectedPreferenceRequirements = {};
  bool _showFavoritesOnly = false;
  bool _showOpenNowOnly = false;
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  Timer? _markerUpdateDebounce;
  bool _isUpdatingMarkers = false;

  late String _currentLocation;
  Brightness? _lastBrightness;

  /// True while the my-location button (in the resources search bar) resolves
  /// GPS.
  bool _isLocatingUser = false;

  double _currentLatitude = MapConstants.defaultLatitude;
  double _currentLongitude = MapConstants.defaultLongitude;

  /// Whether the OS has already granted GPS permission; controls the blue
  /// user-location dot. Re-checked after each prompt or external change.
  bool _locationGranted = false;

  /// Center the facility list was last queried around, plus the live camera
  /// target. When the two drift apart, the "Search this area" button appears
  /// (Yelp / Google Maps pattern). We never auto-query on pan.
  LatLng? _lastQueryCenter;
  LatLng? _mapCenter;
  bool _showSearchAreaButton = false;
  bool _isSearchingArea = false;

  /// Facility to center on once the map finishes creating — set when the user
  /// taps a Home Favorite before the map controller exists (first navigation).
  Facility? _pendingFacility;

  @override
  void initState() {
    super.initState();
    final isDemoMode = DemoModeService().isDemoMode;
    _facilityRepository =
        isDemoMode ? DemoFacilityRepository() : FacilityRepository();

    // Initialise location from ZipCodeService (set during onboarding).
    final zipService = ZipCodeService();
    _currentLatitude = zipService.latitude;
    _currentLongitude = zipService.longitude;
    _currentLocation = zipService.zipCode?.isNotEmpty == true
        ? zipService.zipCode!
        : MapConstants.currentLocationSentinel;

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleKeyboardMetrics();
      _loadFacilities();
      _refreshLocationPermission();
    });
    _isPanelOpen = true;
    _searchFocusNode.addListener(_onSearchFocusChange);

    // Stay in sync with ZipCodeService — when the user toggles GPS on/off
    // or edits ZIP in Settings, that fires notifyListeners(). Without this,
    // MapPage keeps the value from initState (and uses AutomaticKeepAlive
    // so initState only runs once), causing Settings and Map to drift.
    zipService.addListener(_onZipServiceChanged);
    // Map style is loaded in didChangeDependencies so it reacts to theme changes.
  }

  void _onZipServiceChanged() {
    final zipService = ZipCodeService();
    final newLabel = zipService.zipCode?.isNotEmpty == true
        ? zipService.zipCode!
        : MapConstants.currentLocationSentinel;
    final newLat = zipService.latitude;
    final newLng = zipService.longitude;

    final coordsChanged = newLat != _currentLatitude ||
        newLng != _currentLongitude;
    final labelChanged = newLabel != _currentLocation;
    if (!coordsChanged && !labelChanged) return;

    if (!mounted) return;
    setState(() {
      _currentLocation = newLabel;
      _currentLatitude = newLat;
      _currentLongitude = newLng;
    });

    if (coordsChanged) {
      // Reload facilities around the new coords and re-center the camera.
      unawaited(_loadFacilities());
      final controller = _googleMapController;
      if (controller != null) {
        unawaited(
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(newLat, newLng),
              MapConstants.radiusFramingZoom,
            ),
          ),
        );
      }
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
  void didChangeMetrics() {
    _handleKeyboardMetrics();
  }

  void _handleKeyboardMetrics() {
    if (!mounted) return;

    final view = View.of(context);
    final keyboardInset = view.viewInsets.bottom / view.devicePixelRatio;
    final keyboardVisibleNow = keyboardInset > 0;

    if (keyboardVisibleNow) {
      _keyboardHideDebounce?.cancel();
      if (!_isKeyboardVisible) {
        setState(() {
          _isKeyboardVisible = true;
        });
      }
      return;
    }

    _keyboardHideDebounce?.cancel();
    _keyboardHideDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;

      final v = View.of(context);
      final inset = v.viewInsets.bottom / v.devicePixelRatio;
      final stillHidden = inset < 1;
      if (stillHidden && _isKeyboardVisible) {
        setState(() {
          _isKeyboardVisible = false;
        });
      }
    });
  }

  void _onSearchFocusChange() {
    setState(() {
      if (_searchFocusNode.hasFocus) {
        if (_showSingleFacility) {
          _showSingleFacility = false;
          _selectedFacility = null;
        }
        if (!_isPanelOpen) {
          _isPanelOpen = true;
          _isFullyExpanded = false;
        }
      }
      _isSearchActive = _searchFocusNode.hasFocus;
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _keyboardHideDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    ZipCodeService().removeListener(_onZipServiceChanged);
    _disposeMapController();
    _markerUpdateDebounce?.cancel();
    _markerIconCache.clear();
    super.dispose();
  }

  @override
  void deactivate() {
    _disposeMapController();
    super.deactivate();
  }

  void _disposeMapController() {
    _googleMapController?.dispose();
    _googleMapController = null;
    _isMapCreated = false;
  }

  String? _mapStyle;

  Future<void> _loadMapStyle() async {
    final brightness = _lastBrightness ?? Brightness.light;
    final style = await MapStyleService.loadMapStyle(brightness: brightness);
    if (mounted) {
      setState(() => _mapStyle = style);
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    try {
      _googleMapController = controller;

      if (!_isMapCreated) {
        _isMapCreated = true;
        _currentZoom = await _googleMapController!.getZoomLevel();
      }

      if (mounted) {
        final currentZoom = await controller.getZoomLevel();
        await controller.moveCamera(CameraUpdate.zoomTo(currentZoom));
        _updateMarkers();

        if (_pendingFacility != null) {
          // The user tapped a Home Favorite before the map existed — center on
          // it now.
          final pending = _pendingFacility!;
          _pendingFacility = null;
          await _animateToFacility(pending);
        } else if (_currentLatitude != MapConstants.defaultLatitude ||
            _currentLongitude != MapConstants.defaultLongitude) {
          // Center on the user's search location (GPS / ZIP / map area),
          // regardless of the label.
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(_currentLatitude, _currentLongitude),
              MapConstants.detailZoom,
            ),
          );
        } else if (_allFacilities.isNotEmpty) {
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(
                _allFacilities.first.location.latitude,
                _allFacilities.first.location.longitude,
              ),
              MapConstants.defaultZoom,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'MapPage._onMapCreated',
      );
    }
  }

  Future<void> _loadFacilities() async {
    final facilityProvider = context.read<FacilityProvider>();

    // No short-circuit on the provider cache: at nationwide scale `facilities`
    // means "the current region," not "everything," so each location/distance
    // change must re-query. The service-level region cache dedupes repeats.
    setState(() {
      _isLoading = true;
      _error = null;
      _markers.clear();
      _filteredFacilities.clear();
    });

    final queryCenter = LatLng(_currentLatitude, _currentLongitude);

    try {
      final facilities = await _facilityRepository
          .loadFacilitiesWithDistance(
        latitude: _currentLatitude,
        longitude: _currentLongitude,
        radiusMiles: MapConstants.defaultRadiusMiles,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout loading facilities');
        },
      );

      if (mounted) {
        facilityProvider.setFacilities(facilities);

        setState(() {
          _allFacilities = facilities;
          _isLoading = false;
          _lastQueryCenter = queryCenter;
          _showSearchAreaButton = false;
        });
        _filterFacilities();
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'MapPage._loadFacilities',
      );
      if (mounted) {
        setState(() {
          _error = 'Failed to load facilities. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onLocationChanged(
    String displayName,
    double? latitude,
    double? longitude,
  ) async {
    if (latitude == null || longitude == null) return;
    final isCurrent =
        displayName.toLowerCase().contains('current') ||
            displayName == (AppLocalizations.of(context)?.locationCurrentLocation ?? '');

    setState(() {
      _currentLatitude = latitude;
      _currentLongitude = longitude;
      _currentLocation = displayName;
    });

    final zipService = ZipCodeService();
    if (isCurrent) {
      await zipService.setCurrentLocation(
        latitude: latitude,
        longitude: longitude,
        displayName: displayName,
      );
    } else {
      await zipService.setZipAndLocation(displayName, latitude, longitude);
    }

    await _refreshLocationPermission();
    await _loadFacilities();

    if (_googleMapController != null) {
      await _googleMapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(latitude, longitude),
          MapConstants.radiusFramingZoom,
        ),
      );
    }
  }

  /// GPS path for the my-location button in the resources search bar. Reuses
  /// the normal location-changed pipeline (persists to ZipCodeService, reloads,
  /// re-centers).
  Future<void> _useMyLocation() async {
    if (_isLocatingUser) return;
    setState(() => _isLocatingUser = true);

    final result = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isLocatingUser = false);

    if (result.status == LocationStatus.granted) {
      // Store the canonical label; LocationSearch translates it for display.
      await _onLocationChanged(
        MapConstants.currentLocationSentinel,
        result.latitude,
        result.longitude,
      );
      return;
    }

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.locationPermissionDenied ??
              'Location access denied. Enable it in Settings > Privacy > '
                  'Location Services.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Reveals the "Search this area" button once the map has been panned far
  /// enough from the last query center. We never auto-query on pan — the button
  /// is the explicit, quota-friendly trigger.
  void _maybeShowSearchAreaButton() {
    if (!mounted || _showSingleFacility) return;
    final center = _mapCenter;
    final last = _lastQueryCenter;
    if (center == null || last == null) return;

    // Threshold scales with the fixed search radius (~35% of it).
    const radiusMeters = MapConstants.defaultRadiusMiles * 1609.34;
    final thresholdMeters = (radiusMeters * 0.35).clamp(300.0, 40000.0);
    final drifted = _distanceMeters(last, center) > thresholdMeters;

    if (drifted != _showSearchAreaButton) {
      setState(() => _showSearchAreaButton = drifted);
    }
  }

  /// Re-queries facilities around the current map center using the selected
  /// distance, then hides the button. Does not move the camera — the user
  /// panned here intentionally. Kept local (does not touch ZipCodeService) so
  /// it doesn't overwrite the user's saved ZIP / GPS preference.
  Future<void> _searchThisArea() async {
    final center = _mapCenter;
    if (center == null || _isSearchingArea) return;

    setState(() {
      _isSearchingArea = true;
      _currentLatitude = center.latitude;
      _currentLongitude = center.longitude;
      _currentLocation = MapConstants.mapAreaSentinel;
    });

    await _loadFacilities();

    if (mounted) {
      setState(() => _isSearchingArea = false);
    }
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  /// Zooms in toward a tapped cluster; the camera-idle handler then re-clusters
  /// (or breaks the cluster into individual markers past the zoom threshold).
  Future<void> _onClusterTap(LatLng center) async {
    final controller = _googleMapController;
    if (controller == null) return;
    final target = (_currentZoom + 2).clamp(3.0, 18.0);
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(center, target),
    );
  }

  void _filterFacilities() {
    setState(() {
      _filteredFacilities = FacilityFilterService.filterFacilities(
        _allFacilities,
        searchText: _searchController.text,
        selectedCategories: _selectedCategories,
        selectedEligibilityRequirements: _selectedEligibilityRequirements,
        selectedPreferenceRequirements: _selectedPreferenceRequirements,
        showFavoritesOnly: _showFavoritesOnly,
        showOpenNowOnly: _showOpenNowOnly,
      );
      _updateMarkers();
    });
  }

  Future<void> _updateMarkers() async {
    if (!mounted || _googleMapController == null || _isUpdatingMarkers) return;
    _markerUpdateDebounce?.cancel();

    _markerUpdateDebounce = Timer(const Duration(milliseconds: 100), () async {
      if (!mounted) return;
      _isUpdatingMarkers = true;

      try {
        final zoom = await _googleMapController!.getZoomLevel();
        setState(() {
          _currentZoom = zoom;
        });

        if (!mounted) return;

        final newMarkers =
            await MarkerManagementService.createMarkersClustered(
          _filteredFacilities,
          context,
          zoom: zoom,
          showFacilityNames: _showFacilityNames,
          markerIconCache: _markerIconCache,
          onFacilityTap: _showFacilityDetails,
          onClusterTap: _onClusterTap,
        );

        if (mounted) {
          setState(() {
            _markers
              ..clear()
              ..addAll(newMarkers);
          });
        }
      } catch (e, stackTrace) {
        ErrorReporter.instance.report(
          e,
          stackTrace,
          context: 'MapPage._updateMarkers',
        );
      } finally {
        _isUpdatingMarkers = false;
      }
    });
  }

  void _onMapTap(LatLng position) {
    if (_showSingleFacility) {
      _dismissSingleFacilityView(showPanel: false);
    } else if (_isPanelOpen) {
      setState(() {
        _isPanelOpen = false;
        _isFullyExpanded = false;
      });
    }
  }

  void _dismissSingleFacilityView({bool showPanel = true}) {
    if (_showSingleFacility) {
      setState(() {
        _showSingleFacility = false;
        _selectedFacility = null;
        _isPanelOpen = showPanel;
        _isFullyExpanded = false;
      });
    }
  }

  Future<void> _animateToFacility(Facility facility) async {
    if (_googleMapController == null) return;

    try {
      final screenHeight = MediaQuery.of(context).size.height;
      final cardHeight = screenHeight * 0.6;
      const searchBarHeight = MapConstants.searchBarAreaHeight;
      const filterBarHeight = 60.0;
      final visibleMapHeight =
          screenHeight - cardHeight - searchBarHeight - filterBarHeight;
      final targetY = searchBarHeight + filterBarHeight + visibleMapHeight;

      final currentZoom = await _googleMapController!.getZoomLevel();
      final targetZoom = currentZoom < MapConstants.markerZoom
          ? MapConstants.markerZoom
          : currentZoom;

      final metersPerPixel = 156543.03392 *
          math.cos(facility.location.latitude * math.pi / 180) /
          math.pow(2, targetZoom);

      final offsetPixels = (screenHeight / 2) - targetY;
      final offsetMeters = offsetPixels * metersPerPixel;
      final offsetDegrees = offsetMeters / 111320;

      final adjustedTarget = LatLng(
        facility.location.latitude - offsetDegrees,
        facility.location.longitude,
      );

      await _googleMapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: adjustedTarget,
            zoom: targetZoom,
          ),
        ),
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'MapPage._animateToFacility',
      );
    }
  }

  Future<void> _showFacilityDetails(Facility facility) async {
    try {
      setState(() {
        _showSingleFacility = true;
        _selectedFacility = facility;
        _isPanelOpen = false;
        _isFullyExpanded = false;
        _expandedFacilityId = null;
      });

      // Track view for the "Recently Viewed Facilities" section on Home.
      // `read` (vs. `watch`) — we don't need a rebuild here.
      context.read<RecentFacilitiesService>().addFacility(facility);

      await _animateToFacility(facility);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'MapPage._showFacilityDetails',
      );
    }
  }

  void showFacilityById(String facilityId) {
    final facility =
        _allFacilities.where((f) => f.id == facilityId).firstOrNull;
    if (facility != null) {
      _showFacilityDetails(facility);
    }
  }

  /// Applies a category filter and triggers search from external navigation.
  ///
  /// Home quick-actions pass a high-level group ("Health Care", …); we expand
  /// it to the underlying `category_level_2` values the filter matches on. A
  /// raw category_level_2 value is used as-is.
  void filterByCategory(String category) {
    final values = FacilityCategories.isGroup(category)
        ? FacilityCategories.valuesForGroup(category)
        : [category];
    setState(() {
      _selectedCategories
        ..clear()
        ..addAll(values);
      _searchController.clear();
      _showSingleFacility = false;
      _selectedFacility = null;
    });
    _filterFacilities();
  }

  /// Centers the map on [facility] and shows its detail card. Called when the
  /// user taps a facility in the Home Favorites list — works even when the
  /// facility isn't in the current region, since we pass the full object.
  void showFacility(Facility facility) {
    // If the map controller isn't ready yet (first navigation), defer the
    // camera move until `_onMapCreated`.
    if (_googleMapController == null) {
      _pendingFacility = facility;
    }
    _showFacilityDetails(facility);
  }

  /// Re-centers the map on the user's saved location (GPS / ZIP) and reloads
  /// facilities there. Called when the user taps the Home map cutout.
  Future<void> recenterOnUserLocation() async {
    final zipService = ZipCodeService();
    final lat = zipService.latitude;
    final lng = zipService.longitude;
    if (!mounted) return;
    setState(() {
      _currentLatitude = lat;
      _currentLongitude = lng;
      _currentLocation =
          zipService.zipCode?.isNotEmpty == true
              ? zipService.zipCode!
              : MapConstants.currentLocationSentinel;
      _showSingleFacility = false;
      _selectedFacility = null;
    });
    await _loadFacilities();
    final controller = _googleMapController;
    if (controller != null) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(lat, lng),
          MapConstants.radiusFramingZoom,
        ),
      );
    }
  }

  Widget _buildFilterBar() {
    final isGuest = context.read<GuestModeService>().isGuest;
    return FilterBar(
      selectedCategories: _selectedCategories,
      selectedEligibilityRequirements: _selectedEligibilityRequirements,
      selectedPreferenceRequirements: _selectedPreferenceRequirements,
      showFavoritesOnly: _showFavoritesOnly,
      showOpenNowOnly: _showOpenNowOnly,
      isGuestMode: isGuest,
      onFavoritesTap: isGuest
          ? () => showSignInPromptDialog(context)
          : _toggleFavoritesFilter,
      onOpenNowTap: _toggleOpenNowFilter,
      onFiltersTap: _showFilterModal,
      onCategoryTap: () =>
          _showFilterModal(expandedSection: FilterSection.category),
      onEligibilityTap: isGuest
          ? () => showSignInPromptDialog(context)
          : () => _showFilterModal(expandedSection: FilterSection.eligibility),
      onPreferencesTap: isGuest
          ? () => showSignInPromptDialog(context)
          : () => _showFilterModal(expandedSection: FilterSection.preferences),
      onStatusTap: isGuest
          ? () => showSignInPromptDialog(context)
          : _showStatusActionSheet,
    );
  }

  /// Floating "Search this area" pill, shown under the filter bar once the map
  /// has drifted from the last query center. Tapping re-queries around the new
  /// center (Yelp / Google Maps pattern).
  Widget _buildSearchAreaButton() {
    final visible = _showSearchAreaButton && !_showSingleFacility;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: !visible
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _isSearchingArea ? null : _searchThisArea,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.resedaGreen,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isSearchingArea)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 18,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            _isSearchingArea
                                ? AppLocalizations.of(context)!.mapSearching
                                : AppLocalizations.of(context)!
                                    .mapSearchThisArea,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  /// Bottom-sheet picker that one-shot applies the user's saved Eligibility,
  /// Preferences, or both as filter values. Designed for the filter-bar chip
  /// — taps auto-apply and close, no follow-up "Apply" press needed.
  Future<void> _showStatusActionSheet() async {
    final ep = EligibilityPreferencesService();
    final colorScheme = Theme.of(context).colorScheme;
    final choice = await showModalBottomSheet<_StatusChoice>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                AppLocalizations.of(context)!.filterApplyStatusTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(
                Icons.verified_user_outlined,
                color: AppTheme.resedaGreen,
              ),
              title: Text(
                AppLocalizations.of(context)!.filterApplyMyEligibility,
              ),
              onTap: () => Navigator.pop(ctx, _StatusChoice.eligibility),
            ),
            ListTile(
              leading: const Icon(Icons.tune, color: AppTheme.resedaGreen),
              title: Text(
                AppLocalizations.of(context)!.filterApplyMyPreferences,
              ),
              onTap: () => Navigator.pop(ctx, _StatusChoice.preferences),
            ),
            ListTile(
              leading: const Icon(
                Icons.checklist_rtl,
                color: AppTheme.resedaGreen,
              ),
              title: Text(AppLocalizations.of(context)!.filterApplyBoth),
              onTap: () => Navigator.pop(ctx, _StatusChoice.both),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    _applyStatusChoice(choice, ep);
  }

  /// Mutates `_selectedEligibilityRequirements` / `_selectedPreferenceRequirements`
  /// from the user's saved EligibilityPreferencesService state, then re-runs
  /// the filter pipeline. Matches the per-modal helpers in FilterModal so
  /// the semantics are consistent whether the user opens the modal or uses
  /// the filter-bar chip.
  void _applyStatusChoice(
    _StatusChoice choice,
    EligibilityPreferencesService ep,
  ) {
    setState(() {
      if (choice == _StatusChoice.eligibility ||
          choice == _StatusChoice.both) {
        final e = ep.eligibility;
        if (e.proofOfIncome) {
          _selectedEligibilityRequirements[
              EligibilityRequirement.proofOfIncome] = true;
        }
        if (e.proofOfResidency) {
          _selectedEligibilityRequirements[
              EligibilityRequirement.proofOfResidency] = true;
        }
        if (e.insuranceRequired) {
          _selectedEligibilityRequirements[
              EligibilityRequirement.insuranceRequired] = true;
        }
        if (e.referralRequired) {
          _selectedEligibilityRequirements[
              EligibilityRequirement.referralRequired] = true;
        }
      }
      if (choice == _StatusChoice.preferences ||
          choice == _StatusChoice.both) {
        final p = ep.preferences;
        if (p.acceptsWalkIns) {
          _selectedPreferenceRequirements[
              PreferenceRequirement.acceptsWalkins] = true;
        }
        if (p.appointmentOnly) {
          _selectedPreferenceRequirements[
              PreferenceRequirement.appointmentOnly] = true;
        }
        if (p.openToImmigrants) {
          _selectedPreferenceRequirements[
              PreferenceRequirement.openToImmigrants] = true;
        }
        if (p.freeServices) {
          _selectedPreferenceRequirements[
              PreferenceRequirement.freeServicesAvailable] = true;
        }
        if (p.slidingScale) {
          _selectedPreferenceRequirements[
              PreferenceRequirement.slidingScaleAvailable] = true;
        }
        if (p.otherLanguages) {
          _selectedPreferenceRequirements[
              PreferenceRequirement.otherLanguages] = true;
        }
        if (p.telehealthPreference) {
          _selectedPreferenceRequirements[
              PreferenceRequirement.telehealthAvailable] = true;
        }
        if (p.wheelchairAccessible) {
          _selectedPreferenceRequirements[
              PreferenceRequirement.wheelchairAccessible] = true;
        }
        if (p.servesOutsideArea) {
          _selectedPreferenceRequirements[
              PreferenceRequirement.servesOutsideArea] = true;
        }
      }
      _filterFacilities();
    });
  }

  void _toggleFavoritesFilter() {
    _dismissSingleFacilityView();
    setState(() {
      _showFavoritesOnly = !_showFavoritesOnly;
      _filterFacilities();
    });
  }

  void _toggleOpenNowFilter() {
    _dismissSingleFacilityView();
    setState(() {
      _showOpenNowOnly = !_showOpenNowOnly;
      _filterFacilities();
    });
  }

  Future<void> _showFilterModal({FilterSection? expandedSection}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModal(
        selectedCategories: _selectedCategories,
        availableCategories: FacilityCategories.categoryLevel2Values,
        selectedEligibilityRequirements: _selectedEligibilityRequirements,
        selectedPreferenceRequirements: _selectedPreferenceRequirements,
        showFavoritesOnly: _showFavoritesOnly,
        showOpenNowOnly: _showOpenNowOnly,
        expandedSection: expandedSection,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (_showSingleFacility) {
          _showSingleFacility = false;
          _selectedFacility = null;
          _isPanelOpen = true;
          _isFullyExpanded = false;
        }

        _selectedCategories.clear();
        _selectedCategories.addAll(result['categories'] as Set<String>);
        _selectedEligibilityRequirements = result['eligibilityRequirements']
            as Map<EligibilityRequirement, bool?>;
        _selectedPreferenceRequirements = result['preferenceRequirements']
            as Map<PreferenceRequirement, bool?>;
        _showFavoritesOnly = result['showFavoritesOnly'] as bool;
        _showOpenNowOnly = result['showOpenNowOnly'] as bool;
      });
      _filterFacilities();
    }
  }

  /// Rating entry point on facility cards ("Already visited? Rate your
  /// experience"). Guests get the sign-in prompt.
  void _onRateFacility(Facility facility) {
    if (context.read<GuestModeService>().isGuest) {
      showSignInPromptDialog(context);
      return;
    }
    showFacilityRatingDialog(context, facility: facility);
  }

  /// Empty-state "request a facility" entry point. Requests are attributed to
  /// a user (RLS), so guests get the sign-in prompt.
  void _onRequestFacility() {
    if (context.read<GuestModeService>().isGuest) {
      showSignInPromptDialog(context);
      return;
    }
    showFacilityRequestDialog(context);
  }

  String? _expandedFacilityId;

  void _toggleFacilityExpansion(String facilityId) {
    final isOpening = _expandedFacilityId != facilityId;
    setState(() {
      if (_expandedFacilityId == facilityId) {
        _expandedFacilityId = null;
      } else {
        _expandedFacilityId = facilityId;
      }
    });

    // Treat expanding a row in the list panel as a "view" — that's when the
    // user is actually reading facility details and might want to leave
    // feedback.
    if (!isOpening) return;
    final facility = _allFacilities
        .where((f) => f.id == facilityId)
        .firstOrNull;
    if (facility != null) {
      context.read<RecentFacilitiesService>().addFacility(facility);
    }
  }

  void _toggleFavorite(String facilityId) {
    final facilityProvider = context.read<FacilityProvider>();
    facilityProvider.toggleFavorite(facilityId);

    setState(() {
      _allFacilities = facilityProvider.facilities;

      final filteredIndex =
          _filteredFacilities.indexWhere((f) => f.id == facilityId);
      if (filteredIndex != -1) {
        final updatedFacility = facilityProvider.getFacilityById(facilityId);
        if (updatedFacility != null) {
          _filteredFacilities[filteredIndex] = updatedFacility;
        }
      }

      if (_showFavoritesOnly) {
        _filterFacilities();
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    await UrlLauncherService.launchUrlString(url, context);
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.mapLoadFailed ??
                (_error ?? 'An error occurred'),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFacilities,
            child: Text(AppLocalizations.of(context)?.mapRetry ?? 'Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_error != null) {
      return _buildError();
    }

    final isGuest = context.watch<GuestModeService>().isGuest;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          RepaintBoundary(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              style: _mapStyle,
              initialCameraPosition: const CameraPosition(
                target: LatLng(
                  MapConstants.defaultLatitude,
                  MapConstants.defaultLongitude,
                ),
                zoom: MapConstants.defaultZoom,
              ),
              markers: _markers,
              onCameraMove: (CameraPosition position) {
                _currentZoom = position.zoom;
                _mapCenter = position.target;
              },
              onCameraIdle: () {
                if ((_previousZoom - _currentZoom).abs() > 0.1) {
                  _previousZoom = _currentZoom;
                  _updateMarkers();
                }
                _maybeShowSearchAreaButton();
              },
              onTap: _onMapTap,
              myLocationEnabled: _locationGranted,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF222240)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(25.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: FacilitySearch(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _filterFacilities,
                      onClear: _filterFacilities,
                      onUseMyLocation: _useMyLocation,
                      isLocatingUser: _isLocatingUser,
                    ),
                  ),
                  // The ZIP/location search bar is intentionally not rendered
                  // — users move the query with the my-location button and
                  // "Search this area" (§2.9 follow-up). The LocationSearch
                  // widget is kept in the tree for potential reinstatement;
                  // ZIP edits still flow in from Settings via ZipCodeService.
                  const SizedBox(height: 6),
                  _buildFilterBar(),
                  _buildSearchAreaButton(),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _isKeyboardVisible
                ? const SizedBox.shrink()
                : _showSingleFacility
                    ? _buildSingleFacilityCard()
                    : FacilityListPanel(
                        facilities: _filteredFacilities,
                        scrollController: _scrollController,
                        isLoading: _isLoading,
                        isPanelOpen: _isPanelOpen,
                        isFullyExpanded: _isFullyExpanded,
                        isSearchActive: _isSearchActive,
                        expandedFacilityId: _expandedFacilityId,
                        onToggleFacilityExpansion: _toggleFacilityExpansion,
                        onToggleFavorite: _toggleFavorite,
                        onLaunchUrl: _launchUrl,
                        buildCategoryIcon:
                            FacilityCategoryIcons.buildCategoryIcon,
                        canFavorite: !isGuest,
                        onRequestFacility: _onRequestFacility,
                        onRateFacility: _onRateFacility,
                        onPanelStateChange: (isPanelOpen, isFullyExpanded) {
                          setState(() {
                            _isPanelOpen = isPanelOpen;
                            _isFullyExpanded = isFullyExpanded;
                          });
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleFacilityCard() {
    if (_selectedFacility == null) return const SizedBox.shrink();
    final isGuest = context.read<GuestModeService>().isGuest;

    final maxCardHeight = MediaQuery.of(context).size.height * 0.45;
    // Swipe down anywhere on the card chrome (handle bar, header, non-scroll
    // areas) dismisses it — same flick gesture as the list panel. The card's
    // internal scroll view wins the gesture arena while its content scrolls,
    // so the handle bar is the always-available dismiss target.
    return GestureDetector(
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > MapConstants.minFlickVelocity) {
          _dismissSingleFacilityView(showPanel: false);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(16.0),
        constraints: BoxConstraints(maxHeight: maxCardHeight),
        // No background color of its own — the FacilityCard fills the wrapper
        // (zero margin, matching corner radius) and carries the drag handle on
        // its own background, so there's no separate chrome strip behind it.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MapConstants.panelBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8.0,
              spreadRadius: 1.0,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 3.0,
              spreadRadius: 0.5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MapConstants.panelBorderRadius),
          child: FacilityCard(
            facility: _selectedFacility!,
            isExpanded: true,
            onToggleExpand: () {},
            onToggleFavorite: () {
              _toggleFavorite(_selectedFacility!.id);
              setState(() {
                _selectedFacility = _allFacilities.firstWhere(
                  (f) => f.id == _selectedFacility!.id,
                  orElse: () => _selectedFacility!,
                );
              });
            },
            onLaunchUrl: _launchUrl,
            buildCategoryIcon: FacilityCategoryIcons.buildCategoryIcon,
            showExpandButton: false,
            canFavorite: !isGuest,
            onRate: () => _onRateFacility(_selectedFacility!),
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(MapConstants.panelBorderRadius),
            ),
            showDragHandle: true,
          ),
        ),
      ),
    );
  }
}

/// Choices presented in the filter-bar Status action sheet.
enum _StatusChoice { eligibility, preferences, both }
