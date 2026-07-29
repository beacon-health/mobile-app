# Beacon App — Pre-Launch Plan

> **Context doc for AI agents.** Read this before making changes.
>
> **Last updated:** 2026-07-29 · **Target:** iOS App Store (TestFlight ✅ working → public) · **Version:** `1.0.0+2` · **Toolchain:** Flutter 3.44.2 (stable) / Dart 3.12.2
>
> **Status:** All MVP **app code** (§2.1 – §2.13) is **code-complete** — `flutter
> analyze` clean, **30/30 tests** pass, `dart format` clean. The app builds and
> uploads to TestFlight. Everything left is **not app code**: (1) a set of
> copy-paste **Supabase SQL** migrations, (2) **device QA** on real hardware,
> and (3) the **App Store submission** steps (signing / capabilities / privacy
> manifest / export compliance, plus the non-dev listing). All three are
> enumerated in the **Pre-Launch Checklist (§3)** — start there.
>
> **✅ Done — all app code (§2.1–§2.11)**
> - **§2.1–§2.5:** Auth (native Sign in with Apple), GPS, crash reporting
>   (Sentry via `ErrorReporter`), facility ratings, cleanup.
> - **§2.6 nationwide data:** off the ~691-row Illinois view onto
>   **`FCT_Supabase`** (162,937 rows, geocoded). PostGIS `facilities_near` RPC +
>   `fct_supabase_full` view; **server-side per-region** queries, a **"Search
>   this area"** control, **marker clustering**, **region-independent
>   Favorites**, category filter (now on `category_broad` — see §2.13), dark-mode map, overflow-safe empty states.
> - **§2.7 view & edit ratings:** ratings are read/write — a **"Your Ratings"**
>   list + in-place editing (dialog pre-fills, **upsert**, **Remove**) via
>   `FacilityFeedbackService`.
> - **§2.9 UX overhaul:** Feedback→**Ratings** rename + required visit date +
>   5-tag lists; **Request a facility** flow ("Your Requests"); search across
>   description/services/tags; tap-anywhere card expansion + description
>   previews; Services above Next Steps/Hours; swipe-down dismiss; my-location
>   button in the resources search bar; Distance filter removed (fixed 5-mi +
>   "Search this area"); same-address marker fan-out; directions chooser
>   (Apple/Google/Waze, remembered); home shadows; **full i18n** (en/es/zh).
> - **§2.10 Profile + eligibility rework:** new **Profile** nav tab (gated)
>   holding account identity, Ratings, Requests, sign-out, and the
>   **Eligibility** gates with a parent "apply to search" toggle; eligibility
>   **auto-applies** to the map (removed from map filters); **Preferences** is
>   now Map-only; **Status** filter removed; Settings slimmed to App (incl. ZIP
>   + Use My Location) + About; required **eligibility onboarding step**
>   (signed-in only); animated single-card collapse; **TestFlight CI** hardened
>   (API-key signing + build-number bump + main trigger).
> - **§2.11 card/requests refinements:** eligibility parent/child split; **"At a
>   Glance"** above Services; **Submit corrections** dialog →
>   `facility_requests`; request form simplified to name + website; single-card
>   expand/collapse via the handle bar; list-row expand centers the map; home
>   cutout zoomed out.
> - **§2.12 pre-submission scrub:** **demo mode deleted** (unreachable dead
>   code); `UrlLauncherService` debug/i18n fixes; comments trimmed to the
>   non-obvious; **privacy manifest data types filled in**, export-compliance
>   key added, target set to **iPhone-only** for 1.0.
> - **§2.13 category taxonomy:** moved onto **`category_broad`** (13 readable
>   filter values) / **`category_detail`**, replacing the raw
>   `category_level_1`/`level_2` strings. **Needs the §3.3 SQL to take effect.**
>
> **⏳ Remaining before App Store (no app code — all in §3)**
> - **Supabase SQL** — one consolidated run-order in §3.1 (base schema + §2.6
>   PostGIS, `facility_feedback` unique constraint + `visited_on`,
>   `facility_requests` + correction columns, `launched_states` gate, RLS).
> - **Device QA** end-to-end on ≥2 real devices (§3.1).
> - **App Store submission (technical)** — distribution signing, Sign in with
>   Apple capability, privacy manifest, export-compliance key, dSYM upload,
>   attach build → submit for review (§3.2).
> - **Non-dev launch prep** — App Store Connect listing, screenshots, privacy
>   label, legal links (in `Non-Functional_Checklist.md`; see §3.4).
> - **Gradual state-by-state rollout** is wired server-side (§2.8) — add a state
>   with one SQL `insert`, no app release.

