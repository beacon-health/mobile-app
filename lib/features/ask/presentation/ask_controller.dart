import 'dart:async';

import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/features/ask/data/assistant_model.dart';
import 'package:beacon_app/features/ask/domain/ask_prompts.dart';
import 'package:beacon_app/features/ask/domain/ask_request.dart';
import 'package:beacon_app/features/ask/domain/crisis_keywords.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/data/facility_repository.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/services/facility_filter_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// One entry in the conversation.
sealed class AskMessage {
  const AskMessage();
}

class AskUserMessage extends AskMessage {
  const AskUserMessage(this.text);
  final String text;
}

/// 911 and 988, shown the moment a message matches [CrisisKeywords].
class AskCrisisMessage extends AskMessage {
  const AskCrisisMessage();
}

/// Places that match.
class AskAnswerMessage extends AskMessage {
  const AskAnswerMessage({
    required this.facilities,
    required this.totalCount,
    required this.filters,
    required this.origin,
    this.noneOpenNow = false,
  });

  /// The nearest few. Everything shown about them comes from these records.
  final List<Facility> facilities;

  /// How many matched in all.
  final int totalCount;

  /// The filters that produced them — shown, so the person can see how the
  /// request was read.
  final AskFilters filters;

  /// Where distances are measured from: the person's saved location.
  final LatLng origin;

  /// They asked for somewhere open now and nothing is, so these are the
  /// matches regardless of hours. The page says so.
  final bool noneOpenNow;
}

enum AskHandoffReason {
  /// The model couldn't turn the request into filters.
  unclear,

  /// The filters matched nothing nearby.
  noResults,
  medicalAdvice,
  offTopic,
}

/// Ask couldn't answer, and offers the Map instead — with the filters it did
/// work out, if any.
class AskHandoffMessage extends AskMessage {
  const AskHandoffMessage({required this.reason, required this.filters});
  final AskHandoffReason reason;
  final AskFilters filters;
}

/// Runs a request through the assistant, in two steps that keep the model
/// away from the facts:
///
/// 1. The model turns the request into filters, and nothing else.
/// 2. App code runs the Map's own query with them.
///
/// Whenever a step can't do its job — no filters, no results, a request that
/// isn't a search — the answer is a hand-off to the Map, never a guess. The
/// conversation is kept in memory and nowhere else.
class AskController extends ChangeNotifier {
  AskController({
    required AssistantModel model,
    required FacilityRepositoryBase repository,
  })  : _model = model,
        _repository = repository;

  final AssistantModel _model;
  final FacilityRepositoryBase _repository;

  /// Cards shown under an answer.
  static const int maxFacilities = 5;

  final List<AskMessage> _messages = [];
  List<AskMessage> get messages => List.unmodifiable(_messages);

  bool _isThinking = false;
  bool get isThinking => _isThinking;

  /// Counts conversations, so an answer that arrives after "New chat" can be
  /// dropped.
  int _conversation = 0;

  void clear() {
    _conversation++;
    _messages.clear();
    _isThinking = false;
    notifyListeners();
  }

  /// Sends what the person typed.
  Future<void> send(String text) async {
    final request = text.trim();
    if (request.isEmpty || _isThinking) return;

    _messages.add(AskUserMessage(request));
    // First, and without waiting on the model.
    if (CrisisKeywords.matches(request)) {
      _messages.add(const AskCrisisMessage());
    }
    await _answer(() => _readRequest(request));
  }

  /// Runs a ready-made search — a suggestion button, or a follow-up chip —
  /// which already knows its filters and needs no reading.
  Future<void> search(String label, AskFilters filters) async {
    if (_isThinking) return;
    _messages.add(AskUserMessage(label));
    await _answer(
      () async => AskRequest(intent: AskIntent.search, filters: filters),
    );
  }

  Future<void> _answer(Future<AskRequest> Function() read) async {
    final conversation = _conversation;
    _isThinking = true;
    notifyListeners();

    final reply = await _reply(read);

    if (conversation != _conversation) return;
    _messages.add(reply);
    _isThinking = false;
    notifyListeners();
  }

