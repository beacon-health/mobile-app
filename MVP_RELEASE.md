# Beacon App — MVP Release Plan

> **Context doc for AI agents.** Read this before making changes.
>
> **Last updated:** 2026-05-26 · **Target:** iOS App Store (TestFlight -> public) · **Version:** `1.0.0`

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

- **Entry flow:** `AuthGate` → checks auth state and onboarding status. New flow (see §2.1): `LoginPage` (Sign in with Apple / Continue as Guest) → `LocationChoicePage` (Enable Location / Enter Zip) → `MainNavBar`.
- **Guest mode:** `GuestModeService` (`lib/core/services/guest_mode_service.dart`) — singleton `ChangeNotifier` that listens to `Supabase.instance.client.auth.onAuthStateChange`. Exposes `isGuest` (true when `currentUser == null`). Widgets use `context.watch<GuestModeService>().isGuest` for reactive rebuilds.
- **Locked features:** `LockedFeatureGate` wraps children with tap handler → `showSignInPromptDialog`. Used for Favorites, Eligibility, Preferences. `LockedSectionOverlay` provides frosted-glass overlay for locked Settings sections.
- **Error handling:** `ErrorReporter` singleton (`lib/core/services/error_reporter.dart`) — `developer.log` in debug, no-op in release. Line 34 has `// TODO(post-MVP)` for Sentry swap (see §2.3).
- **Theming:** `AppGradients` for onboarding gradients, `ColorSchemeExt` for alpha blends (`onSurfaceMuted`, `onSurfaceSecondary`, `onSurfaceFaded`, `onSurfaceStrong`).
- **Location:** `ZipCodeService` stores zip → geocoded lat/lng via `SharedPreferences`. `LocationService` has full GPS code using `geolocator` — currently disabled, needs re-enabling (see §2.2).
- **Filter bar:** Tune → Distance → Open Now → Favorites → Category → Eligibility → Preferences (reorder complete). Favorites/Eligibility/Preferences show sign-in dialog in guest mode.

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
| Locked feature gate | `lib/core/widgets/locked_feature_gate.dart` |
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

## 2. Remaining MVP Code Tasks

### 2.1 User Authentication (Sign in with Apple)

**Goal:** iOS users sign in via Apple OAuth through Supabase, or continue as guest. Sign-in persists across app restarts. Database tables support Favorites, Feedback, and Settings for authenticated users.

**Current state:** `LoginPage` has both Google + Apple sign-in buttons via `flutter_signin_button` + `Supabase.instance.client.auth.signInWithOAuth()`. Google sign-in has been tested successfully during development. `GuestModeService` already listens to auth state changes — on successful sign-in, `isGuest` flips to `false` and all `LockedFeatureGate`-wrapped features unlock reactively. `AuthGate` currently only checks `ZipCodeService.hasCompletedOnboarding` — it does not check Supabase auth state. The `OnboardingPage` goes directly to `ZipEntryPage` (no login step). "Continue as Guest" on `LoginPage` does `Navigator.pushReplacement` to `MainNavBar` (skips zip entry). Sign-out button in `settings_page.dart` is commented out (line ~77).

**What needs to happen:**

1. **Update `LoginPage` for iOS-only auth.**
   - Keep only "Sign in with Apple" and "Continue as Guest" buttons for iOS. Remove the Google sign-in button (or gate it behind a `Platform.isAndroid` check with a `// TODO(Android)` comment for future Android release).
   - Both "Sign in with Apple" and "Continue as Guest" should navigate to a new `LocationChoicePage` (step 2) instead of going directly to `MainNavBar`.
   - After successful Apple sign-in, Supabase persists the session token locally. On next app launch, `Supabase.instance.client.auth.currentUser` will be non-null — the user stays signed in. Verify this works by closing and reopening the app after sign-in.

