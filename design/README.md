# Beacon design system

The Flutter code is the source of truth. Tokens live in `lib/core/theme/`
(import everything with `package:beacon_app/core/theme/theme.dart`); this folder
holds a generated, platform-neutral copy for Claude Design and other tools that
can't read Dart.

| File | What it is |
|---|---|
| `tokens.json` | Every token value, light and dark color roles included. **Generated.** |
| `tokens.css` | The same tokens as CSS custom properties, `.text-*` type classes, and `@font-face` for Inter. **Generated.** |

Both are rebuilt from the Dart tokens and checked in CI:

```bash
flutter test test/design_tokens_test.dart --update-goldens   # regenerate
flutter test test/design_tokens_test.dart                    # what CI runs
```

Never edit the generated files by hand. Change the Dart token, regenerate, and
commit both together.

## Tokens

| Group | Dart | CSS prefix | Notes |
|---|---|---|---|
| Brand + category colors | `AppColors` | `--color-brand-*`, `--color-category-*` | Category colors double as map pins and stay fixed across modes. |
| Semantic color roles | `Theme.of(context).colorScheme` | `--color-*` | Light mode uses the brand colors verbatim: primary = reseda green, secondary = Payne's gray, tertiary = bittersweet. Dark mode uses lighter tonal variants of the same hues, which stay legible on navy. |
| Opacity | `AppOpacity`, `.tint` / `.tintStrong` / `.tintBorder`, `ColorSchemeExt` | `--opacity-*` | Tinted chips, selected states, muted text. |
| Spacing | `AppSpacing` (`xxs` 2 → `huge` 48) | `--space-*` | Plus `pageGutter` 16, `onboardingGutter` 24, `sheetGutter` 20. |
| Radius | `AppRadii` (`sm` 8, `md` 12, `lg` 16, `xl` 20, `pill`) | `--radius-*` | sm: controls. md: cards and chips. lg: large cards. xl: sheets and dialogs. |
| Shadow | `AppShadows.card` / `raised` / `sheet` | `--shadow-*` | A shadow means "floats", never decoration. |
| Type | `Theme.of(context).textTheme.<role>` | `.text-<role>` | Inter, 10 roles; see the table in `app_typography.dart`. |
| Icons, sizes, motion | `AppIconSize`, `AppSizes`, `AppMotion` | `--icon-*`, `--size-*`, `--motion-*` | 48dp minimum touch target on both platforms. |

## Components

Build from these before writing a new widget:

| Widget | Use |
|---|---|
| `TagChip` | Tinted label: services, eligibility attributes, request status |
| `SectionHeader` | Group label above a card of settings rows |
| `EmptyState` | Icon + title + message (+ optional action) for an empty page |
| `DragHandle` | Grab handle for custom sheets and panels |
| `CustomFilterChip`, `SelectionTile` | Map filter bar pills and filter-modal options |
| `NativeSignInButton` | The only sign-in button; Apple on iOS, Google on Android |
| `AppTheme.secondaryFilledButton` | Payne's-gray CTA used on the green onboarding gradient |

Buttons, cards, inputs, dialogs, sheets, switches, list tiles, and the nav bar
are styled through the theme. Use the stock Material widget and don't restyle
it per call site.

## iOS and Android

Everything visual is pinned in `AppTheme` so both platforms render the same
design:
- One bundled typeface (Inter 4.1, OFL). Canvas-drawn map marker labels set it
  explicitly.
- The same typography base, ink ripple, visual density, and centered app-bar
  titles.
- Status- and navigation-bar icons follow the in-app theme, not the OS setting.

Two things stay native on purpose:
- **Navigation behavior:** page transitions, iOS back-swipe, and scroll physics
  (iOS bounce, Android stretch).
- **Sign-in buttons:** they use the platform font (SF Pro for Apple, Roboto for
  Google), because each brand's guidelines require it.

Chinese text falls back to each platform's CJK font.

## Enforcement

`test/design_system_lint_test.dart` fails CI on any of these outside
`lib/core/theme/`:
- hex colors
- Material palette colors other than white, black, and transparent
- literal font sizes, radii, padding, gaps, and alphas
- hand-rolled `BoxShadow`s

Each failure names the token to use instead.

## Claude Design

Claude Design builds with React/HTML, so it can't run these Flutter widgets.
Its design-system project ("Beacon Design System") holds the tokens, Inter,
the design agent's instructions (`.design-sync/conventions.md`), and
reference cards rendered from the real widgets and screens. Build it with
`dart run tool/build_design_bundle.dart`; `.design-sync/NOTES.md` covers
uploading and what can go stale.

1. **Design → code:** mock the screen in Claude Design against the project,
   then hand the link to Claude Code to rebuild it in Flutter with the same
   tokens.
2. **Code → Design:** when a PR changes `lib/core/theme/` or a component's
   look, rebuild the bundle and re-sync the project.
