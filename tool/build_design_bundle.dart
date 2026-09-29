// Builds the Claude Design project contents into build/ds-bundle/.
//
//   dart run tool/build_design_bundle.dart [--skip-render]
//
// Beacon's components are Flutter, so the project ships the generated tokens
// (design/tokens.*), Inter, the design-agent conventions
// (.design-sync/conventions.md), and reference cards made from real renders:
// tool/design/render_references_test.dart for widgets and screens, and
// .design-sync/captures/ for Home and Map (which need Google Maps). Every
// token and type class the README or cards mention is checked against
// tokens.css before anything is written. See .design-sync/NOTES.md.
//
// Markup is built from adjacent string literals on purpose; whitespace between
// tags doesn't matter in HTML.
// ignore_for_file: no_adjacent_strings_in_list
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:convert';
import 'dart:io';

const _out = 'build/ds-bundle';
const _renders = 'build/design_references';
const _captures = '.design-sync/captures';

Future<void> main(List<String> args) async {
  if (!args.contains('--skip-render')) {
    stdout.writeln('Rendering Flutter references…');
    final result = await Process.run(
      'flutter',
      ['test', 'tool/design/render_references_test.dart'],
      runInShell: true,
    );
    if (result.exitCode != 0) {
      stderr
        ..write(result.stdout)
        ..write(result.stderr);
      exit(result.exitCode);
    }
  }

  final tokens = json.decode(File('design/tokens.json').readAsStringSync())
      as Map<String, dynamic>;
  final out = Directory(_out);
  if (out.existsSync()) out.deleteSync(recursive: true);

  // Tokens, re-pointed at the bundled font files.
  _write(
    'tokens/tokens.css',
    File('design/tokens.css')
        .readAsStringSync()
        .replaceAll('../assets/fonts/inter/', '../fonts/'),
  );
  _copy('design/tokens.json', 'tokens/tokens.json');
  for (final font in Directory('assets/fonts/inter').listSync()) {
    _copy(font.path, 'fonts/${_name(font.path)}');
  }
  _write('styles.css', _stylesCss);
  _write('guidelines/card.css', _cardCss);

  // Reference images: Flutter renders plus device captures.
  for (final dir in [_renders, _captures]) {
    if (!Directory(dir).existsSync()) {
      stderr.writeln('$dir is missing — run without --skip-render.');
      exit(1);
    }
    for (final file in Directory(dir).listSync().whereType<File>()) {
      if (file.path.endsWith('.png')) {
        _copy(file.path, 'guidelines/references/${_name(file.path)}');
      }
    }
  }

  final cards = <_Card>[
    _colorsCard(tokens),
    _typeCard(tokens),
    _spacingCard(tokens),
    ..._componentCards,
    ..._screenCards,
  ];
  for (final card in cards) {
    _write(card.path, card.html);
  }
  _write('guidelines/index.md', _guidelinesIndex(cards));
  _write('README.md', _readme(cards));

  _validate(cards);
  stdout.writeln('Built $_out (${cards.length} cards).');
}

// --- Files -----------------------------------------------------------------

void _write(String path, String contents) {
  File('$_out/$path')
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}

void _copy(String from, String to) {
  File('$_out/$to').parent.createSync(recursive: true);
  File(from).copySync('$_out/$to');
}

String _name(String path) => path.split('/').last;

String _esc(String s) => const HtmlEscape().convert(s);

const _stylesCss = '''
/* Beacon design system entry. Tokens are generated from the Flutter app
   (lib/core/theme/) — see README.md. */
@import url("https://fonts.googleapis.com/icon?family=Material+Icons|Material+Icons+Outlined");
@import "./tokens/tokens.css";

*, *::before, *::after { box-sizing: border-box; }
body { margin: 0; -webkit-font-smoothing: antialiased; }
''';