---

## 1. Project Overview

| Area | Value |
|------|-------|
| **Framework** | Flutter 3.44.2 (stable) / Dart 3.12.2, Material 3, iOS-only (Android post-MVP) |
| **Bundle ID** | `org.beaconhealth.app` |
| **iOS min target** | 15.0 (aligned across Podfile + Xcode) |
| **Backend** | Supabase (Free tier). Data source: **`FCT_Supabase`** (162,937 rows, nationwide, geocoded) via the `facilities_near` PostGIS RPC + `fct_supabase_full` view + `DM_Supabase_Eligibility` (3,713 rows, growing). Launch gated to Illinois first via a `launched_states` allow-list — see §2.6 / §2.8 |
| **Auth** | Supabase OAuth — Sign in with Apple (iOS MVP), Google sign-in tested in dev (Android post-MVP) |
| **State mgmt** | Provider + ChangeNotifier |
| **Maps** | Google Maps Flutter plugin, API key via `Secrets.xcconfig` (gitignored) |
| **Localization** | en, es, zh via `flutter_localizations` + ARB |
| **Secrets** | `--dart-define` for Supabase URL/key; `Secrets.xcconfig` for Google Maps key. No secrets in source. |
| **Linting** | `very_good_analysis` — 0 issues (`flutter analyze` clean) |
| **Tests** | 30 unit tests (all passing) |
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
- **Ratings flow:** `RecentFacilitiesService` (last 3 viewed, persisted to SharedPreferences). Tap a row on Home → the rating dialog (`lib/core/widgets/facility_rating_dialog.dart`). Writes go through `FacilityFeedbackService` (upsert on `(user_id, facility_id)`; the `facility_feedback` table name is kept), so re-opening pre-fills the existing rating/tags/visit-date and edits in place; **Remove** deletes. **Profile → "Your Ratings"** (`MyRatingsPage`) lists everything submitted for view/edit (§2.7; moved off Settings in §2.10).
- **Facility data (§2.6, done):** `SupabaseFacilityService.getFacilitiesNearLocation(lat, lng, radiusKm)` calls the server-side `facilities_near` PostGIS RPC — bounded, distance-sorted, capped at 250 — with a quantized per-region in-memory cache. Favorites / single-facility detail resolve by id through the `fct_supabase_full` view (region-independent). This replaced the old "load the whole table, filter on device" model, which didn't scale past the ~691-row Illinois view. State-rollout gating lives in the RPC (§2.8).
- **Filter bar (post-§2.10):** Tune → Open Now → Favorites → Category → **Preferences** (Map-only, sign-in-gated). The **Distance**, **Status**, and **Eligibility** chips were removed: distance is a fixed 5-mile radius (§2.9), Status is gone, and Eligibility now lives on the **Profile** tab and **auto-applies** to map search via `EligibilityPreferencesService` (parent "apply to search" toggle) — the map re-filters when it changes.

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
| Ratings service (read/upsert/delete) | `lib/core/services/facility_feedback_service.dart` |
| Rating dialog | `lib/core/widgets/facility_rating_dialog.dart` |
| "Your Ratings" list (§2.7) | `lib/features/settings/presentation/pages/my_ratings_page.dart` |
| "Your Requests" list (§2.9/§2.11) | `lib/features/settings/presentation/pages/my_requests_page.dart` |
| Facility request/correction service | `lib/core/services/facility_request_service.dart` |
| Request-a-facility dialog | `lib/core/widgets/facility_request_dialog.dart` |
| Submit-corrections dialog | `lib/core/widgets/facility_correction_dialog.dart` |
| Directions chooser service | `lib/core/services/map_launcher_service.dart` |
| Profile page (§2.10) | `lib/features/profile/presentation/pages/profile_page.dart` |
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

