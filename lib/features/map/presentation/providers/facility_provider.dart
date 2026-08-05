import 'dart:async';

import 'package:beacon_app/core/services/user_favorites_service.dart';
import 'package:beacon_app/features/map/data/facility_repository.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FacilityProvider extends ChangeNotifier {
  FacilityProvider({FacilityRepositoryBase? repository})
      : _repository = repository ?? FacilityRepository() {
    _subscribeToAuth();
  }

  final FacilityRepositoryBase _repository;

  List<Facility> _facilities = [];

  /// The signed-in user's favorited facilities, fetched by id from
  /// `user_favorites` — independent of the current map region. Stays empty for
  /// guests, who can't favorite (see [favoriteFacilities]).
  List<Facility> _favoriteFacilities = [];
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authSubscription;

  List<Facility> get facilities => _facilities;
  bool get isLoading => _isLoading;

  /// Signed-in users: favorites resolved by id from the table, region-agnostic.
  /// Guests: in-memory flags on the current region list.
  List<Facility> get favoriteFacilities {
    if (UserFavoritesService.instance.currentUserId != null) {
      return List.unmodifiable(_favoriteFacilities);
    }
    return _facilities.where((f) => f.isFavorite).toList();
  }

  void _subscribeToAuth() {
    try {
      _authSubscription =
          Supabase.instance.client.auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.initialSession) {
          unawaited(loadRemoteFavorites());
        } else if (state.event == AuthChangeEvent.signedOut) {
          clearFavorites();
        }
      });
    } catch (_) {
      // Supabase not yet initialized — fine for tests/demo paths.
    }
  }

  void setFacilities(List<Facility> facilities) {
    _facilities = facilities;
    _isLoading = false;
    notifyListeners();
    unawaited(loadRemoteFavorites());
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Optimistically flips the favorite, syncing to Supabase for signed-in
  /// users and reverting on failure. Guests stay in-memory only.
  Future<void> toggleFavorite(String facilityId) async {
    final index = _facilities.indexWhere((f) => f.id == facilityId);
    if (index == -1) return;

    final previous = _facilities[index];
    final updated = previous.copyWith(isFavorite: !previous.isFavorite);
    _facilities[index] = updated;
    _syncFavoriteFacility(updated);
    notifyListeners();

    if (UserFavoritesService.instance.currentUserId == null) return;

    final ok = updated.isFavorite
        ? await UserFavoritesService.instance.addFavorite(facilityId)
        : await UserFavoritesService.instance.removeFavorite(facilityId);

    if (!ok) {
      final stillSameSlot =
          index < _facilities.length && _facilities[index].id == facilityId;
      if (stillSameSlot) {
        _facilities[index] = previous;
        _syncFavoriteFacility(previous);
        notifyListeners();
      }
    }
  }

  /// Mirrors a favorite toggle into [_favoriteFacilities] so the Home Favorites
  /// list updates immediately, without waiting for a refetch.
  void _syncFavoriteFacility(Facility facility) {
    _favoriteFacilities.removeWhere((f) => f.id == facility.id);
    if (facility.isFavorite) {
      _favoriteFacilities.add(facility.copyWith(isFavorite: true));
    }
  }

  /// Replaces in-memory `isFavorite` flags by intersecting with
  /// [favoriteIds].
  void applyFavoriteIds(Set<String> favoriteIds) {
    var changed = false;
    for (var i = 0; i < _facilities.length; i++) {
      final f = _facilities[i];
      final shouldBeFavorite = favoriteIds.contains(f.id);
      if (f.isFavorite != shouldBeFavorite) {
        _facilities[i] = f.copyWith(isFavorite: shouldBeFavorite);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Loads the signed-in user's favorites: flags any in-region facilities and
  /// fetches the full favorited set by id (region-independent). No-op if the
  /// user is not signed in.
  Future<void> loadRemoteFavorites() async {
    if (UserFavoritesService.instance.currentUserId == null) return;
    final ids = await UserFavoritesService.instance.loadFavoriteIds();
    applyFavoriteIds(ids);
    await _loadFavoriteFacilities(ids);
  }

  /// Resolves favorite ids to full facility records via the repository so the
  /// Home Favorites list shows favorites anywhere, not just the current region.
  Future<void> _loadFavoriteFacilities(Set<String> ids) async {
    if (ids.isEmpty) {
      if (_favoriteFacilities.isNotEmpty) {
        _favoriteFacilities = [];
        notifyListeners();
      }
      return;
    }
    try {
      final fetched = await _repository.getFacilitiesByIds(ids.toList());
      _favoriteFacilities = [
        for (final f in fetched) f.copyWith(isFavorite: true),
      ];
      notifyListeners();
    } catch (_) {
      // Keep the previous favorites list on a transient fetch failure.
    }
  }

  /// Clears all favorite state. Called on sign-out.
  void clearFavorites() {
    var changed = false;
    if (_favoriteFacilities.isNotEmpty) {
      _favoriteFacilities = [];
      changed = true;
    }
    for (var i = 0; i < _facilities.length; i++) {
      if (_facilities[i].isFavorite) {
        _facilities[i] = _facilities[i].copyWith(isFavorite: false);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Facility? getFacilityById(String id) {
    for (final facility in _facilities) {
      if (facility.id == id) return facility;
    }
    return null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
