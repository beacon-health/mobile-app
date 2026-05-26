# Beacon App — MVP Release Plan

> **Context doc for AI agents.** Read this before making changes.
>
> **Last updated:** 2026-05-26 · **Target:** iOS App Store (TestFlight -> public)

---

## 1. Project Overview

| Area | Value |
|------|-------|
| **Framework** | Flutter 3.41.6 / Dart 3.11.4, Material 3, iOS-only |
| **Bundle ID** | `org.beaconhealth.app` |
| **iOS min target** | 15.0 (aligned across Podfile + Xcode) |
| **Backend** | Supabase (Free tier), `facilities_il_full` view (~691 rows) |
| **Auth** | Supabase OAuth (Google + Apple) — partially wired, MVP requirement |
| **State mgmt** | Provider + ChangeNotifier |
| **Maps** | Google Maps Flutter plugin, API key via `Secrets.xcconfig` (gitignored) |
| **Localization** | en, es, zh via `flutter_localizations` + ARB |
| **Demo mode** | Feature-flagged, hidden in MVP (gated behind TODO) |
| **Secrets** | `--dart-define` for Supabase URL/key; `Secrets.xcconfig` for Google Maps key. No secrets in source. |
| **Linting** | `very_good_analysis` — 0 issues (`flutter analyze` clean) |
| **Tests** | 18 unit tests (all passing) |
| **CI/CD** | GitHub Actions (`ci.yml` + `ios-build.yml`), Fastlane skeleton |
| **Repo** | `github.com/beacon-health/mobile-app` · Data pipeline: `github.com/beacon-health/beacon-data` |

### Architecture

- **Entry flow:** `AuthGate` (`lib/features/auth/presentation/widgets/auth_gate.dart`) checks `ZipCodeService.hasCompletedOnboarding` — shows `OnboardingPage` -> `ZipEntryPage` if first launch, `MainNavBar` if returning.
- **Guest mode:** `GuestModeService` (`lib/core/services/guest_mode_service.dart`) is a singleton `ChangeNotifier` that listens to `Supabase.instance.client.auth.onAuthStateChange`. Exposes `isGuest` (true when `currentUser == null`). Widgets use `context.watch<GuestModeService>().isGuest` for reactive rebuilds.
- **Locked features:** `LockedFeatureGate` widget wraps children with a tap handler that shows `showSignInPromptDialog`. Used for Favorites, Eligibility, Preferences. `LockedSectionOverlay` provides a frosted-glass overlay for locked Settings sections.
- **Error handling:** `ErrorReporter` singleton (`lib/core/services/error_reporter.dart`) — `developer.log` in debug, no-op in release. Has a `// TODO(post-MVP)` for Sentry that should now be implemented (see §2).
- **Theming:** `AppGradients` for onboarding gradient (dark+light), `ColorSchemeExt` for consistent alpha blends (`onSurfaceMuted`, `onSurfaceSecondary`, `onSurfaceFaded`, `onSurfaceStrong`).
- **Location:** `ZipCodeService` (`lib/core/services/zip_code_service.dart`) stores zip -> geocoded lat/lng via `SharedPreferences`. `LocationService` (`lib/features/map/presentation/services/location_service.dart`) has full GPS code using `geolocator` but is currently unused — needs re-enabling for MVP (see §2).
- **Filter bar:** Tune -> Distance -> Open Now -> Favorites -> Category -> Eligibility -> Preferences. Favorites/Eligibility/Preferences show sign-in dialog in guest mode. Eligibility and Preferences are split into separate enums in `lib/features/map/constants/filter_constants.dart`.

### Key Files

