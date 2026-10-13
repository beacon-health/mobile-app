# Beacon

A Flutter app that helps people find free and low-cost healthcare and
social-services facilities near them — clinics, mental health and addiction
services, housing and shelter, food assistance, and more.

The facility dataset is nationwide (~144k geocoded facilities), but only
**launched states** are served. A server-side allow-list gates the data, and the
app reads the same list to name the covered states and to check ZIP codes, so a
new state goes live with a single SQL `insert` and no app release.

| | |
|---|---|
| **Platform** | iOS (App Store) and Android (Google Play) |
| **Flutter / Dart** | 3.47.0 stable / 3.13.0 (SDK constraint `^3.6.0`) |
| **Android toolchain** | Gradle 8.14.5 · AGP 8.11.1 · Kotlin 2.2.20 |
| **Backend** | Supabase — Postgres + PostGIS, RLS, native Sign in with Apple (iOS) / Google (Android) |
| **State management** | `provider` + `ChangeNotifier` singletons |
| **Maps** | `google_maps_flutter` (Maps SDK for iOS and for Android — separate keys) |
| **Languages** | English, Spanish, Chinese |
| **Bundle ID** | `org.beaconhealth.app` |

---

## Prerequisites

- **Flutter 3.47.0** (stable channel) — check with `flutter --version`. Match
  this exactly: all three workflows in `.github/workflows/` pin it, and a newer
  analyzer will fail the build with no code change. Bump all three together.
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

**1. Add the Google Maps keys** (gitignored — never commit them). iOS and
Android each need their own platform-restricted key:

```bash
echo "GOOGLE_MAPS_API_KEY=<your-ios-maps-key>" > ios/Flutter/Secrets.xcconfig
echo "GOOGLE_MAPS_API_KEY=<your-android-maps-key>" >> android/local.properties
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
`--dart-define-from-file=config/dart_defines.json` (that path is gitignored). Copy
`config/dart_defines.json.example` for the full key list — `make run` and the VS Code
launch configs read that file. Android sign-in additionally needs
`GOOGLE_WEB_CLIENT_ID` (see "Key services").

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
    theme/                     Design tokens + AppTheme (see design/README.md)
    utils/                     Formatting, ZIP → state lookup, coverage text
    widgets/                   Shared dialogs, sign-in button, gates
  features/
    auth/                      Onboarding, login, ZIP entry, AuthGate
    home/                      Home page, quick actions, nav bar
    map/
      constants/               Map + filter + category constants
      data/                    Repository + Supabase facility service
      domain/models/           Facility, eligibility, hours
      presentation/            Map page, filters, cards, markers
      utils/                   Map geometry, category icons
    profile/                   Profile tab (account, ratings, eligibility)
    settings/                  Settings, "Your Ratings", "Your Requests"
  l10n/                        ARB files (en/es/zh) + generated localizations
test/                          Unit, widget, and golden tests mirroring lib/
  helpers/                     Fake map, fake data source, app-shell harness
design/                        Design-system guide + generated token export
tool/                          Repo scripts: golden adoption, Claude Design bundle
```

### Architecture at a glance

**Entry flow:** `AuthGate` → `LoginPage` (Apple on iOS, Google on Android, or
guest) → `LocationChoicePage` (GPS, or a ZIP on `ZipEntryPage`) →
`EligibilityOnboardingPage` (signed-in only) → `MainNavBar`. Returning users go
straight to `MainNavBar`; the `hasCompletedOnboarding` flag in
`SharedPreferences` decides.

**Guest mode is a first-class state.** `GuestModeService.isGuest` is derived
from the Supabase session. Guests can browse, search, and get directions;
Favorites, ratings, requests, and the whole Profile tab are gated by checking
`isGuest` and calling `showSignInPromptDialog(context)`. When adding a feature
that writes to Supabase, gate it — RLS will reject anonymous writes anyway, and
a sign-in prompt is a far better experience than a silent failure.

