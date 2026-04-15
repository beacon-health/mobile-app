import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Creates a minimal [Facility] for unit tests.
///
/// Override only the fields you care about; sensible defaults for the rest.
Facility createTestFacility({
  String id = 'test-1',
  String name = 'Test Facility',
  String description = 'A test facility',
  LatLng location = const LatLng(41.8781, -87.6298),
  String address = '123 Main St, Chicago, IL',
  String city = 'Chicago',
  String state = 'IL',
  String appCategory = 'Health Care',
  List<String> services = const ['Primary Care'],
  bool isFavorite = false,
  bool isOpenNow = false,
  List<OperatingHours> hours = const [],
  Map<String, bool> eligibilityRequirements = const {},
}) {
  return Facility(
    id: id,
    name: name,
    description: description,
    location: location,
    address: address,
    city: city,
    state: state,
    appCategory: appCategory,
    services: services,
    isFavorite: isFavorite,
    hours: hours,
    eligibilityRequirements: eligibilityRequirements,
  );
}