| Purpose | Path |
|---------|------|
| App entry | `lib/main.dart` |
| App routing | `lib/app.dart` |
| Auth gate | `lib/features/auth/presentation/widgets/auth_gate.dart` |
| Login page | `lib/features/auth/presentation/pages/login_page.dart` |
| Onboarding | `lib/features/auth/presentation/pages/onboarding_page.dart` |
| Zip entry | `lib/features/auth/presentation/pages/zip_entry_page.dart` |
| Guest mode service | `lib/core/services/guest_mode_service.dart` |
| Zip code service | `lib/core/services/zip_code_service.dart` |
| Error reporter | `lib/core/services/error_reporter.dart` |
| Location service | `lib/features/map/presentation/services/location_service.dart` |
| Sign-in prompt | `lib/core/widgets/sign_in_prompt_dialog.dart` |
| Locked feature gate | `lib/core/widgets/locked_feature_gate.dart` |
| Locked section overlay | `lib/core/widgets/locked_section_overlay.dart` |
| Facility data | `lib/features/map/data/facility_repository.dart`, `supabase_facility_service.dart` |
| Facility model | `lib/features/map/domain/models/facility_model.dart` |
| Facility provider | `lib/features/map/presentation/providers/facility_provider.dart` |
| Map page | `lib/features/map/presentation/pages/map_page.dart` |
| Home page | `lib/features/home/presentation/pages/home_page.dart` |
| Main nav bar | `lib/features/home/presentation/widgets/main_nav_bar.dart` |
| Settings | `lib/features/settings/presentation/pages/settings_page.dart` |
| Filter bar | `lib/features/map/presentation/widgets/filters/components/filter_bar.dart` |
| Filter constants | `lib/features/map/constants/filter_constants.dart` |
| Facility card | `lib/features/map/presentation/widgets/facility/facility_card.dart` |
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

### 2.1 User Authentication (Apple + Google OAuth)

**Goal:** Allow users to sign in via Apple or Google OAuth through Supabase, unlocking Favorites, Eligibility, and Preferences features.

**Current state:** `LoginPage` (`lib/features/auth/presentation/pages/login_page.dart`) already has active Google + Apple sign-in buttons using `flutter_signin_button` + `Supabase.instance.client.auth.signInWithOAuth()`. `GuestModeService` already listens to auth state changes and will automatically flip `isGuest` to `false` on successful sign-in, which reactively unlocks all `LockedFeatureGate`-wrapped features.

**What needs to happen:**

1. **Wire sign-in into the onboarding flow.** Currently `OnboardingPage` goes directly to `ZipEntryPage`. Add a "Sign In" option (e.g. a text button on the onboarding page, or route to `LoginPage`). The "Continue as Guest" button on `LoginPage` currently does `Navigator.pushReplacement` to `MainNavBar` directly — it should instead go to `ZipEntryPage` so guests still enter a zip code.
2. **Update `AuthGate`** to handle the authenticated state. Currently it only checks `hasCompletedOnboarding`. It should also check `Supabase.instance.client.auth.currentUser` — if authenticated, go to `MainNavBar`. If not authenticated and no onboarding, show `OnboardingPage`.
3. **Add Sign in with Apple capability in Xcode.** Create `ios/Runner/Runner.entitlements` with the `com.apple.developer.applesignin` entitlement. Reference it via `CODE_SIGN_ENTITLEMENTS` in `project.pbxproj`.
4. **Configure Supabase Auth providers.** In Supabase Dashboard -> Authentication -> Providers, enable Apple and Google. Apple requires a Service ID + key from Apple Developer Console. Google requires OAuth client credentials from Google Cloud Console.
5. **Update `showSignInPromptDialog`** (`lib/core/widgets/sign_in_prompt_dialog.dart`) to include an actual "Sign In" button that navigates to `LoginPage`, instead of just showing an informational message.
6. **Handle sign-out.** The sign-out button in `settings_page.dart` is currently commented out (lines ~77). Uncomment it and wire it to `Supabase.instance.client.auth.signOut()`. After sign-out, navigate back to `OnboardingPage` or `LoginPage`.
7. **Favorites sync with Supabase.** Currently favorites are in-memory only (`FacilityProvider.toggleFavorite` flips `isFavorite` on the model). For authenticated users, persist favorites to a Supabase `user_favorites` table (user_id + facility_id). Load on sign-in, sync on toggle.

### 2.2 GPS Location Enablement

**Goal:** Allow users to use their device GPS for location-based facility search, alongside the existing zip-code flow.

**Current state:** `LocationService` (`lib/features/map/presentation/services/location_service.dart`) has full GPS code using `geolocator` package (already in `pubspec.yaml`). GPS calls are commented out in map/home pages. `NSLocationWhenInUseUsageDescription` is commented out in `ios/Runner/Info.plist` (line 39). `LocationSearch` widget (`lib/features/map/presentation/widgets/search/location_search.dart`) has "Current Location" button commented out with `// TODO: revisit once location-based search is in-scope`.

**What needs to happen:**