**Coverage follows the database.** `CoverageService` reads `launched_states`
(cached on device, refreshed at startup and before a ZIP is turned away). The
ZIP gate in `ZipCodeService.setZipCode` and the `CoverageNotice` text both come
from it, so never hardcode a state name or a list of states. A ZIP's state
comes from its three-digit prefix (`ZipState`), which needs no network.

**Facility queries are server-side and bounded.** `SupabaseFacilityService`
calls the PostGIS `facilities_near` RPC with a lat/lng + radius, capped at 250
rows, with a quantized per-region in-memory cache. The map deliberately **does
not auto-query on pan** — the user taps "Search this area". Don't reintroduce
load-everything-and-filter-on-device; the table is far too large for it. Home
and Map read the repository from a `Provider<FacilityRepositoryBase>`, which is
also how tests hand them a fake.

**The list follows the map.** The list panel shows the loaded facilities that
are on screen, nearest the middle of the map first, and re-syncs whenever the
camera comes to rest — client-side, with no query. A text search or the
Favorites filter lists every match in the loaded area instead. Selecting a
facility remembers the camera and deselecting returns to it, unless the user
moved the map in between. Facilities that share an address stay a count bubble
until the zoom at which their fanned-out pins can be told apart
(`MarkerManagementService.groupForZoom`).

**Eligibility switches only ever hide what a person can't use.** The rule is
`FacilityFilterService.eligibilityGates`. The four "required" switches (proof
of income, proof of residency, insurance, referral) say what the person can
provide: left off, facilities that require it are hidden; switched on, they
are shown along with everything else. Medicaid runs the other way — only
switching it on filters, hiding places known not to accept it. A facility with
no answer on file always passes, and guests, who can't reach the switches, are
never filtered.

**Nav pages live in an `IndexedStack`** and keep state alive, so `initState`
runs once. Pages that must react to changes made elsewhere (Settings editing the
ZIP, Profile editing eligibility, favorites finishing their load) subscribe to
the relevant service in `initState` and re-filter on notify.

**Tabs and map overlays are not routes, so Android's back button is handled by
hand.** `MainNavBar` wraps the shell in a `PopScope`: back first asks
`MapPageState.handleBack()` to close the innermost thing open on the map
(facility card, expanded row, raised list, search text — the order lives in
`mapBackTarget`), then returns to Home, and only leaves the app from Home.
Dialogs, sheets, and pushed pages are routes and pop on their own. Anything new
that opens over a tab without being a route must be added to that chain.

### Key services

All are `ChangeNotifier` singletons in `lib/core/services/`, initialized in
`main.dart` before `runApp`.

| Service | Responsibility |
|---|---|
| `GuestModeService` | Signed-in vs guest, and the current user, from the Supabase session |
| `CoverageService` | Which states are live, from `launched_states`; drives the ZIP gate and coverage notice |
| `AppleSignInService` | Native Sign in with Apple (iOS) → `signInWithIdToken` |
| `GoogleSignInService` | Native Sign in with Google (Android, Credential Manager) → `signInWithIdToken` |
| `ZipCodeService` | ZIP ↔ coordinates (covered ZIPs only), GPS toggle, onboarding flag |
| `EligibilityPreferencesService` | Eligibility answers (income, residency, insurance, referral, Medicaid) + map preferences; auto-applies to search |
| `UserSettingsService` | Mirrors settings to the `user_settings` Supabase row |
| `UserFavoritesService` | Favorites sync, region-independent |
| `FacilityFeedbackService` | Ratings: read / upsert / delete |
| `FacilityRequestService` | New-facility requests, corrections, and "permanently closed" reports |
| `RecentFacilitiesService` | Last 3 viewed facilities, persisted locally |
| `MapLauncherService` | Directions chooser + remembered choice. Apple Maps, Google Maps, Waze on iOS; Google Maps, Waze on Android |
| `ErrorReporter` | `developer.log` in debug, Sentry in release |

**Error handling convention:** never `print` or `debugPrint`. Every catch site
calls `ErrorReporter.instance.report(e, stack, context: 'WhereItHappened')`.
Report bugs, not user choices: expected outcomes such as a declined location
prompt return a status instead of reaching Sentry. The deliberate exception is
`GoogleSignInService`, which reports every Credential Manager `canceled`
because configuration failures arrive with that same code.

