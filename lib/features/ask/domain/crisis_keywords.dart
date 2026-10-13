import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/l10n/app_localizations.dart';

/// Spots a message that may come from someone in danger, so Ask can show 911
/// and 988 at once — before, and regardless of, anything the model does.
///
/// Deliberately a fixed list and not the model's judgment: it has to work
/// when the model is slow, wrong or missing. The phrases live in the ARB
/// files (`askCrisisKeywords`), and a message is checked against every
/// language's list, because people don't always write in the language their
/// phone is set to.
abstract final class CrisisKeywords {
  static List<String>? _phrases;

  /// Every language's phrases, lowercased.
  static List<String> get phrases => _phrases ??= [
        for (final locale in LocaleProvider.supportedLocales)
          ...lookupAppLocalizations(locale)
              .askCrisisKeywords
              .split('|')
              .map((phrase) => phrase.trim().toLowerCase())
              .where((phrase) => phrase.isNotEmpty),
      ];

  static bool matches(String message) {
    final text = message.toLowerCase();
    return phrases.any(text.contains);
  }
}
