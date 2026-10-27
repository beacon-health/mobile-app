import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/utils/facility_formatting.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    final l10n = lookupAppLocalizations(locale);

    group('in ${locale.languageCode}', () {
      test('every chip has a label of its own, never its raw key', () {
        final labels = [
          for (final key in FacilityCategories.serviceTagKeys)
            FacilityCategoryIcons.tagLabel(l10n, key),
        ];
        for (final (i, key) in FacilityCategories.serviceTagKeys.indexed) {
          expect(labels[i], isNot(contains('_')), reason: key);
          expect(
            labels[i],
            isNot(FacilityCategoryIcons.getCategoryDisplayName(key)),
            reason: key,
          );
        }
        expect(labels.toSet(), hasLength(labels.length));
      });

      // A chip named like its heading ("Recovery" under "Mental Health &
      // Recovery") reads as the whole group.
      test('no chip repeats a group name or one part of one', () {
        final groups = [
          for (final group in FacilityCategories.quickActionGroups)
            FacilityCategoryIcons.groupLabel(l10n, group),
        ];
        expect(groups.toSet(), hasLength(groups.length));
        final names = {
          for (final group in groups) ...[
            group.toLowerCase(),
            ...group.toLowerCase().split(RegExp(r'\s*(?:&|,| y | e |与|、)\s*')),
          ],
        };
        for (final key in FacilityCategories.serviceTagKeys) {
          expect(
            names,
            isNot(contains(
                FacilityCategoryIcons.tagLabel(l10n, key).toLowerCase())),
            reason: key,
          );
        }
      });
    });
  }
}