const _cardCss = '''
body { padding: var(--space-xxl); }
h1 { margin: 0 0 var(--space-xs); }
h2 { margin: var(--space-xxl) 0 var(--space-md); }
.lede { margin: 0 0 var(--space-lg); color: var(--color-on-surface-variant);
  max-width: 720px; }
.grid { display: grid; gap: var(--space-md);
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); }
.swatch { border-radius: var(--radius-md); overflow: hidden;
  border: 1px solid var(--color-outline-variant); background: var(--color-card); }
.swatch .chip { height: 56px; }
.swatch .meta { padding: var(--space-sm); }
.meta code, td code { font-size: 11px; color: var(--color-on-surface-variant); }
.pair { display: flex; flex-wrap: wrap; gap: var(--space-xl);
  align-items: flex-start; }
.pair figure { margin: 0; }
.pair img { width: 390px; max-width: 100%; border-radius: var(--radius-lg);
  border: 1px solid var(--color-outline-variant); display: block; }
.pair figcaption { margin-top: var(--space-xs);
  color: var(--color-on-surface-variant); }
.phone img { width: 300px; }
ul.spec { max-width: 760px; padding-left: var(--space-lg); }
ul.spec li { margin: var(--space-xs) 0; }
table { border-collapse: collapse; }
td { padding: var(--space-sm) var(--space-lg) var(--space-sm) 0;
  vertical-align: middle; border-bottom: 1px solid var(--color-outline-variant); }
.bar { height: 12px; background: var(--color-primary);
  border-radius: var(--radius-pill); }
.box { width: 96px; height: 64px; background: var(--color-card);
  border: 1px solid var(--color-outline-variant); }
''';

// --- Cards -----------------------------------------------------------------

class _Card {
  const _Card(this.path, this.group, this.title, this.html);

  final String path;
  final String group;
  final String title;
  final String html;
}

_Card _card({
  required String path,
  required String group,
  required String title,
  required String lede,
  required String body,
  String viewport = '1000x800',
}) {
  final depth = '../' * (path.split('/').length - 1);
  return _Card(path, group, title, '''
<!-- @dsCard group="${_esc(group)}" viewport="$viewport" -->
<!doctype html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Beacon · ${_esc(title)}</title>
<link rel="stylesheet" href="${depth}styles.css">
<link rel="stylesheet" href="${depth}guidelines/card.css">
</head><body>
<h1 class="text-title-large">${_esc(title)}</h1>
<p class="lede text-body-medium">$lede</p>
$body
</body></html>
''');
}

String _kebab(String camel) => camel.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => '-${m[0]!.toLowerCase()}',
    );

String _swatches(Map<String, dynamic> colors, String prefix) {
  final cells = colors.entries.map((e) {
    final hex = e.value as String;
    return '<div class="swatch"><div class="chip" style="background:$hex">'
        '</div><div class="meta"><div class="text-label-medium">'
        '${_esc(e.key)}</div><code>--$prefix-${_kebab(e.key)}</code><br>'
        '<code>$hex</code></div></div>';
  });
  return '<div class="grid">${cells.join()}</div>';
}

_Card _colorsCard(Map<String, dynamic> tokens) {
  final c = tokens['color'] as Map<String, dynamic>;
  Map<String, dynamic> group(String k) => c[k] as Map<String, dynamic>;
  return _card(
    path: 'tokens/colors.html',
    group: 'Colors',
    title: 'Colors',
    viewport: '1000x1400',
    lede: 'Style with the semantic roles; the brand and category values are '
        'for fixed meanings (categories, map pins, third-party marks). Light '
        'mode uses the brand colors verbatim; dark mode uses lighter tonal '
        'variants of the same hues.',
    body: '''
<h2 class="text-title-medium">Brand</h2>${_swatches(group('brand'), 'color-brand')}
<h2 class="text-title-medium">Facility categories</h2>${_swatches(group('category'), 'color-category')}
<h2 class="text-title-medium">Status</h2>${_swatches(group('status'), 'color-status')}
<h2 class="text-title-medium">Roles — light</h2>${_swatches(group('light'), 'color')}
<h2 class="text-title-medium">Roles — dark (<code>data-theme="dark"</code>)</h2>${_swatches(group('dark'), 'color')}
''',
  );
}

