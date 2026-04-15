/// Static data representing the demo user (Apple sign-in mock).
///
/// Name and email are read-only to simulate an Apple OAuth session.
/// Eligibility preferences have editable defaults for the demo.
class DemoUser {
  DemoUser._();

  // Account (read-only, simulates Apple sign-in)
  static const String name = 'Jane Doe';
  static const String email = 'jane.doe@icloud.com';
  static const String authProvider = 'Apple';
  static const String zipCode = '60613';
  static const String language = 'English';

  // Eligibility preference defaults (editable in demo)
  static const bool wheelchairAccessible = false;
  static const bool proofOfIncomeAvailable = true;
  static const String insuranceStatus = 'Uninsured';
  static const bool acceptsWalkIns = true;
  static const bool telehealthPreference = false;
  static const String householdSize = '2';
  static const int annualIncome = 25000;
  static const String employmentStatus = 'Employed';

  static const List<String> insuranceOptions = [
    'Insured',
    'Uninsured',
    'Medicaid',
    'Medicare',
  ];

  static const List<String> employmentOptions = [
    'Employed',
    'Unemployed',
    'Student',
    'Retired',
    'Disabled',
  ];
}