**One sign-in provider per platform:** Sign in with Apple on iOS, Sign in with
Google on Android — never both. `nativeSignInProviderFor` is the only place the
rule lives (unit-tested), and every sign-in surface uses `NativeSignInButton`.
Google needs the **Web** OAuth client ID as the `GOOGLE_WEB_CLIENT_ID`
dart-define (also listed first under Client IDs on the Supabase Google
provider), plus an **Android** OAuth client in Google Cloud for
`org.beaconhealth.app` for every key that signs a build people run: debug,
upload, and Play's app-signing key. The Android Maps key restriction needs the
same SHA-1s.

**Platform differences live in one function each** and take the platform as an
argument so both can be tested: `nativeSignInProviderFor` for sign-in,
`MapLauncherService.appsFor` / `probeUri` / `directionsUri` for map apps. A map
app's URL scheme must also be declared natively — `<queries>` in
`AndroidManifest.xml`, `LSApplicationQueriesSchemes` in `Info.plist` — or the OS
reports it as not installed; `test/core/config/platform_config_test.dart`
checks the two stay in step.

---

## Backend

Supabase Postgres with PostGIS. The app talks to:

| Object | Purpose |
|---|---|
| `FCT_Supabase` | Facility master table (geocoded, `geom` + GiST index) |
| `DM_Supabase_Eligibility` | Per-facility eligibility attributes |
| `fct_supabase_full` | View joining the two — used for favorites and single-facility lookups by id |
| `facilities_near(...)` | PostGIS RPC — bounded, distance-sorted proximity search; enforces the state allow-list. Must return the same facility and eligibility columns as the view |
| `launched_states` | Allow-list of live states (`ALL` = nationwide). Enforced by the RPC and read by the app |
| `user_favorites`, `user_settings`, `facility_feedback`, `facility_requests` | Per-user data, all protected by owner-only RLS |

Every user table has RLS with `using (auth.uid() = user_id)` **and** a matching
`with check` clause — omitting `with check` makes inserts fail with a 42501.

`facility_requests` holds new-facility requests and corrections
(`request_type`); a correction with `reported_closed = true` is a user saying
the facility has permanently closed.

**Launching a state** is one statement, and the app follows without a release:

```sql
insert into public.launched_states (state_code) values ('OK');
```

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

### Design system

Style with tokens, never literals: colors from `AppColors` or the
`ColorScheme`, text from `Theme.of(context).textTheme`, and `AppSpacing`,
`AppRadii`, `AppShadows` for layout. Import them all from
`package:beacon_app/core/theme/theme.dart`.

`test/design_system_lint_test.dart` fails CI on hardcoded styles. After changing
a token, regenerate the Claude Design export:

```bash
flutter test test/design_tokens_test.dart --update-goldens
```

The full guide is in [`design/README.md`](design/README.md). The Claude Design
project is built from these tokens with `dart run tool/build_design_bundle.dart`
(see [`.design-sync/NOTES.md`](.design-sync/NOTES.md)).

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
`Facility` objects, and `pumpThemed(...)` from `test/helpers/pump_app.dart` to
render widgets with the real theme, localizations, and providers.

- **Unit tests** cover services, models, filtering, map geometry, marker
  grouping, and the category taxonomy.
- **Widget tests** cover the shared components, the facility card and list
  panel, the dialogs, Settings, Profile, and the first-run flow.
- **Shell tests** run the real `MainNavBar` — Home, Map, Profile, Settings —
  over a fake map and a fake data source: Android back in every state, the
  list following the map, cluster taps, selection, location changes, guest
  locks, eligibility. `pumpAppShell` and `FakeFacilityRepository` are in
  `test/helpers/app_shell.dart`; `FakeGoogleMaps`
  (`test/helpers/fake_google_maps.dart`) stands in for the Maps SDK and lets a
  test move the camera or tap a marker. `pressBack(tester)` presses Android's
  back button.
