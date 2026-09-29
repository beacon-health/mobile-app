// Captures the Claude Design map kit's backgrounds: the real Google Map in
// Beacon's map styles, light and dark, at the app's list and city zooms.
//
//   dart run tool/design/capture_map_backgrounds.dart [--device <udid>]
//
// Runs tool/design/map_capture_main.dart on an iOS simulator (default: an
// iPhone 17e — 390×844pt, the design frame — on the oldest installed
// runtime), screenshots each state it announces, and writes 2x JPEGs to
// .design-sync/captures/. Needs Xcode and the gitignored iOS Maps key the app
// build already uses. Until the app adopts the UIScene lifecycle, builds from
// the iOS 27 SDK don't launch on iOS 27 simulators, hence the oldest runtime.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _outDir = '.design-sync/captures';
const _rawDir = 'build/map_captures';

Future<void> main(List<String> args) async {
  final deviceArg = args.indexOf('--device');
  final udid =
      deviceArg >= 0 ? args[deviceArg + 1] : await _findSimulator('iPhone 17e');
  final bootedHere = await _boot(udid);

  Directory(_rawDir).createSync(recursive: true);
  final process = await Process.start(
    'flutter',
    ['run', '-t', 'tool/design/map_capture_main.dart', '-d', udid],
    runInShell: true,
  );
  final done = Completer<void>();
  final shots = <String>[];

  process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) async {
    final match = RegExp(r'BEACON_CAPTURE (\w+)').firstMatch(line);
    if (match != null) {
      final name = match[1]!;
      await _run(
          'xcrun', ['simctl', 'io', udid, 'screenshot', '$_rawDir/$name.png']);
      shots.add(name);
      stdout.writeln('captured $name');
    } else if (line.contains('BEACON_CAPTURE_DONE')) {
      process.stdin.writeln('q');
      if (!done.isCompleted) done.complete();
    }
  });
  process.stderr.transform(utf8.decoder).listen(stderr.write);
  // A build or launch failure ends `flutter run` before the app finishes.
  unawaited(
    process.exitCode.then((code) {
      if (!done.isCompleted) {
        done.completeError(StateError('flutter run exited ($code) early'));
      }
    }),
  );

  try {
    await done.future.timeout(
      // A clean iOS build with the Maps pods alone can take several minutes.
      const Duration(minutes: 15),
      onTimeout: () => throw TimeoutException('the capture app never finished'),
    );
    await process.exitCode.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        process.kill();
        return -1;
      },
    );
  } finally {
    if (bootedHere) await _run('xcrun', ['simctl', 'shutdown', udid]);
  }

  // Downscale 3x screenshots to 2x JPEGs: crisp in a 390pt frame, a fraction
  // of the size.
  for (final name in shots) {
    await _run('sips', [
      '-Z',
      '1688',
      '-s',
      'format',
      'jpeg',
      '-s',
      'formatOptions',
      '80',
      '$_rawDir/$name.png',
      '--out',
      '$_outDir/map_bg_$name.jpg',
    ]);
  }
  stdout.writeln('Wrote ${shots.length} backgrounds to $_outDir.');
}

Future<String> _findSimulator(String name) async {
  final result = await Process.run(
    'xcrun',
    ['simctl', 'list', 'devices', 'available', '-j'],
  );
  final runtimes = (json.decode(result.stdout as String)
      as Map<String, dynamic>)['devices'] as Map<String, dynamic>;
  // Runtime ids sort by version ("…SimRuntime.iOS-26-5" < "…iOS-27-0").
  for (final runtime in runtimes.keys.toList()..sort()) {
    final devices = runtimes[runtime] as List;
    for (final device in devices.cast<Map<String, dynamic>>()) {
      if (device['name'] == name) return device['udid'] as String;
    }
  }
  stderr.writeln('No "$name" simulator; pass --device <udid>.');
  exit(1);
}

/// Boots [udid] if needed; returns whether this run booted it.
Future<bool> _boot(String udid) async {
  final list = await Process.run('xcrun', ['simctl', 'list', 'devices']);
  if ((list.stdout as String).contains('$udid) (Booted)')) return false;
  await _run('xcrun', ['simctl', 'boot', udid]);
  await _run('xcrun', ['simctl', 'bootstatus', udid, '-b']);
  return true;
}

Future<void> _run(String exe, List<String> args) async {
  final result = await Process.run(exe, args);
  if (result.exitCode != 0) {
    stderr
      ..writeln('$exe ${args.join(' ')} failed:')
      ..write(result.stderr);
    exit(result.exitCode);
  }
}
