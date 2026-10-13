import 'dart:async';

import 'package:beacon_app/core/services/coverage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final coverage = CoverageService();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    coverage.debugReset();
  });
  tearDown(coverage.debugReset);

  group('CoverageService', () {
    test('starts from the bundled list until a fetch succeeds', () {
      expect(coverage.launchedStates, ['IL']);
      expect(coverage.isNationwide, isFalse);
      expect(coverage.checkZip('60601'), ZipCoverage.covered);
      expect(coverage.checkZip('73102'), ZipCoverage.outsideCoverage);
    });

    test('a newly launched state is covered as soon as it is fetched',
        () async {
      coverage.debugFetch = () async => ['IL', 'OK'];

      expect(await coverage.refresh(), isTrue);

      expect(coverage.launchedStates, ['IL', 'OK']);
      expect(coverage.checkZip('73102'), ZipCoverage.covered);
      expect(coverage.checkZip('75001'), ZipCoverage.outsideCoverage);
    });

    test('notifies listeners only when the list changes', () async {
      var notifications = 0;
      void onChange() => notifications++;
      coverage.addListener(onChange);
      addTearDown(() => coverage.removeListener(onChange));

      coverage.debugFetch = () async => ['IL', 'OK'];
      await coverage.refresh();
      await coverage.refresh();

      expect(notifications, 1);
    });

    test('the fetched list survives a restart', () async {
      coverage.debugFetch = () async => ['IL', 'OK'];
      await coverage.refresh();

      // A cold start with no network: the fetch fails, the cache answers.
      coverage
        ..debugReset()
        ..debugFetch = () async => throw Exception('offline');
      await coverage.init();

      expect(coverage.launchedStates, ['IL', 'OK']);
    });

    test('a failed or empty fetch keeps the current list', () async {
      coverage.debugSetStates(['IL', 'OK']);

      coverage.debugFetch = () async => throw Exception('offline');
      expect(await coverage.refresh(), isFalse);
      expect(coverage.launchedStates, ['IL', 'OK']);

      // An empty table would turn every ZIP away, so it is not trusted.
      coverage.debugFetch = () async => [];
      expect(await coverage.refresh(), isFalse);
      expect(coverage.launchedStates, ['IL', 'OK']);
    });

    test('ALL switches the gate off', () async {
      coverage.debugFetch = () async => ['ALL'];
      await coverage.refresh();

      expect(coverage.isNationwide, isTrue);
      expect(coverage.launchedStates, isEmpty);
      expect(coverage.checkZip('75001'), ZipCoverage.covered);
      expect(coverage.checkZip('99501'), ZipCoverage.covered);
      // Still not a ZIP, however wide the coverage.
      expect(coverage.checkZip('00000'), ZipCoverage.invalid);
    });

    test('ensureFresh re-reads only when the list is stale', () async {
      var fetches = 0;
      coverage.debugFetch = () async {
        fetches++;
        return ['IL'];
      };

      await coverage.ensureFresh();
      await coverage.ensureFresh();

      expect(fetches, 1);
    });

    test('concurrent refreshes share one request', () async {
      var fetches = 0;
      final gate = Completer<List<String>>();
      coverage.debugFetch = () {
        fetches++;
        return gate.future;
      };

      final first = coverage.refresh();
      final second = coverage.refresh();
      gate.complete(['IL', 'OK']);
      await Future.wait([first, second]);

      expect(fetches, 1);
    });

    test('malformed ZIPs are invalid, not uncovered', () {
      expect(coverage.checkZip('6060'), ZipCoverage.invalid);
      expect(coverage.checkZip('abcde'), ZipCoverage.invalid);
    });
  });
}