2. **Create a `LocationChoicePage`** (new file: `lib/features/auth/presentation/pages/location_choice_page.dart`).
   - Two buttons: "Enable Location-Based Search" and "Enter Zip Code".
   - Either option is valid for both guest and signed-in users.
   - **"Enable Location-Based Search"**: Call `LocationService.getCurrentLocation()`. This triggers the iOS location permission popup. If the user grants permission, store the coordinates via `ZipCodeService.setZipAndLocation()` (use a display name like "Current Location") and set `hasCompletedOnboarding = true`, then navigate to `MainNavBar`. If the user **denies** the permission (i.e. `LocationResult.isCurrentLocation == false` or permission denied), automatically fall back to showing the zip code entry UI on the same page (or navigate to `ZipEntryPage`).
   - **"Enter Zip Code"**: Navigate to the existing `ZipEntryPage`.
   - Accept an optional `prefilledZip` parameter — used when a guest signs in later (step 5) to pre-populate the zip code field.

3. **Update `AuthGate`** to handle authenticated + onboarded state.
   - Current logic: `hasCompletedOnboarding` → `MainNavBar`, else → `OnboardingPage`.
   - New logic:
     ```
     if (demoMode) → MainNavBar
     if (hasCompletedOnboarding) → MainNavBar
     else → LoginPage (not OnboardingPage)
     ```
   - Remove `OnboardingPage` from the flow or repurpose it as a splash/welcome screen before `LoginPage`. The key change is that `LoginPage` is now the first screen for new users.
   - Supabase session persistence handles the "stay signed in" requirement — `currentUser` is non-null on app restart if the user previously signed in.

4. **Add Sign in with Apple capability in Xcode.**
   - Create `ios/Runner/Runner.entitlements` with `com.apple.developer.applesignin` entitlement array containing `Default`.
   - Reference the entitlements file via `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` in `project.pbxproj` (both Debug and Release configurations).

5. **Handle guest → sign-in transition.**
   - When a guest user taps a locked feature and sees `showSignInPromptDialog`, they should be able to navigate to `LoginPage` from the dialog (add a "Sign In" button — currently the dialog is informational only with a lock icon + text + close button).
   - After successful Apple sign-in from a guest session, walk the user through the `LocationChoicePage` again. Pre-populate the zip code value from `ZipCodeService().zipCode` (the zip they entered as a guest).
   - This means `LoginPage` needs awareness of whether it's being shown during initial onboarding vs. from a guest session. Pass a flag like `isGuestUpgrade: true` to skip back to `LocationChoicePage` with the pre-filled zip.

6. **Handle sign-out.**
   - Uncomment the sign-out button in `settings_page.dart` (around line ~77, look for `_buildSignOutButton`).
   - Wire it to `Supabase.instance.client.auth.signOut()`.
   - After sign-out: call `ZipCodeService().clear()` to reset onboarding state, then navigate to `LoginPage` (replace the full navigation stack using `Navigator.pushAndRemoveUntil`).

