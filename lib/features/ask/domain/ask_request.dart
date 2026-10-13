import 'dart:convert';

import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:flutter/foundation.dart';

/// What the person is asking for, as the model read it.
enum AskIntent {
  /// Looking for a place: the only intent Ask answers.
  search,

  /// Asking what is wrong with them or what to take. Never answered.
  medicalAdvice,

  /// Anything else: small talk, general knowledge.
  offTopic,
}

/// The filters a request turns into — the same ones the Map tab has, so a
/// request Ask can't satisfy can be handed to the Map unchanged.
@immutable
class AskFilters {
  const AskFilters({
    this.groups = const {},
    this.openNow = false,
    this.preferences = const {},
    this.keyword = '',
  });

  /// [FacilityCategories] group names ("Health Care", …).
  final Set<String> groups;
  final bool openNow;

  /// Attributes the place must have ("free", "takes walk-ins").
  final Set<PreferenceRequirement> preferences;

  /// A word to match in names, descriptions and services ("dental").
  final String keyword;

  bool get isEmpty =>
      groups.isEmpty && !openNow && preferences.isEmpty && keyword.isEmpty;

  /// The `category_broad` values [groups] stand for, as the Map filters by.
  Set<String> get categories => {
        for (final group in groups) ...FacilityCategories.valuesForGroup(group),
      };

  AskFilters copyWith({bool? openNow, String? keyword}) => AskFilters(
        groups: groups,
        openNow: openNow ?? this.openNow,
        preferences: preferences,
        keyword: keyword ?? this.keyword,
      );

  @override
  bool operator ==(Object other) =>
      other is AskFilters &&
      other.openNow == openNow &&
      other.keyword == keyword &&
      other.groups.length == groups.length &&
      other.groups.containsAll(groups) &&
      other.preferences.length == preferences.length &&
      other.preferences.containsAll(preferences);

  @override
  int get hashCode => Object.hash(
        openNow,
        keyword,
        Object.hashAllUnordered(groups),
        Object.hashAllUnordered(preferences),
      );

  @override
  String toString() => 'AskFilters(groups: $groups, openNow: $openNow, '
      'preferences: $preferences, keyword: "$keyword")';
}

/// A request as the model understood it: what kind it is, and its filters.
class AskRequest {
  const AskRequest({required this.intent, this.filters = const AskFilters()});

  final AskIntent intent;
  final AskFilters filters;

  /// The names the model is told to use, mapped to what the app filters by.
  /// Short and lowercase: a small model copies these far more reliably than
  /// display names with spaces and ampersands.
  static const Map<String, String> categoryIds = {
    'health_care': FacilityCategories.groupHealthCare,
    'mental_health': FacilityCategories.groupMentalHealth,
    'housing': FacilityCategories.groupHousingShelter,
    'basic_needs': FacilityCategories.groupBasicNeeds,
    'community': FacilityCategories.groupCommunity,
    'specialized': FacilityCategories.groupSpecialized,
  };

  static const Map<String, PreferenceRequirement> needIds = {
    'free': PreferenceRequirement.freeServicesAvailable,
    'sliding_scale': PreferenceRequirement.slidingScaleAvailable,
    'walk_in': PreferenceRequirement.acceptsWalkins,
    'telehealth': PreferenceRequirement.telehealthAvailable,
    'wheelchair': PreferenceRequirement.wheelchairAccessible,
    'other_languages': PreferenceRequirement.otherLanguages,
    'immigrants': PreferenceRequirement.openToImmigrants,
  };

  static const Map<String, AskIntent> intentIds = {
    'search': AskIntent.search,
    'medical_advice': AskIntent.medicalAdvice,
    'off_topic': AskIntent.offTopic,
  };

  /// Longest keyword kept. A model that returns a sentence here has
  /// misunderstood the field, and a sentence matches nothing.
  static const int maxKeywordLength = 40;

  /// Reads the model's reply. Strict about what it keeps and forgiving about
  /// how it arrives: the JSON may be wrapped in a code fence or in prose, and
  /// any value that isn't one of the known ids is dropped.
  ///
  /// Never throws. A reply with nothing usable in it comes back as a search
  /// with empty filters, which the caller treats as "hand off to the Map".
  factory AskRequest.parse(String reply) {
    const empty = AskRequest(intent: AskIntent.search);

    final start = reply.indexOf('{');
    final end = reply.lastIndexOf('}');
    if (start == -1 || end <= start) return empty;

    final Object? decoded;
    try {
      decoded = jsonDecode(reply.substring(start, end + 1));
    } on FormatException {
      return empty;
    }
    if (decoded is! Map<String, dynamic>) return empty;

    Iterable<String> strings(Object? value) => value is List
        ? value.whereType<String>().map((s) => s.trim().toLowerCase())
        : const [];

    final intent = intentIds[decoded['intent']] ?? AskIntent.search;
    final keyword = decoded['keyword'];
    final cleanKeyword = keyword is String ? keyword.trim().toLowerCase() : '';

    return AskRequest(
      intent: intent,
      filters: AskFilters(
        groups: {
          for (final id in strings(decoded['categories']))
            if (categoryIds[id] case final group?) group,
        },
        openNow: decoded['open_now'] == true,
        preferences: {
          for (final id in strings(decoded['needs']))
            if (needIds[id] case final need?) need,
        },
        keyword: cleanKeyword.length <= maxKeywordLength ? cleanKeyword : '',
      ),
    );
  }
}
