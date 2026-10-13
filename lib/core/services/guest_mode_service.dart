import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks guest (unauthenticated) mode, notifying listeners on auth changes.
class GuestModeService extends ChangeNotifier {
  static final GuestModeService _instance = GuestModeService._();
  factory GuestModeService() => _instance;
  GuestModeService._();

  StreamSubscription<AuthState>? _authSubscription;

  /// Lets a widget test stand in for a signed-in user without a Supabase
  /// session. Null (the default) means "ask Supabase".
  @visibleForTesting
  User? debugUser;

  /// The signed-in user, or null for a guest — and before Supabase is
  /// initialized (in tests, or ahead of [init]). Screens ask here rather than
  /// asking Supabase directly, which is what lets them be built in a test.
  User? get currentUser {
    final override = debugUser;
    if (override != null) return override;
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Whether the current user is a guest (not signed in).
  bool get isGuest => currentUser == null;

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
