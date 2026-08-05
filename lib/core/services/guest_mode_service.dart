import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks guest (unauthenticated) mode, notifying listeners on auth changes.
class GuestModeService extends ChangeNotifier {
  static final GuestModeService _instance = GuestModeService._();
  factory GuestModeService() => _instance;
  GuestModeService._();

  StreamSubscription<AuthState>? _authSubscription;

  /// Whether the current user is a guest (not signed in). Defaults to `true`
  /// when Supabase is not initialized (e.g. in tests or before [init]).
  bool get isGuest {
    try {
      return Supabase.instance.client.auth.currentUser == null;
    } catch (_) {
      return true;
    }
  }

  /// Subscribes to Supabase auth state changes so [isGuest] stays current.
  /// Must be called after [Supabase.initialize].
  Future<void> init() async {
    try {
      _authSubscription?.cancel();
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((_) => notifyListeners());
    } catch (_) {
      // Supabase not yet initialized — [isGuest] safely defaults to true.
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