1. **Uncomment `NSLocationWhenInUseUsageDescription`** in `ios/Runner/Info.plist`. Use a clear, healthcare-relevant description (e.g. "Beacon uses your location to find healthcare facilities near you.").
2. **Add a "Use My Location" button** on the map page. When tapped: request location permission via `LocationService.getCurrentLocation()`, center map on result, reload facilities for that location. If permission denied, show a snackbar explaining how to enable it in Settings.
3. **Uncomment the "Current Location" button** in `LocationSearch` (`location_search.dart`, around lines 61-62 and 152-165). Wire it to call `LocationService.getCurrentLocation()` and update the map.
4. **Re-enable `myLocationEnabled: true`** on the `GoogleMap` widgets in both `map_page.dart` and `home_page.dart` (currently set to `false` with TODO comments). This shows the blue dot on the map.
5. **Update `PrivacyInfo.xcprivacy`** if the `geolocator` package accesses any additional required-reason APIs beyond what's already declared.
6. **Keep zip-code as the default.** GPS should be an opt-in "Use My Location" action, not the default startup behavior. The zip-code flow via `ZipCodeService` remains the primary location source.

### 2.3 Crash Reporting (Sentry)

**Goal:** Capture crashes and errors in production via Sentry, using the existing `ErrorReporter` facade.

**Current state:** `ErrorReporter` (`lib/core/services/error_reporter.dart`) is a singleton with a `report(error, stackTrace, {context})` method. In debug mode it logs via `developer.log`; in release it's a no-op. There's a `// TODO(post-MVP): Sentry.captureException(...)` comment on line 34. All error-catching code in the app already calls `ErrorReporter.instance.report(...)`.

**What needs to happen:**

1. **Add `sentry_flutter` dependency** to `pubspec.yaml`.
2. **Initialize Sentry in `main.dart`** before `runApp`. Use `SentryFlutter.init()` with the DSN from Sentry project settings. Wrap `runApp(const BeaconApp())` in `SentryWidgets` or use the `appRunner` callback pattern.
3. **Update `ErrorReporter.report()`** to call `Sentry.captureException(error, stackTrace: stackTrace)` in release mode (replace the TODO on line 34). Keep the `developer.log` path for debug mode.
4. **Create a Sentry project** at sentry.io (free tier: 5K errors/month). Get the DSN. Inject it via `--dart-define=SENTRY_DSN=<dsn>` and read with `String.fromEnvironment('SENTRY_DSN')`.
5. **Add `SENTRY_DSN` to GitHub Actions secrets** and update CI workflows to pass it.
6. **Update `PrivacyInfo.xcprivacy`** if Sentry accesses additional required-reason APIs.

### 2.4 Facility Feedback Submission (UI Only)

**Goal:** Allow users to rate recently visited facilities with thumbs up/down and a text comment. UI only — no backend storage yet.

**Current state:** The home page (`lib/features/home/presentation/pages/home_page.dart`) has a map cutout, 4 category buttons, and a Favorites section. There is no "recently visited" tracking or feedback mechanism.

**What needs to happen:**

1. **Track last-clicked facilities.** Create a lightweight service (e.g. `lib/core/services/recent_facilities_service.dart`) that maintains an in-memory list of the last 3 facilities the user tapped on (from map marker taps or facility list taps). Use a simple `List<Facility>` with max length 3, most-recent first. This should be a `ChangeNotifier` provided at app root so both `MapPage` and `HomePage` can access it.
2. **Record taps in `MapPage`.** When `_selectedFacility` is set (around `map_page.dart` line 437 in `_onMarkerTap`), also call `RecentFacilitiesService.addFacility(facility)`. Similarly, when a facility is tapped in the facility list panel.
3. **Add a "Recent" section to `HomePage`.** Place it between the category buttons and the Favorites section in the `build` method. Show the heading "Recent" and a list of up to 3 facility tiles (similar style to the Favorites list: icon + name + address + chevron). If empty, hide the section entirely.
4. **Build a feedback dialog.** When a facility in the Recent section is tapped, show a modal dialog (`showDialog`) with:
   - Facility name as the title
   - A row with two `IconButton`s: thumbs-up (`Icons.thumb_up`) and thumbs-down (`Icons.thumb_down`). Tapping one selects it (highlighted) and deselects the other. Use a local `bool?` state to track selection.
   - A `TextField` for free-text comments with a hint like "Tell us about your experience..."
   - A "Submit" button that is **disabled** until both a rating is selected AND the text field is non-empty.
   - On submit: show a `SnackBar` confirming "Thanks for your feedback!" and close the dialog. No data is sent anywhere — this is UI-only for now.
