# Beacon

A Flutter app that helps people find free and low-cost healthcare and
social-services facilities near them — clinics, mental health and addiction
services, housing and shelter, food assistance, and more.

The facility dataset is nationwide (~144k geocoded facilities), but the public
launch is **gated to one state at a time** (Illinois first) via a server-side
allow-list, so new states go live with a single SQL `insert` and no app release.

| | |
|---|---|
| **Platform** | iOS shipping; Android in bring-up — MVP is a simultaneous launch on both |
| **Flutter / Dart** | 3.47.0 stable / 3.13.0 (SDK constraint `^3.6.0`) |
| **Backend** | Supabase — Postgres + PostGIS, RLS, Apple OAuth |
| **State management** | `provider` + `ChangeNotifier` singletons |
| **Maps** | `google_maps_flutter` (Maps SDK for iOS) |
| **Languages** | English, Spanish, Chinese |
| **Bundle ID** | `org.beaconhealth.app` |

---

## Prerequisites

- **Flutter 3.47.0** (stable channel) — check with `flutter --version`. Match
  this exactly: both CI workflows pin it, and a newer analyzer will fail the
  build with no code change.
- **Xcode 15+** with the iOS 15.0+ SDK, and CocoaPods (`brew install cocoapods`)
- **JDK 17** and the Android SDK, for Android builds
- Access to the **Supabase project** (URL + publishable anon key)
- **Two Google Maps API keys** — one restricted to iOS + the Maps SDK for iOS,
  one restricted to Android + the Maps SDK for Android. They are separate APIs;
  a single key cannot serve both.

> CocoaPods needs a UTF-8 locale. If `pod install` dies with
> `Encoding::CompatibilityError` in `unicode_normalize`, your shell has `LANG`
> unset — export `LANG=en_US.UTF-8` and retry.

> This project uses **CocoaPods, not Swift Package Manager**. If you have SPM
> enabled globally in Flutter, turn it off for this repo
> (`flutter config --no-enable-swift-package-manager`) or the iOS build will try
> to re-migrate the plugins.

---

## Getting started

```bash
git clone https://github.com/beacon-health/mobile-app.git
cd mobile-app
flutter pub get
```

**1. Add the Google Maps key** (gitignored — never commit it):

```bash
echo "GOOGLE_MAPS_API_KEY=<your-ios-maps-key>" > ios/Flutter/Secrets.xcconfig
```

**2. Install the iOS pods:**

```bash
cd ios && pod install && cd ..
```

**3. Run**, injecting the Supabase credentials at build time:

```bash
flutter run --dart-define=SUPABASE_URL=https://<project>.supabase.co --dart-define=SUPABASE_ANON_KEY=<publishable-key>
```

The app **throws on startup** if `SUPABASE_URL` or `SUPABASE_ANON_KEY` is
missing — that's deliberate, so a misconfigured build fails loudly instead of
silently showing an empty map.

Optionally add `--dart-define=SENTRY_DSN=<dsn>` for crash reporting. Sentry only
initializes in **release** builds with a DSN present, so debug runs never send
events.

To avoid retyping the defines, put them in a JSON file and use
`--dart-define-from-file=config/dart_defines.json` (that path is gitignored).

> Always open **`ios/Runner.xcworkspace`** in Xcode, never `Runner.xcodeproj`.

---

## Project structure

```
lib/
  main.dart                    Entry point: service init, Supabase, Sentry
  app.dart                     MaterialApp, providers, routing
  core/
    constants/                 Routes, legal URLs
    services/                  App-wide singletons (see "Key services")
    theme/                     AppTheme, colors, gradients
    utils/                     Formatting helpers
    widgets/                   Shared dialogs, sign-in button, gates
  features/
    auth/                      Onboarding, login, ZIP entry, AuthGate
    home/                      Home page, quick actions, nav bar
    map/
      constants/               Map + filter + category constants
      data/                    Repository + Supabase facility service
      domain/models/           Facility, eligibility, hours
      presentation/            Map page, filters, cards, markers
    profile/                   Profile tab (account, ratings, eligibility)
    settings/                  Settings, "Your Ratings", "Your Requests"
  l10n/                        ARB files (en/es/zh) + generated localizations
test/                          Unit tests mirroring lib/
```

### Architecture at a glance

**Entry flow:** `AuthGate` → `OnboardingPage` → `LoginPage` (Apple / guest) →
`LocationChoicePage` (GPS or ZIP) → eligibility step (signed-in only) →
`MainNavBar`. Returning users go straight to `MainNavBar`; the
`hasCompletedOnboarding` flag in `SharedPreferences` decides.

**Guest mode is a first-class state.** `GuestModeService.isGuest` is derived
from the Supabase session. Guests can browse, search, and get directions;
Favorites, ratings, requests, and the whole Profile tab are gated by checking
`isGuest` and calling `showSignInPromptDialog(context)`. When adding a feature
that writes to Supabase, gate it — RLS will reject anonymous writes anyway, and
a sign-in prompt is a far better experience than a silent failure.

**Facility queries are server-side and bounded.** `SupabaseFacilityService`
calls the PostGIS `facilities_near` RPC with a lat/lng + radius, capped at 250
rows, with a quantized per-region in-memory cache. The map deliberately **does
not auto-query on pan** — the user taps "Search this area". Don't reintroduce
load-everything-and-filter-on-device; the table is far too large for it.

**Nav pages live in an `IndexedStack`** and keep state alive, so `initState`
runs once. Pages that must react to changes made elsewhere (Settings editing the
ZIP, Profile editing eligibility) subscribe to the relevant service in
`initState` and re-filter on notify.

### Key services

All are `ChangeNotifier` singletons in `lib/core/services/`, initialized in
`main.dart` before `runApp`.