**All app code (§2.1 – §2.13) is complete.** `flutter analyze` is clean (0
issues), `flutter test` passes (30/30), and `dart format` is clean. What's left
is the consolidated Supabase SQL runbook (§3.1), device QA (§3.1), and the
technical App Store submission steps (§3.2). The subsections below are kept as
the implementation record.

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

> ⚠️ **Superseded by §2.13.** The `category_level_2` scheme described here was
> replaced by `category_broad` / `category_detail`. The *structure* below still
> holds — two dimensions, one source of truth in `facility_categories.dart`,
> icons consolidating into 4 groups + a fallback — only the column names and
> values changed. See §2.13 for the current mapping.

Two dimensions, one source of truth in
`lib/features/map/constants/facility_categories.dart`:
- **Filtering** was by **`category_level_2`** (12 values); the map Category
  filter listed them and `FacilityFilterService` matched a facility's value
  against the selection (null never matches, so it's excluded when a category
  is chosen). **Now `category_broad`, 13 values.**
- **Icons / colors** consolidate into **4 high-level groups** (Health Care,
  Mental Health, Basic Needs, Housing & Shelter) + a neutral fallback, via
  `FacilityCategories.groupFor(...)`. `Facility.primaryCategory` returns the
  group, so every marker, list icon, and card icon is consistent. **This part is
  unchanged** — only the values feeding it moved.
- Home quick-action buttons pass a group; `MapPage.filterByCategory` expands it
  to that group's underlying values so the filter still works.

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

**Wrapping view** — ⚠️ **superseded: use the §3.3 version**, which swaps the
`category_level_*` columns for `category_broad` / `category_detail`. Kept here as
the original record.
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
- **"Your Feedback" surface:** a list (signed-in only) shows every rating
  (facility name resolved by id — same region-independent path as Favorites,
  rating icon, tags, date). Tap a row to edit/remove via the same dialog. Empty
  + pull-to-refresh states included. *(Later renamed "Your Ratings"
  (`MyRatingsPage`) and moved from Settings to the Profile tab — see §2.9 /
  §2.10.)*
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
> ⚠️ **The RPC body below is superseded by §3.3** (category columns changed, so
> the return type changed). Use §3.3's version, which keeps the same state gate.
> This block remains the record of how the gate was introduced.

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
  names/descriptions/services from the DB, `category_broad` filter values,
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

### 2.11 Card/Requests Refinements (July 2026) ✅ CODE-COMPLETE (1 SQL block pending)

Second on-device pass. `flutter analyze` clean, 31/31 tests, `dart format`
clean.
- **Profile eligibility** — parent "apply to search" toggle split into its own
  card, visually separated from the four gate toggles it governs.
- **Facility card** — "At a Glance" moved **above** Services; added an
  **"Incorrect info? Submit corrections here"** row under the rate row.
- **Submit corrections** — new `FacilityCorrectionDialog` (name / website /
  phone / hours / address, **pre-filled** from the facility) writes to
  `facility_requests` with `request_type = 'correction'` + `facility_id`.
- **Request-a-facility form simplified** to **name + website** (both required);
  the other fields were removed.
- **Your Requests** now shows a New/Correction type label + icon.
- **Single-facility card** gains **expand/collapse** via the handle bar (swipe
  up → ~85% height, swipe down → default → dismiss), mirroring the list panel.
- **List-row expand** now **centers the map** on the facility at a moderate
  zoom (`MapConstants.listExpandZoom = 14` — closer than the region view, less
  than the single-card zoom).
- **Home map cutout** zoom lowered (14 → 12) so POI/facility name labels don't
  render in the preview.

