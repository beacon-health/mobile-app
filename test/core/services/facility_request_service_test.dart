import 'package:beacon_app/core/services/facility_request_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FacilityRequestService.correctionRow', () {
    Map<String, dynamic> row({
      String? website,
      String? phone,
      String? hours,
      String? address,
      bool reportedClosed = false,
    }) =>
        FacilityRequestService.correctionRow(
          userId: 'user-1',
          facilityId: 'facility-9',
          facilityName: '  Mercy Clinic ',
          website: website,
          phone: phone,
          hours: hours,
          address: address,
          reportedClosed: reportedClosed,
        );

    test('is a correction tied to the user and the facility', () {
      final r = row(website: 'https://example.org');
      expect(r['user_id'], 'user-1');
      expect(r['request_type'], 'correction');
      expect(r['facility_id'], 'facility-9');
      expect(r['facility_name'], 'Mercy Clinic');
      expect(r['website'], 'https://example.org');
    });

    test('blank fields become nulls, not empty strings', () {
      final r = row(website: '   ', phone: '', hours: ' 9-5 ');
      expect(r['website'], isNull);
      expect(r['phone'], isNull);
      expect(r['hours'], '9-5');
      expect(r['street_address'], isNull);
    });

    test('a closure report sets reported_closed', () {
      expect(row(reportedClosed: true)['reported_closed'], isTrue);
    });

    test('an ordinary correction does not mention reported_closed', () {
      // The column defaults to false. Leaving it out keeps this the same
      // insert the app has always made.
      expect(row().containsKey('reported_closed'), isFalse);
    });

    test('a closure can ride along with other corrections', () {
      final r = row(reportedClosed: true, address: '1 Main St');
      expect(r['reported_closed'], isTrue);
      expect(r['street_address'], '1 Main St');
    });
  });

  group('FacilityRequestEntry.fromRow', () {
    test('reads a closure report', () {
      final entry = FacilityRequestEntry.fromRow({
        'facility_name': 'Mercy Clinic',
        'status': 'pending',
        'request_type': 'correction',
        'facility_id': 'facility-9',
        'reported_closed': true,
        'created_at': '2026-10-12T15:00:00Z',
      });

      expect(entry.reportedClosed, isTrue);
      expect(entry.isCorrection, isTrue);
      expect(entry.facilityId, 'facility-9');
      expect(entry.createdAt, isNotNull);
    });

    test('a row without the column is not a closure', () {
      final entry = FacilityRequestEntry.fromRow({
        'facility_name': 'New Pantry',
        'request_type': 'new',
      });

      expect(entry.reportedClosed, isFalse);
      expect(entry.isCorrection, isFalse);
      expect(entry.status, 'pending');
    });
  });
}
