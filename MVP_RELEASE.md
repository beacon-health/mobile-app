# Beacon App — MVP Release Plan

> **Context doc for AI agents.** Read this before making changes.
>
> **Last updated:** 2026-06-18 · **Target:** iOS App Store (TestFlight -> public) · **Version:** `1.0.0+1`
>
> **Status:** §2.1 – §2.5 **and** the §2.6 nationwide-data migration are
> code-complete — `flutter analyze` clean, 24/24 tests pass. The geocoding
> backfill is done and both migrations are applied.
>
> **✅ Done**
> - **§2.1–§2.5:** Auth (native Sign in with Apple), GPS, crash reporting
>   (Sentry via `ErrorReporter`), facility feedback, and cleanup.
> - **§2.6 nationwide data:** moved off the ~691-row Illinois view to
>   **`FCT_Supabase`** (162,937 rows, geocoded via the Census batch script).
>   PostGIS `facilities_near` RPC + `fct_supabase_full` view are live; the app
>   queries **server-side per region** with a **"Search this area"** control,
>   **marker clustering** when zoomed out, and **region-independent Favorites**
>   (resolved by id from `user_favorites`). SQL lives in `supabase/migrations/`,
>   the geocoder in `scripts/geocode/`.
> - **§2.6 map UX:** Category filter now uses **`category_level_2`** (12 values)
>   while marker/list icons **consolidate to 4 high-level groups**; Home→Map
>   navigation re-centers correctly (favorites + map cutout); facility feedback
>   uses **selectable tag chips** instead of free text; the "Search this area"
>   location label clears on focus; empty/sparse map state is overflow-safe.
>
> **⏳ Remaining**
> - **Device QA of §2.6** end-to-end (the one code-side gate left — see §2.6).
> - **External configuration only** — Supabase Dashboard, Google Cloud, Apple
>   Developer, App Store Connect (§3).
> - **Optional polish** — lean column projection / lazy detail fetch; offline
>   mode stays a post-MVP outline (§9).

---

## 1. Project Overview

| Area | Value |
|------|-------|
| **Framework** | Flutter 3.41.6 / Dart 3.11.4, Material 3, iOS-only (Android post-MVP) |
| **Bundle ID** | `org.beaconhealth.app` |
| **iOS min target** | 15.0 (aligned across Podfile + Xcode) |
| **Backend** | Supabase (Free tier). Data source migrating from `facilities_il_full` (~691 IL rows) → **`FCT_Supabase`** (162,937 rows, nationwide; lat/lng pending geocoding) + `DM_Supabase_Eligibility` (3,713 rows, growing) — see §2.6 |
| **Auth** | Supabase OAuth — Sign in with Apple (iOS MVP), Google sign-in tested in dev (Android post-MVP) |
| **State mgmt** | Provider + ChangeNotifier |
| **Maps** | Google Maps Flutter plugin, API key via `Secrets.xcconfig` (gitignored) |
| **Localization** | en, es, zh via `flutter_localizations` + ARB |
| **Secrets** | `--dart-define` for Supabase URL/key; `Secrets.xcconfig` for Google Maps key. No secrets in source. |
| **Linting** | `very_good_analysis` — 0 issues (`flutter analyze` clean) |
| **Tests** | 18 unit tests (all passing) |
| **CI/CD** | GitHub Actions (`ci.yml` + `ios-build.yml`), Fastlane skeleton |
| **Repo** | `github.com/beacon-health/mobile-app` · Data pipeline: `github.com/beacon-health/beacon-data` |

### Architecture

- **Entry flow:** `AuthGate` → `OnboardingPage` (welcome) → `LoginPage` (Sign in with Apple / Continue as Guest) → `LocationChoicePage` (GPS / Enter Zip) → `MainNavBar`. After onboarding, `AuthGate` routes returning users straight to `MainNavBar`.
- **Auth:** Native Sign in with Apple via `sign_in_with_apple` + `supabase.auth.signInWithIdToken(...)`. `AppleSignInService` is the single facade; `AppleSignInButton` is the reusable widget used at all in-app sign-in CTAs.
- **Guest mode:** `GuestModeService` — singleton `ChangeNotifier` listening to `Supabase.auth.onAuthStateChange`. `isGuest = currentUser == null`. Widgets `context.watch<GuestModeService>().isGuest`.
- **Locked features:** `LockedFeatureGate` wraps children with tap → `showSignInPromptDialog`. `LockedSectionOverlay` frosted-glass overlay for Settings sections (Eligibility, Preferences). Heart icon on `FacilityCard` is disabled (not just no-op) when guest.
- **Error handling:** `ErrorReporter` singleton — `developer.log` in debug, `Sentry.captureException` in release (when `Sentry.isEnabled`). All catch sites already call `ErrorReporter.instance.report(e, stack, context: 'X')`.
- **Theming:** `AppGradients` for onboarding gradients, `ColorSchemeExt` for alpha blends. App defaults to light mode (`ThemeModeProvider._themeMode = ThemeMode.light`); user can switch in Settings.
- **Location:** `ZipCodeService` stores ZIP → geocoded lat/lng via `SharedPreferences`, including a `_previousZipCode` slot so GPS-on overwriting "Current Location" doesn't lose the user's prior ZIP. `LocationService` returns typed `LocationStatus`; `MapPage` listens to `ZipCodeService.addListener` so it stays in sync when Settings changes the location source.
- **Settings sync:** `UserSettingsService` mirrors `{zip_code, theme_mode, locale, location_search_enabled, eligibility (jsonb), preferences (jsonb)}` to a Supabase `user_settings` row on sign-in. `EligibilityPreferencesService` is the local source of truth for eligibility/preferences toggles, mirrored via `unawaited(UserSettingsService.instance.pushLocal())` on each change.
- **Feedback flow:** `RecentFacilitiesService` (last 3 viewed, persisted to SharedPreferences). Tap a row on Home → `FacilityFeedbackDialog` → insert into `facility_feedback`. Successful submit removes the facility from recently-viewed.
- **Facility data (changing — see §2.6):** today `SupabaseFacilityService.getAllFacilities()` fetches the *entire* `facilities_il_full` view in one `.select()`, caches it in memory, and does all distance/search/category filtering client-side (Haversine in Dart). `loadFacilitiesWithDistance(lat, lng, radiusMiles)` just filters that cached list — the radius never reaches the server. Fine for ~691 rows; **breaks at 162,937**: PostgREST's default `max-rows` cap silently truncates the result, the payload balloons, and 160K+ `Facility.fromSupabase` parses on the UI isolate cause jank/OOM. §2.6 replaces this with bounded, server-side **point-radius** queries keyed off the user's GPS/ZIP or the current map center.
- **Filter bar:** Tune → Distance → Open Now → Favorites → Category → **Status** → Eligibility → Preferences. The Status chip opens an action sheet that one-shot applies the user's saved eligibility/preferences from Settings as filter values (no Apply button — auto-apply + close).

