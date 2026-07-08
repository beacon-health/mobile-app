import 'package:supabase_flutter/supabase_flutter.dart';

/// A single feedback row the signed-in user has submitted for a facility.
///
/// Tags are stored comma-joined in the text `comment` column (no schema change
/// from §2.4), so this entry parses them back into a list for display/editing.
class FacilityFeedbackEntry {
  const FacilityFeedbackEntry({
    required this.facilityId,
    required this.isThumbsUp,
    required this.tags,
    this.submittedAt,
  });

  factory FacilityFeedbackEntry.fromRow(Map<String, dynamic> row) {
    final rating = row['rating'] as String? ?? 'up';
    final comment = row['comment'] as String? ?? '';
    final created = row['created_at'] as String?;
    return FacilityFeedbackEntry(
      facilityId: row['facility_id'] as String? ?? '',
      isThumbsUp: rating == 'up',
      tags: parseTags(comment),
      submittedAt: created == null ? null : DateTime.tryParse(created),
    );
  }

  final String facilityId;
  final bool isThumbsUp;
  final List<String> tags;
  final DateTime? submittedAt;

  /// Splits the comma-joined `comment` column back into discrete tags.
  static List<String> parseTags(String comment) => comment
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  /// Joins selected tags into the single text value stored in `comment`.
  static String tagsToComment(Iterable<String> tags) => tags.join(', ');
}

/// Reads and writes the current user's facility feedback.
///
/// One row per (user, facility): submissions [submit] via **upsert** so editing
/// replaces the existing rating instead of duplicating it — backed by the
/// `facility_feedback_user_facility_uniq` unique constraint (see
/// MVP_RELEASE.md §2.7). Routing every write through this service also gives a
/// future offline mode a single seam to wrap with an outbox (§9).
class FacilityFeedbackService {
  FacilityFeedbackService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'facility_feedback';

  /// The signed-in user's feedback for one facility, or null if none / signed
  /// out.
  Future<FacilityFeedbackEntry?> getForFacility(String facilityId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('facility_id', facilityId)
        .maybeSingle();
    if (row == null) return null;
    return FacilityFeedbackEntry.fromRow(Map<String, dynamic>.from(row));
  }

  /// All of the signed-in user's feedback, most recent first.
  Future<List<FacilityFeedbackEntry>> getMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map(
          (r) =>
              FacilityFeedbackEntry.fromRow(Map<String, dynamic>.from(r as Map)),
        )
        .toList();
  }

  /// Inserts or updates the user's feedback for a facility (one row per pair).
  Future<void> submit({
    required String facilityId,
    required bool isThumbsUp,
    required Iterable<String> tags,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot submit feedback while signed out');
    }
    await _client.from(_table).upsert(
      {
        'user_id': userId,
        'facility_id': facilityId,
        'rating': isThumbsUp ? 'up' : 'down',
        'comment': FacilityFeedbackEntry.tagsToComment(tags),
      },
      onConflict: 'user_id,facility_id',
    );
  }

  /// Removes the user's feedback for a facility. No-op when signed out.
  Future<void> delete(String facilityId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from(_table)
        .delete()
        .eq('user_id', userId)
        .eq('facility_id', facilityId);
  }
}