7. **Create Supabase database tables** (via Supabase Dashboard SQL editor or migrations):

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
     for all using (auth.uid() = user_id);
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
     for all using (auth.uid() = user_id);
   ```

   **`user_settings` table:**
   ```sql
   create table public.user_settings (
     id uuid default gen_random_uuid() primary key,
     user_id uuid references auth.users(id) on delete cascade not null unique,
     zip_code text,
     latitude double precision,
     longitude double precision,
     theme_mode text default 'system',
     locale text default 'en',
     location_search_enabled boolean default false,
     created_at timestamptz default now() not null,
     updated_at timestamptz default now() not null
   );
   alter table public.user_settings enable row level security;
   create policy "Users manage own settings" on public.user_settings
     for all using (auth.uid() = user_id);
   ```

8. **Wire Favorites to Supabase.**
   - `FacilityProvider.toggleFavorite()` currently flips `isFavorite` in-memory only.
   - For authenticated users: on toggle, insert/delete from `user_favorites` table via `Supabase.instance.client.from('user_favorites')`. Keep in-memory flip for instant UI response (optimistic update), revert if the Supabase call fails.
   - On sign-in: load the user's favorites from `user_favorites` and merge with the loaded facility list (set `isFavorite = true` for matching facility IDs).
   - Guest users: favorites remain in-memory only (cleared on app close). Show a hint on the Favorites section that signing in will persist favorites.

9. **Wire Settings to Supabase.**
   - On sign-in: load `user_settings` row. If it exists, apply zip/lat/lng/theme/locale. If not, create a row with current local values.
   - On settings change (zip code, theme, locale): update both local state (`SharedPreferences`) and the `user_settings` table.
   - `location_search_enabled` column tracks whether the user opted into GPS (used by Settings toggle in §2.2).

### 2.2 GPS Location Enablement

**Goal:** Users can opt into GPS-based facility search during onboarding or later via Settings. Zip-code remains the default.

**Current state:** `LocationService` (`lib/features/map/presentation/services/location_service.dart`) has full `getCurrentLocation()` implementation with permission checking via `geolocator` (already in `pubspec.yaml`). `NSLocationWhenInUseUsageDescription` is commented out in `ios/Runner/Info.plist` (line 39). `LocationSearch` widget has a "Current Location" button commented out (lines 61-62 and 152-167 in `location_search.dart`). `GoogleMap` widgets in `map_page.dart` (line 693) and `home_page.dart` (line 322) have `myLocationEnabled: false` with TODO comments. There is also a commented-out `LocationSearch` container block in `map_page.dart` (lines 735-760).

**What needs to happen:**

1. **Uncomment `NSLocationWhenInUseUsageDescription`** in `ios/Runner/Info.plist` (line 39). Update the description text to: `"Beacon uses your location to find healthcare facilities near you."`.

2. **Integrate GPS into the onboarding flow** via the new `LocationChoicePage` (described in §2.1 step 2). The `LocationService.getCurrentLocation()` call handles permission requests. If denied, fall back to zip code entry.

3. **Add a "Use My Location" button on the map page.** Currently there's a commented-out `LocationSearch` widget block in `map_page.dart` (lines 735-760). Instead of uncommenting the full `LocationSearch` bar, add a floating action button or a GPS icon button near the map. When tapped: call `LocationService.getCurrentLocation()`, update `_currentLatitude`/`_currentLongitude`, reload facilities with `_loadFacilities()`, and animate the camera to the new location. If permission denied, show a snackbar: "Location access denied. Enable it in Settings > Privacy > Location Services."

4. **Re-enable the blue location dot.** Set `myLocationEnabled: true` on the `GoogleMap` widget in `map_page.dart` (line 693) and `home_page.dart` (line 322). Keep `myLocationButtonEnabled: false` (we provide our own button). Only enable the dot when the user has granted location permission — check via `Geolocator.checkPermission()` before setting this. If permission is not granted, leave as `false`.

5. **Uncomment the location button in `LocationSearch`** (`location_search.dart`, lines 152-167). Wire the `_getCurrentLocation` method (line 62, currently a TODO comment) to call `LocationService.getCurrentLocation()` and invoke `widget.onLocationChanged` with the result. Re-enable the `LocationSearch` container in `map_page.dart` (lines 735-760) and connect `_onLocationChanged` / `_onLocationSearchFocusChange` handlers (referenced in the TODO on line 305).

6. **Add a Settings toggle for location-based search.**
   - In `settings_page.dart`, add a toggle in the Account section (below the zip code row): "Use My Location" switch.
   - When toggled on: call `LocationService.getCurrentLocation()`. If permission granted, update location and persist `location_search_enabled = true` in `user_settings`. If denied, show a dialog explaining how to enable location in iOS Settings and keep the toggle off.
   - When toggled off: revert to zip-code-based location. Update `user_settings.location_search_enabled = false`.
   - This toggle gives users who denied location during onboarding a way to enable it later.

7. **Update `PrivacyInfo.xcprivacy`** if the `geolocator` package accesses additional required-reason APIs beyond what's already declared.

8. **Keep zip-code as the default.** GPS is always opt-in. The zip-code flow via `ZipCodeService` remains the primary location source for users who don't grant location permission.

### 2.3 Crash Reporting (Sentry)

**Goal:** Capture crashes and errors in production via Sentry, using the existing `ErrorReporter` facade.

**Current state:** `ErrorReporter` (`lib/core/services/error_reporter.dart`) is a singleton with `report(error, stackTrace, {context})`. Debug mode: `developer.log`; release: no-op. Line 34: `// TODO(post-MVP): Sentry.captureException(error, stackTrace: stackTrace);`. All error-catching code already calls `ErrorReporter.instance.report(...)`.

