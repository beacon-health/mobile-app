import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final service = EligibilityPreferencesService();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await service.clear();
  });

  group('EligibilityState', () {
    test('starts unanswered: nothing checked, and nothing applied', () {
      // Applying it by default would hide every facility that asks for a
      // document from someone who was never asked what they have.
      const state = EligibilityState();
      expect(state.proofOfIncome, isFalse);
      expect(state.acceptsMedicaid, isFalse);
      expect(state.applyToSearch, isFalse);
    });

    test('round-trips through the JSON stored with the account', () {
      const state = EligibilityState(
        proofOfIncome: true,
        insuranceRequired: true,
        acceptsMedicaid: true,
        applyToSearch: false,
      );

      final restored = EligibilityState.fromJson(state.toJson());

      expect(restored.proofOfIncome, isTrue);
      expect(restored.proofOfResidency, isFalse);
      expect(restored.insuranceRequired, isTrue);
      expect(restored.referralRequired, isFalse);
      expect(restored.acceptsMedicaid, isTrue);
      expect(restored.applyToSearch, isFalse);
    });

    test('reads a row saved before the Medicaid gate existed', () {
      final restored = EligibilityState.fromJson({
        'proof_of_income': true,
        'proof_of_residency': false,
        'insurance_required': false,
        'referral_required': true,
        'apply_to_search': true,
      });

      expect(restored.acceptsMedicaid, isFalse);
      expect(restored.proofOfIncome, isTrue);
      expect(restored.referralRequired, isTrue);
    });

    test('a missing row is the unanswered state', () {
      final restored = EligibilityState.fromJson(null);
      expect(restored.applyToSearch, isFalse);
      expect(restored.acceptsMedicaid, isFalse);
    });

    test('a saved row without the flag still applies', () {
      // Rows saved before the flag existed came from people who had
      // answered, back when answers always applied.
      final restored = EligibilityState.fromJson({'proof_of_income': true});
      expect(restored.applyToSearch, isTrue);
    });

    test('copyWith changes only what it is given', () {
      const state = EligibilityState(referralRequired: true);
      final next = state.copyWith(acceptsMedicaid: true);
      expect(next.acceptsMedicaid, isTrue);
      expect(next.referralRequired, isTrue);
      expect(next.proofOfIncome, isFalse);
    });
  });

  group('EligibilityPreferencesService', () {
    test('persists every gate, Medicaid included, across a restart', () async {
      await service.updateEligibility(
        const EligibilityState(
          proofOfResidency: true,
          acceptsMedicaid: true,
        ),
        syncToCloud: false,
      );

      // A restart: in-memory state is rebuilt from what was stored.
      await service.init();

      expect(service.eligibility.proofOfResidency, isTrue);
      expect(service.eligibility.acceptsMedicaid, isTrue);
      expect(service.eligibility.insuranceRequired, isFalse);
    });

    test('notifies listeners, so the map can re-filter', () async {
      var notifications = 0;
      void onChange() => notifications++;
      service.addListener(onChange);
      addTearDown(() => service.removeListener(onChange));

      await service.updateEligibility(
        const EligibilityState(acceptsMedicaid: true),
        syncToCloud: false,
      );

      expect(notifications, 1);
    });

    test('the parent switch keeps the gates but stops applying them', () async {
      await service.updateEligibility(
        const EligibilityState(acceptsMedicaid: true),
        syncToCloud: false,
      );

      await service.setApplyEligibilityToSearch(false);

      expect(service.eligibility.applyToSearch, isFalse);
      expect(service.eligibility.acceptsMedicaid, isTrue);
    });

    test('clear leaves nothing behind for the next person on the device',
        () async {
      await service.updateEligibility(
        const EligibilityState(acceptsMedicaid: true, proofOfIncome: true),
        syncToCloud: false,
      );

      await service.clear();
      await service.init();

      expect(service.eligibility.acceptsMedicaid, isFalse);
      expect(service.eligibility.proofOfIncome, isFalse);
    });

    test('settings from the cloud are applied without echoing back', () async {
      await service.applyFromCloud(
        eligibility: const EligibilityState(acceptsMedicaid: true),
      );
      expect(service.eligibility.acceptsMedicaid, isTrue);
    });
  });

  group('PreferencesState', () {
    test('round-trips through JSON', () {
      const state = PreferencesState(
        acceptsWalkIns: true,
        wheelchairAccessible: true,
      );
      final restored = PreferencesState.fromJson(state.toJson());
      expect(restored.acceptsWalkIns, isTrue);
      expect(restored.wheelchairAccessible, isTrue);
      expect(restored.telehealthPreference, isFalse);
    });
  });
}
