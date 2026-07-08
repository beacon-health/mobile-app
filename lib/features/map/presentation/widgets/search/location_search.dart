import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/presentation/services/location_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

class LocationSearch extends StatefulWidget {
  final String currentLocation;
  final Function(String, double?, double?) onLocationChanged;
  final Function(bool)? onFocusChanged;

  const LocationSearch({
    super.key,
    required this.currentLocation,
    required this.onLocationChanged,
    this.onFocusChanged,
  });

  @override
  State<LocationSearch> createState() => _LocationSearchState();
}

class _LocationSearchState extends State<LocationSearch> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentLocation);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(LocationSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation &&
        !_focusNode.hasFocus) {
      _controller.text = _displayFor(widget.currentLocation);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-render sentinel labels ("Current Location", "Map area") in the
    // active locale — covers first build and language switches.
    if (!_focusNode.hasFocus) {
      _controller.text = _displayFor(widget.currentLocation);
    }
  }

  /// Translates canonical location sentinels for display; ZIPs and anything
  /// else pass through unchanged.
  String _displayFor(String raw) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return raw;
    if (raw == MapConstants.currentLocationSentinel) {
      return l10n.locationCurrentLocation;
    }
    if (raw == MapConstants.mapAreaSentinel) return l10n.mapAreaLabel;
    return raw;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    widget.onFocusChanged?.call(_focusNode.hasFocus);

    if (_focusNode.hasFocus) {
      _previousText = _controller.text;
      final lower = _controller.text.toLowerCase();
      final l10n = AppLocalizations.of(context);
      final isPlaceholder = lower.contains('current location') ||
          lower == MapConstants.mapAreaSentinel.toLowerCase() ||
          (l10n != null &&
              (lower == l10n.locationCurrentLocation.toLowerCase() ||
                  lower == l10n.mapAreaLabel.toLowerCase()));
      if (isPlaceholder) {
        // Placeholder-style labels: clear on focus. If the user types nothing,
        // the unfocus branch below restores the label from `_previousText`.
        _controller.clear();
      } else if (_isValidZipCode(_controller.text)) {
        _controller.selection =
            TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      }
    } else {
      if (_controller.text.trim().isEmpty) {
        _controller.text = _previousText;
      }
    }
  }

  /// GPS lookup path — reached when the user types "current" into the field.
  /// (The my-location *button* moved to the resources search bar, §2.9.)
  Future<void> _getCurrentLocation() async {
    final result = await LocationService.getCurrentLocation();

    if (!mounted) return;

    if (result.status == LocationStatus.granted) {
      // Store the canonical sentinel; _displayFor localizes it on render.
      _controller.text = _displayFor(MapConstants.currentLocationSentinel);
      widget.onLocationChanged(
        MapConstants.currentLocationSentinel,
        result.latitude,
        result.longitude,
      );
      _focusNode.unfocus();
      return;
    }

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.locationPermissionDenied ??
              'Location access denied. Enable it in Settings > Privacy > Location Services.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  bool _isValidZipCode(String value) {
    final zipRegex = RegExp(r'^\d{5}(-\d{4})?$');
    return zipRegex.hasMatch(value.trim());
  }

  Future<void> _onLocationSubmitted(String value) async {
    if (value.trim().isEmpty) return;

    final trimmedValue = value.trim();
    final l10n = AppLocalizations.of(context);

    // Typing "current" (or the localized current-location label) triggers GPS.
    final lowerValue = trimmedValue.toLowerCase();
    if (lowerValue.contains('current') ||
        (l10n != null &&
            lowerValue == l10n.locationCurrentLocation.toLowerCase())) {
      await _getCurrentLocation();
      return;
    }

    if (!_isValidZipCode(trimmedValue)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.mapInvalidZip ??
                  'Please enter a valid 5-digit zip code (e.g., 60605)',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    await _geocodeZipCode(trimmedValue);
  }

  Future<void> _geocodeZipCode(String zipCode) async {
    try {
      final List<Location> locations =
          await locationFromAddress('$zipCode, USA');

      if (locations.isNotEmpty) {
        final location = locations.first;
        widget.onLocationChanged(
          zipCode,
          location.latitude,
          location.longitude,
        );
      } else {
        _handleGeocodingFailure(zipCode);
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'LocationSearch.geocodeZipCode',
      );
      _handleGeocodingFailure(zipCode);
    }
  }

  void _handleGeocodingFailure(String zipCode) {
    widget.onLocationChanged(zipCode, null, null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.mapZipNotFound(zipCode) ??
                'Could not find location for zip code $zipCode.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          Icons.location_pin,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: l10n?.mapSearchLocation ?? 'Enter zip code',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              filled: false,
              fillColor: Colors.transparent,
            ),
            style: TextStyle(color: colorScheme.onSurface),
            textAlignVertical: TextAlignVertical.center,
            onSubmitted: _onLocationSubmitted,
          ),
        ),
      ],
    );
  }
}