| Service | Responsibility |
|---|---|
| `GuestModeService` | Tracks signed-in vs guest from the Supabase session |
| `AppleSignInService` | Native Sign in with Apple → `signInWithIdToken` |
| `ZipCodeService` | ZIP ↔ coordinates, GPS toggle, onboarding flag |
| `EligibilityPreferencesService` | Eligibility gates + map preferences; auto-applies to search |
| `UserSettingsService` | Mirrors settings to the `user_settings` Supabase row |
| `UserFavoritesService` | Favorites sync, region-independent |
| `FacilityFeedbackService` | Ratings: read / upsert / delete |
| `FacilityRequestService` | New-facility requests and correction submissions |
| `RecentFacilitiesService` | Last 3 viewed facilities, persisted locally |
| `MapLauncherService` | Directions chooser (Apple / Google / Waze) + remembered choice |
| `ErrorReporter` | `developer.log` in debug, Sentry in release |

**Error handling convention:** never `print` or `debugPrint`. Every catch site
calls `ErrorReporter.instance.report(e, stack, context: 'WhereItHappened')`.

---

## Backend

Supabase Postgres with PostGIS. The app talks to:

| Object | Purpose |
|---|---|
| `FCT_Supabase` | Facility master table (geocoded, `geom` + GiST index) |
| `DM_Supabase_Eligibility` | Per-facility eligibility attributes |
| `fct_supabase_full` | View joining the two — used for favorites and single-facility lookups by id |
| `facilities_near(...)` | PostGIS RPC — bounded, distance-sorted proximity search; enforces the state allow-list |
| `launched_states` | Allow-list gating which states are live |
| `user_favorites`, `user_settings`, `facility_feedback`, `facility_requests` | Per-user data, all protected by owner-only RLS |

Every user table has RLS with `using (auth.uid() = user_id)` **and** a matching
`with check` clause — omitting `with check` makes inserts fail with a 42501.

**Categories** come from `category_broad` (13 values, the filter dimension) and
`category_detail` (21 values, searchable). `FacilityCategories` is the single
source of truth: it maps the 13 broad values into the 6 Home quick-action
groups, each with its own marker icon and color, plus a neutral fallback used
only for unknown/null values. If the database taxonomy changes, update that
file — tests assert both the value count and full group coverage, so drift
fails CI.

> **Schema and migrations are applied by hand** through the Supabase SQL Editor;
> there is no migration tool in this repo, and the DDL is not tracked here.
> Ask the project owner for the current schema reference before changing
> anything that touches the database.

---

## Development

```bash
flutter analyze                       # must be clean — CI runs --fatal-infos
flutter test                          # unit tests
dart format .                         # CI fails on unformatted code
```

**Linting** is `very_good_analysis` with a few rules relaxed in
`analysis_options.yaml`. Note that `require_trailing_commas` is **off**: it
fights Dart 3.7+'s "tall style" formatter, which owns line breaking.

### Localization

User-facing strings must never be hardcoded. Add the key to **all three** ARB
files in `lib/l10n/` (`app_en.arb`, `app_es.arb`, `app_zh.arb`), then:

```bash
flutter gen-l10n
```

Use it as `AppLocalizations.of(context)!.yourKey`. The three files must stay at
identical key counts.

**Deliberately not translated:** facility names, descriptions, and services
(database content), and rating tag phrases (stored verbatim in the `comment`
column, so translating them would break round-tripping).

### Testing

Tests live in `test/`, mirroring `lib/`. Use `createTestFacility(...)` from
`test/helpers/test_facility.dart` to build fixtures rather than hand-rolling
`Facility` objects. Coverage is currently unit-level — services, models,
filtering, and the category taxonomy. Widget tests need a Supabase mock and are
a known gap.

---

## CI/CD

| Workflow | Trigger | Does |
|---|---|---|
| `.github/workflows/ci.yml` | push / PR to `main` | format check, `flutter analyze --fatal-infos`, `flutter test` |
| `.github/workflows/ios-build.yml` | push to `main` (docs ignored), or manual | builds and uploads to TestFlight via Fastlane |

TestFlight uses **App Store Connect API-key cloud-managed signing** — no
Fastlane Match, no certificates repo. The API key must have **App Manager**
access so Xcode can create the distribution certificate and provisioning profile
at build time. The build number is `1000 + github.run_number`, so uploads never
collide.

Required GitHub secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`GOOGLE_MAPS_API_KEY`, `SENTRY_DSN`, `APP_STORE_CONNECT_API_KEY_ID`,
`APP_STORE_CONNECT_API_KEY_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_CONTENT`.

---

## Troubleshooting

**The map renders as a uniform grey rectangle.** Almost always Google Maps
billing, not code — the SDK logs success and silently returns blank tiles. Check
Google Cloud → Billing, and that "Maps SDK for iOS" is enabled.

**Startup throws about `SUPABASE_URL`.** You ran `flutter run` without the
`--dart-define` flags. See "Getting started".

**Ratings or requests fail to submit.** A required table, column, or unique
constraint hasn't been applied to the Supabase project. A 42501 specifically
means an RLS policy is missing its `with check` clause.

**No facilities appear anywhere.** Either the state you're searching isn't in
`launched_states`, or you're outside the fixed 5-mile radius. Illinois ZIPs
(e.g. `60613`) are the reliable test case.

**Pod or build errors after pulling.** `cd ios && pod install`. If Xcode starts
converting plugins to Swift Package Manager, disable SPM (see Prerequisites).

**Every marker is a neutral grey pin and the Category filter matches nothing.**
The `fct_supabase_full` view and the `facilities_near` RPC aren't returning
`category_broad` / `category_detail`. Both must expose those columns.
