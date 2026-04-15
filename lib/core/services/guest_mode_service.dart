import 'dart:async';

import 'package:beacon_app/core/services/demo_mode_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks whether the current user is in guest (unauthenticated) mode.
///
/// Listens to Supabase auth state changes and calls [notifyListeners] so
/// Provider-watching widgets rebuild reactively when the user signs in or out.
/// Provided at the app root via [ChangeNotifierProvider].
class GuestModeService extends ChangeNotifier {
  static const String _debugName = 'GuestModeService';

  static final GuestModeService _instance = GuestModeService._();
  factory GuestModeService() => _instance;
  GuestModeService._();

  StreamSubscription<AuthState>? _authSubscription;

  /// Whether the current user is a guest (not signed in).
  ///
  /// Always `true` in demo mode. Defaults to `true` when Supabase is not
  /// initialized (e.g. in tests or before [init] is called).
  bool get isGuest {
    if (DemoModeService().isDemoMode) return true;
    try {
      return Supabase.instance.client.auth.currentUser == null;
    } catch (_) {
      // Supabase not initialized — treat as guest.
      return true;
    }
  }

  /// Subscribes to Supabase auth state changes so [isGuest] stays current.
  ///
  /// Must be called after [Supabase.initialize]. Safe to call in demo mode —
  /// returns immediately without subscribing.
  Future<void> init() async {
    if (DemoModeService().isDemoMode) return;
    try {
      _authSubscription?.cancel();
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((_) => notifyListeners());
    } catch (_) {
      // Supabase not yet initialized — [isGuest] defaults to true.
      debugPrint('$_debugName: Supabase not available during init, skipping auth listener.');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