- **Guard tests** fail CI on drift that no build catches:
  `test/core/config/platform_config_test.dart` (native manifest and plist
  entries the Dart code relies on), `test/l10n_lint_test.dart` (the three ARB
  files agree; no sentence-like string literal outside them), and
  `test/design_system_lint_test.dart` (no hardcoded styles).
- **Golden tests** (`test/goldens/`) snapshot the component gallery, the
  facility card, and the onboarding, login, settings, and guest-profile
  screens in light and dark. Screens without platform-specific pieces render
  under both iOS and Android against a single image, so the two platforms
  can't drift apart.

  Golden images are canonical on **Linux**, because macOS rasterizes glyphs
  differently. They run in CI and skip locally on macOS. After an intentional
  visual change, push and let CI fail: it uploads the new renders and diffs as
  the `golden-failures` artifact. Review them, then adopt them with:

  ```bash
  tool/update_goldens_from_ci.sh
  ```

Plugins are faked through their method channels (see `resetAppState` in
`test/helpers/app_shell.dart`), so no mocking packages are needed;
`mockPlatformServices()` stubs the ones screens touch on first build. Run a
test on both platforms with `variant: TargetPlatformVariant.only(...)` or
`shippingPlatforms`.

Tests draw every glyph as a full-width block, about twice as wide as the real
typeface, so a row that fits on a phone can overflow in a test; give such a
test a wider surface.

Not covered by any automated test: the native sign-in sheets, and anything
that depends on how a store build is signed (see "Releasing").

---

## CI/CD

| Workflow | Trigger | Does |
|---|---|---|
| `.github/workflows/ci.yml` | push / PR to `main` | format check, `flutter analyze --fatal-infos`, `flutter test`, a debug Android build, and a check that the build requests only the permissions in `android/permissions.txt`; uploads a `golden-failures` artifact when a golden test fails |
| `.github/workflows/ios-build.yml` | push to `main` (docs ignored), or manual | builds and uploads to TestFlight via Fastlane |
| `.github/workflows/android-build.yml` | push to `main` (docs ignored), or manual | builds a signed AAB and uploads to the Play internal track via Fastlane |

- **PR CI never builds iOS.** Changes that touch native iOS code (plugin
  bumps, the Podfile, Xcode settings) need a local
  `flutter build ios --release --no-codesign` before merging.
- **Every merge to `main` ships builds** to Play's internal track and to
  TestFlight; only `**.md` / `docs/**` changes are skipped. Each workflow
  cancels its in-progress run, so merge related PRs in one sitting and only
  the last build completes.