**Supabase SQL to run** (adds columns for corrections + the new/correction
discriminator; safe/additive):
```sql
alter table public.facility_requests
  add column if not exists request_type text default 'new' not null,  -- 'new' | 'correction'
  add column if not exists facility_id text,   -- set for corrections
  add column if not exists website text,
  add column if not exists hours text;
```
Existing RLS already covers the new columns (owner-only). Corrections reuse
`street_address` for the address and `phone` for the phone number.

### 2.12 Pre-Submission Scrub (July 2026) ✅ CODE-COMPLETE

Codebase pass for App Store readiness. `flutter analyze` clean, **28/28 tests**,
`dart format` clean. (Test count dropped 31→28 because the three demo-mode tests
were removed with the feature.)

**Dead code removed**
- **Demo mode deleted entirely** — `DemoModeService` and `DemoFacilityRepository`
  (plus its hardcoded sample facilities) are gone, along with the ~8 branch sites
  that referenced them. `setDemoMode` was never wired to any UI, so `isDemoMode`
  could only ever be `false`; the branches were unreachable and the sample data
  was a liability in a production build.
- **`AuthGate` collapsed to a `StatelessWidget`** — with demo mode gone its only
  job is routing on `hasCompletedOnboarding`; the demo splash screen and its
  `authSigningIn` ARB key were removed (all three locales).

**Debug / correctness cleanup**
- `UrlLauncherService` rewritten: dropped a stray `debugPrint`, routed the catch
  through `ErrorReporter` (matching every other catch site), collapsed four
  branches that were three-quarters identical, and replaced a **hardcoded
  English snackbar that leaked the raw URL** with the localized
  `commonLinkFailed` key (en/es/zh).
- Duplicated `TODO(Android)` comment in `login_page.dart` collapsed to one line.
- Stale doc comment in `facility_model.dart` referencing the retired
  `facilities_il` / `facilities_il_full` objects corrected to `FCT_Supabase` /
  `fct_supabase_full`.
- Comments trimmed across the app so they explain **why**, not **what** —
  section-marker comments (`// Parse phones`) and restatements of the following
  line were removed; the non-obvious ones (ink-over-background asserts, the
  no-auto-query-on-pan rule, gesture-arena notes, the height math) were kept and
  condensed.

**Verified clean:** no hardcoded secrets/API keys, no `print()`, no placeholder
or lorem text, no `http://` URLs, no leftover FIXME/HACK markers.

**iOS submission config** (details in §3.2)
- `PrivacyInfo.xcprivacy` — **`NSPrivacyCollectedDataTypes` was an empty array**
  while the app collects email, user ID, location, crash data, and user content.
  Now declares all six types (linked/tracking flags + app-functionality purpose),
  matching the nutrition label. This is a **hard reject** if it ships mismatched.
- `Info.plist` — added **`ITSAppUsesNonExemptEncryption = false`** so every
  upload skips the manual export-compliance prompt.
- **`TARGETED_DEVICE_FAMILY` 1,2 → 1 (iPhone-only)** for 1.0, since iPad layouts
  are post-MVP and untested — the common 2.4.1/4.0 rejection. The now-moot
  `UISupportedInterfaceOrientations~ipad` block was removed. Revisit when iPad
  layout work lands.

### 2.13 Category Taxonomy Migration ✅ CODE-COMPLETE (SQL pending)

Moved the app off `category_level_1`/`category_level_2` onto the new
**`category_broad`** (13 values) / **`category_detail`** (21 values) columns.
`flutter analyze` clean, **30/30 tests**, `dart format` clean.

**Why this is strictly better:** the old `category_level_2` values were raw data
strings — `Hospital- ACUTE`, `Nonprofit - Public and Societal Benefit` — rendered
**verbatim as filter chips**. The new `category_broad` values are already
user-facing prose ("Veterans", "Housing", "Medical Care"), so the filter reads
like a product instead of a data dump. Coverage is also better: in Illinois
**3,055 / 3,055 rows** have both new columns vs 3,045 for `category_level_2`.

