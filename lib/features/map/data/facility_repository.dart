import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/features/map/data/supabase_facility_service.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';

/// Abstract interface for facility data access, kept as a seam so the Supabase
/// implementation can be swapped (e.g. for an offline cache).
abstract class FacilityRepositoryBase {
  Future<List<Facility>> loadFacilities();

  Future<List<Facility>> loadFacilitiesWithDistance({
    required double latitude,
    required double longitude,
    required double radiusMiles,
  });

  Future<List<Facility>> loadFacilitiesNearLocation({
    required double latitude,
    required double longitude,
    double radiusInKm = 50.0,
  });

  Stream<List<Facility>> getFacilitiesStream();

  Future<List<Facility>> searchFacilities(
    String query, {
    double? latitude,
    double? longitude,
    double? radiusMiles,
  });

  Future<List<Facility>> getFacilitiesByIds(List<String> ids);

  Future<Facility?> getFacilityById(String id);
}

/// Facility data from Supabase. Every method degrades to an empty result
/// rather than throwing; failures still reach [ErrorReporter].
class FacilityRepository implements FacilityRepositoryBase {
  FacilityRepository({SupabaseFacilityService? service})
      : _service = service ?? SupabaseFacilityService();

  final SupabaseFacilityService _service;

  static const double _milesToKm = 1.60934;

  /// Runs [operation], returning [fallback] and reporting if it throws.
  Future<T> _guard<T>(
    String context,
    Future<T> Function() operation,
    T fallback,
  ) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'FacilityRepository.$context',
      );
      return fallback;
    }
  }

  /// A capped page with no proximity filter. Real queries should use
  /// [loadFacilitiesWithDistance]; this only satisfies the interface.
  @override
  Future<List<Facility>> loadFacilities() =>
      _guard('loadFacilities', () => _service.searchFacilities(''), const []);

  @override
  Future<List<Facility>> loadFacilitiesWithDistance({
    required double latitude,
    required double longitude,
    required double radiusMiles,
  }) =>
      _guard(
        'loadFacilitiesWithDistance',
        () => _service.getFacilitiesNearLocation(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusMiles * _milesToKm,
        ),
        const [],
      );

  @override
  Future<List<Facility>> loadFacilitiesNearLocation({
    required double latitude,
    required double longitude,
    double radiusInKm = 50.0,
  }) =>
      _guard(
        'loadFacilitiesNearLocation',
        () => _service.getFacilitiesNearLocation(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusInKm,
        ),
        const [],
      );

  /// Returns a single-shot stream wrapping [loadFacilities] (bounded slice).
  @override
  Stream<List<Facility>> getFacilitiesStream() =>
      Stream.fromFuture(loadFacilities());

  /// Searches facilities by name, optionally bounded to a radius.
  @override
  Future<List<Facility>> searchFacilities(
    String query, {
    double? latitude,
    double? longitude,
    double? radiusMiles,
  }) =>
      _guard(
        'searchFacilities',
        () => _service.searchFacilities(
          query,
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusMiles == null ? null : radiusMiles * _milesToKm,
        ),
        const [],
      );

  /// Gets multiple facilities by ID (used for region-independent Favorites).
  @override
  Future<List<Facility>> getFacilitiesByIds(List<String> ids) => _guard(
        'getFacilitiesByIds',
        () => _service.getFacilitiesByIds(ids),
        const [],
      );

  @override
  Future<Facility?> getFacilityById(String id) => _guard(
        'getFacilityById',
        () => _service.getFacilityById(id),
        null,
      );
}
