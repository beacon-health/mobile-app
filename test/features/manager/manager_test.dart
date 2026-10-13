import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/features/manager/data/manager_repository.dart';
import 'package:beacon_app/features/manager/domain/managed_facility.dart';
import 'package:beacon_app/features/manager/presentation/pages/managed_facilities_page.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_shell.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_facility.dart';

/// A manager backend for tests: answers with the facilities it is given.
class FakeManagerRepository implements ManagerRepository {
  FakeManagerRepository([this.facilities = const []]);

  final List<ManagedFacility> facilities;
  final List<String> requests = [];

  @override
  Future<List<ManagedFacility>> myFacilities() async => facilities;

  @override
  Future<void> requestAccess(String facilityId) async =>
      requests.add(facilityId);
}

void main() {
  final carpls = createTestFacility(id: 'carpls', name: 'CARPLS');
  final clinic = createTestFacility(id: 'clinic', name: 'Loop Clinic');

  group('FeedbackVisibility', () {
    test('hides feedback at 19 people and shows it at 20', () {
      // Fewer voices than that and a manager could tell who said what.
      expect(FeedbackVisibility.isVisible(0), isFalse);
      expect(FeedbackVisibility.isVisible(19), isFalse);
      expect(FeedbackVisibility.isVisible(20), isTrue);
      expect(FeedbackVisibility.isVisible(21), isTrue);
    });
  });

  group('ManagerStatus', () {
    test('anything unrecognized is pending, never verified', () {
      expect(ManagerStatus.parse('verified'), ManagerStatus.verified);
      expect(ManagerStatus.parse('revoked'), ManagerStatus.revoked);
      expect(ManagerStatus.parse('pending'), ManagerStatus.pending);
      expect(ManagerStatus.parse(null), ManagerStatus.pending);
      expect(ManagerStatus.parse('VERIFIED'), ManagerStatus.pending);
    });

    test('only a verified manager can manage', () {
      for (final status in ManagerStatus.values) {
        expect(
          ManagedFacility(facility: carpls, status: status).canManage,
          status == ManagerStatus.verified,
          reason: status.name,
        );
      }
    });
  });

  group('ListingCompleteness', () {
    test('a bare listing names everything that is missing', () {
      final bare = createTestFacility(
        address: Facility.addressUnavailable,
        description: '',
        services: const [],
      );

      final completeness = ListingCompleteness.of(bare);

      expect(completeness.present, isEmpty);
      expect(completeness.missing, ListingField.values);
      expect(completeness.fraction, 0);
    });

    test('a full listing is complete', () {
      final full = createTestFacility(
        website: 'https://example.org',
        phones: const [PhoneContact(number: '3125550100')],
        hours: const [OperatingHours(day: 'mon', opensAt: '9:00')],
        eligibilityRequirements: const {'proof_of_income': false},
      );

      final completeness = ListingCompleteness.of(full);

      expect(completeness.isComplete, isTrue);
      expect(completeness.fraction, 1);
    });

    test('knowing a requirement either way counts as answered', () {
      for (final value in [true, false]) {
        final facility = createTestFacility(
          eligibilityRequirements: {'referral_required': value},
        );
        expect(
          ListingCompleteness.of(facility).present,
          contains(ListingField.whatToBring),
        );
      }
    });
  });

  group('without a backend', () {
    test('nobody has a facility, and requests are refused', () async {
      const backend = NoManagerBackend();

      expect(await backend.myFacilities(), isEmpty);
      expect(backend.requestAccess('carpls'), throwsUnsupportedError);
    });
  });

  group('Profile', () {
    Future<void> pumpProfile(
      WidgetTester tester,
      ManagerRepository managers,
    ) async {
      await resetAppState(tester);
      GuestModeService().debugUser = testUser();
      await pumpThemed(tester, const ProfilePage(), managers: managers);
    }

    testWidgets('hides "Manage facilities" from someone with none',
        (tester) async {
      await pumpProfile(tester, FakeManagerRepository());

      expect(find.text('Manage facilities'), findsNothing);
    });

    testWidgets('shows it to someone with a facility, even a pending one',
        (tester) async {
      await pumpProfile(
        tester,
        FakeManagerRepository([
          ManagedFacility(facility: carpls, status: ManagerStatus.pending),
        ]),
      );

      await tester.tap(find.text('Manage facilities'));
      await tester.pumpAndSettle();

      expect(find.byType(ManagedFacilitiesPage), findsOneWidget);
      expect(find.text('CARPLS'), findsOneWidget);
    });
  });

  group('Your facilities', () {
    Future<void> pumpPage(
      WidgetTester tester,
      List<ManagedFacility> facilities, {
      Locale locale = const Locale('en'),
    }) async {
      mockPlatformServices();
      await pumpThemed(
        tester,
        const ManagedFacilitiesPage(),
        managers: FakeManagerRepository(facilities),
        locale: locale,
      );
    }

    testWidgets('a verified facility says how many manage it', (tester) async {
      await pumpPage(tester, [
        ManagedFacility(
          facility: carpls,
          status: ManagerStatus.verified,
          managerCount: 3,
          needsAttention: 2,
        ),
      ]);

      expect(find.text('Verified · 3 managers'), findsOneWidget);
      expect(find.text('2 things need attention'), findsOneWidget);
    });

    testWidgets('below the threshold it shows the count, not the feedback',
        (tester) async {
      await pumpPage(tester, [
        ManagedFacility(
          facility: carpls,
          status: ManagerStatus.verified,
          feedbackPeople: 12,
        ),
        ManagedFacility(
          facility: clinic,
          status: ManagerStatus.verified,
          feedbackPeople: 20,
        ),
      ]);

      expect(
        find.text('Feedback hidden: 12 of 20 people so far'),
        findsOneWidget,
      );
      expect(find.text('Feedback is ready to read'), findsOneWidget);
    });

    testWidgets('a pending request says how it is checked and how long',
        (tester) async {
      await pumpPage(tester, [
        ManagedFacility(facility: carpls, status: ManagerStatus.pending),
      ]);

      expect(find.text('Waiting for verification'), findsOneWidget);
      expect(find.textContaining('by phone'), findsOneWidget);
      expect(find.textContaining('2–3 business days'), findsOneWidget);
      // Nothing about feedback or attention until it is verified.
      expect(find.textContaining('Feedback'), findsNothing);
    });

    testWidgets('with no facilities, offers to request one', (tester) async {
      await pumpPage(tester, const []);

      expect(find.text('No facilities yet'), findsOneWidget);
      expect(find.text('Request access to a facility'), findsOneWidget);
    });

    testWidgets('is translated', (tester) async {
      await pumpPage(
        tester,
        [ManagedFacility(facility: carpls, status: ManagerStatus.pending)],
        locale: const Locale('es'),
      );

      expect(find.text('Tus centros'), findsOneWidget);
      expect(find.text('En espera de verificación'), findsOneWidget);
    });
  });
}