### Key Files

| Purpose | Path |
|---------|------|
| App entry | `lib/main.dart` |
| App routing / providers | `lib/app.dart` |
| Auth gate | `lib/features/auth/presentation/widgets/auth_gate.dart` |
| Login page | `lib/features/auth/presentation/pages/login_page.dart` |
| Onboarding page | `lib/features/auth/presentation/pages/onboarding_page.dart` |
| Zip entry page | `lib/features/auth/presentation/pages/zip_entry_page.dart` |
| Guest mode service | `lib/core/services/guest_mode_service.dart` |
| Zip code service | `lib/core/services/zip_code_service.dart` |
| Error reporter | `lib/core/services/error_reporter.dart` |
| Location service | `lib/features/map/presentation/services/location_service.dart` |
| Sign-in prompt dialog | `lib/core/widgets/sign_in_prompt_dialog.dart` |
| Apple sign-in service | `lib/core/services/apple_sign_in_service.dart` |
| Apple sign-in button (reusable) | `lib/core/widgets/apple_sign_in_button.dart` |
| Locked feature gate | `lib/core/widgets/locked_feature_gate.dart` |
| Locked section overlay | `lib/core/widgets/locked_section_overlay.dart` |
| User settings sync | `lib/core/services/user_settings_service.dart` |
| User favorites sync | `lib/core/services/user_favorites_service.dart` |
| Eligibility/Preferences | `lib/core/services/eligibility_preferences_service.dart` |
| Recently viewed facilities | `lib/core/services/recent_facilities_service.dart` |
| Feedback dialog | `lib/features/home/presentation/widgets/facility_feedback_dialog.dart` |
| Legal URL constants | `lib/core/constants/legal_urls.dart` |
| Facility data | `lib/features/map/data/facility_repository.dart`, `supabase_facility_service.dart` |
| Facility model | `lib/features/map/domain/models/facility_model.dart` |
| Facility provider | `lib/features/map/presentation/providers/facility_provider.dart` |
| Map page | `lib/features/map/presentation/pages/map_page.dart` |
| Home page | `lib/features/home/presentation/pages/home_page.dart` |
| Main nav bar | `lib/features/home/presentation/widgets/main_nav_bar.dart` |
| Settings page | `lib/features/settings/presentation/pages/settings_page.dart` |
| Filter bar | `lib/features/map/presentation/widgets/filters/components/filter_bar.dart` |
| Filter constants | `lib/features/map/constants/filter_constants.dart` |
| Facility card | `lib/features/map/presentation/widgets/facility/facility_card.dart` |
| Location search | `lib/features/map/presentation/widgets/search/location_search.dart` |
| iOS project | `ios/Runner.xcodeproj/project.pbxproj` |
| Privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy` |

### Apple Developer Account

| Item | Value |
|------|-------|
| **Team ID** | `3VY6L9SG6K` |
| **Apple ID email** | `hq@beacon-health.com` |
| **App Store Connect API Key ID** | `99WRH2CRMQ` |
| **App Store Connect Issuer ID** | `33d021fa-95fd-4d15-a247-98d49c5b138c` |

---

## 2. Code Work

§2.1 – §2.5 (✅ below) are implemented, `flutter analyze` is clean (0 issues),
and `flutter test` passes (18/18). **§2.6 is new scope (⏳ not started)** —
the nationwide-data migration and scaled map querying. Until §2.6 lands, the
only *other* remaining work is external configuration (§3) — a click in
someone else's web console.

### 2.1 User Authentication ✅
- Native **Sign in with Apple** via the `sign_in_with_apple` package and
  `supabase.auth.signInWithIdToken(...)` — no OAuth secret JWT required on
  the Supabase side; the Apple-issued identity token is validated against
  Apple's public keys.
- Routing: `OnboardingPage` (welcome) → `LoginPage` (Apple / Continue as
  Guest) → `LocationChoicePage` → `MainNavBar`. Reactive auth state is
  observed by `GuestModeService` / `UserSettingsService` / `FacilityProvider`.
- Sign-out lives in Settings (only rendered when signed in). Calls
  `Supabase.signOut()` + `ZipCodeService.clear()` then `pushAndRemoveUntil`
  back to `LoginPage`.
- In-app sign-in CTAs (Settings Account row, locked-favorites card, the
  `SignInPromptDialog`) render the reusable `AppleSignInButton` — direct
  Apple flow, no intermediate LoginPage.
- The Account row shows the OAuth provider's logo (Apple/Google glyph) +
  "Signed in through Apple" + the relay/real email returned by the
  provider.

### 2.2 GPS Location Enablement ✅
- `LocationService.getCurrentLocation()` returns a typed `LocationStatus`
  (`granted` / `denied` / `permanentlyDenied` / `serviceDisabled` / `error`).
- `NSLocationWhenInUseUsageDescription` set in `Info.plist`.
- `LocationChoicePage` offers GPS or ZIP at onboarding; ZIP entry page is
  the fallback when permission is denied.
- Map page: `myLocationEnabled` flips on once permission is granted;
  blue-dot stays accurate. `LocationSearch` widget exposes the current ZIP
  or "Current Location" label and re-syncs when `ZipCodeService` notifies.
- Settings has a `Use My Location` toggle. Turning it OFF when the user
  has a stored prior ZIP silently restores that ZIP; turning it OFF when
  no ZIP exists prompts the user via `_ZipEditDialog`.

### 2.3 Crash Reporting ✅
- `sentry_flutter` initialized in `main.dart` when
  `kDebugMode == false && --dart-define=SENTRY_DSN=…` is set. Wrapped via
  the `appRunner: () => runApp(...)` pattern so native crashes are caught.
- `ErrorReporter.report(...)` (used by ~all error-catching sites in the
  app) routes through `Sentry.captureException` in release builds when
  `Sentry.isEnabled`, attaching the call-site `context:` as a Sentry tag.
  Debug builds still log via `developer.log`.
- See also §8 (Sentry-vs-alternatives) — the choice is parked, not final.

### 2.4 Facility Feedback Submission ✅
- New `RecentFacilitiesService` (`lib/core/services/recent_facilities_service.dart`)
  — ChangeNotifier singleton, last-3-viewed list, persisted to
  `SharedPreferences` as JSON so it survives app restarts.
- `MapPage._showFacilityDetails` and `_toggleFacilityExpansion` add the
  viewed facility to the service.
- Home page has a "Recently Viewed Facilities" section between the map
  block and Favorites. Empty state is a compact `Icons.history` row.
  Populated state renders inline `ListTile`s.
- Tap a row → `showFacilityFeedbackDialog(...)` for signed-in users
  (thumbs-up green / thumbs-down bittersweet, 3-line comment, Submit
  disabled until both filled). Successful insert into `facility_feedback`
  removes the facility from Recently Viewed and shows a snackbar. Guests
  get the sign-in prompt instead.
- The DDL for `facility_feedback` (and the `with check` RLS gotcha) is at
  the end of this section.

### 2.5 Cleanup ✅
- `pubspec.yaml` bumped to `1.0.0+1`.
- `LocationService` no longer hardcodes Chicago — falls back to
  `ZipCodeService` coords. All `debugPrint` sites moved to
  `ErrorReporter.instance.report(...)` with a `context:` label.
- `map_page.dart` `debugPrint` migrations done.
- Dropped lat/lng from the `user_settings` cloud row — device re-geocodes
  the ZIP on apply. Eligibility/preferences stored as `jsonb` columns to
  avoid schema churn while the on-device toggle set evolves.

### 2.x Supabase tables — DDL reference

Run these once via Supabase Dashboard → SQL Editor. The app code already
matches the columns exactly.

**`user_favorites` table:**
```sql
create table public.user_favorites (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  facility_id text not null,
  created_at timestamptz default now() not null,
  unique(user_id, facility_id)
);
alter table public.user_favorites enable row level security;
create policy "Users manage own favorites" on public.user_favorites
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