**What needs to happen:**

1. **Add `sentry_flutter`** to `pubspec.yaml`.
2. **Initialize Sentry in `main.dart`** before `runApp`. Use `SentryFlutter.init()` with DSN from `--dart-define=SENTRY_DSN=<dsn>` (read via `String.fromEnvironment('SENTRY_DSN')`). Wrap `runApp(const BeaconApp())` using the `appRunner` callback pattern.
3. **Update `ErrorReporter.report()`** — replace the no-op release path (line 34) with `Sentry.captureException(error, stackTrace: stackTrace)`. Keep `developer.log` for debug mode.
4. **Create a Sentry project** at sentry.io (free tier: 5K errors/month). Get the DSN.
5. **Add `SENTRY_DSN` to GitHub Actions secrets** and update CI workflows to pass it via `--dart-define`.
6. **Update `PrivacyInfo.xcprivacy`** if Sentry accesses additional required-reason APIs.

### 2.4 Facility Feedback Submission

**Goal:** Users can view recently viewed facilities on the home page and submit thumbs up/down feedback with a text comment. Feedback is stored in Supabase for authenticated users.

**Current state:** The home page (`lib/features/home/presentation/pages/home_page.dart`) has a map cutout, 4 category buttons, and a Favorites section. There is no "recently viewed" tracking or feedback mechanism. The `facility_feedback` Supabase table is created in §2.1 step 7.

**What needs to happen:**

1. **Create `RecentFacilitiesService`** (`lib/core/services/recent_facilities_service.dart`).
   - `ChangeNotifier` singleton (same pattern as `GuestModeService`).
   - Maintains an in-memory `List<Facility>` of the last 3 facilities the user viewed, most-recent first. If a facility is already in the list, move it to the front. Cap at 3.
   - Provide at app root in `app.dart` via `ChangeNotifierProvider`.
   - Methods: `addFacility(Facility)`, `List<Facility> get recentFacilities`, `void clear()`.

2. **Record facility views in `MapPage`.**
   - In `_showFacilityDetails()` (around `map_page.dart` line 433), after setting `_selectedFacility`, call `context.read<RecentFacilitiesService>().addFacility(facility)`.
   - Also record when a facility is tapped from the facility list panel (wherever facility taps navigate to detail views).

3. **Add "Recently Viewed Facilities" section to `HomePage`.**
   - Position: after the map cutout + category buttons (`_buildMapAndCategories`), **above** the Favorites section.
   - Section heading: "Recently Viewed Facilities" (styled like the existing "Favorites" heading).
   - Use `context.watch<RecentFacilitiesService>()` for reactive rebuilds.
   - **When populated** (1-3 facilities): Show a compact, horizontally-bounded list that spans the width of the phone. Use a similar style to the Favorites list: `ListTile` with category icon + facility name + address + chevron. If 3 items, use a fixed-height container with an internal `ListView` so it scrolls if needed but doesn't dominate the screen. Keep the section short — roughly the height of 2-3 `ListTile`s max.
   - **When empty**: Show a minimal empty state (similar to Favorites empty state but shorter): a container with an icon (`Icons.history`), "No recently viewed facilities" text, and a one-line hint like "Tap a facility on the map to see it here." Keep the empty state compact (not as tall as the Favorites empty state).
   - Tapping a facility in this section opens the feedback dialog (step 4), not the map.

