# Beacon App — MVP Release Plan

> **Context doc for AI agents.** Read this before making changes.
>
> **Last updated:** 2026-05-27 · **Target:** iOS App Store (TestFlight -> public) · **Version:** `1.0.0+1`
>
> **Status:** All code work for §2.1 – §2.5 is complete. Remaining work is
> exclusively external configuration (Supabase Dashboard, Google Cloud
> Console, Apple Developer Console, App Store Connect) — see §3.

---

## 1. Project Overview

| Area | Value |
|------|-------|
| **Framework** | Flutter 3.41.6 / Dart 3.11.4, Material 3, iOS-only (Android post-MVP) |
| **Bundle ID** | `org.beaconhealth.app` |
| **iOS min target** | 15.0 (aligned across Podfile + Xcode) |
| **Backend** | Supabase (Free tier), `facilities_il_full` view (~691 rows) |
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

## 2. Code Work — Completed

All code-side MVP tasks (§2.1 – §2.5) are implemented, `flutter analyze` is
clean (0 issues), and `flutter test` passes (18/18). What's left is
documented in §3 — every remaining item is a click in someone else's web
console.

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

## 3. Pre-TestFlight Checklist

### Engineer (code)
- [x] All §2.1 – §2.5 tasks implemented
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
| **Medium** | Offline/connectivity handling (`connectivity_plus` + offline banner) |
| **Medium** | Full accessibility audit (VoiceOver, Dynamic Type, WCAG 2.1 AA) |
| **Low** | Professional localization review (es, zh) |
| **Low** | iPad layout optimization |
| **Low** | Supabase Pro upgrade ($25/mo) — evaluate based on user volume |

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
