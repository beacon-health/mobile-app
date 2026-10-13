import 'package:beacon_app/features/map/presentation/providers/facility_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/app_shell.dart';
import '../../../../helpers/test_facility.dart';

void main() {
  FacilityProvider providerWith(List<String> ids) =>
      FacilityProvider(repository: FakeFacilityRepository())
        ..setFacilities([for (final id in ids) createTestFacility(id: id)]);

  group('FacilityProvider favorites', () {
    test('toggling flips the heart and the id set together', () async {
      final provider = providerWith(['a', 'b']);
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.toggleFavorite('a');

      expect(provider.favoriteIds, {'a'});
      expect(provider.facilities.first.isFavorite, isTrue);
      expect(provider.favoriteFacilities.map((f) => f.id), ['a']);
      expect(notifications, 1);

      await provider.toggleFavorite('a');

      expect(provider.favoriteIds, isEmpty);
      expect(provider.facilities.first.isFavorite, isFalse);
    });

    test('a facility that is not loaded cannot be toggled', () async {
      final provider = providerWith(['a']);

      await provider.toggleFavorite('elsewhere');

      expect(provider.favoriteIds, isEmpty);
    });

    test('applying ids from the server marks loaded facilities', () {
      final provider = providerWith(['a', 'b', 'c']);

      provider.applyFavoriteIds({'b', 'not-in-this-region'});

      // The id set keeps favorites from other regions too — the map uses it
      // to mark facilities it loads later.
      expect(provider.favoriteIds, {'b', 'not-in-this-region'});
      expect(
        [for (final f in provider.facilities) f.isFavorite],
        [false, true, false],
      );
    });

    test('notifies when only the id set changed', () {
      // The provider may hold a different region than the map does. The map
      // still has to hear that favorites arrived.
      final provider = providerWith(['a']);
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.applyFavoriteIds({'somewhere-else'});
      expect(notifications, 1);

      provider.applyFavoriteIds({'somewhere-else'});
      expect(notifications, 1, reason: 'nothing changed the second time');
    });

    test('the id set cannot be edited from outside', () {
      final provider = providerWith(['a']);
      expect(() => provider.favoriteIds.add('x'), throwsUnsupportedError);
    });

    test('clearing on sign-out empties everything', () async {
      final provider = providerWith(['a', 'b']);
      await provider.toggleFavorite('a');

      provider.clearFavorites();

      expect(provider.favoriteIds, isEmpty);
      expect(provider.favoriteFacilities, isEmpty);
      expect(provider.facilities.any((f) => f.isFavorite), isFalse);
    });
  });

  group('FacilityProvider loading', () {
    test('setFacilities replaces the list and ends loading', () {
      final provider = FacilityProvider(repository: FakeFacilityRepository())
        ..setLoading(true);
      expect(provider.isLoading, isTrue);

      provider.setFacilities([createTestFacility(id: 'x')]);

      expect(provider.isLoading, isFalse);
      expect(provider.getFacilityById('x')!.id, 'x');
      expect(provider.getFacilityById('missing'), isNull);
    });
  });
}
