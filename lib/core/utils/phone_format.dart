/// Formats raw phone strings for consistent display.
///
/// The dataset stores phones in mixed shapes — `xxx-xxx-xxxx`, `xxxxxxxxxx`,
/// `(xxx) xxx-xxxx`, sometimes with a leading 1. Everything 10-digit
/// normalizes to `(xxx) xxx-xxxx`; anything else (extensions, international,
/// short codes) is returned as-is rather than mangled.
String formatPhoneForDisplay(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  final national = (digits.length == 11 && digits.startsWith('1'))
      ? digits.substring(1)
      : digits;
  if (national.length != 10) return raw.trim();
  return '(${national.substring(0, 3)}) '
      '${national.substring(3, 6)}-${national.substring(6)}';
}

/// Strips a phone string down to a `tel:`-safe dial string.
String dialablePhone(String raw) => raw.replaceAll(RegExp('[^0-9+]'), '');
