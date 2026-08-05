import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/domain/models/eligibility_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Represents a phone contact with its type (e.g., "Business Line", "Contact").
class PhoneContact {
  final String number;
  final String? type;
  final bool isMain;

  const PhoneContact({
    required this.number,
    this.type,
    this.isMain = false,
  });

  factory PhoneContact.fromJson(Map<String, dynamic> json) {
    return PhoneContact(
      number: json['number'] as String? ?? '',
      type: json['type'] as String?,
      isMain: json['isMain'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'type': type,
        'isMain': isMain,
      };

  @override
  String toString() => type != null ? '$type: $number' : number;
}

/// Represents structured operating hours for a specific day.
class OperatingHours {
  final String day;
  final String? opensAt;
  final String? closesAt;

  const OperatingHours({
    required this.day,
    this.opensAt,
    this.closesAt,
  });

  factory OperatingHours.fromJson(Map<String, dynamic> json) {
    return OperatingHours(
      day: json['day'] as String? ?? '',
      opensAt: json['opens_at'] as String? ?? json['opensAt'] as String?,
      closesAt: json['closes_at'] as String? ?? json['closesAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'opens_at': opensAt,
        'closes_at': closesAt,
      };

  /// Formats hours for display (e.g., "Mon: 9:00am - 5:00pm").
  String toDisplayString() {
    final dayName = _formatDay(day);
    if (opensAt == null || closesAt == null) return dayName;
    return '$dayName: ${_formatTime(opensAt!)} - ${_formatTime(closesAt!)}';
  }

  static String _formatDay(String day) {
    const dayMap = {
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
    };
    return dayMap[day.toLowerCase()] ?? day;
  }

  static String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute$period';
  }
}

/// Healthcare facility model for the Beacon app.
class Facility {
  final String id;
  final String name;
  final String description;
  final LatLng location;
  final String address;
  final String city;
  final String state;
  final String? postalCode;
  final String? website;
  final String? email;

  /// All phone contacts with their types.
  final List<PhoneContact> phones;

  /// Structured operating hours.
  final List<OperatingHours> hours;

  /// List of service names offered by this facility.
  final List<String> services;

  /// `category_broad` (13 known values + null) — the dimension the map's
  /// Category filter operates on. Consolidated into a high-level group by
  /// [primaryCategory] for icons/colors.
  final String? categoryBroad;

  /// `category_detail` (21 known values + null) — the finer grain beneath
  /// [categoryBroad]. Not a filter dimension, but it is searchable.
  final String? categoryDetail;

  /// Structured eligibility data from DM_Supabase_Eligibility.
  final FacilityEligibility? eligibility;

  /// Eligibility requirement flags derived from [eligibility].
  ///
  /// Y → true, N → false, U → omitted. Used by the filter system.
  final Map<String, bool> eligibilityRequirements;

  /// Plain-language summary of services from eligibility scrape.
  final String? servicesSummary;

  /// Plain-language summary of other eligibility details.
  final String? otherEligibilitySummary;

  final bool isFavorite;
  final bool isVisited;

  /// Primary phone number for quick display.
  String get primaryPhone =>
      phones.isNotEmpty ? phones.first.number : 'Phone not available';

  /// Formatted hours string for display.
  String get hoursDisplay {
    if (hours.isEmpty) return 'Contact facility for hours';
    return hours.map((h) => h.toDisplayString()).join('\n');
  }

  /// Checks if the facility is currently open based on operating hours.
  bool get isOpenNow {
    if (hours.isEmpty) return false;

    final now = DateTime.now();
    final currentDay = _getDayAbbreviation(now.weekday);
    final currentMinutes = now.hour * 60 + now.minute;

    for (final h in hours) {
      if (h.day.toLowerCase() == currentDay.toLowerCase()) {
        final openMinutes = _parseTimeToMinutes(h.opensAt);
        final closeMinutes = _parseTimeToMinutes(h.closesAt);
        if (openMinutes != null && closeMinutes != null) {
          if (currentMinutes >= openMinutes && currentMinutes <= closeMinutes) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static String _getDayAbbreviation(int weekday) {
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return days[weekday - 1];
  }

  static int? _parseTimeToMinutes(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  /// Consolidated high-level group used for marker icons/colors and the small
  /// category icon on cards/lists. Derived from [categoryBroad] so the four
  /// Home-page groups stay consistent across the app.
  String get primaryCategory => FacilityCategories.groupFor(categoryBroad);

  const Facility({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.address,
    required this.city,
    required this.state,
    this.postalCode,
    this.website,
    this.email,
    this.phones = const [],
    this.hours = const [],
    this.services = const [],
    this.categoryBroad,
    this.categoryDetail,
    this.eligibility,
    this.eligibilityRequirements = const {},
    this.servicesSummary,
    this.otherEligibilitySummary,
    this.isFavorite = false,
    this.isVisited = false,
  });

  /// Creates a Facility from a `fct_supabase_full` row (or the equivalent
  /// `facilities_near` RPC row), which joins `FCT_Supabase` with
  /// `DM_Supabase_Eligibility` and adds a computed `app_category` column.
  factory Facility.fromSupabase(Map<String, dynamic> data) {
    final latitude = _parseDouble(data['latitude']);
    final longitude = _parseDouble(data['longitude']);
    final location = LatLng(latitude, longitude);

    final phones = _extractPhones(data);

    var hours = _parseHours(data['hours']);

    final services = _extractServiceNames(data['services']);

    final street = data['street_address'] as String? ?? '';
    final city = data['city'] as String? ?? '';
    final state = data['state'] as String? ?? '';
    final postalCode = data['postal_code'] as String?;
    final address = _formatAddress(street, city, state, postalCode);

    FacilityEligibility? eligibility;
    if (data['operational'] != null || data['proof_of_income'] != null) {
      eligibility = FacilityEligibility.fromSupabase(data);
    }

    // Derive filter map from eligibility (Y→true, N→false, U→omit)
    final eligReqs = eligibility?.toFilterMap() ?? <String, bool>{};

    // Fall back to the eligibility table's free-text hours when the
    // structured JSONB hours are absent.
    if (hours.isEmpty && eligibility?.operatingHours != null) {
      hours = _parseOperatingHoursString(
        eligibility!.operatingHours!,
      );
    }

    return Facility(
      id: data['id'] as String? ?? '',
      name: data['facility_name'] as String? ?? 'Healthcare Facility',
      description: data['facility_description'] as String? ?? '',
      location: location,
      address: address,
      city: city,
      state: state,
      postalCode: postalCode,
      website: data['website_url'] as String?,
      email: data['contact_email'] as String?,
      phones: phones,
      hours: hours,
      services: services,
      categoryBroad: data['category_broad'] as String?,
      categoryDetail: data['category_detail'] as String?,
      eligibility: eligibility,
      eligibilityRequirements: eligReqs,
      servicesSummary: eligibility?.servicesSummary,
      otherEligibilitySummary: eligibility?.otherEligibilitySummary,
    );
  }

  static List<PhoneContact> _extractPhones(Map<String, dynamic> data) {
    final phones = <PhoneContact>[];
    final seenNumbers = <String>{};

    final contactPhones = data['contact_phones'];
    if (contactPhones is List) {
      for (final phone in contactPhones) {
        final number = phone?.toString();
        if (number != null &&
            number.isNotEmpty &&
            !seenNumbers.contains(number)) {
          seenNumbers.add(number);
          phones.add(PhoneContact(number: number));
        }
      }
    }

    // services JSONB can carry additional, more specific numbers.
    final services = data['services'];
    if (services is List) {
      for (final service in services) {
        if (service is Map) {
          final servicePhones = service['phones'];
          if (servicePhones is List) {
            for (final phone in servicePhones) {
              if (phone is Map) {
                final number = phone['number']?.toString();
                if (number != null &&
                    number.isNotEmpty &&
                    !seenNumbers.contains(number)) {
                  seenNumbers.add(number);
                  phones.add(
                    PhoneContact.fromJson(Map<String, dynamic>.from(phone)),
                  );
                }
              }
            }
          }
        }
      }
    }

    return phones;
  }

  static List<OperatingHours> _parseHours(dynamic hoursData) {
    if (hoursData == null) return [];
    if (hoursData is! List) return [];

    return hoursData
        .whereType<Map>()
        .map((h) => OperatingHours.fromJson(Map<String, dynamic>.from(h)))
        .toList();
  }

  static List<String> _extractServiceNames(dynamic servicesData) {
    if (servicesData == null) return [];
    if (servicesData is! List) return [];

    return servicesData
        .whereType<Map>()
        .map((s) => s['name']?.toString())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList();
  }

  /// Parses num (double precision columns) or String (legacy text columns).
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Parses "M: 9:00AM-5:00PM, T: Closed, …" (days M/T/W/Th/F/Sa/Su) into
  /// structured [OperatingHours].
  static List<OperatingHours> _parseOperatingHoursString(String raw) {
    if (raw.isEmpty || raw.toUpperCase() == 'N') return [];

    const dayMap = {
      'M': 'mon',
      'T': 'tue',
      'W': 'wed',
      'Th': 'thu',
      'F': 'fri',
      'Sa': 'sat',
      'Su': 'sun',
    };

    final result = <OperatingHours>[];
    final entries = raw.split(',').map((e) => e.trim());

    for (final entry in entries) {
      final colonIdx = entry.indexOf(':');
      if (colonIdx < 0) continue;

      final dayPart = entry.substring(0, colonIdx).trim();
      final timePart = entry.substring(colonIdx + 1).trim();
      final dayKey = dayMap[dayPart];
      if (dayKey == null) continue;

      if (timePart.toLowerCase() == 'closed') {
        result.add(OperatingHours(day: dayKey));
        continue;
      }

      final times = timePart.split('-').map((t) => t.trim()).toList();
      if (times.length == 2) {
        result.add(
          OperatingHours(
            day: dayKey,
            opensAt: _convertTo24h(times[0]),
            closesAt: _convertTo24h(times[1]),
          ),
        );
      }
    }
    return result;
  }

  /// Converts "9:00AM" / "5:00PM" to 24-hour "09:00" / "17:00".
  static String _convertTo24h(String time) {
    final upper = time.toUpperCase().replaceAll(' ', '');
    final isPm = upper.contains('PM');
    final isAm = upper.contains('AM');
    final cleaned = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
    final parts = cleaned.split(':');
    if (parts.length < 2) return time;

    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];

    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;

    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  static String _formatAddress(
    String street,
    String city,
    String state,
    String? postalCode,
  ) {
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (city.isNotEmpty || state.isNotEmpty) {
      final cityState = [city, state].where((s) => s.isNotEmpty).join(', ');
      if (postalCode != null && postalCode.isNotEmpty) {
        parts.add('$cityState $postalCode');
      } else {
        parts.add(cityState);
      }
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Address not available';
  }

  Facility copyWith({
    bool? isFavorite,
    bool? isVisited,
  }) {
    return Facility(
      id: id,
      name: name,
      description: description,
      location: location,
      address: address,
      city: city,
      state: state,
      postalCode: postalCode,
      website: website,
      email: email,
      phones: phones,
      hours: hours,
      services: services,
      categoryBroad: categoryBroad,
      categoryDetail: categoryDetail,
      eligibility: eligibility,
      eligibilityRequirements: eligibilityRequirements,
      servicesSummary: servicesSummary,
      otherEligibilitySummary: otherEligibilitySummary,
      isFavorite: isFavorite ?? this.isFavorite,
      isVisited: isVisited ?? this.isVisited,
    );
  }
}