_Card _typeCard(Map<String, dynamic> tokens) {
  final type = tokens['typography'] as Map<String, dynamic>;
  final roles = type['roles'] as Map<String, dynamic>;
  final rows = roles.entries.map((e) {
    final s = e.value as Map<String, dynamic>;
    return '<tr><td><div class="text-${_kebab(e.key)}">Find free and '
        'low-cost care</div></td><td><code>.text-${_kebab(e.key)}</code><br>'
        '<code>${s['fontSize']}px · ${s['fontWeight']} · '
        '${s['lineHeight']}</code></td></tr>';
  });
  return _card(
    path: 'tokens/typography.html',
    group: 'Type',
    title: 'Typography',
    viewport: '1000x1000',
    lede: 'Inter on every platform. Use a role class for all text; change '
        'color freely and weight sparingly. The sign-in buttons are the one '
        'exception: SF Pro (Apple) and Roboto (Google), per their brand rules.',
    body: '<table>${rows.join()}</table>',
  );
}

_Card _spacingCard(Map<String, dynamic> tokens) {
  Map<String, dynamic> group(String k) => tokens[k] as Map<String, dynamic>;
  final spacing = group('spacing').entries.map(
        (e) => '<tr><td><code>--space-${_kebab(e.key)}</code></td>'
            '<td>${e.value}px</td><td style="width:320px"><div class="bar" '
            'style="width:${e.value}px"></div></td></tr>',
      );
  final radii = group('radius').entries.map(
        (e) => '<div><div class="box" style="border-radius:'
            'var(--radius-${e.key})"></div><code>--radius-${e.key}</code></div>',
      );
  final shadows = group('shadow').keys.map(
        (k) => '<div><div class="box" style="border:0;border-radius:'
            'var(--radius-md);box-shadow:var(--shadow-$k)"></div>'
            '<code>--shadow-$k</code></div>',
      );
  final sizes = {...group('iconSize'), ...group('size')}.entries.map(
        (e) =>
            '<tr><td><code>--${group('iconSize').containsKey(e.key) ? 'icon' : 'size'}-'
            '${_kebab(e.key)}</code></td><td>${e.value}px</td></tr>',
      );
  return _card(
    path: 'tokens/spacing.html',
    group: 'Spacing & shape',
    title: 'Spacing, radius, elevation, sizes',
    viewport: '1000x1300',
    lede: 'Every gap and inset lands on the spacing scale. Shadows mean '
        '"floats"; everything else is flat. Touch targets are at least 48px.',
    body: '''
<h2 class="text-title-medium">Spacing</h2><table>${spacing.join()}</table>
<h2 class="text-title-medium">Radius</h2><div class="pair">${radii.join()}</div>
<h2 class="text-title-medium">Elevation</h2><div class="pair">${shadows.join()}</div>
<h2 class="text-title-medium">Icons and fixed sizes</h2><table>${sizes.join()}</table>
''',
  );
}

String _refs(String name, {bool light = true, bool dark = true}) {
  String fig(String mode) =>
      '<figure><img src="../references/${name}_$mode.png"'
      ' alt="$name ($mode)"><figcaption class="text-body-small">'
      '${mode[0].toUpperCase()}${mode.substring(1)}</figcaption></figure>';
  return '<div class="pair">${[
    if (light) fig('light'),
    if (dark) fig('dark')
  ].join()}</div>';
}

String _spec(List<String> items) =>
    '<ul class="spec text-body-medium">${items.map((i) => '<li>$i</li>').join()}</ul>';

