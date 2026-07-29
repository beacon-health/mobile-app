import 'package:supabase_flutter/supabase_flutter.dart';

/// A user-submitted request in the `facility_requests` staging table — either
/// a **new** facility to add, or a **correction** to an existing one
/// (`requestType`).
class FacilityRequestEntry {
  const FacilityRequestEntry({
    required this.facilityName,
    required this.status,
    required this.requestType,
    this.facilityId,
    this.website,
    this.phone,
    this.hours,
    this.streetAddress,
    this.createdAt,
  });

  factory FacilityRequestEntry.fromRow(Map<String, dynamic> row) {
    final created = row['created_at'] as String?;
    return FacilityRequestEntry(
      facilityName: row['facility_name'] as String? ?? '',
      status: row['status'] as String? ?? 'pending',
      requestType: row['request_type'] as String? ?? 'new',
      facilityId: row['facility_id'] as String?,
      website: row['website'] as String?,
      phone: row['phone'] as String?,
      hours: row['hours'] as String?,
      streetAddress: row['street_address'] as String?,
      createdAt: created == null ? null : DateTime.tryParse(created),
    );
  }

  final String facilityName;

  /// Review status: `pending` | `approved` | `rejected` (set internally).
  final String status;

  /// `new` (add a facility) or `correction` (fix an existing one).
  final String requestType;

  /// Set for corrections — the id of the facility being corrected.
  final String? facilityId;
  final String? website;
  final String? phone;
  final String? hours;
  final String? streetAddress;
  final DateTime? createdAt;

  bool get isCorrection => requestType == 'correction';
}

/// Writes and reads the current user's facility requests (adds + corrections).
///
/// Backed by the `facility_requests` staging table. Owner-only RLS: users see
/// and manage only their own requests; the review workflow happens in the
/// Supabase dashboard.
class FacilityRequestService {
  FacilityRequestService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'facility_requests';

  static String? _clean(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot submit a facility request while signed out');
    }
    return userId;
  }

  /// Submits a request to add a facility that isn't in the dataset. Name and
  /// website are both required.
  Future<void> submitNew({
    required String facilityName,
    required String website,
  }) async {
    await _client.from(_table).insert({
      'user_id': _requireUserId(),
      'request_type': 'new',
      'facility_name': facilityName.trim(),
      'website': website.trim(),
    });
  }

  /// Submits a correction to an existing facility. Any subset of fields may be
  /// provided; blanks are dropped.
  Future<void> submitCorrection({
    required String facilityId,
    required String facilityName,
    String? website,
    String? phone,
    String? hours,
    String? address,
  }) async {
    await _client.from(_table).insert({
      'user_id': _requireUserId(),
      'request_type': 'correction',
      'facility_id': facilityId,
      'facility_name': facilityName.trim(),
      'website': _clean(website),
      'phone': _clean(phone),
      'hours': _clean(hours),
      'street_address': _clean(address),
    });
  }

  /// All of the signed-in user's requests, most recent first.
  Future<List<FacilityRequestEntry>> getMine() async {
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
              FacilityRequestEntry.fromRow(Map<String, dynamic>.from(r as Map)),
        )
        .toList();
  }
}