**`facility_feedback` table:**
```sql
create table public.facility_feedback (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  facility_id text not null,
  rating text check (rating in ('up', 'down')) not null,
  comment text not null,
  created_at timestamptz default now() not null
);
alter table public.facility_feedback enable row level security;
create policy "Users manage own feedback" on public.facility_feedback
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```
The `with check` clause is required for INSERT to succeed. If you omitted
it on first creation, you'll see a 42501 "new row violates row-level
security policy" error when users submit feedback. Run
`drop policy "Users manage own feedback" on public.facility_feedback;`
then re-run the `create policy` above to fix without recreating the table.

**`user_settings` table:**
```sql
create table public.user_settings (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null unique,
  zip_code text,
  theme_mode text default 'light',
  locale text default 'en',
  location_search_enabled boolean default false,
  -- Eligibility hard gates + service preferences. JSON-blob shape:
  --   eligibility: { proof_of_income: bool, proof_of_residency: bool,
  --                  insurance_required: bool, referral_required: bool }
  --   preferences: { accepts_walk_ins: bool, appointment_only: bool, ... }
  -- See lib/core/services/eligibility_preferences_service.dart for the
  -- canonical key list. Stored as jsonb so we can add/remove fields
  -- without migrations.
  eligibility jsonb default '{}'::jsonb,
  preferences jsonb default '{}'::jsonb,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);
alter table public.user_settings enable row level security;
create policy "Users manage own settings" on public.user_settings
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```
Note: lat/lng are intentionally not stored — the device geocodes the ZIP
on apply. Eligibility / preferences live as `jsonb` blobs to keep schema
churn low while the on-device set is still evolving.

### 2.6 Nationwide Data & Scaled Map Querying ✅ CODE-COMPLETE (device QA pending)

> **Implementation status (2026-06-18).** All §2.6 app code is written and
> passes `flutter analyze` + 24 tests; geocoding + migrations `0001`/`0002` are
> applied, so the app queries the live `facilities_near` RPC. In code:
> `SupabaseFacilityService` calls the RPC with a quantized region cache (no more
> load-all); `MapPage` re-queries per region with a drift-gated **"Search this
> area"** button and an overflow-safe empty/sparse state; **Favorites resolve by
> id** from `user_favorites` (region-independent); **markers cluster** when
> zoomed out; the Category filter uses **`category_level_2`** while icons
> **consolidate to 4 groups** (see "Category taxonomy" below); Home→Map
> navigation re-centers (favorites + cutout); and facility feedback uses
> **selectable tag chips**. **Still pending:** a device QA pass, and (optional) a
> lean column projection / lazy detail fetch — the RPC returns full rows, fine
> at the 250-result cap.
>
> ⚠️ **Re-run `0002` after pulling:** the `facilities_near` RPC return type and
> the `fct_supabase_full` view changed (added `category_level_2`; `contact_phones`
> normalized to a JSON array). The migration drops + recreates both, so just run
> the whole file again — it's idempotent.

#### Category taxonomy (filter vs. icon)

Two dimensions, one source of truth in
`lib/features/map/constants/facility_categories.dart`:
- **Filtering** is by **`category_level_2`** — the map Category filter lists the
  12 known values (`FacilityCategories.categoryLevel2Values`);
  `FacilityFilterService` matches a facility's `categoryLevel2` against the
  selection (null never matches, so it's excluded when a category is chosen).
- **Icons / colors** consolidate those 12 into **4 high-level groups** (Health
  Care, Mental Health, Basic Needs, Housing & Shelter) + a neutral fallback,
  via `FacilityCategories.groupFor(...)`. `Facility.primaryCategory` returns the
  group, so every marker, list icon, and card icon is consistent. Hospitals →
  Health Care (except `Hospital- PSYCH` → Mental Health); `Treatment Facility`
  and the mental-health nonprofit → Mental Health; housing nonprofit → Housing
  & Shelter; human-services / public-benefit nonprofits → Basic Needs.
- Home quick-action buttons pass a group; `MapPage.filterByCategory` expands it
  to that group's `category_level_2` values so the filter still works.
- Grouping choices for `Hospital- RELIGIOUS NON-MED` and `Treatment Facility`
  are best-guess — adjust the switch in `facility_categories.dart` if the data
  owner wants different buckets. `category_level_1` (`appCategory`) is retained
  on the model for any raw-value display.

**Goal.** Switch the facility data source from the ~691-row `facilities_il_full`
view to the **`FCT_Supabase`** table (162,937 rows, US-wide) and make every map
query **server-side and region-bounded**, so the app loads only the facilities
near a point — never the whole table. Two query entry points drive this:

1. **Location-search change (ZIP):** when the user types a ZIP into the
   location-search box, geocode it and query the DB around that lat/lng using
   the **default distance** already in `MapConstants.distanceOptions.first`
   (`1.0 mi`; the distance chip widens it). The wiring exists today
   (`MapPage._onLocationChanged` → `_loadFacilities`); only the underlying
   query needs to become a real bounded server call.
2. **Pan / zoom the map:** add a **"Search this area"** floating button (the
   Yelp / Uber Eats / Google Maps pattern). We do **not** auto-query on every
   camera move — the button is the explicit, quota-friendly trigger.

#### Why the current approach can't ship on this data

`SupabaseFacilityService` is built around a single `getAllFacilities()` that
does `.from(view).select().order(...)`, caches the whole list in `_cache`, and
filters in Dart. At 162,937 rows: PostgREST caps the response (default
`max-rows`, usually 1,000) so you'd **silently** get a truncated, arbitrary
slice; the transfer is multi-MB; and parsing 160K+ models on the main isolate
janks or OOMs. The in-memory "load once" cache and `FacilityProvider`'s
"facilities == the entire dataset" assumption both have to go.

#### Data prerequisites (must happen first — these block all app work)

`FCT_Supabase` is **not query-ready as-is.** Two backfills and one view stand
between the table and the app:

**1. Geocode every facility — no coordinates exist yet.** `latitude` /
`longitude` are `text` and currently null; `geocode_coordinates` is null too.
Until they're populated **zero facilities can render on the map.** This is a
one-time (then incremental) batch job — implemented here as a standalone
script in **`scripts/geocode/geocode_facilities.py`** (could equally live in
the `beacon-data` pipeline):
- Reuse the existing free-geocoder + Python approach. For US street addresses
  the **U.S. Census Bureau Geocoder** is the natural fit — no API key, no
  cost, and a **batch endpoint of up to 10,000 addresses per request**
  (`street, city, state, zip` → lat/lng), so ~163K rows ≈ 17 batches. Use
  **Nominatim / OpenStreetMap** (1 req/s, real User-Agent, attribution) or a
  paid geocoder for the long tail Census can't match (rural / PO-box /
  malformed — expect a low-90s% match rate).