final List<_Card> _componentCards = [
  _card(
    path: 'guidelines/components/buttons.html',
    group: 'Components',
    title: 'Buttons',
    lede: 'Rendered from the Flutter app. Buttons are 48px tall with '
        '<code>--radius-sm</code> corners and <code>.text-label-large</code> '
        'labels.',
    body: _refs('component_buttons') +
        _spec([
          '<b>Primary</b>: fill <code>--color-primary</code>, text '
              '<code>--color-on-primary</code> — the main action on a screen.',
          '<b>Onboarding CTA</b>: fill <code>--color-secondary</code>, text '
              '<code>--color-on-secondary</code> — on the green onboarding '
              'gradient, where a green button would disappear.',
          '<b>Secondary</b>: transparent, 1px <code>--color-primary</code> '
              'outline and text.',
          '<b>Text</b>: bare <code>--color-primary</code> text; destructive '
              'actions use <code>--color-tertiary</code>.',
          '<b>Disabled</b>: content at 38% opacity on a faint fill.',
        ]),
  ),
  _card(
    path: 'guidelines/components/chips.html',
    group: 'Components',
    title: 'Chips and selection',
    lede: 'Tag chips label facilities; filter chips drive the map; selection '
        'tiles are options inside the filter sheet.',
    body: _refs('component_chips') +
        _spec([
          '<b>Tag chip</b>: color at 12% fill with a 30% outline, '
              '<code>--radius-md</code>, <code>.text-label-small</code> in '
              'the color, optional 14px icon. Eligibility uses '
              '<code>--color-primary</code>, services '
              '<code>--color-tertiary</code>, facility types their '
              '<code>--color-category-*</code>.',
          '<b>Filter chip</b>: <code>--color-card</code> fill, '
              '<code>--color-outline-variant</code> border, '
              '<code>--radius-md</code>, <code>--shadow-card</code>, '
              '<code>.text-label-medium</code>. Selected fills '
              '<code>--color-secondary</code>; locked (guest-only) chips '
              'fade to 38% with a lock icon.',
          '<b>Selection tile</b>: <code>--radius-sm</code>, 1px '
              '<code>--color-outline-variant</code>; selected gets a 2px '
              '<code>--color-primary</code> outline, 12% primary fill, and '
              'primary text.',
        ]),
  ),
  _card(
    path: 'guidelines/components/lists.html',
    group: 'Components',
    title: 'Lists, fields, and dialogs',
    lede: 'Settings-style screens are section headers over cards of rows.',
    viewport: '1000x1100',
    body: _refs('component_lists') +
        _spec([
          '<b>Section header</b>: <code>.text-title-small</code> in '
              '<code>--color-secondary</code>, 0.5px letter spacing.',
          '<b>Card of rows</b>: <code>--color-card</code>, '
              '<code>--radius-md</code>, rows split by 1px '
              '<code>--color-outline-variant</code>. Rows have a 24px '
              '<code>--color-secondary</code> icon, a '
              '<code>.text-body-large</code> title, and trailing values in '
              '<code>.text-body-medium</code> '
              '<code>--color-on-surface-variant</code>.',
          '<b>Switch</b>: on uses <code>--color-primary</code>.',
          '<b>Text field</b>: <code>--color-card</code> fill, 1px outline, '
              '<code>--radius-sm</code>.',
          '<b>Dialog</b>: <code>--color-card</code>, '
              '<code>--radius-xl</code>, <code>.text-title-large</code> '
              'title, actions bottom-right (text, then filled).',
        ]),
  ),
  _card(
    path: 'guidelines/components/facility-card.html',
    group: 'Components',
    title: 'Facility card',
    lede: 'The core unit of the Map list, collapsed and expanded.',
    viewport: '1000x1100',
    body: _refs('component_facility_card') +
        _spec([
          'Fill <code>--color-brand-honeydew</code> in light mode, '
              '<code>--color-card</code> in dark; <code>--radius-md</code>.',
          'Leading 24px category icon on an 18% tint of its '
              '<code>--color-category-*</code>, <code>--radius-sm</code>.',
          'Title <code>.text-title-small</code>; collapsed subtitle '
              '<code>.text-body-small</code> muted, two lines. A heart sits '
              'top-right (<code>--color-status-favorite</code> when saved).',
          'Expanded sections sit between dividers with '
              '<code>.text-title-medium</code> headings: eligibility tags '
              '(primary), service tags (tertiary), then Next steps (20px '
              '<code>--color-tertiary</code> icons, '
              '<code>.text-label-medium</code>) beside Hours '
              '(<code>.text-label-small</code>).',
          'Action links: bold lead-in, then an underlined '
              '<code>--color-tertiary</code> action.',
        ]),
  ),
  _card(
    path: 'guidelines/components/feedback.html',
    group: 'Components',
    title: 'Empty states and sheets',
    lede: 'What people see when a list has nothing in it, and the grab '
        'handle on sheets.',
    body: _refs('component_feedback') +
        _spec([
          '<b>Empty state</b>: centered 48px icon in '
              '<code>--color-on-surface-variant</code>, '
              '<code>.text-title-medium</code> title, '
              '<code>.text-body-medium</code> muted message, optional primary '
              'action; <code>--space-xxxl</code> padding.',
          '<b>Coverage notice</b>: 16px info icon with '
              '<code>.text-body-small</code> at 70% of '
              '<code>--color-on-surface</code>.',
          '<b>Sheet</b>: <code>--color-card</code>, top corners '
              '<code>--radius-xl</code>, a 40×4 pill handle at 20% of '
              '<code>--color-on-surface</code>.',
        ]),
  ),
  _card(
    path: 'guidelines/components/navigation.html',
    group: 'Components',
    title: 'App bar and tab bar',
    lede: 'Four tabs, always in this order.',
    viewport: '1000x600',
    body: _refs('component_navigation') +
        _spec([
          '<b>App bar</b>: <code>--color-background</code>, no shadow, '
              'centered <code>.text-title-large</code> title.',
          '<b>Tab bar</b>: Home, Map, Profile, Settings on '
              '<code>--color-nav-bar</code>; 24px icons; labels 12px; the '
              'active tab is <code>--color-brand-bittersweet</code>, others '
              '<code>--color-on-surface-variant</code>.',
        ]),
  ),
];

