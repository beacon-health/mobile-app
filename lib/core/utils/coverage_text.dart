import 'package:beacon_app/core/services/coverage_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';

/// Spanish swaps "y" for "e" before an /i/ sound ("Ohio e Indiana"). English
/// and Chinese carry identical text under both keys, so the check is harmless
/// there.
final RegExp _startsWithISound = RegExp('^(i|hi(?!e))', caseSensitive: false);

/// State names joined as prose in the current language: "Illinois",
/// "Illinois and Oklahoma", "Illinois, Oklahoma, and Indiana".
String localizedStateList(AppLocalizations l10n, List<String> stateCodes) {
  final names = [for (final code in stateCodes) l10n.stateName(code)];
  if (names.isEmpty) return '';
  if (names.length == 1) return names.single;

  final last = names.last;
  final beforeI = _startsWithISound.hasMatch(last);
  if (names.length == 2) {
    return beforeI
        ? l10n.listTwoBeforeI(names.first, last)
        : l10n.listTwo(names.first, last);
  }

  final rest = names.sublist(0, names.length - 1).join(l10n.listSeparator);
  return beforeI ? l10n.listManyBeforeI(rest, last) : l10n.listMany(rest, last);
}

/// What to tell someone whose ZIP [ZipCodeService.setZipCode] turned down.
/// An uncovered ZIP names the states that are live, so the reason is clear.
String zipErrorMessage(AppLocalizations l10n, ZipResult result) {
  if (result == ZipResult.outsideCoverage) {
    return l10n.zipOutsideCoverage(
      localizedStateList(l10n, CoverageService().launchedStates),
    );
  }
  return l10n.settingsZipNotFoundError;
}