**The taxonomy is a strict hierarchy** — every `category_detail` rolls up to
exactly one `category_broad` (verified across all 21 values), so the two can be
treated as a clean two-level tree.

**Design decisions**
- **Filter dimension = `category_broad`** (13 chips). `category_detail` (21) is
  too many to show as chips, so it is **searchable** and available for display,
  but is not a filter.
- **Icon/color groups stay at 4 + neutral fallback**, so the Home quick-actions
  grid and every existing marker color are unchanged. The 13 broad values map:

  | Icon group | `category_broad` values | Facilities |
  |---|---|---|
  | **Health Care** | Medical Care, Hospitals, Home Care, Health Charities | 31,470 |
  | **Mental Health** | Mental Health, Addiction Recovery | 38,664 |
  | **Housing & Shelter** | Housing | 16,121 |
  | **Basic Needs** | Basic Needs, Children and Families, Seniors, Veterans, Disability Services | 16,338 |
  | **Community Resource** (fallback) | Community Services | 41,632 |

- **`Community Services` is deliberately left in the neutral fallback group.**
  It's the generic community-nonprofit bucket and the single largest category
  (41,632); giving it its own pin color would flood the map and drown out the
  specific groups.
- **`appCategory` (`category_level_1`) was dropped from the model entirely.** It
  only existed as a fallback for demo-mode data (§2.12) and for "raw-category
  display needs" that never materialized.

**Files changed:** `facility_categories.dart` (value list + `groupFor`),
`facility_model.dart` (`categoryBroad`/`categoryDetail` replace
`categoryLevel2`/`appCategory`; `primaryCategory` simplifies to a single call),
`facility_filter_service.dart` (filter + search), `map_page.dart` (filter
options), `recent_facilities_service.dart` (persisted JSON), plus the tests.

> ⚠️ **The app shows no categories until the SQL in §3.3 is applied** — the RPC
> doesn't return the new columns yet. Marker icons fall back to the neutral pin
> and the Category filter matches nothing. Run the SQL before the next QA pass.

**Open data question:** query 1 sums to **144,225** facilities with no `(null)`
bucket, but this doc has recorded **162,937** rows since §2.6. Worth confirming
with `select count(*) from public."FCT_Supabase";` — if the table really did
shrink by ~18.7k, that's a data-pipeline change worth knowing about, and the row
count in §1 / §2.6 needs updating.

## 3. Pre-Launch Checklist

All MVP **app code** is done (§2.1–§2.11) and the app uploads to TestFlight.
Everything below is **not app code**. It's split into **§3.1 engineering/backend**
(dev-owned), **§3.2 App Store submission** (dev-owned, technical), **§3.3**
the category-column extraction SQL, and **§3.4 non-functional** (hand-off to
the non-dev team). The single biggest gate is
**device QA**.

### 3.1 Engineering & Backend (dev-owned)

**Code — done**
- [x] §2.1–§2.13 implemented; `flutter analyze` clean (0 issues); `flutter test` 30/30; `dart format` clean
- [x] `flutter build ios --release` compiles (verified `--no-codesign`; SPM disabled → pure CocoaPods)
- [x] `pubspec.yaml` at `1.0.0+2` — marketing version `1.0.0`; CI sets the build number to `1000 + github.run_number`, so TestFlight/App Store uploads never collide
- [ ] Widget tests for `AppleSignInButton`, `_ZipEditDialog`, `EligibilityPreferencesService`, `RecentFacilitiesService` (post-launch follow-up)

