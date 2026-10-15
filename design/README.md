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
| Brand + category colors | `AppColors` | `--color-brand-*`, `--color-category-*` | Map pins keep one color in both modes. As icons and labels, four category tones lighten in dark mode (`MarkerUtils.getColorForCategory(group, brightness:)`). |
| Semantic color roles | `Theme.of(context).colorScheme` | `--color-*` | Light mode uses the brand colors verbatim: primary = reseda green, secondary = Payne's gray, tertiary = bittersweet. Dark mode uses lighter tonal variants of the same hues, which stay legible on navy. |
| Roles Material has no slot for | `ColorSchemeExt` on the scheme | `--color-primary-text`, `--color-tertiary-text`, `--color-facility-card`, `--color-nav-indicator`, `--color-focus-ring`, `--color-scrim` | See "Color roles" below. |
| Opacity | `AppOpacity`, `.tint` / `.tintStrong` / `.tintBorder`, `ColorSchemeExt` | `--opacity-*` | Tinted chips, selected states, muted text. |
| Spacing | `AppSpacing` (`xxs` 2 → `huge` 48) | `--space-*` | Plus `pageGutter` 16, `onboardingGutter` 24, `sheetGutter` 20. |
| Radius | `AppRadii` (`sm` 8, `md` 12, `lg` 16, `xl` 20, `pill`) | `--radius-*` | sm: controls. md: cards and chips. lg: large cards. xl: sheets and dialogs. |
| Shadow | `AppShadows.card` / `raised` / `sheet` | `--shadow-*` | A shadow means "floats", never decoration. |
| Type | `Theme.of(context).textTheme.<role>` | `.text-<role>` | Inter, 10 roles plus the tab label; see the table in `app_typography.dart`. Nothing under 11pt. |
| Icons, sizes, motion | `AppIconSize`, `AppSizes`, `AppMotion` | `--icon-*`, `--size-*`, `--motion-*` | 48dp minimum touch target on both platforms. Durations go through `AppMotion.of(context, …)`, which is zero when the OS asks for reduced motion. |

### Color roles

Each color has one job. Where two look alike, this is the difference:

| Color | Job | Not for |
|---|---|---|
| Bittersweet (`tertiary`) | Fills and icons: the Food & Essentials category, the active tab's pill | Text (2.7:1 on white), anything destructive |
| `tertiaryText` | Inline links, the active tab label, chip text | Fills |
| Reseda green (`primary`) | Filled buttons, selected outlines, icons | Text on the onboarding gradient (3.5:1) |
| `primaryText` | Text buttons, outlined-button labels, selected options, chip text | Fills |
| `error` | Destructive actions and error text | Links |
| `AppColors.favorite` | The filled heart, and nothing else | — |
| Payne's gray (`secondary`) | Headings, section headers, row icons, the focus ring | — |
| `AppColors.userLocation` | The "use my location" control: the platform's location blue, matching the map's dot | — |
| `AppColors.googleBlue` | Google's mark | — |

The three gutters are deliberate: `pageGutter` (16) for tabbed pages,
`sheetGutter` (20) inside sheets, `onboardingGutter` (24) on the full-bleed
onboarding screens.

**Dark mode is navy, on purpose**, not a darkened Payne's gray: the map's dark
style is navy, and the app's surfaces match it. Surfaces step up in lightness
as they rise — page, card, tab bar — and cards take a hairline outline
(`colorScheme.cardOutline`), because a shadow can't be seen there.

When the OS asks for more contrast, `MaterialApp` switches to
`AppTheme.highContrastLightTheme` / `highContrastDarkTheme`, in which every
outline steps up to the next stronger tone.

## Components

Build from these before writing a new widget:

| Widget | Use |
|---|---|
| `TagChip` | Tinted label: services, eligibility attributes, request status. Its color is its text color, so pass a `*Text` role |
| `SectionHeader` | Group label above a card of settings rows, with an optional note |
| `EligibilityChecklist` | "What can you provide?" — the one wording of it, for onboarding and Profile |
| `OnboardingScaffold`, `OnboardingHeading` | The frame of an onboarding step: gradient, back, step count |
| `CategoryIcon` | A category's icon on its tinted tile, in the tone for the current mode |
| `EmptyState` | Icon + title + message (+ optional action) for an empty page |
| `DragHandle` | Grab handle for custom sheets and panels |
| `CustomFilterChip`, `SelectionTile` | Map filter bar pills and the filter sheet's category options |
| `BeaconLogo` | The wordmark, in brand colors on light and white on dark. No tagline in the artwork: that is the `brandTagline` string |
| `AppleMark` | Apple's logo, for the sign-in button and the Profile badge; never `Icons.apple` |
| `DashedVerticalDivider` | A light dashed rule between columns of one list (the two halves of a week's hours) |
| `NativeSignInButton` | The only sign-in button; Apple on iOS, Google on Android, each in its brand's light and dark style |
| `AppTheme.destructiveTextButton` / `destructiveFilledButton` | Deleting an account, removing a rating |
| `FocusRingBorder` | The ring a button draws while it holds keyboard focus (applied by the theme) |

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

Chinese text falls back to each platform's Simplified Chinese font, named in
`AppTypography.fontFamilyFallback`, and gets taller lines
(`AppTheme.adapted`).

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
