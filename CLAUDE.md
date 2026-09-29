# Beacon — working agreements for agents

Flutter app (iOS + Android) for finding free and low-cost healthcare and social
services. This file loads into every Claude Code session, so it holds **rules
and traps only**. Facts and procedures have one home each — read the relevant
section before working in that area:

- `README.md` — architecture, setup, backend, testing, CI/CD, releases,
  signing, monitoring, troubleshooting
- `design/README.md` — design tokens, components, and the Claude Design export

If you find this file or the README out of date, fix it in the same PR.

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
  `showSignInPromptDialog(context)`.
- Never auto-query facilities on map pan, and never load-and-filter on device
  (README → Architecture).
- `FacilityCategories` is the single source of truth for the taxonomy.
- One sign-in provider per platform: the rule lives only in
  `nativeSignInProviderFor`, and every sign-in surface uses `NativeSignInButton`.
- **Style with design tokens, never literals** — import
  `package:beacon_app/core/theme/theme.dart`, and reuse `TagChip`,
  `SectionHeader`, `EmptyState`, `DragHandle` before writing new widgets.
  `test/design_system_lint_test.dart` fails on hardcoded colors, sizes, radii,
  padding, gaps, alphas, or shadows.
- Changed a token? Run `flutter test test/design_tokens_test.dart
  --update-goldens` and commit the regenerated `design/tokens.*`.
- `require_trailing_commas` is off; let `dart format` own line breaks.

## Tests

- Use `createTestFacility(...)`, `pumpThemed(...)`, and
  `mockPlatformServices()` from `test/helpers/`. Fake plugins through their
  method channels — don't add mocking packages.
- **Never generate goldens locally.** They're canonical on Linux and skip on
  macOS (glyph rasterization differs). After an intentional visual change:
  push, let CI fail, review the `golden-failures` diffs, then run
  `tool/update_goldens_from_ci.sh` (README → Testing).

## Database

**Ask before changing anything database-side.** Schema changes are applied by
hand in the Supabase SQL Editor and aren't tracked here. Every user table needs
RLS with `using (auth.uid() = user_id)` **and** a matching `with check`
(README → Backend).
