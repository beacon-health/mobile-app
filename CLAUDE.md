# Beacon — working agreements for agents

Flutter app (iOS + Android) for finding free and low-cost healthcare and social
services. This file loads into every Claude Code session, so it holds **rules
and traps only**. Facts and procedures have one home each — read the relevant
section before working in that area:

- `README.md` — architecture, setup, backend, testing, CI/CD, releases,
  signing, monitoring, troubleshooting
- `design/README.md` — design tokens, components, and the Claude Design export

**Every PR: re-read the README sections your change touches and update them in
the same PR**, and this file too. Both hold only what stays true — no one-time
setup walkthroughs, launch status, or anything else that expires once it's done.

**This repository is public.** Keep cloud project IDs and numbers, account and
service-account names, user or device data, user counts, store-review
correspondence, tester quotes, and security specifics out of code, comments,
commits, PR text, and docs.

## Workflow

- **Never commit to `main`** (a local `pre-push` hook blocks it). Branch as
  `feat/`, `fix/`, `chore/`, or `docs/`, push, and open a PR with `gh pr create`.
- Commit style follows history: `feat: …`, `fix: …`, `chore: …`. Push as
  **Rohan-50**; never commit as `beacon-health` (the org account). Never
  force-push a shared branch.
- Fixing a Sentry issue? Put `Fixes BEACON-<n>` in the commit message.
- **Merges ship builds** to Play internal and TestFlight (README → CI/CD):
  merge related PRs in one sitting.

## Before opening a PR

```bash
dart format .
flutter analyze --fatal-infos
flutter test
```

- PR CI never builds iOS. For native iOS changes (plugin bumps, Podfile, Xcode
  settings), also run `flutter build ios --release --no-codesign`.
- Flutter is pinned to 3.47.0 in all three workflows; bump them together and
  match locally.
- **A dependency bump can add Android permissions**, and Play can refuse the
  upload over them. CI runs `tool/check_android_permissions.sh` after the
  debug build. When it fails, add the permission to `android/permissions.txt`
  only if Beacon uses it; otherwise remove it in the app manifest with
  `tools:node="remove"` (README → CI/CD).
- Changed a screen, navigation, or the map? Run it on an iOS simulator **and**
  an Android emulator, and press Android's back button from wherever you
  changed. Tests can't see what only a device shows.

## Running

- Use `make run`. A bare `flutter run` crashes on startup by design — the
  Supabase dart-defines are missing.
- iOS uses **CocoaPods, not SPM**: open `ios/Runner.xcworkspace`, never the
  `.xcodeproj` (README → Prerequisites).

## Secrets — never read, print, or commit

| File | Holds |
|---|---|
| `config/dart_defines.json` | Supabase URL + anon key, Sentry DSN, Google Web client ID |
| `ios/Flutter/Secrets.xcconfig` | Google Maps iOS key |
| `sentry.properties` | Sentry auth token |
| `android/local.properties` | Google Maps Android key |
| `android/key.properties` | Upload keystore path + passwords |

To check whether a key is *set*, list key names, never values.
`.claude/settings.json` denies reading these, and
`.claude/hooks/block-secret-reads.sh` blocks any shell command that names one
alongside a reader (`cat`, `grep`, `sed`, `head`, …) — even when the command
only lists key names or merely mentions the file in a string. Split such
commands, or make text edits with the file tools instead of the shell.

## Code rules (CI or review will catch these)

- No `print` / `debugPrint`: every catch site calls
  `ErrorReporter.instance.report(e, stack, context: 'WhereItHappened')`.
- **Report bugs, not user choices** — expected outcomes return a status
  (README → Key services has the one Google sign-in exception).
- No hardcoded user-facing strings: add the key to all three ARB files in
  `lib/l10n/`, then `make l10n`.
- Gate every Supabase write on `GuestModeService.isGuest` and call
  `showSignInPromptDialog(context)`. Read the session through
  `GuestModeService` (`isGuest`, `currentUser`), never `Supabase.instance` in
  a widget — it is also what tests sign in through.
