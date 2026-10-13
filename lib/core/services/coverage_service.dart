import 'dart:async';

import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/utils/zip_state.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Whether Beacon serves the area a ZIP code is in.
enum ZipCoverage {
  /// In a state that has launched.
  covered,

  /// A real-looking ZIP in a state that hasn't launched yet.
  outsideCoverage,

  /// Not five digits, or a prefix no state uses.
  invalid,
}

/// Which states are live, read from the `launched_states` table — the same
/// allow-list the `facilities_near` RPC enforces. Driving the app from it means
/// a new state needs one SQL insert and no release: the ZIP gate and the
/// coverage notice follow along.
class CoverageService extends ChangeNotifier {
  factory CoverageService() => _instance;

  CoverageService._();

  static final CoverageService _instance = CoverageService._();

  /// Row value that switches the allow-list off (every state is live).
  static const String nationwideCode = 'ALL';

  static const String _table = 'launched_states';
  static const String _prefsKey = 'launched_states_v1';
  static const String _logContext = 'CoverageService';

  /// How long a fetched list is trusted before a ZIP check re-reads it.
  static const Duration _maxAge = Duration(hours: 1);
  static const Duration _fetchTimeout = Duration(seconds: 6);

  /// Used only until the first fetch succeeds on a fresh install.
  static const List<String> _bundledStates = ['IL'];

  List<String> _states = _bundledStates;
  DateTime? _fetchedAt;
  Future<bool>? _inFlight;

  /// Replaces the Supabase read in tests.
  @visibleForTesting
  Future<List<String>> Function()? debugFetch;

  /// Live state codes in launch order. Empty when [isNationwide].
  List<String> get launchedStates =>
      List.unmodifiable(_states.where((s) => s != nationwideCode));

  /// True when the allow-list is switched off and every state is served.
  bool get isNationwide => _states.contains(nationwideCode);

  /// Loads the last list seen on this device, then refreshes in the
  /// background so startup never waits on the network.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList(_prefsKey);
    if (cached != null && cached.isNotEmpty) {
      _states = cached;
      notifyListeners();
    }
    unawaited(refresh());
  }

  /// Re-reads the allow-list. Returns false (keeping the current list) when
  /// the read fails, so being offline never empties coverage.
  Future<bool> refresh() {
    return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
  }

  Future<bool> _refresh() async {
    try {
      final fetched =
          await (debugFetch ?? _fetchFromSupabase)().timeout(_fetchTimeout);
      // An empty table would lock every ZIP out; treat it as a failed read.
      if (fetched.isEmpty) return false;

      _fetchedAt = DateTime.now();
      if (!listEquals(fetched, _states)) {
        _states = fetched;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_prefsKey, fetched);
        notifyListeners();
      }
      return true;
    } on PostgrestException catch (e, stackTrace) {
      // The server answered and refused — a missing table or grant, which is
      // ours to fix.
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: '$_logContext.refresh',
      );
      return false;
    } catch (_) {
      // Anything else is the network: offline, slow, or timed out. Not a bug,
      // and the cached list stands.
      return false;
    }
  }

  static Future<List<String>> _fetchFromSupabase() async {
    final rows = await Supabase.instance.client
        .from(_table)
        .select('state_code')
        .order('launched_at');
    return [
      for (final row in rows as List)
        if ((row as Map)['state_code'] case final String code
            when code.trim().isNotEmpty)
          code.trim().toUpperCase(),
    ];
  }

  /// Refreshes unless the list was read recently. Call before a decision that
  /// turns a user away, so a state launched minutes ago is honored.
  Future<void> ensureFresh() async {
    final fetchedAt = _fetchedAt;
    if (fetchedAt != null && DateTime.now().difference(fetchedAt) < _maxAge) {
      return;
    }
    await refresh();
  }

  bool isStateCovered(String stateCode) =>
      isNationwide || _states.contains(stateCode.toUpperCase());

  ZipCoverage checkZip(String zip) {
    final state = ZipState.stateFor(zip);
    if (state == null) return ZipCoverage.invalid;
    return isStateCovered(state)
        ? ZipCoverage.covered
        : ZipCoverage.outsideCoverage;
  }

  /// Sets the list directly, bypassing storage and the network.
  @visibleForTesting
  void debugSetStates(List<String> states) {
    _states = List.of(states);
    _fetchedAt = DateTime.now();
    notifyListeners();
  }

  /// Restores the fresh-install state between tests.
  @visibleForTesting
  void debugReset() {
    _states = _bundledStates;
    _fetchedAt = null;
    _inFlight = null;
    debugFetch = null;
  }
}