- Write results back as **real numbers** (convert the columns to
  `double precision`, or add `lat_num`/`lng_num`) so they can be indexed and
  fed to PostGIS. Stamp a `geocoded_at` / match-quality column so re-runs only
  touch the unmatched. Make the job idempotent + resumable — skip already-done
  rows, log failures, never let one bad address stall the run.
- **Implemented:** `scripts/geocode/geocode_facilities.py` (Census batch +
  optional Nominatim fallback, idempotent/resumable) plus the two ordered
  migrations in `supabase/migrations/`. Run order + flags in
  `scripts/geocode/README.md`.

**2. Eligibility coverage is partial — 3,713 / 162,937 (≈ 2.3%), growing.**
`DM_Supabase_Eligibility` joins `master_id → FCT_Supabase.id`. The app must
treat it as a **LEFT join**: most facilities return null eligibility today, so
the Eligibility / Preferences / Status filters must treat null as **"unknown,"
not "fails"** — otherwise turning those filters on empties the map. (The
existing `FacilityFilterService` semantics should be re-checked against this.)

**3. A wrapping view keeps the Dart model untouched.** `Facility.fromSupabase`
expects the old IL view's column names; `FCT_Supabase`'s differ. Create a
`fct_supabase_full` view (DDL below) that: casts `text` lat/lng →
`double precision`; maps `category_level_1/2/3` → an `app_category` the app
understands; LEFT-joins `DM_Supabase_Eligibility`; and passes the already-
matching columns (`facility_name`, `facility_description`, `website_url`,
`contact_email`, `street_address`, `city`, `state`, `postal_code`) straight
through. **Mapping caveat (resolved):** `contact_phones` is free-text with
varied formats — the view + RPC run it through `to_phone_jsonb` (splits on
common separators) so the model's phone list renders. `hours` / `services` are
all NULL today and pass through as-is; add a `::jsonb` cast in the view when
they're populated. No model change was needed.

#### Data-layer changes

- **Server-side point-radius query.** Replace `getAllFacilities()` +
  client-side Haversine with a bounded query. Keep the existing
  `FacilityRepositoryBase.loadFacilitiesWithDistance(latitude, longitude,
  radiusMiles)` signature — only the body changes. Two options:
  - **(A — recommended) PostGIS RPC.** Add a `geography(Point,4326)` column +
    GiST index to `FCT_Supabase`, and a `facilities_near(lat, lng, radius_m,
    max_results)` SQL function using `ST_DWithin` for the filter and
    `ST_Distance` for ordering. Call it with
    `_client.rpc('facilities_near', params: {...})`. Returns only in-radius
    rows, pre-sorted by distance, hard-capped. Scales to millions.
  - **(B — fallback, no PostGIS) bounding box.** Compute a lat/lng min/max box
    for the radius, filter with `.gte()/.lte()` on **indexed**
    `latitude`/`longitude` columns, `.limit(N)`, then refine the square to a
    circle and sort by Haversine on-device. Simpler, no extension, but
    approximate and returns a box's worth of extras.
  - DDL/RPC reference for both is at the end of this sub-section.
- **Lean projection.** Stop selecting `*` from a 162,937-row table. The
  map/list only needs `id, facility_name, latitude, longitude, app_category,
  street_address, city, state, postal_code` (+ eligibility columns used by
  the filter map). Fetch the full record lazily via `getFacilityById` only
  when a facility card is opened.
- **Hard result cap.** `max_results ≈ 250` per query. When a query hits the
  cap, surface "Zoom in or narrow your search to see more."
- **Drop the load-all cache.** Replace the global `_cache` with a small,
  short-TTL region cache keyed by *quantized* center + radius + active-filter
  signature; invalidate on filter / eligibility / preference change.
- **`FacilityProvider` semantics.** `facilities` now means "facilities for the
  current query region," not "everything." Favorites merge still works
  (intersect by id) for in-region flags, and Home's Favorites list no longer
  assumes the favorited facility is in the current region — done: the provider
  keeps a separate `_favoriteFacilities` loaded via `getFacilitiesByIds` from
  the `user_favorites` ids (signed-in only; guests can't favorite, demo uses
  in-memory flags).

#### "Search this area" interaction spec

- Hidden on first load and immediately after any query completes.
- On `onCameraIdle`, compare the current camera target to the last-query
  center. Reveal the button (fade-in) once the drift exceeds a threshold
  (~30% of the current query radius) **or** zoom changed by more than ~1 step.
- Tap → query around the **current map center**, using a radius derived from
  the visible region (`getVisibleRegion()` → half the diagonal), clamped to a
  sane min/max; show an inline spinner on the button; on completion hide the
  button and refresh markers + list panel.
- Reuse the existing `_markerUpdateDebounce` / `onCameraIdle` plumbing; the
  button gate is what prevents query spam.
- The distance chip and location-search box still re-query around their own
  center (current center / geocoded ZIP) at the chosen radius.

#### Performance & UX best practices (build these in, not later)

- **Indexes are non-negotiable:** GiST on the geography column (option A) or a
  composite btree on `(latitude, longitude)` (option B). A 162,937-row table
  scan per pan is unacceptably slow without one.
- **Marker clustering / viewport cap.** Never drop hundreds of pins on the
  map. Cluster at low zoom (e.g. `google_maps_cluster_manager`) or show
  region counts; render individual markers only near `detailZoom`. This also
  keeps `MarkerManagementService` icon generation bounded.
- **Loading affordances.** Skeleton/shimmer rows in the list panel during a
  fetch, a spinner on the "Search this area" button, and a min-visible
  duration so spinners don't flash on fast queries. Keep the existing 30s
  timeout + retry path.
