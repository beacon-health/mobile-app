import 'dart:async';
import 'dart:convert';

import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the last few facilities the user has viewed.
///
/// Persists to [SharedPreferences] so the list survives app restarts.
/// We only serialize the fields actually rendered in the home "Recently
/// Viewed" list (id, name, address, category, lat/lng) and the feedback
/// dialog (id, name). Full Facility objects (with hours, services,
/// eligibility, …) are not persisted — they're recovered from Supabase on
/// demand when the user opens the map.
///
/// Stored most-recent-first, capped at [maxItems]. Re-viewing an existing
/// facility moves it to the front rather than duplicating.
class RecentFacilitiesService extends ChangeNotifier {
  factory RecentFacilitiesService() => _instance;

  RecentFacilitiesService._();

  static final RecentFacilitiesService _instance = RecentFacilitiesService._();

  /// Maximum number of recently-viewed facilities retained.
  static const int maxItems = 3;

  static const String _prefsKey = 'recent_facilities_v1';

  final List<Facility> _recent = [];
  bool _initialized = false;

  /// Snapshot of the recently-viewed facilities, most recent first.
  List<Facility> get recentFacilities => List.unmodifiable(_recent);

  /// Whether there are any recently-viewed facilities.
  bool get isEmpty => _recent.isEmpty;

  /// Loads the persisted list from prefs. Idempotent — repeated calls are
  /// no-ops once initialized.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = json.decode(raw);
      if (decoded is! List) return;
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final facility = _facilityFromJson(Map<String, dynamic>.from(entry));
        if (facility != null && _recent.length < maxItems) {
          _recent.add(facility);
        }
      }
      if (_recent.isNotEmpty) notifyListeners();
    } catch (_) {
      // Corrupt prefs payload — drop it. We don't want stale data to crash
      // home startup.
      await prefs.remove(_prefsKey);
    }
  }

  /// Records a facility view.
  ///
  /// If [facility] is already in the list, it's moved to the front;
  /// otherwise it's inserted at the front and the list is trimmed to
  /// [maxItems].
  void addFacility(Facility facility) {
    final existingIndex = _recent.indexWhere((f) => f.id == facility.id);
    if (existingIndex == 0) {
      // Already at the front — refresh the entry to pick up any mutated
      // fields (e.g. favorite toggled while viewing).
      _recent[0] = facility;
    } else {
      if (existingIndex > 0) {
        _recent.removeAt(existingIndex);
      }
      _recent.insert(0, facility);
      if (_recent.length > maxItems) {
        _recent.removeRange(maxItems, _recent.length);
      }
    }
    notifyListeners();
    unawaited(_persist());
  }

  /// Removes [facilityId] from the list (if present). No-op otherwise.
  void removeFacility(String facilityId) {
    final before = _recent.length;
    _recent.removeWhere((f) => f.id == facilityId);
    if (_recent.length == before) return;
    notifyListeners();
    unawaited(_persist());
  }

  /// Clears all recently-viewed facilities.
  void clear() {
    if (_recent.isEmpty) return;
    _recent.clear();
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _recent.map(_facilityToJson).toList();
    await prefs.setString(_prefsKey, json.encode(payload));
  }

  Map<String, dynamic> _facilityToJson(Facility f) => {
        'id': f.id,
        'name': f.name,
        'address': f.address,
        'city': f.city,
        'state': f.state,
        'appCategory': f.appCategory,
        'categoryLevel2': f.categoryLevel2,
        'latitude': f.location.latitude,
        'longitude': f.location.longitude,
      };

  /// Reconstructs the minimal Facility needed to render the row and open
  /// the feedback dialog. Fields not persisted (hours, services, …) come
  /// back as their defaults — that's fine because the home row only uses
  /// name/address/category, and the feedback dialog only uses name/id.
  Facility? _facilityFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String || name.isEmpty) return null;
    return Facility(
      id: id,
      name: name,
      description: '',
      location: LatLng(
        (json['latitude'] as num?)?.toDouble() ?? 0,
        (json['longitude'] as num?)?.toDouble() ?? 0,
      ),
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      appCategory: json['appCategory'] as String? ?? 'Health Care',
      categoryLevel2: json['categoryLevel2'] as String?,
    );
  }
}
