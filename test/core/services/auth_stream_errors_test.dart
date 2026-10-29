import 'package:beacon_app/core/services/auth_stream_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('an offline background refresh is not a bug', () {
    // gotrue retries it when the network is back; it reached Sentry as an
    // uncaught error because no listener handled the stream's errors.
    expect(
      isOfflineRefresh(
          AuthRetryableFetchException(message: 'Failed host lookup')),
      isTrue,
    );
  });

  test('any other auth error still is', () {
    expect(isOfflineRefresh(const AuthException('Invalid Refresh Token')),
        isFalse);
    expect(isOfflineRefresh(StateError('unexpected')), isFalse);
  });
}
