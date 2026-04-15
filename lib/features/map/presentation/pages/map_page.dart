import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:beacon_app/core/services/demo_mode_service.dart';
import 'package:beacon_app/core/widgets/sign_in_prompt_dialog.dart';
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
import 'package:beacon_app/features/map/presentation/widgets/search/location_search.dart';
import 'package:beacon_app/features/map/utils/facility_display_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final Completer<GoogleMapController> _mapController = Completer();
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
  bool _showFavoritesOnly = false;
  bool _showOpenNowOnly = false;
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  Timer? _markerUpdateDebounce;
  bool _isUpdatingMarkers = false;

  double _selectedDistance = MapConstants.distanceOptions.first;
  String _currentLocation = 'Current Location';

  bool get _isGuest => Supabase.instance.client.auth.currentUser == null;

  double _currentLatitude = MapConstants.defaultLatitude;
  double _currentLongitude = MapConstants.defaultLongitude;

  @override
  void initState() {
    super.initState();
    final isDemoMode = DemoModeService().isDemoMode;
    _facilityRepository =
        isDemoMode ? DemoFacilityRepository() : FacilityRepository();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleKeyboardMetrics();
    });
    _tryGetCurrentLocationOnStartup();
    _isPanelOpen = true;
    _searchFocusNode.addListener(_onSearchFocusChange);
    _loadMapStyle();
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
    _mapStyle ??= await MapStyleService.loadMapStyle();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    try {
      _googleMapController = controller;

      if (!_mapController.isCompleted) {
        _mapController.complete(controller);
      }

      if (!_isMapCreated) {
        _isMapCreated = true;
        _currentZoom = await _googleMapController!.getZoomLevel();
      }

      if (mounted) {
        final currentZoom = await controller.getZoomLevel();
        await controller.moveCamera(CameraUpdate.zoomTo(currentZoom));
        _updateMarkers();

        if (_currentLocation == 'Current Location' &&
            _currentLatitude != MapConstants.defaultLatitude &&
            _currentLongitude != MapConstants.defaultLongitude) {
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
    } catch (e) {
      debugPrint('Error in _onMapCreated: $e');
    }
  }

  Future<void> _loadFacilities() async {
    final facilityProvider =
        Provider.of<FacilityProvider>(context, listen: false);

    if (facilityProvider.facilities.isNotEmpty) {
      setState(() {
        _allFacilities = facilityProvider.facilities;
        _isLoading = false;
      });
      _filterFacilities();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _markers.clear();
      _filteredFacilities.clear();
    });

    try {
      debugPrint(
        '📍 Loading facilities near ($_currentLatitude, $_currentLongitude) within $_selectedDistance mi',
      );

      final facilities = await _facilityRepository
          .loadFacilitiesWithDistance(
        latitude: _currentLatitude,
        longitude: _currentLongitude,
        radiusMiles: _selectedDistance,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout loading facilities');
        },
      );

      debugPrint('✅ Loaded ${facilities.length} facilities');

      if (mounted) {
        facilityProvider.setFacilities(facilities);

        setState(() {
          _allFacilities = facilities;
          _isLoading = false;
        });
        _filterFacilities();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading facilities: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = 'Failed to load facilities. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _onLocationChanged(
    String location,
    double? latitude,
    double? longitude,
  ) {
    final bool locationActuallyChanged = latitude != null &&
        longitude != null &&
        LocationService.hasLocationChanged(
          _currentLatitude,
          _currentLongitude,
          latitude,
          longitude,
        );

    setState(() {
      _currentLocation = location;
      if (latitude != null && longitude != null) {
        _currentLatitude = latitude;
        _currentLongitude = longitude;
      }
    });

    if (locationActuallyChanged) {
      _loadFacilities();
      _centerMapOnCurrentLocation();
    } else {
      _centerMapOnCurrentLocation();
    }
  }

  void _onLocationSearchFocusChange(bool hasFocus) {
    setState(() {
      if (hasFocus && !_isPanelOpen) {
        _isPanelOpen = true;
        _isFullyExpanded = false;
      }
      _isSearchActive = hasFocus || _searchFocusNode.hasFocus;
    });
  }

  double _getZoomLevelForDistance(double distanceMiles) {
    return MapConstants.distanceToZoom[distanceMiles] ??
        MapConstants.detailZoom;
  }

  Future<void> _centerMapOnCurrentLocation() async {
    if (_googleMapController != null) {
      await _googleMapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentLatitude, _currentLongitude),
          _getZoomLevelForDistance(_selectedDistance),
        ),
      );
    } else {
      log('Google map controller is null, cannot center map', name: 'MapPage');
    }
  }

  Future<void> _tryGetCurrentLocationOnStartup() async {
    try {
      final locationResult = await LocationService.getCurrentLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Location timeout');
        },
      );

      setState(() {
        _currentLocation = locationResult.locationName;
        _currentLatitude = locationResult.latitude;
        _currentLongitude = locationResult.longitude;
      });

      if (_googleMapController != null && locationResult.isCurrentLocation) {
        await _googleMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(locationResult.latitude, locationResult.longitude),
            MapConstants.detailZoom,
          ),
        );
      }

      _loadFacilities();
    } catch (e) {
      _loadFacilities();
    }
  }

  void _filterFacilities() {
    setState(() {
      _filteredFacilities = FacilityFilterService.filterFacilities(
        _allFacilities,
        searchText: _searchController.text,
        selectedCategories: _selectedCategories,
        selectedEligibilityRequirements: _selectedEligibilityRequirements,
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
            await MarkerManagementService.createMarkersForFacilities(
          _filteredFacilities,
          context,
          _showFacilityNames,
          _markerIconCache,
          _showFacilityDetails,
        );

        if (mounted) {
          setState(() {
            _markers
              ..clear()
              ..addAll(newMarkers);
          });
        }
      } catch (e) {
        debugPrint('Error updating markers: $e');
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
    } catch (e) {
      debugPrint('Error animating to facility: $e');
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

      await _animateToFacility(facility);
    } catch (e) {
      debugPrint('Error in _showFacilityDetails: $e');
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
  void filterByCategory(String category) {
    setState(() {
      _selectedCategories.clear();
      _selectedCategories.add(category);
      _searchController.clear();
      _showSingleFacility = false;
      _selectedFacility = null;
    });
    _filterFacilities();
  }

  Widget _buildFilterBar() {
    return FilterBar(
      selectedDistance: _selectedDistance,
      selectedCategories: _selectedCategories,
      selectedEligibilityRequirements: _selectedEligibilityRequirements,
      showFavoritesOnly: _showFavoritesOnly,
      showOpenNowOnly: _showOpenNowOnly,
      onFavoritesTap: _isGuest
          ? () => showSignInPromptDialog(context)
          : _toggleFavoritesFilter,
      onOpenNowTap: _toggleOpenNowFilter,
      onFiltersTap: _showFilterModal,
      onDistanceTap: () =>
          _showFilterModal(expandedSection: FilterSection.distance),
      onCategoryTap: () =>
          _showFilterModal(expandedSection: FilterSection.category),
      onEligibilityTap: _isGuest
          ? () => showSignInPromptDialog(context)
          : () => _showFilterModal(expandedSection: FilterSection.eligibility),
    );
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
        selectedDistance: _selectedDistance,
        selectedCategories: _selectedCategories,
        availableCategories:
            FacilityFilterService.getAvailableCategories(_allFacilities)
                .toList(),
        selectedEligibilityRequirements: _selectedEligibilityRequirements,
        showFavoritesOnly: _showFavoritesOnly,
        showOpenNowOnly: _showOpenNowOnly,
        expandedSection: expandedSection,
      ),
    );

    if (result != null && mounted) {
      final wasSingleFacility = _showSingleFacility;
      final oldDistance = _selectedDistance;

      setState(() {
        if (wasSingleFacility) {
          _showSingleFacility = false;
          _selectedFacility = null;
          _isPanelOpen = true;
          _isFullyExpanded = false;
        }

        _selectedDistance = result['distance'] as double;
        _selectedCategories.clear();
        _selectedCategories.addAll(result['categories'] as Set<String>);
        _selectedEligibilityRequirements = result['eligibilityRequirements']
            as Map<EligibilityRequirement, bool?>;
        _showFavoritesOnly = result['showFavoritesOnly'] as bool;
        _showOpenNowOnly = result['showOpenNowOnly'] as bool;
      });

      if (_selectedDistance != oldDistance) {
        setState(() {
          _isLoading = true;
        });

        try {
          final facilities =
              await _facilityRepository.loadFacilitiesWithDistance(
            latitude: _currentLatitude,
            longitude: _currentLongitude,
            radiusMiles: _selectedDistance,
          );

          if (mounted) {
            setState(() {
              _allFacilities = facilities;
              _isLoading = false;
            });
            _filterFacilities();

            if (_googleMapController != null) {
              await _googleMapController!.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(_currentLatitude, _currentLongitude),
                  _getZoomLevelForDistance(_selectedDistance),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _error =
                  'Failed to update facilities for distance. Please try again.';
              _isLoading = false;
            });
          }
        }
      } else {
        _filterFacilities();
      }
    }
  }

  String? _expandedFacilityId;

  void _toggleFacilityExpansion(String facilityId) {
    setState(() {
      if (_expandedFacilityId == facilityId) {
        _expandedFacilityId = null;
      } else {
        _expandedFacilityId = facilityId;
      }
    });
  }

  void _toggleFavorite(String facilityId) {
    final facilityProvider =
        Provider.of<FacilityProvider>(context, listen: false);
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
            _error ?? 'An error occurred',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFacilities,
            child: const Text('Retry'),
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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
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
            },
            onCameraIdle: () {
              if ((_previousZoom - _currentZoom).abs() > 0.1) {
                _previousZoom = _currentZoom;
                _updateMarkers();
              }
            },
            onTap: _onMapTap,
            // TODO: re-enable when location permission is added back post-MVP
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
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
                      color: Colors.white,
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
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: LocationSearch(
                      currentLocation: _currentLocation,
                      onLocationChanged: _onLocationChanged,
                      onFocusChanged: _onLocationSearchFocusChange,
                    ),
                  ),
                  _buildFilterBar(),
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

    final maxCardHeight = MediaQuery.of(context).size.height * 0.45;
    return Container(
      margin: const EdgeInsets.all(16.0),
      constraints: BoxConstraints(maxHeight: maxCardHeight),
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
        ),
      ),
    );
  }
}
