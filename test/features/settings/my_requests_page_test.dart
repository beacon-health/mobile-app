import 'package:beacon_app/core/services/facility_request_service.dart';
import 'package:beacon_app/core/widgets/tag_chip.dart';
import 'package:beacon_app/features/settings/presentation/pages/my_requests_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

class _FakeRequests extends FacilityRequestService {
  _FakeRequests(this.entries);

  final List<FacilityRequestEntry> entries;

  @override
  Future<List<FacilityRequestEntry>> getMine() async => entries;
}

void main() {
  setUp(mockPlatformServices);

  Future<void> pumpRequests(
    WidgetTester tester,
    List<FacilityRequestEntry> entries,
  ) =>
      pumpThemed(
        tester,
        MyRequestsPage(requestService: _FakeRequests(entries)),
      );

  String subtitleOf(WidgetTester tester, String facilityName) {
    final tile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, facilityName),
    );
    return (tile.subtitle! as Text).data!;
  }

  testWidgets('labels each kind of request', (tester) async {
    await pumpRequests(tester, [
      FacilityRequestEntry(
        facilityName: 'New Pantry',
        status: 'pending',
        requestType: 'new',
        createdAt: DateTime(2026, 10, 1),
      ),
      FacilityRequestEntry(
        facilityName: 'Mercy Clinic',
        status: 'approved',
        requestType: 'correction',
        createdAt: DateTime(2026, 10, 2),
      ),
      FacilityRequestEntry(
        facilityName: 'Old Shelter',
        status: 'pending',
        requestType: 'correction',
        reportedClosed: true,
        createdAt: DateTime(2026, 10, 3),
      ),
    ]);

    expect(subtitleOf(tester, 'New Pantry'), startsWith('New facility'));
    expect(subtitleOf(tester, 'Mercy Clinic'), startsWith('Correction'));
    // A closure is stored as a correction, but reads as what it is.
    expect(subtitleOf(tester, 'Old Shelter'), startsWith('Reported closed'));
  });

  testWidgets('shows the review status of each', (tester) async {
    await pumpRequests(tester, const [
      FacilityRequestEntry(
        facilityName: 'A',
        status: 'approved',
        requestType: 'new',
      ),
      FacilityRequestEntry(
        facilityName: 'B',
        status: 'rejected',
        requestType: 'new',
      ),
    ]);

    expect(find.widgetWithText(TagChip, 'approved'), findsOneWidget);
    expect(find.widgetWithText(TagChip, 'rejected'), findsOneWidget);
  });

  testWidgets('with no requests, invites one', (tester) async {
    await pumpRequests(tester, const []);

    expect(find.text('No requests yet'), findsOneWidget);
    expect(find.text('Request a facility'), findsOneWidget);
  });
}
