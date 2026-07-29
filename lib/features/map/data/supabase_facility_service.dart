import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Short TTL for the in-memory region cache. Long enough to make rapid
/// pan/zoom/re-query cheap, short enough that data edits surface quickly.
const Duration _kRegionCacheTtl = Duration(minutes: 5);

/// Service for querying nationwide healthcare facilities from Supabase.
///
/// Backed by the `facilities_near` PostGIS RPC (see
/// `supabase/migrations/0002_facilities_postgis.sql`), which returns only the
/// facilities within a radius of a point — sorted by true distance and capped
/// server-side. This replaces the old "fetch the whole table, filter in Dart"
/// model, which did not scale past the ~691-row Illinois view to the 162,937-row
/// `FCT_Supabase` table.
class SupabaseFacilityService {
  SupabaseFacilityService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// PostGIS proximity RPC: `facilities_near(lat, lng, radius_m, max_results)`.
  static const String _rpcName = 'facilities_near';

  /// View used for single-record lookups (column mapping + eligibility join).
  static const String _viewName = 'fct_supabase_full';

  /// Server-side result cap. Matches the RPC default; the map/list never needs
  /// more than this for one region.
  static const int _maxResults = 250;

  /// Quantized-region → results cache, so small pans and repeat queries don't
  /// re-hit the network. Bounded + TTL'd.
  final Map<String, _CachedRegion> _regionCache = {};
  static const int _maxCacheEntries = 16;

  /// Returns facilities within [radiusKm] of a point via the server-side
  /// PostGIS RPC, already sorted by distance and capped.
  Future<List<Facility>> getFacilitiesNearLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final key = _regionKey(latitude, longitude, radiusKm);
    final cached = _regionCache[key];
    if (cached != null && !cached.isExpired) return cached.facilities;

    final response = await _client.rpc<dynamic>(
      _rpcName,
      params: {
        'lat': latitude,
        'lng': longitude,
        'radius_m': radiusKm * 1000.0,
        'max_results': _maxResults,
      },
    );

    final facilities = _parseRows(response);
    _putCache(key, facilities);
    return facilities;
  }

  /// Fetches multiple facilities by id from the view.
  ///
  /// Used to render the user's Favorites (stored in `user_favorites` as bare
  /// ids) independent of the current map region — a favorite 500 mi away is
  /// still resolvable here.
  Future<List<Facility>> getFacilitiesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final response = await _client.from(_viewName).select().inFilter('id', ids);
    return _parseRows(response);
  }

  /// Fetches a single facility by id from the view (full record, lazily loaded
  /// when a card is opened).
  Future<Facility?> getFacilityById(String id) async {
    final response =
        await _client.from(_viewName).select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return Facility.fromSupabase(Map<String, dynamic>.from(response));
  }

  /// Searches facilities by name within a region, or — when no location is
  /// given — across a bounded slice of the view. Distance-scoped search is the
  /// common path; the unbounded branch is capped to [_maxResults].
  Future<List<Facility>> searchFacilities(
    String query, {
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final q = query.trim();

    if (latitude != null && longitude != null && radiusKm != null) {
      final pool = await getFacilitiesNearLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      if (q.isEmpty) return pool;
      final lower = q.toLowerCase();
      return pool
          .where(
            (f) =>
                f.name.toLowerCase().contains(lower) ||
                f.description.toLowerCase().contains(lower),
          )
          .toList();
    }

    final builder = _client.from(_viewName).select();
    final response = q.isEmpty
        ? await builder.limit(_maxResults)
        : await builder.ilike('facility_name', '%$q%').limit(_maxResults);
    return _parseRows(response);
  }

  List<Facility> _parseRows(dynamic response) {
    final rows = (response as List?) ?? const [];
    final facilities = <Facility>[];
    for (final row in rows) {
      try {
        facilities.add(
          Facility.fromSupabase(Map<String, dynamic>.from(row as Map)),
        );
      } catch (e, stackTrace) {
        ErrorReporter.instance.report(
          e,
          stackTrace,
          context: 'SupabaseFacilityService._parseRows',
        );
      }
    }
    return facilities;
  }

  /// Clears the region cache (e.g. after a data refresh).
  void clearCache() => _regionCache.clear();

  /// Quantizes the query to ~0.01° (~1.1 km) so near-identical centers reuse
  /// the same cache entry.
  String _regionKey(double lat, double lng, double radiusKm) {
    String q(double v) => (v / 0.01).round().toString();
    return '${q(lat)}:${q(lng)}:${radiusKm.toStringAsFixed(1)}';
  }

  void _putCache(String key, List<Facility> facilities) {
    if (_regionCache.length >= _maxCacheEntries &&
        !_regionCache.containsKey(key)) {
      // Evict the oldest entry.
      final oldest = _regionCache.entries.reduce(
        (a, b) => a.value.fetchedAt.isBefore(b.value.fetchedAt) ? a : b,
      );
      _regionCache.remove(oldest.key);
    }
    _regionCache[key] = _CachedRegion(facilities, DateTime.now());
  }
}

class _CachedRegion {
  _CachedRegion(this.facilities, this.fetchedAt);

  final List<Facility> facilities;
  final DateTime fetchedAt;

  bool get isExpired => DateTime.now().difference(fetchedAt) > _kRegionCacheTtl;
}