- Never auto-query facilities on map pan, and never load-and-filter on device
  (README → Architecture).
- **Never hardcode a state or a list of states.** Coverage comes from
  `CoverageService`, which follows `launched_states`.
- **The Ask tab's model only picks filters** (README → Architecture). Never
  show text it generated, never send a request anywhere but the on-device
  bridge, and keep `CrisisKeywords` independent of it. A new filter id goes in
  `AskRequest`, `AskPrompts`, and the Swift struct together;
  `platform_config_test.dart` checks they agree.
- **Tabs and map overlays are not routes**, so Android's back button doesn't
  close them on its own. Anything new that opens over a tab without being a
  route joins the chain in `MapPageState.handleBack()` / `mapBackTarget`, with
  a `pressBack` test (README → Architecture).
- `FacilityCategories` is the single source of truth for the taxonomy,
  `FacilityFilterService.eligibilityGates` for what the "what can you provide"
  answers hide, and `EligibilityChecklist` for how the question is worded.
- One sign-in provider per platform: the rule lives only in
  `nativeSignInProviderFor`, and every sign-in surface uses `NativeSignInButton`.
- Anything else that differs by platform goes in a function that takes the
  platform (as `MapLauncherService.appsFor` does) so both sides are tested. If
  it relies on a native declaration (`<queries>`, `Info.plist`), add the pair
  to `test/core/config/platform_config_test.dart`.
- **Style with design tokens, never literals** — import
  `package:beacon_app/core/theme/theme.dart`, and reuse `TagChip`,
  `SectionHeader`, `EmptyState`, `DragHandle` before writing new widgets.
  `test/design_system_lint_test.dart` fails on hardcoded colors, sizes, radii,
  padding, gaps, alphas, or shadows.
- Changed a token? Run `flutter test test/design_tokens_test.dart
  --update-goldens` and commit the regenerated `design/tokens.*`.
- Changed tokens or a component's look? The Claude Design project is now
  stale: rebuild with `dart run tool/build_design_bundle.dart` and re-sync
  (`.design-sync/NOTES.md`).
- `require_trailing_commas` is off; let `dart format` own line breaks.

## Accessibility (README → Accessibility)

- **Text colors:** brand colors are for fills and icons. Text takes
  `colorScheme.primaryText` / `tertiaryText`, destructive actions `error`
  (`AppTheme.destructiveTextButton`). New pairings go in
  `test/core/theme/contrast_test.dart`.
- **No fixed heights around text**, and nothing tappable under 48×48: use
  `minHeight` / `AppSizes.minTouchTarget`. A new screen joins
  `test/accessibility/large_text_test.dart`.
- **Icon-only controls get a `tooltip`** that names what they act on ("Save
  CARPLS"), and state shows in shape as well as color.
- **Animations take `AppMotion.of(context, …)`**; camera moves go through the
  page's reduced-motion helper.
- A control that needs an account stays full-contrast with a lock and opens
  the sign-in prompt. Never disable it.

## Tests

- Use `createTestFacility(...)`, `pumpThemed(...)`, and
  `mockPlatformServices()` from `test/helpers/`. Fake plugins through their
  method channels — don't add mocking packages.
- Test Home, Map, and anything about navigation through the real shell:
  `pumpAppShell` with `FakeFacilityRepository` and `FakeGoogleMaps`, and
  `pressBack(tester)` for Android's back button (README → Testing).
- **Never generate goldens locally.** They're canonical on Linux and skip on
  macOS (glyph rasterization differs). After an intentional visual change:
  push, let CI fail, review the `golden-failures` diffs, then run
  `tool/update_goldens_from_ci.sh` (README → Testing).

## Database

**Ask before changing anything database-side.** Schema changes are applied by
hand in the Supabase SQL Editor and aren't tracked here. Every user table needs
RLS with `using (auth.uid() = user_id)` **and** a matching `with check`
(README → Backend).
