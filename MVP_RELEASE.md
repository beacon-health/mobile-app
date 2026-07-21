# Beacon App — Pre-Launch Plan

> **Context doc for AI agents.** Read this before making changes.
>
> **Last updated:** 2026-07-08 · **Target:** iOS App Store (TestFlight ✅ working → public) · **Version:** `1.0.0+2`
>
> **Status:** All MVP code (§2.1 – §2.7 **and the §2.9 / §2.10 UX overhauls**)
> is **code-complete** — `flutter analyze` clean, 31/31 tests pass, `dart
> format` clean. The app builds and uploads to TestFlight. What's left is
> **device QA + non-engineering launch prep** (App Store listing, legal, beta
> testers) and **a few Supabase SQL blocks** (§2.7 constraint, §2.8 state gate,
> §2.9 `visited_on` + `facility_requests`; **§2.10 adds no new SQL**) — see the
> **Pre-Launch Checklist (§3)**.
>
> **✅ Done (all code)**
> - **§2.1–§2.5:** Auth (native Sign in with Apple), GPS, crash reporting
>   (Sentry via `ErrorReporter`), facility feedback, cleanup.
> - **§2.6 nationwide data:** off the ~691-row Illinois view onto
>   **`FCT_Supabase`** (162,937 rows, geocoded). PostGIS `facilities_near` RPC +
>   `fct_supabase_full` view; **server-side per-region** queries, a **"Search
>   this area"** control, **marker clustering**, **region-independent
>   Favorites**, category filter on **`category_level_2`** (12 values) with icons
>   consolidated to 4 groups, dark-mode map, overflow-safe empty states.
> - **§2.7 view & edit ratings:** ratings are read/write — a Settings **"Your
>   Ratings"** list + in-place editing (dialog pre-fills, **upsert**,
>   **Remove**) via `FacilityFeedbackService`.
> - **§2.9 UX overhaul (July 2026):** ratings rename + required visit date +
>   5-tag lists; **Request a facility** flow (dialog + Settings "Your
>   Requests"); search across description/services/tags; tap-anywhere card
>   expansion + description previews; Services above Next Steps/Hours; swipe-
>   down dismiss on the single-facility card; my-location button in the
>   resources search bar; Distance filter removed (fixed 5-mi + "Search this
>   area"); same-address marker fan-out; directions chooser (Apple/Google/
>   Waze, remembered); home shadows; **full i18n chrome coverage** (en/es/zh).
> - **§2.10 Profile + eligibility rework (July 2026):** new **Profile** nav tab
>   (gated) holding account identity, Ratings, Requests, sign-out, and the
>   **Eligibility** gates with a parent "apply to search" toggle; **Eligibility
>   auto-applies** to the map (removed from map filters); **Preferences** is now
>   Map-only; **Status** filter removed; Settings slimmed to App (now incl. ZIP
>   + Use My Location) + About; required **eligibility onboarding step** for
>   signed-in users; animated single-card collapse; cleaner rate-row layout;
>   **TestFlight CI** hardened (API-key signing + build-number bump + main
>   trigger).
>
> **⏳ Remaining**
> - **Device QA** end-to-end on real hardware (§3.1).
> - **Supabase SQL one-liners:** §2.7 unique constraint + §2.8 state-rollout
>   allow-list (both copy-paste, run in the dashboard).
> - **Non-dev launch prep** — App Store Connect listing, screenshots, privacy
>   label, legal links, beta testers (§3.2, written for hand-off).
> - **Gradual state-by-state rollout** is wired via a server-side allow-list so
>   the team can add states with one SQL `insert`, no app release (§2.8).
> - **External config** — Google Cloud, Apple Developer, Supabase RLS (§3.1).

---

## 1. Project Overview

| Area | Value |
|------|-------|
| **Framework** | Flutter 3.41.6 / Dart 3.11.4, Material 3, iOS-only (Android post-MVP) |
| **Bundle ID** | `org.beaconhealth.app` |
| **iOS min target** | 15.0 (aligned across Podfile + Xcode) |
| **Backend** | Supabase (Free tier). Data source: **`FCT_Supabase`** (162,937 rows, nationwide, geocoded) via the `facilities_near` PostGIS RPC + `fct_supabase_full` view + `DM_Supabase_Eligibility` (3,713 rows, growing). Launch gated to Illinois first via a `launched_states` allow-list — see §2.6 / §2.8 |
| **Auth** | Supabase OAuth — Sign in with Apple (iOS MVP), Google sign-in tested in dev (Android post-MVP) |
| **State mgmt** | Provider + ChangeNotifier |
| **Maps** | Google Maps Flutter plugin, API key via `Secrets.xcconfig` (gitignored) |
| **Localization** | en, es, zh via `flutter_localizations` + ARB |
| **Secrets** | `--dart-define` for Supabase URL/key; `Secrets.xcconfig` for Google Maps key. No secrets in source. |
| **Linting** | `very_good_analysis` — 0 issues (`flutter analyze` clean) |
| **Tests** | 28 unit tests (all passing) |
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
- **Feedback flow:** `RecentFacilitiesService` (last 3 viewed, persisted to SharedPreferences). Tap a row on Home → `FacilityFeedbackDialog`. Writes go through `FacilityFeedbackService` (upsert on `(user_id, facility_id)`), so re-opening pre-fills the existing rating/tags and edits in place; **Remove** deletes. Settings → **"Your Feedback"** (`MyFeedbackPage`) lists everything submitted for view/edit (§2.7).
- **Facility data (§2.6, done):** `SupabaseFacilityService.getFacilitiesNearLocation(lat, lng, radiusKm)` calls the server-side `facilities_near` PostGIS RPC — bounded, distance-sorted, capped at 250 — with a quantized per-region in-memory cache. Favorites / single-facility detail resolve by id through the `fct_supabase_full` view (region-independent). This replaced the old "load the whole table, filter on device" model, which didn't scale past the ~691-row Illinois view. State-rollout gating lives in the RPC (§2.8).
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
| Feedback service (read/upsert/delete) | `lib/core/services/facility_feedback_service.dart` |
| Feedback dialog | `lib/features/home/presentation/widgets/facility_feedback_dialog.dart` |
| "Your Feedback" list (§2.7) | `lib/features/settings/presentation/pages/my_feedback_page.dart` |
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

**All code work (§2.1 – §2.7) is complete.** `flutter analyze` is clean (0
issues) and `flutter test` passes (28/28). What's left is device QA, two
Supabase SQL one-liners (§2.7, §2.8), and non-engineering launch prep (§3).
The subsections below are kept as the implementation record.

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
- `pubspec.yaml` at `1.0.0+2` (bump `+N` per TestFlight upload).
- **ARB scrub:** removed 40 stale keys (old home categories, Profile tab,
  hardcoded filter/map strings, retired settings inputs) across `app_en/es/zh`;
  all three now share an identical 64-key set, every used key translated.
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

Moved the data source off the ~691-row Illinois view to the nationwide
**`FCT_Supabase`** (162,937 rows, geocoded via the Census batch script) and
replaced "load everything, filter on device" with bounded server-side queries.
`flutter analyze` clean, 28 tests pass; geocoding + the PostGIS schema (view +
RPC, DDL below) applied. What shipped:
- **Server-side proximity** via the PostGIS `facilities_near` RPC +
  `fct_supabase_full` view; `SupabaseFacilityService` calls it with a quantized
  region cache (no more load-all), capped at 250 results.
- **"Search this area"** drift-gated map button (no auto-query on pan), and
  Home→Map navigation that re-centers (favorites + map cutout).
- **Marker clustering** when zoomed out (grid bubbles, tap to zoom in).
- **Region-independent Favorites** — resolved by id from `user_favorites`.
- **Category filter on `category_level_2`** (12 values) with marker/list icons
  consolidated to 4 groups (see below). Null eligibility treated as "unknown".
- Empty/sparse "search a wider area" state; dark-mode map style; `contact_phones`
  normalized to a list; summary-sentinel ("N") scrubbing.
- **Remaining:** device QA pass; optional lean projection / lazy detail fetch
  (the RPC returns full rows — fine at the 250 cap).

> ⚠️ The SQL below is the **authoritative record** — apply it via Supabase
> Dashboard → SQL Editor. The view + RPC are idempotent (`create or replace`);
> re-running is safe if the definition changes.

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

#### DDL / RPC reference (applied)

Two query entry points drive the map: a **ZIP location-search change** (geocode
→ query around that point at the default distance) and a **"Search this area"**
button on pan/zoom (explicit, quota-friendly — no auto-query on camera move).
Both call the `facilities_near` RPC below.

The geocode backfill ran first; the `text` coordinates were then promoted to
real numbers so they can be indexed / fed to PostGIS:
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

**PostGIS spatial column + RPC:**
```sql
create extension if not exists postgis;

-- Spatial column + GiST index on the base table. Populate after each geocode
-- batch (or maintain via trigger / generated column if your Postgres accepts
-- the geography cast as immutable).
alter table public."FCT_Supabase"
  add column if not exists geom geography(Point, 4326);
update public."FCT_Supabase"
  set geom = st_setsrid(st_point(longitude, latitude), 4326)::geography
  where latitude is not null and longitude is not null and geom is null;
create index if not exists fct_supabase_geom_gix
  on public."FCT_Supabase" using gist (geom);
```

The **`facilities_near` RPC** body (bounded, distance-sorted, capped, joins
eligibility) is shown in full in **§2.8** — that's the authoritative deployed
definition (returns `contact_phones` as `jsonb` via the `to_phone_jsonb` helper,
includes `category_level_2`, `st_setsrid`-wrapped, limit clamped) and already
carries the state-rollout gate. Copy it from there if standing the function up
fresh. Called from `SupabaseFacilityService.getFacilitiesNearLocation` as
`_client.rpc('facilities_near', params: {'lat': …, 'lng': …, 'radius_m':
radiusKm * 1000, 'max_results': 250})`.

> RLS: `FCT_Supabase` + `fct_supabase_full` are public facility data — enable
> RLS with a read-only `anon` / `authenticated` SELECT policy. `facilities_near`
> is `stable` and runs under the caller's RLS.

### 2.7 View & Edit Submitted Feedback ✅ DONE (one Supabase one-liner pending)

Feedback used to be write-only — §2.4 inserted a `facility_feedback` row and
never surfaced it again. It's now fully read/write:
- **`FacilityFeedbackService`** (`lib/core/services/facility_feedback_service.dart`)
  is the single seam for `getForFacility` / `getMine` / `submit` (upsert) /
  `delete`, plus the tag↔`comment` parsing (`FacilityFeedbackEntry`). This is
  also the offline outbox seam §9 recommends.
- **In-place editing:** `FacilityFeedbackDialog` now loads any existing
  feedback on open and **pre-fills** the rating + tag chips; the write is an
  **upsert keyed on `(user_id, facility_id)`** (edits replace, not duplicate),
  and a **Remove** action deletes it. Submit button reads "Update" when editing.
- **"Your Feedback" surface:** a Settings list (`MyFeedbackPage`, signed-in
  only) shows every rating (facility name resolved by id — same region-
  independent path as Favorites, rating icon, tags, date). Tap a row to
  edit/remove via the same dialog. Empty + pull-to-refresh states included.
- Tests: `FacilityFeedbackEntry` parsing/round-trip is unit-tested
  (`test/core/services/facility_feedback_service_test.dart`).

**Supabase one-liner to run** (backs the upsert — without it, edits insert
duplicate rows):
```sql
alter table public.facility_feedback
  add constraint facility_feedback_user_facility_uniq unique (user_id, facility_id);
```
RLS already covers it — the existing `for all … with check (auth.uid() =
user_id)` policy lets owners SELECT / UPDATE / DELETE their own rows.

> Not wired: an in-context "You rated this 👍 — edit" affordance on the map
> facility detail card. The Settings list + the Recently-Viewed funnel cover
> view & edit for MVP; the card affordance is an easy post-MVP add (the service
> + dialog already support it).

### 2.8 Gradual State-by-State Rollout ✅ DESIGN — one Supabase table to add

The app already points at the full nationwide `FCT_Supabase`, but the team wants
to **launch one state at a time** (Illinois first) as the eligibility table is
populated, expanding **without re-pointing the app or shipping a new build each
time**.

**Recommendation: a server-side allow-list table the RPC filters against.** Add
a tiny `launched_states` table and have `facilities_near` (and, optionally, the
view) return only facilities whose `state` is in it. Adding a state is then a
**one-row `insert` in the Supabase dashboard — no app release, no App Store
review.** This is strictly better than the alternatives:

| Approach | Add a state by… | App release to expand? | Notes |
|---|---|---|---|
| **Allow-list table (recommended)** | `insert` one row | **No** | Single source of truth; non-dev team can flip states via SQL; instant. |
| Hardcoded state list in Dart | edit code, rebuild | **Yes** (days of review) | Client builds drift out of sync; every state = a release cycle. |
| Per-row `is_live` flag on facilities | update ~thousands of rows | No | Touches 162,937 rows; state-grain matches how the data is actually populated. |

**SQL (run in the dashboard):**
```sql
-- 1. Allow-list of launched states. Seed with Illinois.
create table if not exists public.launched_states (
  state_code text primary key,           -- must match FCT_Supabase.state values
  launched_at timestamptz default now() not null
);
insert into public.launched_states (state_code) values ('IL')
  on conflict do nothing;

alter table public.launched_states enable row level security;
create policy "Anyone can read launched states" on public.launched_states
  for select using (true);
```
Then re-run `facilities_near` **in its entirety** with the state-gate clause
added to the `where`. This is the **live deployed definition** (verified via
`pg_get_functiondef`) — it returns `contact_phones` as `jsonb` (via the
`to_phone_jsonb` helper), includes `category_level_2`, wraps points in
`st_setsrid`, and clamps the limit. Because the return type is unchanged, this
is a clean `create or replace` (no drop needed):
```sql
CREATE OR REPLACE FUNCTION public.facilities_near(lat double precision, lng double precision, radius_m double precision, max_results integer DEFAULT 250)
 RETURNS TABLE(id text, facility_name text, facility_description text, website_url text, contact_email text, contact_phones jsonb, street_address text, city text, state text, postal_code text, latitude double precision, longitude double precision, hours text, services text, app_category text, category_level_2 text, operational text, proof_of_income text, proof_of_residency text, insurance_required text, referral_required text, accepts_walkins text, appointment_only text, open_to_immigrants text, free_services_available text, sliding_scale_available text, other_languages text, telehealth_available text, wheelchair_accessible text, serves_outside_area text, operating_hours text, other_eligibility_summary text, services_summary text)
 LANGUAGE sql
 STABLE
AS $function$
  select
    f.id,
    f.facility_name,
    f.facility_description,
    f.website_url,
    f.contact_email,
    public.to_phone_jsonb(f.contact_phones),
    f.street_address,
    f.city,
    f.state,
    f.postal_code,
    f.latitude,
    f.longitude,
    f.hours,
    f.services,
    coalesce(f.category_level_1, 'Health Care'),
    f.category_level_2,
    e.operational,
    e.proof_of_income,
    e.proof_of_residency,
    e.insurance_required,
    e.referral_required,
    e.accepts_walkins,
    e.appointment_only,
    e.open_to_immigrants,
    e.free_services_available,
    e.sliding_scale_available,
    e.other_languages,
    e.telehealth_available,
    e.wheelchair_accessible,
    e.serves_outside_area,
    e.operating_hours,
    e.other_eligibility_summary,
    e.services_summary
  from public."FCT_Supabase" f
  left join public."DM_Supabase_Eligibility" e on e.master_id = f.id
  where f.geom is not null
    and st_dwithin(f.geom, st_setsrid(st_point(lng, lat), 4326)::geography, radius_m)
    -- §2.8 state gate: 'ALL' = nationwide; otherwise restrict to launched states.
    and (
      exists (select 1 from public.launched_states where state_code = 'ALL')
      or f.state in (select state_code from public.launched_states)
    )
  order by f.geom <-> st_setsrid(st_point(lng, lat), 4326)::geography
  limit greatest(1, least(max_results, 1000));
$function$
```
> Only line added vs. the deployed function: the `and ( … )` state gate after
> `st_dwithin`. Run the `launched_states` `create table` + seed **first**. If you
> ever see `ERROR: 42P13 cannot change return type`, the live shape has drifted
> again — re-dump with `pg_get_functiondef('public.facilities_near(double precision,double precision,double precision,integer)'::regprocedure)` and add the clause to that.

**Operating it:**
- **Add a state:** `insert into public.launched_states (state_code) values ('IN');`
- **Go nationwide:** `insert into public.launched_states (state_code) values ('ALL');`
- **Verify the code format first** — `state_code` must match what
  `FCT_Supabase.state` stores (e.g. `'IL'` vs `'Illinois'`):
  `select distinct state from public."FCT_Supabase" order by 1;`

**Notes / decisions:**
- **Fail-closed:** an empty table returns *no* facilities, so a fresh deploy
  can't accidentally expose un-launched states. Seed `'IL'` before launch.
- **Border bleed is handled:** because gating is inside the radius RPC, a user
  near a state line only sees launched-state facilities — exactly the intent.
- **No Dart change** — the existing RPC signature is unchanged. Favorites /
  single-facility detail go through the view (`fct_supabase_full`), which is
  intentionally left **ungated** (users only favorite what they already saw). If
  you want those gated too, add the same `state in (…)` filter to the view.
- **Eligibility is independent:** this gates *which facilities appear*, not
  whether eligibility is populated. IL eligibility being filled in is what makes
  IL the right first state; other states can launch list-only and gain
  eligibility later.

### 2.9 UX Overhaul Batch (July 2026) ✅ CODE-COMPLETE (device QA + 2 SQL pending)

Twelve UX/functional changes requested 2026-07-08 — **all implemented**;
`flutter analyze` clean, **31/31 tests pass**. Executed as independent,
file-scoped workstreams (A–I), i18n last. Decisions confirmed with the product
owner: rating tag lists trimmed to **5 options each**; Get Directions uses a
**chooser sheet + remembered choice** (iOS has no default-maps API); the
map-page rate entry lives on **expanded facility cards**; the required rating
date is **date-of-visit, defaulting to today, past dates only**.

**Still needed before device testing:** run the two SQL blocks below
(`visited_on` column + `facility_requests` table) — the rating dialog writes
`visited_on` on every submit and the request flow reads/writes
`facility_requests`, so both features fail without them. Then `cd ios && pod
install` isn't required (no new pods), but do a **full rebuild** — Info.plist
gained `LSApplicationQueriesSchemes` (Google Maps / Waze detection).

**Post-QA refinements (first device pass, 2026-07-08):**
- **ZIP/location search bar hidden** on the map page — users navigate with the
  my-location button + "Search this area". `LocationSearch` is kept in the tree
  (unrendered) for easy reinstatement; Settings ZIP edits still flow in via
  `ZipCodeService`.
- **List preview falls back to the services summary** (descriptions are null
  across the dataset today; description auto-takes-over when populated).
- **Rate entry moved into Next Steps** (under Get directions) instead of a
  divider-separated footer row.
- **Single-card handle blends in** — the drag handle renders on the card's own
  background (`FacilityCard.showDragHandle` + zero margin + matching radius);
  no separate chrome strip.
- **Marker fan-out is now a fixed ~25 m geographic offset** (was zoom-scaled
  pixels) — co-located markers no longer slide together/apart while zooming.

**Notable implementation decisions:**
- **Feedback → Ratings** across all UI; the `facility_feedback` table name and
  `FacilityFeedbackService` class stay (they document the storage), while the
  dialog moved to `lib/core/widgets/facility_rating_dialog.dart` and Settings
  gained **Your Ratings** + **Your Requests** + **Directions app** rows.
- **i18n approach re-evaluated:** the gen-l10n/ARB infrastructure was right —
  the failure was *coverage*. All app chrome is now keyed (~85 new keys ×
  en/es/zh): map page, filter bar/modal (incl. eligibility/preference option
  names via `filter_l10n.dart`), facility card, rating/request dialogs,
  Settings toggles, home sections. **Location sentinels** ("Current Location",
  "Map area") are stored canonically and translated at display time, so
  language switches can't break placeholder-clearing logic.
  **Deliberately not translated (data, not chrome):** facility
  names/descriptions/services from the DB, `category_level_2` filter values,
  and the rating **tag phrases** (stored verbatim in the `comment` column —
  localizing them would break round-tripping; a display-map is a post-MVP
  follow-up alongside the §7 professional-localization review).
- **Same-coordinate markers** fan out in a ~35 px circle (zoom-aware,
  deterministic by id) so co-located facilities stay individually tappable.
- **5-mile fixed radius** everywhere (initial load, ZIP change, Search this
  area); the Distance chip/modal section and "widen search" empty state are
  gone — the empty state now funnels into **Request a facility** (guest-gated,
  writes to `facility_requests` with status `pending`).

| WS | Scope | Key files |
|---|---|---|
| **A** | Foundations: 5-mi default radius constant; `visited_on` on the feedback service; new `FacilityRequestService`; new `MapLauncherService` (directions chooser + remember); `LSApplicationQueriesSchemes`; phone formatter | `map_constants.dart`, `facility_feedback_service.dart`, `facility_request_service.dart` (new), `map_launcher_service.dart` (new), `Info.plist` |
| **B** | Rating dialog: rename Feedback→Ratings, remove explainer, 5 tags/rating, tags optional, required visit-date picker (default today, past-only), pre-fill incl. date | `facility_rating_dialog.dart` (moved to `core/widgets/`) |
| **C** | Settings: "Your Ratings" (renamed), new "Your Requests", "Directions app" row | `my_ratings_page.dart` (renamed), `my_requests_page.dart` (new), `settings_page.dart` |
| **D** | Facility card: Services above Next Steps/Hours; subtitle shows **description** (fallback city, state); tap anywhere toggles expansion; "Already visited? Rate your experience" row; directions via chooser; consistent phone/hours formatting | `facility_card.dart` |
| **E** | Map page: my-location button moves into the "Search for resources" bar; Distance filter removed (fixed 5-mi initial + "Search this area" queries); single-facility card gets handle bar + swipe-down dismiss; empty state → "Can't find a facility? Submit a request to add one" | `map_page.dart`, `facility_search.dart`, `location_search.dart`, `filter_bar.dart`, `filter_modal.dart`, `facility_list_panel.dart` |
| **F** | Same-coordinate facilities fan out with small deterministic offsets so both markers stay visible/tappable | `marker_management_service.dart` |
| **G** | Home: Recently Viewed + Favorites drop `Border.all` for card-style shadows | `home_page.dart` |
| **H** | i18n: full-coverage ARB sweep (map page, filters, facility card, dialogs, settings toggles, home). Sentinel labels ("Current Location", "Map area") stay stable internally and are translated at display time. **DB-sourced content (facility names/descriptions/category values) stays English** — data, not chrome | `app_en/es/zh.arb`, all UI files |
| **I** | `flutter analyze` + tests green; doc updated; manual dev tasks listed | — |

**Search scope decision:** facility search matches **name, description,
services, services summary, and category values** over the loaded region pool
(client-side — zero extra DB load; the pool is ≤250 rows). Server-side trigram
search across all 162,937 rows is deliberately out of scope for MVP.

**Supabase SQL to run (manual — see §3.1):**
```sql
-- (1) Rating visit date (required in the new dialog)
alter table public.facility_feedback
  add column if not exists visited_on date;

-- (2) Facility add-requests (temp table for internal review)
create table if not exists public.facility_requests (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  facility_name text not null,
  description text,
  services text,
  street_address text,
  city text,
  state text,
  postal_code text,
  phone text,
  status text default 'pending' not null,  -- pending | approved | rejected
  created_at timestamptz default now() not null
);
alter table public.facility_requests enable row level security;
create policy "Users manage own facility requests" on public.facility_requests
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

### 2.10 Profile Tab + Eligibility/Preferences Rework (July 2026) ✅ CODE-COMPLETE

Restructured where Eligibility, Preferences, and account data live, plus CI +
polish fixes. `flutter analyze` clean, 31/31 tests, `dart format` clean. **No
new Supabase SQL** — the eligibility parent toggle rides in the existing
`user_settings.eligibility` jsonb (`apply_to_search`).

**Navigation & pages**
- New **Profile** tab between Map and Settings (`lib/features/profile/…`),
  **gated** — guests see a sign-in CTA only (per product decision). Signed-in
  users get: account identity ("Signed in through…"), **Your Ratings**, **Your
  Requests**, **Eligibility** gates, and **Sign out** (all moved off Settings).
- **Settings** slimmed to **App** + **About**. ZIP code and Use My Location
  moved into the **App** section; account/eligibility/preferences/sign-out
  removed. (The old dead `profile_page.dart` DOB/income form was replaced.)

**Eligibility vs. Preferences split**
- **Eligibility** is no longer a map filter. It lives only on Profile and
  **auto-applies** to map search, gated by a parent **"Apply eligibility
  criteria to search"** toggle (`EligibilityState.applyToSearch`, default on).
  Turning it off **disables (doesn't reset)** the child gates. The map listens
  to `EligibilityPreferencesService` and re-filters when it changes.
- **Preferences** is now **Map-only** (the existing filter chip/modal section),
  still sign-in-gated for guests (per product decision). Removed from Settings.
- **Status** filter (chip + modal section + action sheet) removed entirely.

**Onboarding**
- After the location step, **signed-in** users hit a **required** Eligibility
  step (`EligibilityOnboardingPage`) before the app opens; **guests skip it**.
  Picks carry to the Profile tab. Both the GPS-grant and ZIP-entry paths route
  through `finishLocationOnboarding()`.

**Polish**
- Single-facility card now **animates its swipe-down/tap collapse** (slide
  down, matching the list panel) instead of vanishing.
- Facility card "Already visited? Rate your experience" moved to a **clean
  full-width row** under Next Steps/Hours (was wrapping to 4 lines in the
  narrow column).

**TestFlight CI hardening** (see §3.1 / §6)
- `ios/fastlane/Fastfile` `beta` lane now does **App Store Connect API-key
  automatic ("cloud-managed") signing** (`-allowProvisioningUpdates` +
  `signingStyle: automatic`) — the previous lane never set up signing at all.
- Workflow triggers on **push to `main`** (doc-only commits ignored) as well as
  manual dispatch, and the build number is `1000 + github.run_number` so
  TestFlight never rejects a duplicate. Added `ios/Gemfile` + `bundle exec`.
- **Requires** the App Store Connect API key to have **App Manager** access
  (needed to create/download the distribution cert + profile). See §6.

**Lint note:** `require_trailing_commas` was disabled in
`analysis_options.yaml` — it's incompatible with Dart 3.7+'s "tall style"
`dart format` (which strips those commas), so the two fought in CI.
`very_good_analysis` retired the rule for the same reason.

> **iOS Metal HUD (dev question):** the black telemetry box a single tester saw
> over the map is iOS's **Metal Performance HUD**, a per-device developer
> overlay (Settings → Developer → Graphics HUD, or `MTL_HUD_ENABLED=1` in an
> Xcode scheme). Not app code; never appears in Release/TestFlight builds.

## 3. Pre-Launch Checklist

All MVP **code** is done and the app uploads to TestFlight. The work below is
split into **§3.1 engineering/backend** (dev-owned) and **§3.2 non-functional**
(hand-off to non-dev team). The single biggest gate is **device QA**.

### 3.1 Engineering & Backend (dev-owned)

**Code — done**
- [x] §2.1–§2.7 + §2.9 implemented; `flutter analyze` clean (0 issues); `flutter test` 31/31
- [x] `flutter build ios --release` compiles (verified `--no-codesign`; SPM disabled → pure CocoaPods). Re-verify after §2.9 (Info.plist changed).
- [x] `pubspec.yaml` at `1.0.0+2` (bump `+N` for each TestFlight upload)
- [ ] Widget tests for `AppleSignInButton`, `_ZipEditDialog`, `EligibilityPreferencesService`, `RecentFacilitiesService` (post-launch follow-up)

**Supabase SQL to run** (copy-paste → Dashboard → SQL Editor)
- [x] §2.6 PostGIS schema: lat/lng→`double precision`, `geom` + GiST index, `fct_supabase_full` view, `facilities_near` RPC
- [ ] **§2.7 unique constraint** on `facility_feedback (user_id, facility_id)` — backs the upsert (without it, edits duplicate)
- [ ] **§2.8 state allow-list:** create `launched_states`, seed `'IL'`, re-run the full `facilities_near` in §2.8
- [ ] **§2.9 `visited_on` column** on `facility_feedback` — rating submits **fail** without it
- [ ] **§2.9 `facility_requests` table** + RLS — the request flow fails without it
- [ ] Verify **RLS** (read-only `anon`) on `FCT_Supabase`, `fct_supabase_full`, `DM_Supabase_Eligibility`, `launched_states`; confirm `SUPABASE_ANON_KEY` is the **publishable** key (not service role)

**Device QA — the main gate** (smoke test on ≥2 iOS devices, different sizes)
- [ ] Auth/onboarding: Apple sign-in, location grant/deny, guest mode, sign-out
- [ ] §2.6 map: ZIP search, pan + "Search this area" (fixed 5 mi), sparse rural area, cluster tap, Favorites across regions
- [ ] §2.7/§2.9 ratings: rate from a map card ("Already visited?"), date picker (past-only), tags optional, re-open (pre-filled), edit, **Remove**, Settings → "Your Ratings"
- [ ] §2.9 requests: empty map area → "Request a facility" dialog → row appears under Settings → "Your Requests" (status `pending`)
- [ ] §2.9 UX: my-location button in the resources search bar; search matches description/services; tap-anywhere card expansion; description preview on collapsed rows; Services above Next Steps/Hours; swipe-down dismisses the single-facility card; two same-address facilities render side-by-side
- [ ] §2.9 directions: first "Get directions" shows the chooser (Google Maps/Waze listed only if installed), choice remembered, changeable in Settings → "Directions app"
- [ ] §2.9 i18n: switch to Spanish and Chinese — home sections, Settings toggles, map filter bar/modal, facility card labels, and both dialogs all translate (facility data + rating tags stay English by design)
- [ ] §2.8: confirm **only Illinois** facilities appear until more states are added

**Technical console config** (dev/admin access)
- *Google Cloud:* [ ] restrict Maps key to `org.beaconhealth.app` + Maps SDK for iOS; [ ] **enable billing** (else tiles fail silently → uniform grey map despite a success log — check Billing → Account management); [ ] confirm "Maps SDK for iOS" is enabled in the API Library
- *Apple Developer:* [ ] Service ID for Sign in with Apple; [ ] configure Sign in with Apple for `org.beaconhealth.app`; [ ] iOS Distribution certificate; [ ] App Store provisioning profile
- *Xcode:* [x] entitlements wired; [x] pure CocoaPods (SPM disabled — re-migrates if SPM is enabled globally, keep it off in CI); [ ] add **Sign in with Apple capability** (Signing & Capabilities — the entitlement file alone isn't enough); [ ] `cd ios && pod install` after pulling; [ ] always open **`Runner.xcworkspace`** (not the bare project); [ ] upload via `flutter build ipa --dart-define-from-file=config/dart_defines.json` or Archive → Transporter/Fastlane
- *Supabase auth:* [x] Apple provider enabled (Client IDs incl. bundle ID; OAuth secret **not** needed for native iOS); [ ] confirm Google provider (post-MVP Android)
- *Crash reporting:* [ ] confirm Sentry (or pick an alternative — §8); [ ] create sentry.io project (free 5K errors/mo); [ ] add `SENTRY_DSN` GitHub secret + pass via `--dart-define`

### 3.2 Non-Functional — Hand-off to Non-Dev Team

The non-engineering launch prep (App Store Connect listing, visual assets,
compliance/legal) **and the Privacy Nutrition Label** now live in a standalone,
hand-off-ready file at the repo root:
**[`Non-Functional_Checklist.md`](Non-Functional_Checklist.md)**.
App Review notes (the reviewer "how to test" text) remain in §5 below.

---

## 4. Privacy Nutrition Label

Moved to **[`Non-Functional_Checklist.md`](Non-Functional_Checklist.md)** (the
"Privacy Nutrition Label" section) so the non-dev checklist is self-contained.
Enter those answers in App Store Connect → App Privacy.

---

## 5. App Review Notes Template

```
This app helps users find free and low-cost healthcare facilities.

To test:
1. Launch the app — sign in with Apple, or tap "Continue as Guest"
2. Choose "Enable Location-Based Search" or enter a US zip code (e.g., 60613)
3. Browse the map, search for facilities, and use filters
4. Signed-in users can save Favorites, set Eligibility/Preferences filters, and submit facility feedback (and review/edit it under Settings → "Your Feedback")
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
| `MATCH_PASSWORD` | Fastlane Match encryption (unused — CI now uses API-key cloud signing, §2.10) |

> **TestFlight signing (§2.10):** the `beta` lane uses **API-key cloud-managed
> signing** — the App Store Connect API key above must have **App Manager**
> access so Xcode can create/download the distribution certificate + App Store
> provisioning profile at build time. No Fastlane Match / certs repo is needed.
> The workflow runs on push to `main` and bumps the build number automatically
> (`1000 + run_number`).

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