final List<_Card> _screenCards = [
  _card(
    path: 'guidelines/screens/sign-in.html',
    group: 'Screens',
    title: 'Sign in',
    lede: 'One sign-in provider per platform: Apple on iOS, Google on '
        'Android — never both. (The 🌐 after "Select a language" shows on '
        'devices; the render tool has no emoji font.)',
    viewport: '1000x900',
    body: '''
<div class="pair phone">
<figure><img src="../references/screen_login_ios_light.png" alt="iOS light"><figcaption class="text-body-small">iOS</figcaption></figure>
<figure><img src="../references/screen_login_light.png" alt="Android light"><figcaption class="text-body-small">Android</figcaption></figure>
<figure><img src="../references/screen_login_ios_dark.png" alt="iOS dark"><figcaption class="text-body-small">iOS, dark</figcaption></figure>
</div>''',
  ),
  for (final (file, title, name, lede) in const [
    (
      'location-choice',
      'Location choice',
      'screen_location_choice',
      'Onboarding screens sit on <code>--gradient-onboarding</code> with '
          '<code>--space-onboarding-gutter</code> margins and '
          '<code>.text-headline-medium</code> titles in '
          '<code>--color-secondary</code>.',
    ),
    (
      'zip-entry',
      'ZIP entry',
      'screen_zip_entry',
      'The onboarding CTA fills <code>--color-secondary</code>.',
    ),
    (
      'eligibility',
      'Eligibility onboarding',
      'screen_eligibility_onboarding',
      'A card of switch rows between the title and the CTA.',
    ),
    (
      'settings',
      'Settings',
      'screen_settings',
      'Section headers over cards of rows.',
    ),
    (
      'profile-guest',
      'Profile (guest)',
      'screen_profile_guest',
      'Guests see a sign-in prompt instead of their account.',
    ),
  ])
    _card(
      path: 'guidelines/screens/$file.html',
      group: 'Screens',
      title: title,
      lede: lede,
      viewport: '1000x900',
      body: '<div class="pair phone">'
          '<figure><img src="../references/${name}_light.png" alt="light">'
          '<figcaption class="text-body-small">Light</figcaption></figure>'
          '<figure><img src="../references/${name}_dark.png" alt="dark">'
          '<figcaption class="text-body-small">Dark</figcaption></figure>'
          '</div>',
    ),
  _card(
    path: 'guidelines/screens/home-and-map.html',
    group: 'Screens',
    title: 'Home and Map',
    lede: 'Captured on device (Home: Pixel 10 Pro; Map: iPhone 17 Pro). The '
        'map is Google Maps with a floating <code>--radius-pill</code> '
        'search bar, a row of filter chips, a sliding results panel with '
        '<code>--radius-xl</code> top corners and '
        '<code>--shadow-sheet</code>, and a single-facility card when a pin '
        'is tapped.',
    viewport: '1300x900',
    body: '''
<div class="pair phone">
<figure><img src="../references/home_light.png" alt="Home light"><figcaption class="text-body-small">Home</figcaption></figure>
<figure><img src="../references/home_dark.png" alt="Home dark"><figcaption class="text-body-small">Home, dark</figcaption></figure>
<figure><img src="../references/map_dark.png" alt="Map dark"><figcaption class="text-body-small">Map, dark</figcaption></figure>
<figure><img src="../references/map_facility_dark.png" alt="Map facility"><figcaption class="text-body-small">Map, pin selected</figcaption></figure>
</div>''',
  ),
];

