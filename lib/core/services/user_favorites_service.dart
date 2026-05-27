import 'package:beacon_app/core/services/demo_mode_service.dart';
import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the Supabase `user_favorites` table.
///
/// Guest users never reach this service — [FacilityProvider] short-circuits
/// to local-only state when no user is signed in.
class UserFavoritesService {
  UserFavoritesService._();
  static final UserFavoritesService instance = UserFavoritesService._();

  static const String _table = 'user_favorites';
  static const String _logContext = 'UserFavoritesService';

  /// Returns the set of facility IDs the signed-in user has favorited.
  ///
  /// Empty set if the user is not signed in or the query fails.
  Future<Set<String>> loadFavoriteIds() async {
    final userId = _currentUserId();
    if (userId == null) return <String>{};
    try {
      final rows = await Supabase.instance.client
          .from(_table)
          .select('facility_id')
          .eq('user_id', userId);
      return {
        for (final row in rows as List)
          if (row is Map && row['facility_id'] is String)
            row['facility_id'] as String,
      };
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: '$_logContext.loadFavoriteIds',
      );
      return <String>{};
    }
  }

  /// Adds [facilityId] to favorites. Returns `true` on success.
  Future<bool> addFavorite(String facilityId) async {
    final userId = _currentUserId();
    if (userId == null) return false;
    try {
      await Supabase.instance.client.from(_table).insert({
        'user_id': userId,
        'facility_id': facilityId,
      });
      return true;
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: '$_logContext.addFavorite',
      );
      return false;
    }
  }

  /// Removes [facilityId] from favorites. Returns `true` on success.
  Future<bool> removeFavorite(String facilityId) async {
    final userId = _currentUserId();
    if (userId == null) return false;
    try {
      await Supabase.instance.client
          .from(_table)
          .delete()
          .match({'user_id': userId, 'facility_id': facilityId});
      return true;
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: '$_logContext.removeFavorite',
      );
      return false;
    }
  }

  /// The signed-in user's ID, or null in demo / unauthenticated / pre-init states.
  String? get currentUserId => _currentUserId();

  String? _currentUserId() {
    if (DemoModeService().isDemoMode) return null;
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }
}
