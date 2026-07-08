import 'package:supabase_flutter/supabase_flutter.dart';

/// A user-submitted request to add a facility that isn't in the dataset.
class FacilityRequestEntry {
  const FacilityRequestEntry({
    required this.facilityName,
    required this.status,
    this.description,
    this.services,
    this.streetAddress,
    this.city,
    this.state,
    this.postalCode,
    this.phone,
    this.createdAt,
  });

  factory FacilityRequestEntry.fromRow(Map<String, dynamic> row) {
    final created = row['created_at'] as String?;
    return FacilityRequestEntry(
      facilityName: row['facility_name'] as String? ?? '',
      status: row['status'] as String? ?? 'pending',
      description: row['description'] as String?,
      services: row['services'] as String?,
      streetAddress: row['street_address'] as String?,
      city: row['city'] as String?,
      state: row['state'] as String?,
      postalCode: row['postal_code'] as String?,
      phone: row['phone'] as String?,
      createdAt: created == null ? null : DateTime.tryParse(created),
    );
  }

  final String facilityName;

  /// Review status: `pending` | `approved` | `rejected` (set internally).
  final String status;
  final String? description;
  final String? services;
  final String? streetAddress;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? phone;
  final DateTime? createdAt;
}

/// Writes and reads the current user's "add a facility" requests.
///
/// Backed by the `facility_requests` table (staging for internal review — DDL
/// in MVP_RELEASE.md §2.9). Owner-only RLS: users see and manage only their
/// own requests; the review workflow happens in the Supabase dashboard.
class FacilityRequestService {
  FacilityRequestService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'facility_requests';

  /// Submits a new facility request. Only [facilityName] is required.
  Future<void> submit({
    required String facilityName,
    String? description,
    String? services,
    String? streetAddress,
    String? city,
    String? state,
    String? postalCode,
    String? phone,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot submit a facility request while signed out');
    }
    String? clean(String? v) {
      final t = v?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    await _client.from(_table).insert({
      'user_id': userId,
      'facility_name': facilityName.trim(),
      'description': clean(description),
      'services': clean(services),
      'street_address': clean(streetAddress),
      'city': clean(city),
      'state': clean(state),
      'postal_code': clean(postalCode),
      'phone': clean(phone),
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
