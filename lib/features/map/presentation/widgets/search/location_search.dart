import 'package:beacon_app/core/services/error_reporter.dart';
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
  bool _isLoadingLocation = false;

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
      _controller.text = widget.currentLocation;
    }
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
      if (_controller.text.toLowerCase().contains('current location')) {
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

  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return;
    setState(() => _isLoadingLocation = true);

    final result = await LocationService.getCurrentLocation();

    if (!mounted) return;
    setState(() => _isLoadingLocation = false);

    if (result.status == LocationStatus.granted) {
      final name = AppLocalizations.of(context)?.locationCurrentLocation ??
          'Current Location';
      _controller.text = name;
      widget.onLocationChanged(name, result.latitude, result.longitude);
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

    if (trimmedValue.toLowerCase().contains('current')) {
      await _getCurrentLocation();
      return;
    }

    if (!_isValidZipCode(trimmedValue)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please enter a valid 5-digit zip code (e.g., 60605)'),
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
        if (_isLoadingLocation)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.blue),
            onPressed: _getCurrentLocation,
            tooltip: l10n?.locationUseMyLocationTooltip ?? 'Use my location',
          ),
      ],
    );
  }
}
