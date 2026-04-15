import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationSearch extends StatefulWidget {
  final String currentLocation;
  final Function(String, double?, double?) onLocationChanged;
  final Function(bool)? onFocusChanged;

  const LocationSearch({
    Key? key,
    required this.currentLocation,
    required this.onLocationChanged,
    this.onFocusChanged,
  }) : super(key: key);

  @override
  State<LocationSearch> createState() => _LocationSearchState();
}

class _LocationSearchState extends State<LocationSearch> {
  late TextEditingController _controller;
  bool _isLoadingLocation = false;
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
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _controller.text = 'Current Location';
      widget.onLocationChanged(
          'Current Location', position.latitude, position.longitude);
    } catch (e) {
      log('Error getting current location: $e', name: 'LocationSearch');
      _controller.text = '60613';
      widget.onLocationChanged('60613', 41.9542, -87.6668);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Unable to get current location. Using Chicago 60613.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  bool _isValidZipCode(String value) {
    final zipRegex = RegExp(r'^\d{5}(-\d{4})?$');
    return zipRegex.hasMatch(value.trim());
  }

  Future<void> _onLocationSubmitted(String value) async {
    if (value.trim().isEmpty) return;

    final trimmedValue = value.trim();

    if (trimmedValue.toLowerCase().contains('current')) {
      _getCurrentLocation();
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
      List<Location> locations = await locationFromAddress('$zipCode, USA');

      if (locations.isNotEmpty) {
        final location = locations.first;
        widget.onLocationChanged(
            zipCode, location.latitude, location.longitude);
      } else {
        _handleGeocodingFailure(zipCode);
      }
    } catch (e) {
      log('Geocoding error for $zipCode: $e', name: 'LocationSearch');
      _handleGeocodingFailure(zipCode);
    }
  }

  void _handleGeocodingFailure(String zipCode) {
    widget.onLocationChanged(zipCode, 41.9542, -87.6668);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Could not find location for zip code $zipCode. Using Chicago as default.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_pin, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              hintText: 'Enter zip code',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12.0),
              filled: false,
              fillColor: Colors.transparent,
            ),
            style: const TextStyle(color: Colors.black),
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
            tooltip: 'Use current location',
          ),
      ],
    );
  }
}
