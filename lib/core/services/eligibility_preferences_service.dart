import 'dart:async';

import 'package:beacon_app/core/services/user_settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Eligibility hard-gates — things the user *needs* from a facility. Filters
/// out facilities demanding more than the user can provide.
class EligibilityState {
  const EligibilityState({
    this.proofOfIncome = false,
    this.proofOfResidency = false,
    this.insuranceRequired = false,
    this.referralRequired = false,
    this.applyToSearch = true,
  });

  final bool proofOfIncome;
  final bool proofOfResidency;
  final bool insuranceRequired;
  final bool referralRequired;

  /// When false the gates are kept but not applied, so the user sees
  /// everything. Defaults to true.
  final bool applyToSearch;

  EligibilityState copyWith({
    bool? proofOfIncome,
    bool? proofOfResidency,
    bool? insuranceRequired,
    bool? referralRequired,
    bool? applyToSearch,
  }) {
    return EligibilityState(
      proofOfIncome: proofOfIncome ?? this.proofOfIncome,
      proofOfResidency: proofOfResidency ?? this.proofOfResidency,
      insuranceRequired: insuranceRequired ?? this.insuranceRequired,
      referralRequired: referralRequired ?? this.referralRequired,
      applyToSearch: applyToSearch ?? this.applyToSearch,
    );
  }

  Map<String, dynamic> toJson() => {
        'proof_of_income': proofOfIncome,
        'proof_of_residency': proofOfResidency,
        'insurance_required': insuranceRequired,
        'referral_required': referralRequired,
        'apply_to_search': applyToSearch,
      };

  factory EligibilityState.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EligibilityState();
    return EligibilityState(
      proofOfIncome: json['proof_of_income'] as bool? ?? false,
      proofOfResidency: json['proof_of_residency'] as bool? ?? false,
      insuranceRequired: json['insurance_required'] as bool? ?? false,
      referralRequired: json['referral_required'] as bool? ?? false,
      applyToSearch: json['apply_to_search'] as bool? ?? true,
    );
  }
}

/// Service-preference toggles (soft preferences — nice-to-have attributes).
class PreferencesState {
  const PreferencesState({
    this.acceptsWalkIns = false,
    this.appointmentOnly = false,
    this.openToImmigrants = false,
    this.freeServices = false,
    this.slidingScale = false,
    this.otherLanguages = false,
    this.telehealthPreference = false,
    this.wheelchairAccessible = false,
    this.servesOutsideArea = false,
  });

  final bool acceptsWalkIns;
  final bool appointmentOnly;
  final bool openToImmigrants;
  final bool freeServices;
  final bool slidingScale;
  final bool otherLanguages;
  final bool telehealthPreference;
  final bool wheelchairAccessible;
  final bool servesOutsideArea;

  PreferencesState copyWith({
    bool? acceptsWalkIns,
    bool? appointmentOnly,
    bool? openToImmigrants,
    bool? freeServices,
    bool? slidingScale,
    bool? otherLanguages,
    bool? telehealthPreference,
    bool? wheelchairAccessible,
    bool? servesOutsideArea,
  }) {
    return PreferencesState(
      acceptsWalkIns: acceptsWalkIns ?? this.acceptsWalkIns,
      appointmentOnly: appointmentOnly ?? this.appointmentOnly,
      openToImmigrants: openToImmigrants ?? this.openToImmigrants,
      freeServices: freeServices ?? this.freeServices,
      slidingScale: slidingScale ?? this.slidingScale,
      otherLanguages: otherLanguages ?? this.otherLanguages,
      telehealthPreference: telehealthPreference ?? this.telehealthPreference,
      wheelchairAccessible: wheelchairAccessible ?? this.wheelchairAccessible,
      servesOutsideArea: servesOutsideArea ?? this.servesOutsideArea,
    );
  }

  Map<String, dynamic> toJson() => {
        'accepts_walk_ins': acceptsWalkIns,
        'appointment_only': appointmentOnly,
        'open_to_immigrants': openToImmigrants,
        'free_services': freeServices,
        'sliding_scale': slidingScale,
        'other_languages': otherLanguages,
        'telehealth_preference': telehealthPreference,
        'wheelchair_accessible': wheelchairAccessible,
        'serves_outside_area': servesOutsideArea,
      };

  factory PreferencesState.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PreferencesState();
    return PreferencesState(
      acceptsWalkIns: json['accepts_walk_ins'] as bool? ?? false,
      appointmentOnly: json['appointment_only'] as bool? ?? false,
      openToImmigrants: json['open_to_immigrants'] as bool? ?? false,
      freeServices: json['free_services'] as bool? ?? false,
      slidingScale: json['sliding_scale'] as bool? ?? false,
      otherLanguages: json['other_languages'] as bool? ?? false,
      telehealthPreference: json['telehealth_preference'] as bool? ?? false,
      wheelchairAccessible: json['wheelchair_accessible'] as bool? ?? false,
      servesOutsideArea: json['serves_outside_area'] as bool? ?? false,
    );
  }
}

/// Stores eligibility-gate and service-preference toggles in SharedPreferences
/// as individual boolean keys, synced to `user_settings` when signed in.
class EligibilityPreferencesService extends ChangeNotifier {
  factory EligibilityPreferencesService() => _instance;

  EligibilityPreferencesService._();

  static final EligibilityPreferencesService _instance =
      EligibilityPreferencesService._();

  // Keys are kept as-is (snake_case) so they map directly to the Supabase
  // jsonb shape.
  static const _keyProofOfIncome = 'elig.proof_of_income';
  static const _keyProofOfResidency = 'elig.proof_of_residency';
  static const _keyInsuranceRequired = 'elig.insurance_required';
  static const _keyReferralRequired = 'elig.referral_required';
  static const _keyApplyToSearch = 'elig.apply_to_search';