5. **Do NOT store feedback in a database.** The dialog just validates the form and shows a confirmation. Backend storage will be added in a future iteration.

### 2.5 Remaining Cleanup Tasks

| # | Priority | Task | Notes |
|---|----------|------|-------|
| 1 | **High** | Set version to `1.0.0` in `pubspec.yaml` | Currently `0.1.1`. Standard for first public release. |
| 2 | **Medium** | Audit `LocationService` after GPS re-enable | Clean up `debugPrint` calls (should use `ErrorReporter`), verify `defaultLocation` fallback uses `ZipCodeService` coordinates instead of hardcoded Chicago coords. |
| 3 | **Low** | Consider breaking `settings_page.dart` (560 lines) into separate widgets per section | Improves rebuild granularity and readability. |

---

## 3. Pre-TestFlight Checklist

### Engineer (code)
- [ ] All §2 tasks implemented
- [ ] `pubspec.yaml` version: `1.0.0`
- [ ] `flutter analyze` passes with 0 issues
- [ ] `flutter test` — all tests pass (add tests for new features)
- [ ] `flutter build ios --release` succeeds
- [ ] Manual smoke test on >= 2 iOS devices (different screen sizes)

### External Config (requires web UI / dashboard access)

**Supabase Dashboard:**
- [ ] Enable Apple OAuth provider (requires Apple Service ID + key from Apple Developer Console)
- [ ] Enable Google OAuth provider (requires Google OAuth client credentials)
- [ ] Create `user_favorites` table (columns: `id`, `user_id`, `facility_id`, `created_at`) with RLS policy allowing users to read/write only their own rows
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
- [ ] Description + keywords (healthcare, free clinics, community health, etc.)
- [ ] Screenshots (6.7" + 6.5" minimum, 3 per size)
- [ ] App icon: verify `app_icon_final.jpg` meets 1024x1024 no-alpha spec
- [ ] Age rating questionnaire
- [ ] Copyright
- [ ] Privacy nutrition label (see §4)
- [ ] Export compliance: "Yes, but exempt" (HTTPS only)
- [ ] App Review notes (see §5)

---

## 4. Privacy Nutrition Label (MVP Draft)

MVP includes auth, GPS, and crash reporting. Update this table in App Store Connect.

| Data Type | Collected? | Details |
|-----------|-----------|---------|
| **Email Address** | Yes — collected via OAuth | Linked to user identity. Used for app functionality (account). Not used for tracking. |
| **User ID** | Yes — collected via OAuth | Linked to user identity. Used for app functionality (favorites sync). Not used for tracking. |
| **Coarse Location** | Yes — collected by Google Maps SDK | Third-party collection. Not linked to identity. Not used for tracking. |
| **Precise Location** | Yes — collected via GPS (opt-in) | Used for app functionality (finding nearby facilities). Not linked to identity. Not used for tracking. |
| **Diagnostics (Crash Data)** | Yes — collected via Sentry | Not linked to identity. Used for app functionality (crash reporting). Not used for tracking. |
| **User Content (Feedback)** | Not collected | Feedback UI exists but data is not stored or transmitted in MVP. |
| All other categories | Not collected | |

**Tracking declaration:** "This app does **not** track users." No ATT prompt needed.

---

## 5. App Review Notes Template

```
This app helps users find free and low-cost healthcare facilities.

To test sign-in:
1. Launch the app and sign in with Apple or Google, OR tap "Continue as Guest"
2. Enter a US zip code (e.g., 60613) when prompted
3. Browse the map, search for facilities, and use filters
4. Signed-in users can save Favorites and set Eligibility/Preferences filters
5. Guest users see a lock icon on Favorites, Eligibility, and Preferences — tapping shows a sign-in prompt
6. The "Recent" section on the home page shows the last 3 facilities tapped — tapping one opens a feedback dialog
7. GPS location is available via "Use My Location" on the map (requires location permission)
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
| **High** | Facility feedback backend storage (Supabase table + API) |
| **High** | Favorites cloud sync for authenticated users |
| **Medium** | Analytics (PostHog recommended for healthcare privacy) |
| **Medium** | Offline/connectivity handling (`connectivity_plus` + offline banner) |
| **Medium** | Full accessibility audit (VoiceOver, Dynamic Type, WCAG 2.1 AA) |
| **Medium** | Android release |
| **Low** | Professional localization review (es, zh) |
| **Low** | iPad layout optimization |
| **Low** | Supabase Pro upgrade ($25/mo) — evaluate based on user volume |

---