4. **Build the feedback dialog.**
   - When a facility in the "Recently Viewed" section is tapped, show a modal dialog (`showDialog`) with:
     - Facility name as the dialog title.
     - A row with two `IconButton`s: thumbs-up (`Icons.thumb_up`) and thumbs-down (`Icons.thumb_down`). Tapping one highlights it (e.g., filled icon + color) and deselects the other. Track with a local `bool? rating` state.
     - A `TextField` for free-text comments. Hint: "Tell us about your experience...". Use a `maxLines: 3` to keep it compact.
     - A "Submit" button that is **disabled** until both a rating is selected AND the text field is non-empty.
     - On submit:
       - **Authenticated users:** Insert into `facility_feedback` table via `Supabase.instance.client.from('facility_feedback').insert({...})`. Include `user_id`, `facility_id`, `rating` ('up'/'down'), `comment`. Show a `SnackBar` confirming "Thanks for your feedback!" and close the dialog. If the insert fails, show an error snackbar but still close the dialog.
       - **Guest users:** Show `showSignInPromptDialog` instead of submitting. They need to sign in to submit feedback.

5. **Guest handling.**
   - Guest users can see the "Recently Viewed" section and tap on facilities, but when they tap "Submit" in the feedback dialog, show the sign-in prompt instead. Alternatively, show the sign-in prompt when they tap a facility in the section (before opening the dialog). Choose whichever feels more natural — the key point is guests cannot submit feedback without signing in.

### 2.5 Remaining Cleanup Tasks

| # | Task | Notes |
|---|------|-------|
| 1 | Set version to `1.0.0` in `pubspec.yaml` | Currently `0.1.1`. |
| 2 | Audit `LocationService` after GPS re-enable | Replace `debugPrint` calls with `ErrorReporter.instance.report()`. Verify `defaultLocation` fallback uses `ZipCodeService` coordinates instead of hardcoded Chicago coords. |
| 3 | Migrate `debugPrint` calls in `map_page.dart` | Lines ~265-294 and ~429 use `debugPrint` — should use `ErrorReporter`. |

---

## 3. Pre-TestFlight Checklist

### Engineer (code)
- [ ] All §2 tasks implemented and tested
- [ ] `pubspec.yaml` version: `1.0.0`
- [ ] `flutter analyze` passes with 0 issues
- [ ] `flutter test` — all tests pass (add tests for new services: `RecentFacilitiesService`, auth flow, feedback submission)
- [ ] `flutter build ios --release` succeeds
- [ ] Manual smoke test on >= 2 iOS devices (different screen sizes): sign-in with Apple, location permission grant/deny, feedback submission, guest mode, sign-out

### External Config (requires web UI / dashboard access)

**Supabase Dashboard:**
- [ ] Enable Apple OAuth provider (requires Apple Service ID + key from Apple Developer Console)
- [ ] Confirm Google OAuth provider is configured (already tested in dev — needed for post-MVP Android)
- [ ] Create `user_favorites` table with RLS (see §2.1 step 7 SQL)
- [ ] Create `facility_feedback` table with RLS (see §2.1 step 7 SQL)
- [ ] Create `user_settings` table with RLS (see §2.1 step 7 SQL)
- [ ] Verify RLS is enabled on all tables/views with read-only anon policy for facility data
- [ ] Confirm `SUPABASE_ANON_KEY` in `--dart-define` / GitHub Secret is the publishable key (not service role)

**Sentry:**
- [ ] Create Sentry project at sentry.io (free tier)
- [ ] Get DSN and add as `SENTRY_DSN` GitHub Actions secret

**Google Cloud Console:**
- [ ] Update API key bundle ID restriction to `org.beaconhealth.app`
- [ ] Verify API key restricted to iOS apps + Maps SDK for iOS only

**Apple Developer Console:**
- [ ] Create Service ID for Sign in with Apple
- [ ] Configure Sign in with Apple for the App ID `org.beaconhealth.app`
- [ ] Create/download iOS Distribution certificate
- [ ] Create App Store provisioning profile for `org.beaconhealth.app`

**Xcode:**
- [ ] Add Sign in with Apple capability
- [ ] Create `Runner.entitlements` with `com.apple.developer.applesignin`
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
