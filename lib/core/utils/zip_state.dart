/// Maps a US ZIP code to its state from the first three digits.
///
/// USPS allocates 3-digit prefixes to states in fixed blocks, so this needs no
/// network and no per-ZIP data. A handful of ZIPs straddle a state line and
/// resolve to the prefix's main state, which is close enough for deciding
/// whether Beacon covers an area.
class ZipState {
  ZipState._();

  static final RegExp _fiveDigits = RegExp(r'^\d{5}$');

  /// Inclusive prefix blocks, in ascending order. Military (090–098, 340,
  /// 962–966) and unassigned prefixes are absent on purpose.
  static const List<(int, int, String)> _blocks = [
    (5, 5, 'NY'),
    (6, 7, 'PR'),
    (8, 8, 'VI'),
    (9, 9, 'PR'),
    (10, 27, 'MA'),
    (28, 29, 'RI'),
    (30, 38, 'NH'),
    (39, 49, 'ME'),
    (50, 54, 'VT'),
    (55, 55, 'MA'),
    (56, 59, 'VT'),
    (60, 69, 'CT'),
    (70, 89, 'NJ'),
    (100, 149, 'NY'),
    (150, 196, 'PA'),
    (197, 199, 'DE'),
    (200, 200, 'DC'),
    (201, 201, 'VA'),
    (202, 205, 'DC'),
    (206, 219, 'MD'),
    (220, 246, 'VA'),
    (247, 268, 'WV'),
    (270, 289, 'NC'),
    (290, 299, 'SC'),
    (300, 319, 'GA'),
    (320, 339, 'FL'),
    (341, 342, 'FL'),
    (344, 344, 'FL'),
    (346, 347, 'FL'),
    (349, 349, 'FL'),
    (350, 369, 'AL'),
    (370, 385, 'TN'),
    (386, 397, 'MS'),
    (398, 399, 'GA'),
    (400, 427, 'KY'),
    (430, 459, 'OH'),
    (460, 479, 'IN'),
    (480, 499, 'MI'),
    (500, 528, 'IA'),
    (530, 549, 'WI'),
    (550, 567, 'MN'),
    (569, 569, 'DC'),
    (570, 577, 'SD'),
    (580, 588, 'ND'),
    (590, 599, 'MT'),
    (600, 629, 'IL'),
    (630, 658, 'MO'),
    (660, 679, 'KS'),
    (680, 693, 'NE'),
    (700, 714, 'LA'),
    (716, 729, 'AR'),
    (730, 732, 'OK'),
    (733, 733, 'TX'),
    (734, 749, 'OK'),
    (750, 799, 'TX'),
    (800, 816, 'CO'),
    (820, 831, 'WY'),
    (832, 838, 'ID'),
    (840, 847, 'UT'),
    (850, 865, 'AZ'),
    (870, 884, 'NM'),
    (885, 885, 'TX'),
    (889, 898, 'NV'),
    (900, 961, 'CA'),
    (967, 968, 'HI'),
    (969, 969, 'GU'),
    (970, 979, 'OR'),
    (980, 994, 'WA'),
    (995, 999, 'AK'),
  ];

  /// Whether [zip] is five digits. Says nothing about whether it exists.
  static bool isWellFormed(String zip) => _fiveDigits.hasMatch(zip.trim());

  /// The two-letter state for [zip], or null when it isn't five digits or the
  /// prefix belongs to no state.
  static String? stateFor(String zip) {
    final trimmed = zip.trim();
    if (!_fiveDigits.hasMatch(trimmed)) return null;
    final prefix = int.parse(trimmed.substring(0, 3));
    for (final (start, end, state) in _blocks) {
      if (prefix < start) return null;
      if (prefix <= end) return state;
    }
    return null;
  }
}