// --- README ----------------------------------------------------------------

String _guidelinesIndex(List<_Card> cards) {
  final lines = cards
      .where((c) => c.path.startsWith('guidelines/'))
      .map((c) => '- `${c.path.substring('guidelines/'.length)}` — '
          '${c.title} (${c.group})');
  return '# Guidelines\n\nReference cards rendered from the Flutter app.\n\n'
      '${lines.join('\n')}\n';
}

String _readme(List<_Card> cards) {
  final header =
      File('.design-sync/conventions.md').readAsStringSync().trimRight();
  final index = cards.map((c) => '- `${c.path}` — ${c.title}').join('\n');
  return '''
$header

## Where things are

- `styles.css` — the one stylesheet to link; imports `tokens/tokens.css`,
  Inter (`fonts/`), and Material Icons.
- `tokens/tokens.css` / `tokens/tokens.json` — every token, generated from the
  Flutter app's `lib/core/theme/`. Dark roles apply under
  `data-theme="dark"`.
- Cards:
$index
''';
}

// --- Checks ----------------------------------------------------------------

void _validate(List<_Card> cards) {
  final css = File('$_out/tokens/tokens.css').readAsStringSync();
  final defined =
      RegExp('(--[a-z0-9-]+):').allMatches(css).map((m) => m[1]!).toSet();
  final classes =
      RegExp(r'\.(text-[a-z-]+) \{').allMatches(css).map((m) => m[1]!).toSet();
  final problems = <String>[];

  void check(String where, String text) {
    for (final m in RegExp('--[a-z0-9]+(?:-[a-z0-9]+)*').allMatches(text)) {
      // A family written as "--color-category-*" is a pattern, not a name.
      final rest = text.substring(m.end);
      if (rest.startsWith('-*') || rest.startsWith('*')) continue;
      if (!defined.contains(m[0])) problems.add('$where: unknown ${m[0]}');
    }
    for (final m in RegExp(r'\.(text-[a-z]+(?:-[a-z]+)*)').allMatches(text)) {
      if (!classes.contains(m[1])) problems.add('$where: unknown .${m[1]}');
    }
    for (final m in RegExp('src="([^"]+)"').allMatches(text)) {
      final ref = File(
        Uri.file('$_out/$where').resolve(m[1]!).toFilePath(),
      );
      if (!ref.existsSync()) problems.add('$where: missing ${m[1]}');
    }
  }

  for (final card in cards) {
    if (!card.html.startsWith('<!-- @dsCard group="')) {
      problems.add('${card.path}: first line is not a @dsCard marker');
    }
    check(card.path, card.html);
  }
  check('README.md', File('$_out/README.md').readAsStringSync());

  if (problems.isNotEmpty) {
    stderr.writeln(problems.join('\n'));
    exit(1);
  }
}
