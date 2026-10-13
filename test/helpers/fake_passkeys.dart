import 'package:beacon_app/core/services/passkey_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Passkeys for tests: ends each attempt the way it is told to.
class FakePasskeyService implements PasskeyService {
  PasskeyOutcome signInOutcome = PasskeyOutcome.success;
  PasskeyOutcome createOutcome = PasskeyOutcome.success;
  bool alreadyHasPasskey = false;

  int signIns = 0;

  /// The name passed to each `create`, oldest first.
  final List<String?> createdNames = [];

  @override
  Future<PasskeyOutcome> signIn() async {
    signIns++;
    return signInOutcome;
  }

  @override
  Future<PasskeyOutcome> create({String? name}) async {
    createdNames.add(name);
    return createOutcome;
  }

  @override
  Future<bool> hasPasskey() async => alreadyHasPasskey;
}

/// Switches passkeys on for one test, over a [FakePasskeyService].
FakePasskeyService usePasskeys() {
  final service = FakePasskeyService();
  PasskeyService.debugEnabled = true;
  PasskeyService.debugInstance = service;
  addTearDown(() {
    PasskeyService.debugEnabled = null;
    PasskeyService.debugInstance = null;
  });
  return service;
}
