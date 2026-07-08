import 'package:beacon_app/core/services/facility_feedback_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FacilityFeedbackEntry tag <-> comment', () {
    test('parseTags splits, trims, and drops empties', () {
      expect(
        FacilityFeedbackEntry.parseTags('Friendly staff, Clean facility'),
        ['Friendly staff', 'Clean facility'],
      );
      expect(
        FacilityFeedbackEntry.parseTags(' Long wait times ,, Slow service ,'),
        ['Long wait times', 'Slow service'],
      );
      expect(FacilityFeedbackEntry.parseTags(''), isEmpty);
    });

    test('tagsToComment round-trips through parseTags', () {
      const tags = ['Friendly staff', 'Affordable or free'];
      final comment = FacilityFeedbackEntry.tagsToComment(tags);
      expect(FacilityFeedbackEntry.parseTags(comment), tags);
    });
  });

  group('FacilityFeedbackEntry.fromRow', () {
    test('maps rating to isThumbsUp and parses tags + date', () {
      final entry = FacilityFeedbackEntry.fromRow({
        'facility_id': 'abc',
        'rating': 'down',
        'comment': 'Slow service, Long wait times',
        'created_at': '2026-01-15T10:30:00Z',
      });

      expect(entry.facilityId, 'abc');
      expect(entry.isThumbsUp, isFalse);
      expect(entry.tags, ['Slow service', 'Long wait times']);
      expect(entry.submittedAt, isNotNull);
    });

    test('defaults gracefully on missing fields', () {
      final entry = FacilityFeedbackEntry.fromRow({'facility_id': 'x'});
      expect(entry.isThumbsUp, isTrue); // default 'up'
      expect(entry.tags, isEmpty);
      expect(entry.submittedAt, isNull);
    });
  });
}