  Future<AskMessage> _reply(Future<AskRequest> Function() read) async {
    final asked = await read();
    switch (asked.intent) {
      case AskIntent.medicalAdvice:
        return const AskHandoffMessage(
          reason: AskHandoffReason.medicalAdvice,
          filters: AskFilters(),
        );
      case AskIntent.offTopic:
        return const AskHandoffMessage(
          reason: AskHandoffReason.offTopic,
          filters: AskFilters(),
        );
      case AskIntent.search:
        break;
    }
    if (asked.filters.isEmpty) {
      return const AskHandoffMessage(
        reason: AskHandoffReason.unclear,
        filters: AskFilters(),
      );
    }

    final zip = ZipCodeService();
    final origin = LatLng(zip.latitude, zip.longitude);
    final pool = await _repository.loadFacilitiesWithDistance(
      latitude: origin.latitude,
      longitude: origin.longitude,
      radiusMiles: MapConstants.defaultRadiusMiles,
    );

    var found = _search(pool, asked.filters, origin);
    var noneOpenNow = false;
    // "Open now" is the flag the model over-applies, and listed hours are
    // patchy. Nothing open is worth saying; it isn't a dead end.
    if (found == null && asked.filters.openNow) {
      found = _search(pool, asked.filters.copyWith(openNow: false), origin);
      noneOpenNow = found != null;
    }
    if (found == null) {
      return AskHandoffMessage(
        reason: AskHandoffReason.noResults,
        filters: asked.filters,
      );
    }

    final (filters, matches) = found;
    return AskAnswerMessage(
      facilities: matches.take(maxFacilities).toList(),
      totalCount: matches.length,
      filters: filters,
      origin: origin,
      noneOpenNow: noneOpenNow,
    );
  }

  /// The first of [keywordLadder]'s keywords to match anything, with what it
  /// matched; null if none does.
  (AskFilters, List<Facility>)? _search(
    List<Facility> pool,
    AskFilters asked,
    LatLng origin,
  ) {
    for (final keyword in keywordLadder(asked.keyword)) {
      final filters = asked.copyWith(keyword: keyword);
      if (filters.isEmpty) continue;
      final matches = _matching(pool, filters, origin);
      if (matches.isNotEmpty) return (filters, matches);
    }
    return null;
  }

  /// The keyword as the model gave it, then looser forms of it, then none.
  /// The keyword is the model's own wording, matched against listings
  /// written by other people: "dentist" where the listing says "Dental",
  /// "food pantry" where it says "Food Bank".
  @visibleForTesting
  static List<String> keywordLadder(String keyword) {
    if (keyword.isEmpty) return const [''];
    final firstWord = keyword.split(' ').first;
    return {
      keyword,
      firstWord,
      if (firstWord.length > _stemLength) firstWord.substring(0, _stemLength),
      '',
    }.toList();
  }

  /// Letters of a word kept as its stem: "dent" finds dental, dentist and
  /// dentistry.
  static const int _stemLength = 4;

  /// Step 1. A model that fails, or says something unreadable, is the same
  /// as one that found no filters.
  Future<AskRequest> _readRequest(String request) async {
    try {
      final reply = await _model.extractFilters(
        instructions: AskPrompts.filterInstructions,
        prompt: AskPrompts.filterPrompt(request),
      );
      return AskRequest.parse(reply);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'AskController.extractFilters',
      );
      return const AskRequest(intent: AskIntent.search);
    }
  }

  /// Step 2, the Map's own filtering: the same pool, the same rules, the
  /// same answers about what the person can provide. Nearest first.
  List<Facility> _matching(
    List<Facility> pool,
    AskFilters filters,
    LatLng origin,
  ) {
    // As on the Map, the person's answers and the preference filters belong
    // to an account. Ask is only offered to one, but the rule is the Map's.
    final isGuest = GuestModeService().isGuest;
    final matches = FacilityFilterService.filterFacilities(
      pool,
      searchText: filters.keyword,
      selectedCategories: filters.categories,
      selectedEligibilityRequirements: isGuest
          ? const {}
          : FacilityFilterService.eligibilityGates(
              EligibilityPreferencesService().eligibility,
            ),
      selectedPreferenceRequirements: isGuest
          ? const {}
          : {for (final need in filters.preferences) need: true},
      showFavoritesOnly: false,
      showOpenNowOnly: filters.openNow,
    );
    return FacilityFilterService.nearestFirst(matches, center: origin);
  }
}