- **Empty / sparse states.** Rural areas may return 0 within the default
  1 mi radius. Show "No facilities within X mi — widen your search" with a
  one-tap widen (bump to the next distance option and re-query).
- **Caching & cold start.** Optionally persist the last region's results to
  disk for an instant first paint, then refresh in the background.
- **Isolate offload.** If a capped payload still parses slowly, move
  `Facility.fromSupabase` mapping to a background isolate via `compute`.
- **Telemetry hooks.** Count capped/empty results to tune the default radius
  post-launch.

#### Still-open questions (smaller now that the schema is known)

1. ~~Is PostGIS enabled?~~ **Resolved — PostGIS is enabled; Option A is the
   chosen path.** The Option B bounding-box notes below stay only as a
   reference/fallback.
2. ~~What format are `contact_phones` / `hours` / `services`?~~ **Resolved.**
   `contact_phones` is free-text with varied formats (`xxx-xxx-xxxx`,
   `xxxxxxxxxx`, `(xxx) xxx-xxxx`) — the view + RPC normalize it to a JSON array
   via `to_phone_jsonb` so the model renders phones (no Dart change). `hours` /
   `services` are all NULL today; they pass through as-is and the model
   tolerates null — add a `::jsonb` cast in the view once they're populated.
3. **Geocoder coverage + licensing.** Census output is public-domain;
   Nominatim's policy requires attribution + ≤1 req/s. Confirm which provider
   covers the long tail and that its terms permit storing the coordinates.

#### Option A (PostGIS) vs Option B (bounding box) — performance

Both answer "facilities near a point," but differ on accuracy, index
behavior, and where the work happens.

| Dimension | A — PostGIS `ST_DWithin` + GiST | B — bounding box + btree |
|---|---|---|
| **Shape queried** | True circle (exact radius) | Square; ~21–27% extra corner rows you discard on-device |
| **Index** | GiST spatial index, purpose-built for 2-D proximity (~O(log n)) | Composite btree `(latitude, longitude)`; only the **leading** column gets a true range scan — longitude becomes a filter on that latitude band |
| **Distance sort** | Server-side via the `<->` KNN operator, index-assisted → a correct `LIMIT` of the true-nearest | Not possible server-side; must over-fetch the box and Haversine-sort on-device. A server `LIMIT` without distance order can drop closer edge facilities for farther in-box ones |
| **Latency @ ~163K rows, small radius** | Single-digit-ms index probe | Fast in sparse areas; degrades in dense latitude bands (major metros) where the lat range-scan returns many rows to filter |
| **Payload** | Exactly the capped in-radius set | A box's worth of rows (more transfer + parse) before client refine |
| **Scales to millions** | Yes — this is PostGIS's job | OK to low hundreds-of-thousands; leading-column-only indexing caps it |
| **Setup** | `create extension postgis` + `geom` column + GiST index + RPC | One btree index; pure PostgREST query — no extension, no function |
| **Footguns** | Few | Square≠circle, and the LIMIT-without-order bug above |

**Bottom line:** A is faster, exact, sorts by true distance server-side, and
is the only one that comfortably scales as the table grows. B's sole
advantage is needing no extension. **Target A; use B only if PostGIS genuinely
can't be enabled**, and treat it as a stopgap. The repository interface is
identical either way, so a later B→A swap is an internal change.

#### DDL / RPC reference

> **Runnable versions:** `supabase/migrations/0001_geocode_prep.sql` (run
> before geocoding) and `supabase/migrations/0002_facilities_postgis.sql`
> (run after). The blocks below mirror those files for reading; apply the
> files, don't copy-paste from here.

