import 'dart:async';

import 'package:beacon_app/core/services/demo_mode_service.dart';
import 'package:beacon_app/core/services/user_favorites_service.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FacilityProvider extends ChangeNotifier {
  FacilityProvider() {
    _subscribeToAuth();
  }

  List<Facility> _facilities = [];
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authSubscription;

  List<Facility> get facilities => _facilities;
  bool get isLoading => _isLoading;

  List<Facility> get favoriteFacilities =>
      _facilities.where((f) => f.isFavorite).toList();

  void _subscribeToAuth() {
    if (DemoModeService().isDemoMode) return;
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((state) {
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

  /// Optimistically flips the in-memory favorite state, then syncs to Supabase
  /// for signed-in users. If the remote call fails, reverts the flip.
  ///
  /// Guest users keep purely in-memory favorites; the Supabase calls no-op
  /// when no user is signed in.
  Future<void> toggleFavorite(String facilityId) async {
    final index = _facilities.indexWhere((f) => f.id == facilityId);
    if (index == -1) return;

    final previous = _facilities[index];
    final updated = previous.copyWith(isFavorite: !previous.isFavorite);
    _facilities[index] = updated;
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
        notifyListeners();
      }
    }
  }

  /// Replaces in-memory `isFavorite` flags by intersecting with [favoriteIds].
  ///
  /// Called after loading remote favorites on sign-in or after a facility
  /// list refresh.
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

  /// Loads the signed-in user's favorites and merges them into the facility
  /// list. No-op if the user is not signed in.
  Future<void> loadRemoteFavorites() async {
    if (UserFavoritesService.instance.currentUserId == null) return;
    final ids = await UserFavoritesService.instance.loadFavoriteIds();
    applyFavoriteIds(ids);
  }

  /// Clears all in-memory favorite flags. Called on sign-out.
  void clearFavorites() {
    var changed = false;
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