- **Each App Store release needs a version bump** in `pubspec.yaml`. Once a
  version is approved, TestFlight rejects further builds on it (ITMS-90186, "the
  pre-release train is closed"), so `ios-build.yml` fails until the bump lands.

TestFlight uses **App Store Connect API-key cloud-managed signing** — no
Fastlane Match, no certificates repo. The API key must have **App Manager**
access so Xcode can create the distribution certificate and provisioning profile
at build time. The build number is `1000 + github.run_number`, so uploads never
collide.

Android releases are signed in CI with the upload key, rebuilt from secrets
because the keystore and `android/key.properties` are gitignored; the workflow
deletes both afterwards. A local release build without `android/key.properties`
falls back to debug keys: it runs, but can't be uploaded to Play. Play uploads
authenticate with **Workload Identity Federation** rather than a
service-account key — GitHub's OIDC token is exchanged for short-lived Google
credentials, so nothing long-lived is stored.

The Play upload needs three things outside this repository: the
`PLAY_UPLOAD_ENABLED` repository variable set to `true`, the **Google Play
Android Developer API** enabled in the Google Cloud project the service account
lives in, and that service account added in Play Console (Users and
permissions) with permission to release the app to testing tracks. The signed
bundle is kept as the `beacon-release-aab` artifact either way, so a build can
be uploaded by hand.

**Plugins can add Android permissions.** Their manifests are merged into the
app's, so a dependency bump can ship a permission nobody asked for, and Play
refuses an upload that carries certain permissions (foreground services, for
one) until they are declared in Play Console. `tool/check_android_permissions.sh`
fails CI when the built app's permissions differ from `android/permissions.txt`.
If Beacon doesn't use a new permission, remove it in the app manifest with
`tools:node="remove"`, as is done for geolocator's foreground-service
permission.

Required GitHub secrets:

| Secret | Used by |
|---|---|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | both release workflows |
| `SENTRY_DSN`, `SENTRY_AUTH_TOKEN` | both (symbol upload is skipped when the token is absent) |
| `GOOGLE_MAPS_API_KEY` | iOS |
| `GOOGLE_MAPS_API_KEY_ANDROID`, `GOOGLE_WEB_CLIENT_ID` | Android |
| `APP_STORE_CONNECT_API_KEY_ID`, `..._ISSUER_ID`, `..._CONTENT` | iOS / TestFlight |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Android signing |
| `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_PLAY_PUBLISHER_SA` | Play upload (keyless) |

---

## Releasing

1. Bump `version` in `pubspec.yaml`.
2. Merge the release PRs in one sitting; the last merge's builds land on
   TestFlight and Play's internal track.
3. **Smoke-test the store-installed builds** before promoting them. Play
   re-signs with its own key and TestFlight builds use the release SDK, so
   these only show up there: sign in, check that map tiles load, open
   directions, and on Android press back from each tab.
4. Promote, then launch any new state with the `launched_states` insert under
   "Backend".

---

## Monitoring

Crashes and errors go to **Sentry**. Only release builds report; debug builds
log through `developer.log`. A commit message containing `Fixes BEACON-<n>` resolves that
issue when the commit reaches `main`.

---

## Troubleshooting

**The map renders as a uniform grey rectangle.** Almost always Google Maps
billing, not code — the SDK logs success and silently returns blank tiles. Check
Google Cloud → Billing, that "Maps SDK for iOS" / "Maps SDK for Android" is
enabled, and — on Android — that the key's package name and SHA-1 restriction
match the signing key of the build you're running.

**Startup throws about `SUPABASE_URL`.** You ran `flutter run` without the
`--dart-define` flags. See "Getting started".

**Android: the Google account picker closes instantly, or nothing happens.**
Credential Manager reports misconfiguration as a user cancel. Check the Android
OAuth client's package name and SHA-1 against the build, and that
`GOOGLE_WEB_CLIENT_ID` is the **Web** client ID, not the Android one.

**Android: Google sign-in works locally but fails on Play installs** with
`[16] Account reauth failed`. Play re-signs releases with the Play App Signing
key, and that key's SHA-1 isn't registered. Add it to an Android OAuth client
and the Android Maps key restriction (see "Key services").

**Ratings or requests fail to submit.** A required table, column, or unique
constraint hasn't been applied to the Supabase project. A 42501 specifically
means an RLS policy is missing its `with check` clause.

**No facilities appear anywhere.** Either the state you're searching isn't in
`launched_states`, or you're outside the fixed 5-mile radius. A ZIP in a
launched state (e.g. `60613`) is the reliable test case.

**A facility field is always empty in the map list but shows for favorites.**
The `facilities_near` RPC isn't returning that column; the view is. Both must
expose it.

**The Play upload step fails.** The message from Google says which piece is
missing:

- *"Google Play Android Developer API has not been used in project…"* — enable
  that API in the Cloud project.
- *"The caller does not have permission"* — the upload service account isn't a
  Play Console user with release access to the app.
- *"You must let us know whether your app uses any Foreground Service
  permissions"* (or a similar request for a declaration) — the bundle requests
  a permission Play wants declared. Usually a plugin added it; see "Plugins can
  add Android permissions" under CI/CD.

After fixing it, re-run the failed job; nothing needs rebuilding by hand.

**Android back leaves the app from a new screen.** That screen isn't a route.
See "Tabs and map overlays are not routes" under Architecture.

**Pod or build errors after pulling.** `cd ios && pod install`. If Xcode starts
converting plugins to Swift Package Manager, disable SPM (see Prerequisites).

**Every marker is a neutral grey pin and the Category filter matches nothing.**
The `fct_supabase_full` view and the `facilities_near` RPC aren't returning
`category_broad` / `category_detail`. Both must expose those columns.