**Supabase SQL runbook** — run once, **in this order**, via Dashboard → SQL
Editor. Each block is copy-paste from the linked section; the app already matches
the columns exactly.
- [ ] **1. Base schema** (if not already live): `user_favorites`, `facility_feedback`, `user_settings` tables + RLS — see the **§2.x DDL reference**
- [ ] **2. §2.6 PostGIS:** lat/lng→`double precision`, `geom` + GiST index, `fct_supabase_full` view, `facilities_near` RPC
- [ ] **3. §2.7 unique constraint** on `facility_feedback (user_id, facility_id)` — backs the rating upsert (without it, edits insert duplicates)
- [ ] **4. §2.9 `visited_on` column** on `facility_feedback` — rating submits **fail** without it
- [ ] **5. §2.9 `facility_requests` table** + RLS — the request flow fails without it
- [ ] **6. §2.11 correction columns** on `facility_requests` (`request_type`, `facility_id`, `website`, `hours`) — the corrections dialog fails without them
- [ ] **7. §2.8 state allow-list:** create `launched_states`, seed `'IL'`, then re-run the **full** `facilities_near` (with the state gate) from §2.8
- [ ] **8. §2.13 category taxonomy** — rebuild `fct_supabase_full` + `facilities_near` for `category_broad`/`category_detail` (**§3.3**). Until this runs, the Category filter matches nothing.
- [ ] **9. Verify RLS:** read-only `anon` SELECT on `FCT_Supabase`, `fct_supabase_full`, `DM_Supabase_Eligibility`, `launched_states`; confirm `SUPABASE_ANON_KEY` is the **publishable** key (not service role)

**Device QA — the main gate** (smoke test on ≥2 iOS devices, different sizes)
- [ ] Auth/onboarding: Apple sign-in, location grant/deny, guest mode, sign-out
- [ ] §2.6 map: ZIP search, pan + "Search this area" (fixed 5 mi), sparse rural area, cluster tap, Favorites across regions
- [ ] §2.7/§2.9 ratings: rate from a map card ("Already visited?"), date picker (past-only), tags optional, re-open (pre-filled), edit, **Remove**, Profile → "Your Ratings"
- [ ] §2.9/§2.11 requests & corrections: empty map area → "Request a facility" (name + website) → row under Profile → "Your Requests"; "Incorrect info? Submit corrections here" → pre-filled correction dialog → row tagged **Correction**
- [ ] §2.9 UX: my-location button in the resources search bar; search matches description/services; tap-anywhere card expansion; description preview on collapsed rows; Services above Next Steps/Hours; swipe-down dismisses the single-facility card; two same-address facilities render side-by-side
- [ ] §2.10/§2.11 Profile & eligibility: gated for guests (sign-in CTA); required eligibility onboarding step (signed-in only); Profile eligibility parent toggle disables the child gates; eligibility auto-applies to map results; "At a Glance" renders above Services; single-card expand/collapse via the handle bar; list-row tap re-centers the map
- [ ] §2.9 directions: first "Get directions" shows the chooser (Google Maps/Waze listed only if installed), choice remembered, changeable in Settings → "Directions app"
- [ ] §2.9 i18n: switch to Spanish and Chinese — home sections, Settings/Profile toggles, map filter bar/modal, facility card labels, and all dialogs translate (facility data + rating tags stay English by design)
- [ ] §2.8: confirm **only Illinois** facilities appear until more states are added

**Technical console config** (dev/admin access) — Apple Developer / Xcode
signing lives in §3.2.
- *Google Cloud:* [ ] restrict Maps key to `org.beaconhealth.app` + Maps SDK for iOS; [ ] **enable billing** (else tiles fail silently → uniform grey map despite a success log — check Billing → Account management); [ ] confirm "Maps SDK for iOS" is enabled in the API Library
- *Supabase auth:* [x] Apple provider enabled (Client IDs incl. bundle ID; OAuth secret **not** needed for native iOS); [ ] confirm Google provider (post-MVP Android)
- *Crash reporting:* [ ] confirm Sentry (or pick an alternative — §8); [ ] create sentry.io project (free 5K errors/mo); [ ] add `SENTRY_DSN` GitHub secret + pass via `--dart-define`

### 3.2 App Store Submission — Technical Requirements (dev-owned)

TestFlight already works; these are the **engineering** gates to move a green
TestFlight build through App Review to the public App Store. (Listing copy,
screenshots, and the privacy nutrition label are non-dev — see §3.4.)

