import 'dart:async';
import 'dart:math' as math;

import 'package:beacon_app/core/services/accessibility_settings.dart';
import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/facility_correction_dialog.dart';
import 'package:beacon_app/core/widgets/facility_rating_dialog.dart';
import 'package:beacon_app/core/widgets/facility_request_dialog.dart';
import 'package:beacon_app/core/widgets/sign_in_prompt_dialog.dart';
import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
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
import 'package:beacon_app/features/map/utils/map_geometry.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

/// What a back press undoes on the map, innermost layer first.
enum MapBackTarget {
  /// The single-facility card opened from a marker.
  facilityCard,

  /// A list row expanded in place.
  expandedRow,

  /// The list pulled up to full height.
  expandedPanel,

  /// Text in the search field.
  searchText,

  /// Nothing is open; the press belongs to whoever is above the map.
  nothing,
}

/// Which layer a back press closes, given what is open: whatever covers the
/// most goes first. A card sits on top of everything; a raised list hides the
/// map and is lowered before the search that filled it is thrown away, so one
/// press never costs both the view and the typed text.
MapBackTarget mapBackTarget({
  required bool cardOpen,
  required bool rowExpanded,
  required bool hasSearchText,
  required bool panelFullyExpanded,
}) {
  if (cardOpen) return MapBackTarget.facilityCard;
  if (rowExpanded) return MapBackTarget.expandedRow;
  if (panelFullyExpanded) return MapBackTarget.expandedPanel;
  if (hasSearchText) return MapBackTarget.searchText;
  return MapBackTarget.nothing;
}

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
  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(
      MapConstants.defaultLatitude,
      MapConstants.defaultLongitude,
    ),
    zoom: MapConstants.defaultZoom,
  );

  /// Slack allowed when asking "is the camera still where the focus put it?"
  static const double _focusTolerancePx = 24;
  static const double _focusToleranceZoom = 0.25;

  /// Margin kept around a cluster's members when the camera zooms to fit them.
  static const double _clusterFitPadding = 56;

  /// Closest the camera goes when fitting a cluster a few doors wide.
  static const double _clusterFitMaxZoom = 19;

  /// The least map kept in play when a tall sheet covers nearly all of it.
  static const double _minVisibleStrip = 80;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _chromeKey = GlobalKey();
  GoogleMapController? _googleMapController;
  bool _isMapCreated = false;
  List<Facility> _allFacilities = [];
  List<Facility> _filteredFacilities = [];

  /// What the list panel shows: the filtered facilities on screen, nearest
  /// the middle of the map first. Markers still draw all of
  /// [_filteredFacilities].
  List<Facility> _listFacilities = [];

  /// The map's last reported view, or null while it isn't known — before the
  /// map exists, or while the camera travels to a newly loaded area.
  LatLngBounds? _visibleBounds;

  bool _isPanelOpen = false;
  bool _isFullyExpanded = false;
  bool _isSearchActive = false;
  bool _isKeyboardVisible = false;
  Timer? _keyboardHideDebounce;
  bool _showSingleFacility = false;

  /// Drives the slide-down exit animation for the single-facility card so a
  /// swipe (or map tap) collapses it smoothly, matching the list panel — not
  /// an instant disappear.
  bool _cardDismissing = false;

  /// Single-facility card height state: false = default (~45% h), true =
  /// expanded (~85% h). Driven by the handle-bar swipe, like the list panel.
  bool _singleCardExpanded = false;
  Facility? _selectedFacility;
  late final FacilityRepositoryBase _facilityRepository;
  late final FacilityProvider _facilityProvider;
  bool _isLoading = true;
  bool _loadFailed = false;
  final Set<Marker> _markers = {};
  double _currentZoom = MapConstants.defaultZoom;
  double _previousZoom = MapConstants.defaultZoom;
  bool get _showFacilityNames => _currentZoom >= MapConstants.detailZoom;
  final Set<String> _selectedCategories = {};
  Map<PreferenceRequirement, bool?> _selectedPreferenceRequirements = {};
  bool _showFavoritesOnly = false;
  bool _showOpenNowOnly = false;
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  Timer? _markerUpdateDebounce;
  bool _isUpdatingMarkers = false;

  /// A marker refresh was asked for while one was running. Dropping it left
  /// the map showing clusters from a zoom level it had already left.
  bool _markerUpdateQueued = false;

  late String _currentLocation;
  Brightness? _lastBrightness;

  /// True while the my-location button (in the resources search bar) resolves
  /// GPS.
  bool _isLocatingUser = false;

  double _currentLatitude = MapConstants.defaultLatitude;
  double _currentLongitude = MapConstants.defaultLongitude;

  /// Whether the OS has already granted GPS permission. Re-checked after each
  /// prompt or external change.
  bool _locationGranted = false;

  /// Whether the user chose GPS over a ZIP. The blue dot shows only when both
  /// this and [_locationGranted] hold: someone who switched to a ZIP has said
  /// they don't want to be located, permission or not.
  bool _gpsMode = false;

  /// Center the facility list was last queried around, plus the live camera
  /// target. When the two drift apart, the "Search this area" button appears
  /// (Yelp / Google Maps pattern). We never auto-query on pan.
  LatLng? _lastQueryCenter;
  LatLng? _mapCenter;
  bool _showSearchAreaButton = false;
  bool _isSearchingArea = false;

  /// The camera as the map last reported it.
  CameraPosition _camera = _initialCamera;

  /// Set while a facility holds the camera's attention (card open, or a list
  /// row expanded): where the camera was beforehand, and where the focus put
  /// it. Releasing the facility returns to the first — unless the user has
  /// since moved the map away from the second, in which case it stays put.
  CameraPosition? _cameraBeforeFocus;
  CameraPosition? _focusCamera;

  /// The focus animation is still running, so [_camera] can't yet be compared
  /// with [_focusCamera].
  bool _focusInFlight = false;

  /// Size of the map itself, in logical pixels.
  Size _mapSize = Size.zero;

  /// Facility to center on once the map finishes creating — set when the user
  /// taps a Home Favorite before the map controller exists (first navigation).
  Facility? _pendingFacility;

  @override
  void initState() {
    super.initState();
    _facilityRepository = context.read<FacilityRepositoryBase>();
    _facilityProvider = context.read<FacilityProvider>();

    final zipService = ZipCodeService();
    _currentLatitude = zipService.latitude;
    _currentLongitude = zipService.longitude;
    _currentLocation = zipService.zipCode?.isNotEmpty == true
        ? zipService.zipCode!
        : ZipCodeService.currentLocationSentinel;
    _gpsMode = zipService.locationSearchEnabled;

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleKeyboardMetrics();
      _loadFacilities();
      _refreshLocationPermission();
    });
    _isPanelOpen = true;
    // Settings → Accessibility: start on the list, the part of this tab a
    // screen reader can read.
    _isFullyExpanded = AccessibilitySettings().openMapAsList;
    _pinScale = AccessibilitySettings().pinScale;
    _searchFocusNode.addListener(_onSearchFocusChange);

    // AutomaticKeepAlive means initState runs once, so each of these must be
    // listened to or Map drifts from Settings, Profile, and the favorites.
    zipService.addListener(_onZipServiceChanged);
    EligibilityPreferencesService().addListener(_onEligibilityChanged);
    _facilityProvider.addListener(_onFavoritesChanged);
    AccessibilitySettings().addListener(_onAccessibilityChanged);
  }

  /// The pin size last drawn, to tell when it changes.
  double _pinScale = 1;

  void _onAccessibilityChanged() {
    final scale = AccessibilitySettings().pinScale;
    if (!mounted || scale == _pinScale) return;
    _pinScale = scale;
    _redrawMarkers();
  }

  /// Throws away every drawn pin and draws them again — for when how a pin
  /// looks has changed, not which pins there are.
  void _redrawMarkers() {
    _markerIconCache.clear();
    unawaited(_updateMarkers());
  }

  void _onZipServiceChanged() {
    final zipService = ZipCodeService();
    final newLabel = zipService.zipCode?.isNotEmpty == true
        ? zipService.zipCode!
        : ZipCodeService.currentLocationSentinel;
    final newLat = zipService.latitude;
    final newLng = zipService.longitude;
    final gpsMode = zipService.locationSearchEnabled;

    final coordsChanged =
        newLat != _currentLatitude || newLng != _currentLongitude;
    final labelChanged = newLabel != _currentLocation;
    final modeChanged = gpsMode != _gpsMode;
    if (!coordsChanged && !labelChanged && !modeChanged) return;

    if (!mounted) return;
    setState(() {
      _currentLocation = newLabel;
      _currentLatitude = newLat;
      _currentLongitude = newLng;
      _gpsMode = gpsMode;
    });

    if (coordsChanged) {
      _forgetFocus();
      unawaited(_loadFacilities());
      final controller = _googleMapController;
      if (controller != null) {
        unawaited(
          _moveCamera(
            controller,
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
      final hadStyle = _lastBrightness != null;
      _lastBrightness = brightness;
      _loadMapStyle();
      // Pin names are drawn for the map style under them.
      if (hadStyle) _redrawMarkers();
    }
  }

  /// Moves the camera: a flight, or a cut for someone who has asked the OS to
  /// reduce motion.
  Future<void> _moveCamera(
    GoogleMapController controller,
    CameraUpdate update,
  ) =>
      AppMotion.reduced(context)
          ? controller.moveCamera(update)
          : controller.animateCamera(update);

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
        // Android's back button hides the keyboard but leaves the field
        // focused, and a focused search pins the list at its default height
        // where it can't be raised or scrolled. Once the keyboard is gone,
        // the typing is over.
        if (_searchFocusNode.hasFocus) _searchFocusNode.unfocus();
      }
    });
  }

  void _onSearchFocusChange() {
    final closesCard = _searchFocusNode.hasFocus && _showSingleFacility;
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
    if (closesCard) _releaseFocus();
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
    EligibilityPreferencesService().removeListener(_onEligibilityChanged);
    _facilityProvider.removeListener(_onFavoritesChanged);
    AccessibilitySettings().removeListener(_onAccessibilityChanged);
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
          final pending = _pendingFacility!;
          _pendingFacility = null;
          await _focusOn(
            pending.location,
            minZoom: MapConstants.markerZoom,
            sheetHeight: _singleCardSheetHeight(),
          );
        } else if (_currentLatitude != MapConstants.defaultLatitude ||
            _currentLongitude != MapConstants.defaultLongitude) {
          unawaited(
            _moveCamera(
              controller,
              CameraUpdate.newLatLngZoom(
                LatLng(_currentLatitude, _currentLongitude),
                MapConstants.detailZoom,
              ),
            ),
          );
        } else if (_allFacilities.isNotEmpty) {
          unawaited(
            _moveCamera(
              controller,
              CameraUpdate.newLatLngZoom(
                LatLng(
                  _allFacilities.first.location.latitude,
                  _allFacilities.first.location.longitude,
                ),
                MapConstants.defaultZoom,
              ),
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
    // Deliberately no provider-cache short-circuit: `facilities` holds the
    // current region, not everything, so each location change must re-query.
    setState(() {
      _isLoading = true;
      _loadFailed = false;
      _markers.clear();
      _filteredFacilities = [];
      _listFacilities = [];
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
        MapConstants.facilityQueryTimeout,
        onTimeout: () {
          throw Exception('Timeout loading facilities');
        },
      );

      if (mounted) {
        _facilityProvider.setFacilities(facilities);

        setState(() {
          // A copy: the provider edits its list in place when favorites
          // change, and this page needs to see those edits as changes.
          _allFacilities = List.of(facilities);
          _applyFavoriteFlags();
          _isLoading = false;
          _lastQueryCenter = queryCenter;
          _showSearchAreaButton = false;
          // The camera may still be on its way here. Until it settles and
          // reports its view, list everything that came back rather than
          // filtering against wherever the map was.
          final bounds = _visibleBounds;
          if (bounds != null && !bounds.contains(queryCenter)) {
            _visibleBounds = null;
          }
        });
        _filterFacilities();
        unawaited(_syncListToViewport(mustContain: queryCenter));
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'MapPage._loadFacilities',
      );
      if (mounted) {
        setState(() {
          _loadFailed = true;
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
    final isCurrent = displayName == ZipCodeService.currentLocationSentinel;

    _forgetFocus();
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

    final controller = _googleMapController;
    if (controller != null && mounted) {
      await _moveCamera(
        controller,
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
      await _onLocationChanged(
        ZipCodeService.currentLocationSentinel,
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
        backgroundColor: AppColors.warning,
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

    const radiusMeters = MapConstants.defaultRadiusMiles * 1609.34;
    final thresholdMeters = (radiusMeters * 0.35).clamp(300.0, 40000.0);
    final drifted = MapGeometry.distanceMeters(last, center) > thresholdMeters;

    if (drifted != _showSearchAreaButton) {
      setState(() => _showSearchAreaButton = drifted);
    }
  }

  /// Re-queries around the current map center. Deliberately does not move the
  /// camera or touch ZipCodeService, so the user's saved location survives.
  Future<void> _searchThisArea() async {
    final center = _mapCenter;
    if (center == null || _isSearchingArea) return;

    _forgetFocus();
    setState(() {
      _isSearchingArea = true;
      _expandedFacilityId = null;
      _currentLatitude = center.latitude;
      _currentLongitude = center.longitude;
      _currentLocation = MapConstants.mapAreaSentinel;
    });

    await _loadFacilities();

    if (mounted) {
      setState(() => _isSearchingArea = false);
    }
  }

  // --- Keeping the list, the camera, and the selection in step -------------

  /// Runs whenever the camera comes to rest, whoever moved it.
  void _onCameraIdle() {
    _focusInFlight = false;
    if ((_previousZoom - _currentZoom).abs() > 0.1) {
      _previousZoom = _currentZoom;
      _updateMarkers();
    }
    _maybeShowSearchAreaButton();

    // The list is hidden behind the card; it re-syncs when the card closes.
    if (_showSingleFacility) return;

    if (_expandedFacilityId != null) {
      // The expanded row's own camera move ends here, and the list must not
      // reshuffle under the row the user just opened.
      if (_isCameraAtFocus()) return;
      // Anything else was the user moving the map: the row gives way.
      setState(() => _expandedFacilityId = null);
      _forgetFocus();
    }
    unawaited(_syncListToViewport());
  }

  /// Reads the map's view and narrows the list to it. With [mustContain], it
  /// does nothing unless the view already shows that point — used after a
  /// load, when the camera may still be travelling to the new area.
  Future<void> _syncListToViewport({LatLng? mustContain}) async {
    final controller = _googleMapController;
    if (controller == null || !mounted) return;
    try {
      final bounds = await controller.getVisibleRegion();
      if (!mounted) return;
      // A map that hasn't been laid out yet reports an empty region.
      if (bounds.northeast == bounds.southwest) return;
      if (mustContain != null && !bounds.contains(mustContain)) return;
      _visibleBounds = bounds;
      _rebuildList();
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'MapPage._syncListToViewport',
      );
    }
  }

  /// Recomputes the list from the filtered facilities and the map's view.
  void _rebuildList() {
    final bounds = _visibleBounds;
    final isGuest = context.read<GuestModeService>().isGuest;
    // A text search, or the Favorites filter, asks about the whole loaded
    // area, so those matches list even when they're off screen.
    final asksAboutWholeArea = _searchController.text.trim().isNotEmpty ||
        (_showFavoritesOnly && !isGuest);

    final next = FacilityFilterService.nearestFirst(
      _filteredFacilities,
      center:
          bounds == null ? null : _mapCenter ?? MapGeometry.centerOf(bounds),
      within: asksAboutWholeArea ? null : bounds,
    );

    final reordered = next.length != _listFacilities.length ||
        Iterable<int>.generate(next.length)
            .any((i) => next[i].id != _listFacilities[i].id);
    setState(() => _listFacilities = next);
    // A list that changed under the user starts from its top.
    if (reordered && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  /// The band of the map, top to bottom in logical pixels, left visible
  /// between the search chrome and a bottom sheet [sheetHeight] tall.
  ({double top, double bottom}) _visibleStrip(double sheetHeight) {
    final top = _chromeBottom();
    return (
      top: top,
      bottom: math.max(top + _minVisibleStrip, _mapSize.height - sheetHeight),
    );
  }

  /// Bottom edge of the search bar and filter chips, measured from the top of
  /// the map.
  double _chromeBottom() {
    final chrome = _chromeKey.currentContext?.findRenderObject();
    final map = context.findRenderObject();
    if (chrome is! RenderBox || map is! RenderBox || !chrome.hasSize) {
      return MapConstants.searchBarAreaHeight;
    }
    return chrome
        .localToGlobal(Offset(0, chrome.size.height), ancestor: map)
        .dy;
  }

  double _listPanelHeight() => FacilityListPanel.heightFor(
        MediaQuery.of(context),
        isPanelOpen: _isPanelOpen,
        isFullyExpanded: _isFullyExpanded,
        isSearchActive: _isSearchActive,
      );

  /// Height the facility sheet takes at its default size.
  double _singleCardSheetHeight() =>
      MediaQuery.of(context).size.height *
      MapConstants.singleCardDefaultHeightRatio;

  /// Where the camera must point, at [zoom], for [point] to sit in the middle
  /// of the strip a sheet [sheetHeight] tall leaves visible.
  LatLng _targetShowing(LatLng point, double zoom, double sheetHeight) {
    if (_mapSize.height <= 0) return point;
    final strip = _visibleStrip(sheetHeight);
    return MapGeometry.targetShowing(
      point,
      zoom: zoom,
      pixelsAboveCenter: _mapSize.height / 2 - (strip.top + strip.bottom) / 2,
    );
  }

  /// Gives [point] the camera's attention: centers it in the visible strip,
  /// zooming in to at least [minZoom], and remembers where the camera was so
  /// [_releaseFocus] can go back.
  Future<void> _focusOn(
    LatLng point, {
    required double minZoom,
    required double sheetHeight,
  }) async {
    final controller = _googleMapController;
    if (controller == null) return;

    try {
      // Moving between facilities keeps the original starting point.
      _cameraBeforeFocus ??= _camera;
      final zoom = math.max(_camera.zoom, minZoom);
      final focus = CameraPosition(
        target: _targetShowing(point, zoom, sheetHeight),
        zoom: zoom,
      );
      _focusCamera = focus;
      _focusInFlight = true;
      await _moveCamera(controller, CameraUpdate.newCameraPosition(focus));
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'MapPage._focusOn',
      );
    }
  }

  bool _isCameraAtFocus() {
    final focus = _focusCamera;
    if (focus == null) return false;
    if (_focusInFlight) return true;
    if ((focus.zoom - _camera.zoom).abs() > _focusToleranceZoom) return false;
    final tolerance = _focusTolerancePx *
        MapGeometry.metersPerPixel(_camera.target.latitude, _camera.zoom);
    return MapGeometry.distanceMeters(focus.target, _camera.target) <=
        tolerance;
  }

  /// Ends a facility's hold on the camera. If the camera is still where the
  /// focus left it, it returns to where it was beforehand; if the user has
  /// moved the map since, it stays where they put it.
  void _releaseFocus() {
    final before = _cameraBeforeFocus;
    final shouldRestore = before != null && _isCameraAtFocus();
    _forgetFocus();

    final controller = _googleMapController;
    if (shouldRestore && controller != null) {
      // The list re-syncs when this move comes to rest.
      unawaited(
        _moveCamera(controller, CameraUpdate.newCameraPosition(before)),
      );
    } else {
      unawaited(_syncListToViewport());
    }
  }

  /// Drops any remembered camera without moving the map — for when the map is
  /// about to go somewhere else entirely.
  void _forgetFocus() {
    _cameraBeforeFocus = null;
    _focusCamera = null;
    _focusInFlight = false;
  }

  /// Zooms until a tapped cluster's members stand apart, framed in the part
  /// of the map the list leaves visible. When the camera comes to rest the
  /// markers redraw and the list narrows to what is on screen: the cluster.
  Future<void> _onClusterTap(List<Facility> members) async {
    final controller = _googleMapController;
    final bounds = MapGeometry.boundsOf(members.map((f) => f.location));
    if (controller == null || bounds == null) return;

    final center = MapGeometry.centerOf(bounds);
    final sheetHeight = _listPanelHeight();
    final strip = _visibleStrip(sheetHeight);

    // Members at one address can't be separated by framing them; they need
    // the zoom at which their pins fan out.
    final sameAddress =
        MapGeometry.distanceMeters(bounds.southwest, bounds.northeast) < 1;
    var zoom = sameAddress
        ? MarkerManagementService.fanOutRevealZoom(center.latitude)
        : math.min(
            MapGeometry.zoomToFit(
              bounds,
              Size(
                math.max(1, _mapSize.width - 2 * _clusterFitPadding),
                math.max(
                  1,
                  strip.bottom - strip.top - 2 * _clusterFitPadding,
                ),
              ),
            ),
            _clusterFitMaxZoom,
          );
    // Always make visible progress, even when the members already fit.
    zoom = math.max(zoom, _currentZoom + 1);

    _forgetFocus();
    try {
      await _moveCamera(
        controller,
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _targetShowing(center, zoom, sheetHeight),
            zoom: zoom,
          ),
        ),
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'MapPage._onClusterTap',
      );
    }
  }

  /// Re-runs filtering when the "what you can provide" answers change on the
  /// Profile tab (this map stays alive in the IndexedStack, so it must react
  /// explicitly).
  void _onEligibilityChanged() {
    if (mounted) _filterFacilities();
  }

  /// Favorites arrive after the facilities they belong to, and from a
  /// provider this page doesn't rebuild on. Fold the hearts in when they land;
  /// without this the Favorites filter could come up empty.
  void _onFavoritesChanged() {
    if (!mounted || _isLoading) return;
    if (_applyFavoriteFlags()) _filterFacilities();
  }

  /// Sets each loaded facility's heart from the provider's favorite ids.
  /// Returns whether anything changed.
  bool _applyFavoriteFlags() {
    final favoriteIds = _facilityProvider.favoriteIds;
    var changed = false;
    for (var i = 0; i < _allFacilities.length; i++) {
      final facility = _allFacilities[i];
      final isFavorite = favoriteIds.contains(facility.id);
      if (facility.isFavorite != isFavorite) {
        _allFacilities[i] = facility.copyWith(isFavorite: isFavorite);
        changed = true;
      }
    }

    final selected = _selectedFacility;
    if (selected != null &&
        selected.isFavorite != favoriteIds.contains(selected.id)) {
      _selectedFacility = selected.copyWith(isFavorite: !selected.isFavorite);
      changed = true;
    }
    return changed;
  }

  void _filterFacilities() {
    _filteredFacilities = _facilitiesMatching(
      categories: _selectedCategories,
      preferenceRequirements: _selectedPreferenceRequirements,
      showFavoritesOnly: _showFavoritesOnly,
      showOpenNowOnly: _showOpenNowOnly,
    );
    _rebuildList();
    _updateMarkers();
  }

  /// The loaded facilities a set of filters leaves, with the search text and
  /// the "what you can provide" answers applied on top.
  ///
  /// Guests have no favorites and no preference filters; ignoring any stale
  /// state here means neither can hide a facility from someone who can't
  /// change it. Their answers about what they can provide do apply — those
  /// they can change, on Profile.
  List<Facility> _facilitiesMatching({
    required Set<String> categories,
    required Map<PreferenceRequirement, bool?> preferenceRequirements,
    required bool showFavoritesOnly,
    required bool showOpenNowOnly,
  }) {
    final isGuest = context.read<GuestModeService>().isGuest;
    return FacilityFilterService.filterFacilities(
      _allFacilities,
      searchText: _searchController.text,
      selectedCategories: categories,
      selectedEligibilityRequirements: FacilityFilterService.eligibilityGates(
        EligibilityPreferencesService().eligibility,
      ),
      selectedPreferenceRequirements:
          isGuest ? const {} : preferenceRequirements,
      showFavoritesOnly: showFavoritesOnly && !isGuest,
      showOpenNowOnly: showOpenNowOnly,
    );
  }

  Future<void> _updateMarkers() async {
    if (!mounted || _googleMapController == null) return;
    if (_isUpdatingMarkers) {
      // Run again once the current pass finishes, with the zoom of that
      // moment — not the one this request was made at.
      _markerUpdateQueued = true;
      return;
    }
    _markerUpdateDebounce?.cancel();

    _markerUpdateDebounce = Timer(const Duration(milliseconds: 100), () async {
      if (!mounted || _googleMapController == null) return;
      _isUpdatingMarkers = true;

      try {
        final zoom = await _googleMapController!.getZoomLevel();
        if (!mounted) return;
        setState(() {
          _currentZoom = zoom;
        });

        final newMarkers = await MarkerManagementService.createMarkersClustered(
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
        if (_markerUpdateQueued) {
          _markerUpdateQueued = false;
          unawaited(_updateMarkers());
        }
      }
    });
  }

  void _onMapTap(LatLng position) {
    if (_showSingleFacility) {
      _dismissSingleFacilityAnimated(showPanel: false);
    } else if (_isPanelOpen) {
      setState(() {
        _isPanelOpen = false;
        _isFullyExpanded = false;
      });
    }
  }

  /// Slides the single-facility card down, then clears it — the animated
  /// counterpart of [_dismissSingleFacilityView], used for user gestures
  /// (swipe-down handle, map tap, back) so the collapse is smooth.
  void _dismissSingleFacilityAnimated({bool showPanel = false}) {
    if (!_showSingleFacility || _cardDismissing) return;
    setState(() => _cardDismissing = true);
    Future.delayed(AppMotion.of(context, MapConstants.animationDuration), () {
      if (!mounted) return;
      _dismissSingleFacilityView(showPanel: showPanel);
    });
  }

  void _dismissSingleFacilityView({bool showPanel = true}) {
    if (!_showSingleFacility) return;
    setState(() {
      _showSingleFacility = false;
      _cardDismissing = false;
      _singleCardExpanded = false;
      _selectedFacility = null;
      _isPanelOpen = showPanel;
      _isFullyExpanded = false;
    });
    _releaseFocus();
  }

  Future<void> _showFacilityDetails(Facility facility) async {
    try {
      setState(() {
        _showSingleFacility = true;
        _cardDismissing = false;
        _singleCardExpanded = false;
        _selectedFacility = facility;
        _isPanelOpen = false;
        _isFullyExpanded = false;
        _expandedFacilityId = null;
      });

      context.read<RecentFacilitiesService>().addFacility(facility);

      await _focusOn(
        facility.location,
        minZoom: MapConstants.markerZoom,
        sheetHeight: _singleCardSheetHeight(),
      );
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

  /// Home quick-actions pass a group ("Health Care", …), which expands to its
  /// `category_broad` values; a raw category_broad value is used as-is.
  void filterByCategory(String category) {
    final values = FacilityCategories.isGroup(category)
        ? FacilityCategories.valuesForGroup(category)
        : [category];
    final hadCard = _showSingleFacility;
    setState(() {
      _selectedCategories
        ..clear()
        ..addAll(values);
      _searchController.clear();
      _showSingleFacility = false;
      _selectedFacility = null;
      _expandedFacilityId = null;
      if (hadCard) _isPanelOpen = true;
    });
    _forgetFocus();
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
    _forgetFocus();
    setState(() {
      _currentLatitude = lat;
      _currentLongitude = lng;
      _currentLocation = zipService.zipCode?.isNotEmpty == true
          ? zipService.zipCode!
          : ZipCodeService.currentLocationSentinel;
      _showSingleFacility = false;
      _selectedFacility = null;
      _expandedFacilityId = null;
    });
    await _loadFacilities();
    final controller = _googleMapController;
    if (controller != null && mounted) {
      await _moveCamera(
        controller,
        CameraUpdate.newLatLngZoom(
          LatLng(lat, lng),
          MapConstants.radiusFramingZoom,
        ),
      );
    }
  }

  /// Shows a search handed over from the Ask tab: its filters, around the
  /// saved location — the same place Ask looked, wherever the map was
  /// pointing before.
  Future<void> applyFilters({
    required Set<String> categories,
    required bool openNow,
    required Set<PreferenceRequirement> preferences,
    required String searchText,
  }) async {
    if (!mounted) return;
    setState(() {
      _selectedCategories
        ..clear()
        ..addAll(categories);
      _showOpenNowOnly = openNow;
      _selectedPreferenceRequirements = {
        for (final preference in preferences) preference: true,
      };
      _showFavoritesOnly = false;
      _searchController.text = searchText;
      _isPanelOpen = true;
    });
    // Clears any open card or row, reloads, and re-filters.
    await recenterOnUserLocation();
  }

  /// Undoes the innermost thing open on the map — the facility card, an
  /// expanded row, the raised list, or a search — and says whether there was
  /// one. Android's back button asks here before it leaves the tab.
  bool handleBack() {
    // Android hides the keyboard on its own first, which can leave the field
    // focused with nothing showing; drop that focus without spending a press.
    if (_searchFocusNode.hasFocus) _searchFocusNode.unfocus();

    switch (mapBackTarget(
      cardOpen: _showSingleFacility,
      rowExpanded: _expandedFacilityId != null,
      hasSearchText: _searchController.text.isNotEmpty,
      panelFullyExpanded: _isFullyExpanded,
    )) {
      case MapBackTarget.facilityCard:
        _dismissSingleFacilityAnimated(showPanel: true);
      case MapBackTarget.expandedRow:
        _toggleFacilityExpansion(_expandedFacilityId!);
      case MapBackTarget.expandedPanel:
        setState(() => _isFullyExpanded = false);
      case MapBackTarget.searchText:
        _searchController.clear();
        _filterFacilities();
      case MapBackTarget.nothing:
        return false;
    }
    return true;
  }

  Widget _buildFilterBar() {
    final isGuest = context.read<GuestModeService>().isGuest;
    return FilterBar(
      selectedCategories: _selectedCategories,
      selectedPreferenceRequirements:
          isGuest ? const {} : _selectedPreferenceRequirements,
      showFavoritesOnly: _showFavoritesOnly && !isGuest,
      showOpenNowOnly: _showOpenNowOnly,
      isGuestMode: isGuest,
      onFavoritesTap: isGuest
          ? () => showSignInPromptDialog(context)
          : _toggleFavoritesFilter,
      onOpenNowTap: _toggleOpenNowFilter,
      onFiltersTap: _showFilterModal,
      onCategoryTap: () =>
          _showFilterModal(expandedSection: FilterSection.category),
      onPreferencesTap: isGuest
          ? () => showSignInPromptDialog(context)
          : () => _showFilterModal(expandedSection: FilterSection.preferences),
    );
  }

  /// Floating "Search this area" pill, shown under the filter bar once the map
  /// has drifted from the last query center. Tapping re-queries around the new
  /// center (Yelp / Google Maps pattern).
  Widget _buildSearchAreaButton() {
    final visible = _showSearchAreaButton && !_showSingleFacility;
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: !visible
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: AppRadii.pillAll,
                    onTap: _isSearchingArea ? null : _searchThisArea,
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: AppSizes.minTouchTarget,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: AppRadii.pillAll,
                        boxShadow: AppShadows.raised,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isSearchingArea)
                            SizedBox.square(
                              dimension: AppIconSize.sm,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: onPrimary,
                              ),
                            )
                          else
                            Icon(
                              Icons.refresh,
                              color: onPrimary,
                              size: AppIconSize.md,
                            ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _isSearchingArea
                                ? AppLocalizations.of(context)!.mapSearching
                                : AppLocalizations.of(context)!
                                    .mapSearchThisArea,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: onPrimary,
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

  void _toggleFavoritesFilter() {
    _dismissSingleFacilityView();
    setState(() => _showFavoritesOnly = !_showFavoritesOnly);
    _filterFacilities();
  }

  void _toggleOpenNowFilter() {
    _dismissSingleFacilityView();
    setState(() => _showOpenNowOnly = !_showOpenNowOnly);
    _filterFacilities();
  }

  Future<void> _showFilterModal({FilterSection? expandedSection}) async {
    final isGuest = context.read<GuestModeService>().isGuest;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FilterModal(
        selectedCategories: _selectedCategories,
        availableCategories: FacilityCategories.categoryBroadValues,
        selectedPreferenceRequirements: _selectedPreferenceRequirements,
        showFavoritesOnly: _showFavoritesOnly,
        showOpenNowOnly: _showOpenNowOnly,
        expandedSection: expandedSection,
        isGuest: isGuest,
        onLockedTap: () => showSignInPromptDialog(sheetContext),
        resultCount: (selection) => _facilitiesMatching(
          categories: selection.categories,
          preferenceRequirements: selection.preferenceRequirements,
          showFavoritesOnly: selection.showFavoritesOnly,
          showOpenNowOnly: selection.showOpenNowOnly,
        ).length,
      ),
    );

    if (result != null && mounted) {
      final hadCard = _showSingleFacility;
      setState(() {
        if (_showSingleFacility) {
          _showSingleFacility = false;
          _selectedFacility = null;
          _isPanelOpen = true;
          _isFullyExpanded = false;
        }

        _selectedCategories.clear();
        _selectedCategories.addAll(result['categories'] as Set<String>);
        _selectedPreferenceRequirements = result['preferenceRequirements']
            as Map<PreferenceRequirement, bool?>;
        _showFavoritesOnly = result['showFavoritesOnly'] as bool;
        _showOpenNowOnly = result['showOpenNowOnly'] as bool;
      });
      if (hadCard) _releaseFocus();
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

  /// "Incorrect info? Submit corrections" entry point on facility cards.
  /// Guests get the sign-in prompt.
  void _onCorrectFacility(Facility facility) {
    if (context.read<GuestModeService>().isGuest) {
      showSignInPromptDialog(context);
      return;
    }
    showFacilityCorrectionDialog(context, facility: facility);
  }

  String? _expandedFacilityId;

  void _toggleFacilityExpansion(String facilityId) {
    final isOpening = _expandedFacilityId != facilityId;
    setState(() {
      _expandedFacilityId = isOpening ? facilityId : null;
    });

    if (!isOpening) {
      // Back to the view the user had before opening the row.
      _releaseFocus();
      return;
    }

    final facility =
        _allFacilities.where((f) => f.id == facilityId).firstOrNull;
    if (facility != null) {
      context.read<RecentFacilitiesService>().addFacility(facility);
      unawaited(
        _focusOn(
          facility.location,
          minZoom: MapConstants.listExpandZoom,
          sheetHeight: _listPanelHeight(),
        ),
      );
    }
  }

  /// The provider flips the heart and notifies; [_onFavoritesChanged] carries
  /// the change into this page's lists. Favorites live with an account, so a
  /// guest is offered sign-in instead.
  void _toggleFavorite(String facilityId) {
    if (context.read<GuestModeService>().isGuest) {
      showSignInPromptDialog(context);
      return;
    }
    _facilityProvider.toggleFavorite(facilityId);
  }

  Future<void> _launchUrl(String url) async {
    await UrlLauncherService.launchUrlString(url, context);
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: AppIconSize.hero,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppLocalizations.of(context)!.mapLoadFailed,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
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

    if (_loadFailed) {
      return _buildError();
    }

    // Rebuild on sign-in and sign-out: the locked chips depend on it.
    context.watch<GuestModeService>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          _mapSize = constraints.biggest;
          return Stack(
            children: [
              RepaintBoundary(
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  style: _mapStyle,
                  initialCameraPosition: _initialCamera,
                  markers: _markers,
                  onCameraMove: (CameraPosition position) {
                    _camera = position;
                    _currentZoom = position.zoom;
                    _mapCenter = position.target;
                  },
                  onCameraIdle: _onCameraIdle,
                  onTap: _onMapTap,
                  myLocationEnabled: _locationGranted && _gpsMode,
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
                    key: _chromeKey,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: AppRadii.pillAll,
                          boxShadow: AppShadows.raised,
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
                      const SizedBox(height: AppSpacing.xs),
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
                            facilities: _listFacilities,
                            totalMatches: _filteredFacilities.length,
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
                            onRequestFacility: _onRequestFacility,
                            onRateFacility: _onRateFacility,
                            onCorrectFacility: _onCorrectFacility,
                            onPanelStateChange: (isPanelOpen, isFullyExpanded) {
                              setState(() {
                                _isPanelOpen = isPanelOpen;
                                _isFullyExpanded = isFullyExpanded;
                              });
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The sheet a tapped pin opens: the same surface and the same card as a
  /// row of the list, full width, sliding up from the bottom edge.
  Widget _buildSingleFacilityCard() {
    if (_selectedFacility == null) return const SizedBox.shrink();

    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    // Expanded, it stops below the search + filter bars so it never overlaps
    // that chrome.
    final expandedHeight = screenHeight -
        MapConstants.searchBarAreaHeight -
        topPadding -
        kToolbarHeight -
        MapConstants.panelBottomOffset;
    final cardHeight = _singleCardExpanded
        ? expandedHeight
        : screenHeight * MapConstants.singleCardDefaultHeightRatio;
    final duration = AppMotion.of(context, MapConstants.animationDuration);
    // The card's scroll view wins the gesture arena while scrolling, so the
    // handle bar is the always-available drag target.
    return AnimatedSlide(
      offset: _cardDismissing ? const Offset(0, 1.2) : Offset.zero,
      duration: duration,
      curve: MapConstants.animationCurve,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > MapConstants.minFlickVelocity) {
            if (_singleCardExpanded) {
              setState(() => _singleCardExpanded = false);
            } else {
              _dismissSingleFacilityAnimated(showPanel: false);
            }
          } else if (velocity < -MapConstants.minFlickVelocity) {
            if (!_singleCardExpanded) {
              setState(() => _singleCardExpanded = true);
            }
          }
        },
        child: AnimatedContainer(
          duration: duration,
          curve: MapConstants.animationCurve,
          height: cardHeight,
          decoration: const BoxDecoration(
            borderRadius: AppRadii.sheetTop,
            boxShadow: AppShadows.sheet,
          ),
          child: ClipRRect(
            borderRadius: AppRadii.sheetTop,
            child: FacilityCard(
              facility: _selectedFacility!,
              isExpanded: true,
              onToggleExpand: () {},
              onToggleFavorite: () => _toggleFavorite(_selectedFacility!.id),
              onLaunchUrl: _launchUrl,
              buildCategoryIcon: FacilityCategoryIcons.buildCategoryIcon,
              showExpandButton: false,
              onRate: () => _onRateFacility(_selectedFacility!),
              onSubmitCorrection: () => _onCorrectFacility(_selectedFacility!),
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.sheetTop,
              ),
              showDragHandle: true,
            ),
          ),
        ),
      ),
    );
  }
}
