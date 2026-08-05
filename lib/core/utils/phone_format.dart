/// Normalizes the dataset's mixed phone shapes to `(xxx) xxx-xxxx`. Anything
/// not 10-digit (extensions, international, short codes) is returned as-is.
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