**Signing & capabilities**
- [x] Distribution signing via App Store Connect **API-key cloud-managed signing** (§2.10) — the same path produces the App Store distribution certificate + provisioning profile, not just TestFlight. The API key must have **App Manager** access.
- [ ] Apple Developer portal: **Service ID** for Sign in with Apple configured; **Sign in with Apple** enabled on the `org.beaconhealth.app` App ID; distribution profile regenerated after enabling it.
- [ ] **Sign in with Apple capability** added to the Runner target in Xcode → Signing & Capabilities (the entitlement file alone isn't enough — App Review rejects if the capability isn't on the App ID + profile).
- [x] Pure CocoaPods (SPM disabled — re-migrates if SPM is enabled globally; keep it off in CI). Always open **`Runner.xcworkspace`**; run `cd ios && pod install` after pulling.
- [ ] Upload via CI (`bundle exec fastlane beta`) or `flutter build ipa --dart-define-from-file=config/dart_defines.json` → Transporter.

**Info.plist / build settings**
- [x] **`ITSAppUsesNonExemptEncryption = false`** in `Info.plist` (§2.12) — standard HTTPS only, so this skips the manual export-compliance prompt on **every** upload.
- [x] `NSLocationWhenInUseUsageDescription` present with a user-facing purpose string (App Review 5.1.1 gate) (§2.2).
- [x] `LSApplicationQueriesSchemes` for `comgooglemaps` / `waze` (directions-chooser detection) (§2.9).
- [x] **`TARGETED_DEVICE_FAMILY = 1`** (iPhone-only for 1.0) (§2.12) — keeps App Review off untested iPad layouts.
- [ ] Marketing version `1.0.0` set for the first public submission; build number monotonic (CI handles this).
- [ ] Launch screen storyboard + app-icon asset catalog complete; the 1024² marketing icon has **no alpha channel** (binary validation rejects otherwise).

**Privacy manifest** (Apple-required)
- [x] `ios/Runner/PrivacyInfo.xcprivacy` declares **required-reason API** usage (`UserDefaults` CA92.1, file timestamp C617.1, boot time 35F9.1, disk space E174.1).
- [x] **Collected data types declared** (§2.12) — email, user ID, precise + coarse location, crash data, user content. This array was **empty** before the scrub, which contradicts the nutrition label and is a hard reject.
- [ ] **Keep the manifest and the App Store Connect App Privacy answers identical** — if either changes, update both (source of truth: the nutrition label in `Non-Functional_Checklist.md`).
- [ ] Confirm bundled third-party SDKs ship their own privacy manifests (`google_maps_flutter_ios`, `sign_in_with_apple`, `sentry_flutter`); bump the pod if any lacks one. Tracking domains: **none** (the app does not track).
- [ ] **Legal URLs are on a `*.vercel.app` preview-style domain** (`beacon-website-pied.vercel.app`, see `lib/core/constants/legal_urls.dart`). Apple requires a reachable, stable Privacy Policy URL — move these to the production domain before submitting.

**Crash symbolication**
- [ ] Build with **DWARF with dSYM** (Release default) and **upload dSYMs to Sentry** so release crash reports symbolicate (wire the Sentry Fastlane plugin, or upload manually from the Xcode archive / App Store Connect).

**Submit for review**
- [ ] In App Store Connect, create the **1.0.0** App Store version, attach the processed TestFlight build, and fill the metadata (§3.4).
- [ ] Paste the **App Review notes** (§5) — the guest path lets the reviewer test without an Apple ID handoff.
- [ ] Answer the **App Privacy** questionnaire from the nutrition label (§3.4), the **age-rating** questionnaire, and the **export-compliance** declaration (exempt — standard HTTPS).
- [ ] Submit; consider **phased release** (7-day staged rollout) for the first version.

### 3.3 Category Taxonomy Migration SQL (§2.13)

**Run this before the next QA pass** — the app code is already on
`category_broad` / `category_detail`, so until this ships the Category filter
matches nothing and every marker uses the neutral pin.

**Step 1 — rebuild the view.** `create or replace view` can only *append*
columns, and this removes three, so the view must be dropped first. Nothing
depends on it (the RPC reads `FCT_Supabase` directly), so this is safe:

