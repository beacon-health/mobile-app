import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:flutter/foundation.dart';

/// Where a person's link to a facility stands. Only the Beacon team moves it
/// past [pending]: requests are checked by hand.
enum ManagerStatus {
  pending,
  verified,
  revoked;

  static ManagerStatus parse(String? value) => switch (value) {
        'verified' => ManagerStatus.verified,
        'revoked' => ManagerStatus.revoked,
        _ => ManagerStatus.pending,
      };
}

/// A facility the signed-in person manages, or has asked to. A facility can
/// have several managers, and a manager several facilities.
@immutable
class ManagedFacility {
  const ManagedFacility({
    required this.facility,
    required this.status,
    this.managerCount = 1,
    this.needsAttention = 0,
    this.feedbackPeople = 0,
  });

  final Facility facility;
  final ManagerStatus status;

  /// Verified managers of this facility, this person included.
  final int managerCount;

  /// Things waiting on the manager: suggested corrections, hours to confirm,
  /// requests from would-be co-managers.
  final int needsAttention;

  /// How many different people have left feedback for the facility.
  final int feedbackPeople;

  /// Only a verified manager can open a facility's overview or edit it.
  bool get canManage => status == ManagerStatus.verified;
}

/// When a manager may see feedback about their facility.
///
/// Feedback is anonymous, and with only a handful of visitors a manager could
/// work out who said what. So none of it is shown until enough different
/// people have left some. The count is safe to show; the feedback isn't.
///
/// The server enforces this — it returns no feedback rows below the
/// threshold. This is the same rule on the client, for what to draw.
abstract final class FeedbackVisibility {
  static const int minimumPeople = 20;

  static bool isVisible(int people) => people >= minimumPeople;
}

/// How much of a listing is filled in, and what is missing — the first thing
/// a manager can act on.
@immutable
class ListingCompleteness {
  const ListingCompleteness._(this.present, this.missing);

  factory ListingCompleteness.of(Facility facility) {
    final eligibility = facility.eligibilityRequirements;
    final checks = <ListingField, bool>{
      ListingField.address: facility.hasAddress,
      ListingField.phone: facility.phones.isNotEmpty,
      ListingField.website: facility.website?.trim().isNotEmpty ?? false,
      ListingField.hours: facility.hours.isNotEmpty,
      ListingField.description: facility.description.trim().isNotEmpty,
      ListingField.services: facility.services.isNotEmpty ||
          (facility.servicesSummary?.trim().isNotEmpty ?? false),
      // What visitors may need to bring: known either way counts as answered.
      ListingField.whatToBring: _whatToBring.any(eligibility.containsKey),
    };
    return ListingCompleteness._(
      [
        for (final entry in checks.entries)
          if (entry.value) entry.key
      ],
      [
        for (final entry in checks.entries)
          if (!entry.value) entry.key
      ],
    );
  }

  static const _whatToBring = [
    'proof_of_income',
    'proof_of_residency',
    'insurance_required',
    'referral_required',
  ];

  final List<ListingField> present;
  final List<ListingField> missing;

  /// From 0 to 1.
  double get fraction => present.length / ListingField.values.length;

  bool get isComplete => missing.isEmpty;
}

/// The parts of a listing a manager is asked to keep filled in.
enum ListingField {
  address,
  phone,
  website,
  hours,
  description,
  services,
  whatToBring,
}