  static const _keyAcceptsWalkIns = 'pref.accepts_walk_ins';
  static const _keyAppointmentOnly = 'pref.appointment_only';
  static const _keyOpenToImmigrants = 'pref.open_to_immigrants';
  static const _keyFreeServices = 'pref.free_services';
  static const _keySlidingScale = 'pref.sliding_scale';
  static const _keyOtherLanguages = 'pref.other_languages';
  static const _keyTelehealthPreference = 'pref.telehealth_preference';
  static const _keyWheelchairAccessible = 'pref.wheelchair_accessible';
  static const _keyServesOutsideArea = 'pref.serves_outside_area';

  EligibilityState _eligibility = const EligibilityState();
  PreferencesState _preferences = const PreferencesState();

  EligibilityState get eligibility => _eligibility;
  PreferencesState get preferences => _preferences;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _eligibility = EligibilityState(
      proofOfIncome: prefs.getBool(_keyProofOfIncome) ?? false,
      proofOfResidency: prefs.getBool(_keyProofOfResidency) ?? false,
      insuranceRequired: prefs.getBool(_keyInsuranceRequired) ?? false,
      referralRequired: prefs.getBool(_keyReferralRequired) ?? false,
      applyToSearch: prefs.getBool(_keyApplyToSearch) ?? true,
    );
    _preferences = PreferencesState(
      acceptsWalkIns: prefs.getBool(_keyAcceptsWalkIns) ?? false,
      appointmentOnly: prefs.getBool(_keyAppointmentOnly) ?? false,
      openToImmigrants: prefs.getBool(_keyOpenToImmigrants) ?? false,
      freeServices: prefs.getBool(_keyFreeServices) ?? false,
      slidingScale: prefs.getBool(_keySlidingScale) ?? false,
      otherLanguages: prefs.getBool(_keyOtherLanguages) ?? false,
      telehealthPreference: prefs.getBool(_keyTelehealthPreference) ?? false,
      wheelchairAccessible: prefs.getBool(_keyWheelchairAccessible) ?? false,
      servesOutsideArea: prefs.getBool(_keyServesOutsideArea) ?? false,
    );
    notifyListeners();
  }

  Future<void> updateEligibility(
    EligibilityState value, {
    bool syncToCloud = true,
  }) async {
    if (identical(_eligibility, value)) return;
    _eligibility = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyProofOfIncome, value.proofOfIncome);
    await prefs.setBool(_keyProofOfResidency, value.proofOfResidency);
    await prefs.setBool(_keyInsuranceRequired, value.insuranceRequired);
    await prefs.setBool(_keyReferralRequired, value.referralRequired);
    await prefs.setBool(_keyApplyToSearch, value.applyToSearch);
    notifyListeners();
    if (syncToCloud) {
      unawaited(UserSettingsService.instance.pushLocal());
    }
  }

  /// Flips the parent "apply eligibility to search" toggle without touching the
  /// individual gate values (they're kept, just applied or not).
  Future<void> setApplyEligibilityToSearch(bool value) {
    return updateEligibility(_eligibility.copyWith(applyToSearch: value));
  }

  Future<void> updatePreferences(
    PreferencesState value, {
    bool syncToCloud = true,
  }) async {
    if (identical(_preferences, value)) return;
    _preferences = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAcceptsWalkIns, value.acceptsWalkIns);
    await prefs.setBool(_keyAppointmentOnly, value.appointmentOnly);
    await prefs.setBool(_keyOpenToImmigrants, value.openToImmigrants);
    await prefs.setBool(_keyFreeServices, value.freeServices);
    await prefs.setBool(_keySlidingScale, value.slidingScale);
    await prefs.setBool(_keyOtherLanguages, value.otherLanguages);
    await prefs.setBool(_keyTelehealthPreference, value.telehealthPreference);
    await prefs.setBool(_keyWheelchairAccessible, value.wheelchairAccessible);
    await prefs.setBool(_keyServesOutsideArea, value.servesOutsideArea);
    notifyListeners();
    if (syncToCloud) {
      unawaited(UserSettingsService.instance.pushLocal());
    }
  }

  /// Resets to defaults and drops the stored keys, so the next person to use
  /// the device doesn't inherit the previous account's answers.
  Future<void> clear() async {
    _eligibility = const EligibilityState();
    _preferences = const PreferencesState();
    final prefs = await SharedPreferences.getInstance();
    for (final key in const [
      _keyProofOfIncome,
      _keyProofOfResidency,
      _keyInsuranceRequired,
      _keyReferralRequired,
      _keyApplyToSearch,
      _keyAcceptsWalkIns,
      _keyAppointmentOnly,
      _keyOpenToImmigrants,
      _keyFreeServices,
      _keySlidingScale,
      _keyOtherLanguages,
      _keyTelehealthPreference,
      _keyWheelchairAccessible,
      _keyServesOutsideArea,
    ]) {
      await prefs.remove(key);
    }
    notifyListeners();
  }

  /// Applies a snapshot pulled from Supabase. Does NOT re-upload (we just
  /// downloaded these values — uploading them back would be wasteful and
  /// could ping-pong if another device wrote concurrently).
  Future<void> applyFromCloud({
    EligibilityState? eligibility,
    PreferencesState? preferences,
  }) async {
    if (eligibility != null) {
      await updateEligibility(eligibility, syncToCloud: false);
    }
    if (preferences != null) {
      await updatePreferences(preferences, syncToCloud: false);
    }
  }
}