```sql
drop view if exists public.fct_supabase_full;

create view public.fct_supabase_full as
select
  f.id, f.facility_name, f.facility_description,
  f.website_url, f.contact_email, f.contact_phones,
  f.street_address, f.city, f.state, f.postal_code,
  f.latitude, f.longitude, f.hours, f.services,
  f.category_broad, f.category_detail,
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

**Step 2 — rebuild the RPC.** Swapping `app_category` + `category_level_2` for
`category_broad` + `category_detail` **changes the return type**, so this needs
`drop function` first — `create or replace` alone raises `42P13` (see §2.8).
The `launched_states` gate from §2.8 is retained:

```sql
drop function if exists public.facilities_near(double precision, double precision, double precision, integer);

CREATE OR REPLACE FUNCTION public.facilities_near(lat double precision, lng double precision, radius_m double precision, max_results integer DEFAULT 250)
 RETURNS TABLE(id text, facility_name text, facility_description text, website_url text, contact_email text, contact_phones jsonb, street_address text, city text, state text, postal_code text, latitude double precision, longitude double precision, hours text, services text, category_broad text, category_detail text, operational text, proof_of_income text, proof_of_residency text, insurance_required text, referral_required text, accepts_walkins text, appointment_only text, open_to_immigrants text, free_services_available text, sliding_scale_available text, other_languages text, telehealth_available text, wheelchair_accessible text, serves_outside_area text, operating_hours text, other_eligibility_summary text, services_summary text)
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
    f.category_broad,
    f.category_detail,
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

**Step 3 — index the filter column.** The Category filter runs client-side over
the ≤250-row region pool, so this isn't needed for the app, but it helps any
future server-side category query and costs nothing:

```sql
create index if not exists fct_supabase_category_broad_idx
  on public."FCT_Supabase" (category_broad);
```

**Step 4 — verify.** Both should return rows with the new columns populated:

```sql
select id, facility_name, category_broad, category_detail
from public.fct_supabase_full
where state = 'IL' limit 5;

select facility_name, category_broad, category_detail
from public.facilities_near(41.8781, -87.6298, 8047, 5);
```

> **Retiring the old columns:** `category_level_1` / `category_level_2` are no
> longer referenced by the app or by these objects. Leave them on
> `FCT_Supabase` for now as a rollback path; drop them once the new taxonomy has
> survived a full QA pass.

**Re-run these any time the taxonomy changes** — if the distinct
`category_broad` values ever drift from the 13 hardcoded in
`facility_categories.dart`, the filter silently loses options. The
`facility_categories_test.dart` test asserting `hasLength(13)` is the tripwire:

```sql
select coalesce(category_broad, '(null)') as category_broad, count(*) as facilities
from public."FCT_Supabase" group by 1 order by facilities desc;
```

### 3.4 Non-Functional — Hand-off to Non-Dev Team

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
This app helps users find free and low-cost healthcare and social-services facilities.

To test:
1. Launch the app — sign in with Apple, or tap "Continue as Guest"
2. Choose "Enable Location-Based Search" or enter an Illinois zip code (e.g., 60613). The launch is gated to Illinois, so zip codes in other states intentionally return no facilities.
3. Browse the map, search by name/service, tap a facility card to expand it, and use the filters
4. Signed-in users can save Favorites, set Eligibility (Profile tab — auto-applied to search) and Preferences filters, rate a facility ("Already visited? Rate your experience"), and submit info corrections ("Incorrect info? Submit corrections here") — all reviewable/editable under the Profile tab ("Your Ratings" / "Your Requests")
5. Guest users see a lock icon on Favorites and the Profile tab — tapping shows a sign-in prompt
6. The "Recently Viewed" section on the home page lists the last 3 facilities opened — tapping one opens the rating dialog (requires sign-in to submit)
7. GPS location is available via the location button on the map (requires location permission); "Get directions" opens Apple Maps, Google Maps, or Waze

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