Assumes the geocode backfill (prerequisite #1) has run. First promote the
`text` coordinates to real numbers so they can be indexed / fed to PostGIS:
```sql
alter table public."FCT_Supabase"
  alter column latitude  type double precision using nullif(latitude,'')::double precision,
  alter column longitude type double precision using nullif(longitude,'')::double precision;
```

**Wrapping view (the model reads its columns; both options use it):**
```sql
create or replace view public.fct_supabase_full as
select
  f.id, f.facility_name, f.facility_description,
  f.website_url, f.contact_email, f.contact_phones,
  f.street_address, f.city, f.state, f.postal_code,
  f.latitude, f.longitude, f.hours, f.services,
  coalesce(f.category_level_1, 'Health Care') as app_category,
  f.category_level_1, f.category_level_2, f.category_level_3,
  -- eligibility (LEFT join — null for most facilities until backfilled)
  e.operational, e.proof_of_income, e.proof_of_residency,
  e.insurance_required, e.referral_required, e.accepts_walkins,
  e.appointment_only, e.open_to_immigrants, e.free_services_available,
  e.sliding_scale_available, e.other_languages, e.telehealth_available,
  e.wheelchair_accessible, e.serves_outside_area,
  e.operating_hours, e.other_eligibility_summary, e.services_summary
from public."FCT_Supabase" f
left join public."DM_Supabase_Eligibility" e on e.master_id = f.id;
```

**Option A — PostGIS (recommended):**
```sql
create extension if not exists postgis;

-- Spatial column + GiST index on the base table. Populate after each geocode
-- batch (or maintain via trigger / generated column if your Postgres accepts
-- the geography cast as immutable).
alter table public."FCT_Supabase"
  add column if not exists geom geography(Point, 4326);
update public."FCT_Supabase"
  set geom = st_point(longitude, latitude)::geography
  where latitude is not null and longitude is not null and geom is null;
create index if not exists fct_supabase_geom_gix
  on public."FCT_Supabase" using gist (geom);

-- Bounded, distance-sorted, capped. Joins eligibility + maps category so it
-- returns the same shape as fct_supabase_full (feed rows to Facility.fromSupabase).
create or replace function public.facilities_near(
  lat double precision, lng double precision,
  radius_m double precision, max_results integer default 250
)
returns table (
  id text, facility_name text, facility_description text,
  website_url text, contact_email text, contact_phones text,
  street_address text, city text, state text, postal_code text,
  latitude double precision, longitude double precision,
  hours text, services text, app_category text,
  operational text, proof_of_income text, proof_of_residency text,
  insurance_required text, referral_required text, accepts_walkins text,
  appointment_only text, open_to_immigrants text, free_services_available text,
  sliding_scale_available text, other_languages text, telehealth_available text,
  wheelchair_accessible text, serves_outside_area text,
  operating_hours text, other_eligibility_summary text, services_summary text
)
language sql stable
as $$
  select
    f.id, f.facility_name, f.facility_description,
    f.website_url, f.contact_email, f.contact_phones,
    f.street_address, f.city, f.state, f.postal_code,
    f.latitude, f.longitude, f.hours, f.services,
    coalesce(f.category_level_1, 'Health Care'),
    e.operational, e.proof_of_income, e.proof_of_residency,
    e.insurance_required, e.referral_required, e.accepts_walkins,
    e.appointment_only, e.open_to_immigrants, e.free_services_available,
    e.sliding_scale_available, e.other_languages, e.telehealth_available,
    e.wheelchair_accessible, e.serves_outside_area,
    e.operating_hours, e.other_eligibility_summary, e.services_summary
  from public."FCT_Supabase" f
  left join public."DM_Supabase_Eligibility" e on e.master_id = f.id
  where f.geom is not null
    and st_dwithin(f.geom, st_point(lng, lat)::geography, radius_m)
  order by f.geom <-> st_point(lng, lat)::geography
  limit max_results;
$$;
```
Call from Dart: `_client.rpc('facilities_near', params: {'lat': …, 'lng': …,
'radius_m': radiusMiles * 1609.34, 'max_results': 250})`.

**Option B — bounding box (no PostGIS):**
```sql
create index if not exists fct_supabase_lat_lng_idx
  on public."FCT_Supabase" (latitude, longitude);
```
Query the **view** (so you still get the category map + eligibility join). Dart
computes the box (≈ `radiusMiles / 69` for lat degrees,
`/ (69 * cos(lat))` for lng):
`_client.from('fct_supabase_full').select(projection)
  .gte('latitude', minLat).lte('latitude', maxLat)
  .gte('longitude', minLng).lte('longitude', maxLng).limit(250)`
— then refine to the circle and Haversine-sort on-device. The planner inlines
the simple view, so the `fct_supabase_lat_lng_idx` index on the base table is
still used.

> RLS: `FCT_Supabase` + `fct_supabase_full` are public facility data — enable
> RLS with a read-only `anon` / `authenticated` SELECT policy. `facilities_near`
> is `stable` and runs under the caller's RLS.

## 3. Pre-TestFlight Checklist

### Engineer (code)
- [x] All §2.1 – §2.5 tasks implemented
- [x] **§2.6 data prerequisites (scripts + SQL written; backfill treated as run — confirm before release):**
  - [x] Apply `supabase/migrations/0001_geocode_prep.sql` (tracking columns)
  - [x] Run `scripts/geocode/geocode_facilities.py` to geocode all 162,937 rows (Census + optional Nominatim)
  - [x] Apply `supabase/migrations/0002_facilities_postgis.sql` — PostGIS → lat/lng→`double precision`, `geom` + GiST index, `fct_supabase_full` view, `facilities_near` RPC, read-only RLS on `FCT_Supabase` + `DM_Supabase_Eligibility`
  - [x] `contact_phones` normalized to a JSON array in the view/RPC (`to_phone_jsonb`); `hours`/`services` null today (deferred — add `::jsonb` cast when populated)
- [ ] **§2.6 nationwide querying (code-complete ✓ — device QA pending):**
  - [x] Repoint the data source at the `facilities_near` RPC / `fct_supabase_full` view
  - [x] Server-side point-radius query via the PostGIS `facilities_near` RPC
  - [x] `max_results` cap (250) — lean projection / lazy full-record fetch deferred (RPC returns full rows; fine at the cap)
  - [x] Remove the load-all/in-memory-cache model in `SupabaseFacilityService`; quantized region cache added
  - [x] Null eligibility treated as "unknown, not fails" (already handled by `FacilityFilterService`)
  - [x] "Search this area" map button — drift-gated, explicit tap, no auto-query on pan
  - [x] Favorites resolved by id from `user_favorites` (`getFacilitiesByIds`) — region-independent Home Favorites list
  - [x] Marker clustering for dense metros (grid-bucketed count bubbles, tap to zoom)
  - [x] Empty/sparse ("search a wider area") state; loading spinner retained
  - [ ] **Verify end-to-end against the geocoded data** (smoke test ZIP search, pan + "Search this area", distance widen, sparse rural area, cluster tap, favorites across regions)
- [x] `pubspec.yaml` version: `1.0.0+1`
- [x] `flutter analyze` passes with 0 issues
- [x] `flutter test` — 18/18 unit tests pass
- [ ] `flutter build ios --release` succeeds (requires Xcode signing — run after Apple Developer Console + App Store Connect items below)
- [ ] Manual smoke test on ≥ 2 iOS devices (different screen sizes): sign-in with Apple, location permission grant/deny, feedback submission, guest mode, sign-out
- [ ] Write widget tests for `AppleSignInButton`, `_ZipEditDialog`, `EligibilityPreferencesService`, and `RecentFacilitiesService` persistence (post-launch follow-up — current 18 unit tests cover the older services)

### External Config (requires web UI / dashboard access)

**Supabase Dashboard:**
- [x] Enable Apple provider. iOS uses the native `sign_in_with_apple` package + `supabase.auth.signInWithIdToken(...)`, so Supabase only needs to validate the Apple-issued JWT against Apple's public keys — **no OAuth secret JWT is required**. Required field in Authentication → Providers → Apple:
  - **Client IDs**: comma-separated list — at minimum the iOS bundle ID (`org.beaconhealth.app`). Add a Services ID too if you ever plan to use the web OAuth fallback.
  - You can leave the "Secret Key (for OAuth)" block empty for iOS-only MVP. (If you DO need the OAuth redirect path later — e.g. Android Web client or browser sign-in — populate it then.)
- [ ] Confirm Google OAuth provider is configured (already tested in dev — needed for post-MVP Android)
- [x] Create `user_favorites` table with RLS (DDL in §2.x)
- [x] Create `facility_feedback` table with RLS (DDL in §2.x) — make sure the policy uses `for all ... with check (auth.uid() = user_id)`; otherwise inserts fail with `42501`
- [x] Create `user_settings` table with RLS (DDL in §2.x) — includes `eligibility jsonb` and `preferences jsonb` columns
- [ ] Verify RLS is enabled on all tables/views with read-only anon policy for facility data
- [ ] Confirm `SUPABASE_ANON_KEY` in `--dart-define` / GitHub Secret is the publishable key (not service role)

**Crash reporting (Sentry by default — see §8 for alternatives before locking in):**
- [ ] Decide on provider (Sentry / Crashlytics / Supabase-native logging — see §8 trade-offs)
- [ ] If staying on Sentry: create project at sentry.io (free tier: 5K errors/mo)
- [ ] Add the DSN as `SENTRY_DSN` GitHub Actions secret + pass via `--dart-define` in CI

**Google Cloud Console:**
- [ ] Update API key bundle ID restriction to `org.beaconhealth.app`
- [ ] Verify API key restricted to iOS apps + Maps SDK for iOS only
- [ ] **Enable billing on the Google Cloud project.** Maps Platform requires a billing account to be attached to the project even though the first $200/month of usage is free. Without it, tile loading fails silently — the map view will render an empty background with markers but no streets or labels (no error printed to logs). If your dev install shows a uniform dark/grey map area with no map detail despite the "✅ Google Maps initialized with API key" success log, this is almost always the cause. Verify in Google Cloud Console → Billing → Account management.
- [ ] **Confirm Maps SDK for iOS is enabled** (Cloud Console → APIs & Services → Library → "Maps SDK for iOS" → Enable). Initialization succeeding does not imply the API has actually been turned on for tile requests.

**Apple Developer Console:**
- [ ] Create Service ID for Sign in with Apple
- [ ] Configure Sign in with Apple for the App ID `org.beaconhealth.app`
- [ ] Create/download iOS Distribution certificate
- [ ] Create App Store provisioning profile for `org.beaconhealth.app`

**Xcode:**
- [x] `Runner.entitlements` with `com.apple.developer.applesignin` is in the repo + wired into `project.pbxproj` (`CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements`)
- [ ] Add **Sign in with Apple capability** in the Signing & Capabilities tab (Xcode → Runner target → "+ Capability"). The entitlement file alone isn't enough — Xcode also needs the capability listed for App Store builds.
- [ ] Run `cd ios && pod install` after pulling — `sign_in_with_apple` and `sentry_flutter` both add new CocoaPods entries
- [ ] Archive and upload to TestFlight

**App Store Connect:**
- [ ] Create App ID matching `org.beaconhealth.app`
- [ ] Set up the app in App Store Connect
- [ ] App name: "Beacon" (verify no trademark conflicts)
- [ ] Subtitle (e.g. "Find Free Healthcare Near You")
- [ ] Description + keywords
- [ ] Screenshots (6.7" + 6.5" minimum, 3 per size)
- [ ] App icon: verify `app_icon_final.jpg` meets 1024x1024 no-alpha spec
- [ ] Age rating questionnaire
- [ ] Copyright
- [ ] Privacy nutrition label (see §4)
- [ ] Export compliance: "Yes, but exempt" (HTTPS only)
- [ ] App Review notes (see §5)

---

## 4. Privacy Nutrition Label (MVP Draft)

MVP includes auth (Apple), GPS (opt-in), crash reporting, and feedback submission. Update this table in App Store Connect.

| Data Type | Collected? | Details |
|-----------|-----------|---------|
| **Email Address** | Yes — collected via Apple OAuth | Linked to user identity. Used for app functionality (account). Not used for tracking. Note: Apple "Hide My Email" may provide a relay address. |
| **User ID** | Yes — collected via Apple OAuth | Linked to user identity. Used for app functionality (favorites sync, feedback, settings). Not used for tracking. |
| **Coarse Location** | Yes — collected by Google Maps SDK | Third-party collection. Not linked to identity. Not used for tracking. |
| **Precise Location** | Yes — collected via GPS (opt-in) | Used for app functionality (finding nearby facilities). Not linked to identity. Not used for tracking. |
| **Diagnostics (Crash Data)** | Yes — collected via Sentry | Not linked to identity. Used for app functionality (crash reporting). Not used for tracking. |
| **User Content (Feedback)** | Yes — rating + text comment submitted by user | Linked to user identity. Used for app functionality. Not used for tracking. |
| All other categories | Not collected | |

**Tracking declaration:** "This app does **not** track users." No ATT prompt needed.

---

## 5. App Review Notes Template

```
This app helps users find free and low-cost healthcare facilities.

To test:
1. Launch the app — sign in with Apple, or tap "Continue as Guest"
2. Choose "Enable Location-Based Search" or enter a US zip code (e.g., 60613)
3. Browse the map, search for facilities, and use filters
4. Signed-in users can save Favorites, set Eligibility/Preferences filters, and submit facility feedback
5. Guest users see a lock icon on Favorites, Eligibility, Preferences — tapping shows a sign-in prompt
6. The "Recently Viewed Facilities" section on the home page shows the last 3 facilities tapped on the map — tapping one opens a feedback dialog (requires sign-in to submit)
7. GPS location is available via the location button on the map (requires location permission)

Demo account: Not required — Sign in with Apple uses the reviewer's Apple ID. Guest mode is fully functional for browsing.
```

---

## 6. Secrets & CI

**Local dev:**
```bash
flutter run \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<anon-key> \
  --dart-define=SENTRY_DSN=<dsn>
```
Google Maps key: `ios/Flutter/Secrets.xcconfig` (gitignored).

**GitHub Actions secrets:**

| Secret | Purpose |
|--------|---------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Publishable API key |
| `GOOGLE_MAPS_API_KEY` | iOS-restricted Maps key |
| `SENTRY_DSN` | Sentry error tracking DSN |
| `APP_STORE_CONNECT_API_KEY_ID` | Fastlane TestFlight upload |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | Fastlane TestFlight upload |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64-encoded `.p8` key |
| `MATCH_PASSWORD` | Fastlane Match encryption |

---

## 7. Post-MVP Fast Follows

| Priority | Item |
|----------|------|
| **High** | Android release — enable "Sign in with Google" (code exists, needs testing + Play Store listing) |
| **Medium** | Analytics (PostHog recommended for healthcare privacy) |
| **Medium** | Offline/connectivity handling (`connectivity_plus` + offline banner) — full design outline in **§9** (what an MVP-scoped offline mode would actually require) |
| **Medium** | Full accessibility audit (VoiceOver, Dynamic Type, WCAG 2.1 AA) |
| **Low** | Professional localization review (es, zh) |
| **Low** | iPad layout optimization |
| **Low** | Supabase Pro upgrade ($25/mo) — evaluate based on user volume **and** `FCT_Supabase` size against the 500 MB free-tier DB cap (see §2.6). Bounded queries keep egress low; DB size is the variable to watch. |

---

## 8. Crash Reporting — Sentry vs. alternatives

The code currently wires `ErrorReporter` to **Sentry** via the
`sentry_flutter` package, but that decision is reversible — `ErrorReporter`
is a thin facade and swapping the release-path implementation is a
10-line change. Before locking in Sentry for launch, here's the landscape:

| Provider | Free-tier ceiling | Flutter SDK | Native crashes (iOS) | Integrates with our stack? | Notes |
|---|---|---|---|---|---|
| **Sentry** (current) | 5K errors/mo, 50 replays, 30-day retention | Official `sentry_flutter`, mature | Yes (uses `Sentry.captureException` + native bindings) | Stack-neutral. Pairs fine with Supabase/Google Cloud. | Best Flutter docs in the space. Generous free tier for our expected MVP scale. ~$26/mo on the next paid tier (50K errors). |
| **Firebase Crashlytics** | Unlimited errors, no retention cap on free tier | Official `firebase_crashlytics` | Yes (industry-standard for native iOS/Android) | **Tight Google Cloud Console integration** — uses the same project you already have Maps Platform billing on. | Needs `GoogleService-Info.plist` + adding a Firebase project. Free tier is genuinely free at scale, but you're pulling in the whole Firebase SDK family (1–2 MB extra binary). Privacy nutrition label would gain Firebase as a data processor. |
| **Supabase logging (self-managed)** | Whatever Supabase Free tier allows (500 MB DB) | None — would need a tiny in-house `from('client_errors').insert(...)` writer | No native iOS crash capture | **Already on Supabase**, no new dependency, no new SOC2 review. | Misses native (Swift/Obj-C) crashes the Dart runtime never sees, and misses crashes that happen before Flutter starts. Useful as a *complement* to a real crash reporter, not a replacement. Probably the right backstop if you want zero new vendors. |
| **GlitchTip** | Self-hosted (or $15/mo hosted) — Sentry-compatible API | Works with the `sentry_flutter` SDK as-is | Yes | Open-source Sentry-protocol drop-in. | If you want Sentry's DX without the vendor lock-in, point `dsn:` at a GlitchTip instance. Zero code changes. Worth bookmarking if Sentry's pricing pinches later. |
| **Bugsnag / Datadog RUM / Instabug** | All paid from day one for our scale | All have Flutter packages | Yes | Stack-agnostic. | Better suited to multi-product orgs. Overkill for an MVP. |

**Recommendation for launch:** stay on **Sentry**.
- We've already wired it; switching now costs more than it saves.
- 5K errors/month is far above what a few hundred MVP testers will produce.
- It's the only option with first-party native-crash + Dart-stack-trace
  symbolication that's also "free enough" to start with.

**Reconsider Crashlytics if** the org commits to Firebase for Android
(which is the typical post-MVP path — push notifications, A/B testing,
Remote Config all live there). At that point one less vendor is worth the
Firebase SDK bloat.

**Reconsider GlitchTip if** Sentry's price-per-event becomes the
bottleneck and we want a stable self-hosted option without rewriting any
Dart code.

The `ErrorReporter` facade was specifically built so this decision can be
re-litigated without touching call sites. To swap: replace the
`Sentry.captureException(...)` block in
`lib/core/services/error_reporter.dart` with the new provider's call, and
swap `sentry_flutter` in `pubspec.yaml`.

---

## 9. Offline Mode — If It Were In MVP Scope (outline)

Offline mode is currently a **post-MVP** fast-follow (§7). This section
outlines what it would take **if promoted into the MVP**, and what the app
would actually do with no connection. The honest summary up front: a
*useful* offline mode is a meaningful chunk of work because of one hard
constraint, but a *lite* version reuses infrastructure §2.6 already adds.

### The hard constraint: map tiles need the network

The Google Maps SDK streams its tiles on demand and has **no supported
offline tile cache** in `google_maps_flutter`. So "offline" can't mean "the
same map, cached." Realistically offline mode is **list-first**: the
facility *data* (names, addresses, categories, eligibility, phone, hours)
is cached and fully browsable; the *map canvas* degrades to whatever tiles
are already in the SDK's volatile cache (often blank for un-visited areas).
A true offline map would require switching the map layer to `flutter_map` +
cached MBTiles or Mapbox offline regions — that's a post-MVP-sized swap on
its own and is **out of scope even for an MVP-offline.**

### What offline mode would do (tiered)

**Tier 1 — "Offline-lite" (the realistic MVP version).** Read-only browse of
the last data the user already pulled, plus a graceful banner:
- **Cache last results.** Persist the §2.6 region-query results to a local
  store (`sqflite`/`drift`, or `hive`) keyed by region. On launch with no
  network, hydrate the list + single-facility cards from cache. We already
  persist Recently-Viewed and ZIP via `SharedPreferences`; this extends the
  same idea to the working facility set.
- **Local geo-query over the cache.** Reuse §2.6's bounding-box math
  (Haversine) against the cached subset — or SQLite's built-in **R*Tree**
  module for an indexed local nearest query — so distance filtering still
  works offline within whatever region was last downloaded.
- **Connectivity awareness.** `connectivity_plus` drives a persistent
  "You're offline — showing saved facilities" banner and disables the
  "Search this area" button (or queues the request for when you reconnect).
  Stamp each cached region with a fetched-at time and show a staleness hint.
- **Queue writes (outbox pattern).** Feedback submissions and favorite
  toggles made offline are written to a local outbox and flushed to Supabase
  on reconnect. Favorites are already optimistic in `FacilityProvider`;
  feedback's `facility_feedback` insert would move behind the same queue.
  Surface a small "will sync when online" confirmation.
- **Auth offline.** A cached Supabase session lets a signed-in user keep
  their identity (favorites/feedback attribution) offline; *new* sign-in
  still needs network — the Apple flow can't complete offline.

**Tier 2 — "Offline-full" (post-MVP, for completeness).** Bundled or
pre-downloaded regional datasets, offline map tiles (`flutter_map` +
MBTiles), and background pre-fetch of the user's home region. Not
recommended for MVP — 162,937 rows is too large to bundle wholesale, and
the tile swap touches the entire map layer.

### What's available vs degraded vs unavailable offline

| Capability | Offline behavior (Tier 1) |
|---|---|
| Browse last-loaded facility list + detail cards | ✅ Works (from cache) |
| Distance filter within the cached region | ✅ Works (local Haversine / R*Tree) |
| Category / Eligibility / Preferences / Status filters | ✅ Works (client-side already) |
| Map tiles / panning to new areas | ⚠️ Degraded — only cached tiles; "Search this area" disabled |
| Favorites toggle | ✅ Optimistic now; ⏳ syncs on reconnect (outbox) |
| Submit facility feedback | ⏳ Queued offline, flushed on reconnect |
| New sign-in with Apple | ❌ Requires network |
| First-ever launch with no network + empty cache | ❌ Nothing to show — needs a "connect once to load your area" empty state |

### Effort & dependencies

- **New deps:** `connectivity_plus`, a local store (`sqflite`/`drift` or
  `hive`). All mature, iOS-safe.
- **New surface area:** a cache/repository layer behind
  `FacilityRepositoryBase` (offline-first: serve cache, refresh in
  background), an outbox + flush-on-reconnect service, and the banner/empty
  states. The §2.6 region cache is the natural seed — **build §2.6's caching
  with an eventual offline store in mind** even if offline ships later, so it
  isn't a rewrite.
- **Privacy note:** caching facility data locally is low-risk (public data).
  Cached *user* content (queued feedback, session) lives in app-sandboxed
  storage — call it out in the privacy label if offline ships.

**Recommendation:** keep offline **post-MVP**, but make two cheap decisions
now so the door stays open — (1) implement the §2.6 region cache through a
small repository seam rather than ad-hoc in `MapPage`, and (2) route the
feedback insert through a thin service that an outbox can later wrap. Both
are good structure regardless of offline, and they turn Tier-1 offline from
a refactor into an addition.

---
