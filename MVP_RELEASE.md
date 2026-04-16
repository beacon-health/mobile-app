# Beacon App — MVP Release Plan

> **Living document.** Update as development progresses, decisions are made, and new findings emerge.
>
> **Last updated:** 2026-04-16 · **Target:** iOS App Store (TestFlight → public)

---

## Progress at a Glance

| Stream | Done | In progress | Remaining | Notes |
|--------|------|-------------|-----------|-------|
| **MVP feature work** (§2.1–§2.5) | ~30 / 32 | 0 | 2 | Phase 6 complete: onboarding, zip entry (mandatory), guest flow, filter bar reorder/split, settings restructure (zip under Account), dark mode, map search bar, facility card fix. Remaining: GPS entry-path removal (§2.2), zip-centered Home map (§2.3). |
| **Critical security fixes** (§4) | 4 / 4 | 0 | 0 | ✅ All done. `PrivacyInfo.xcprivacy` authored and wired into Xcode project (Phase 7). |
| **Dev infrastructure** | 5 / 5 | 0 | 0 | ✅ `analysis_options.yaml` + `very_good_analysis`; GitHub Actions CI + iOS build workflow; Fastlane skeleton; CI secret injection; 18 unit tests. |
| **iOS compliance** | 4 / 4 | 0 | 0 | ✅ Bundle ID updated to `org.beaconhealth.app`; deployment targets aligned to 15.0; `PrivacyInfo.xcprivacy` created; portrait-only orientation locked. |
| **Repo hygiene** | 3 / 3 | 0 | 0 | ✅ All clean. New repo: `github.com/beacon-health/mobile-app`. Data pipeline: `github.com/beacon-health/beacon-data`. Old repo pending archive. |
| **Phase 6.5 — cleanup audit** | 0 / 13 | 0 | 13 | New (2026-04-16): comprehensive post-Phase-7 audit surfaced 13 cleanup items (dead code, dedup, best practices, 1 TestFlight-signing blocker). See [§3.4](#34-post-phase-7-comprehensive-audit-2026-04-16). |

> See [§15.5 Work Sequencing Phases](#155-work-sequencing-phases) for the dependency-ordered plan to close the rest.

---

## Table of Contents

1. [Current State Summary](#1-current-state-summary)
2. [Application MVP — Feature Work](#2-application-mvp--feature-work)
   - [2.0 Architectural Prerequisites](#20-architectural-prerequisites-must-land-before-23-25-lock-work)
   - [2.1 Onboarding / Guest Flow](#21-onboarding--guest-flow)
   - [2.2 Location Removal / Zip-Code Default](#22-location-removal--zip-code-default)
   - [2.3 Home Page](#23-home-page)
   - [2.4 Map Page](#24-map-page)
   - [2.5 Settings Page](#25-settings-page)
3. [Dead & Unused Code Audit](#3-dead--unused-code-audit)
4. [Security Findings & Fixes (Critical)](#4-security-findings--fixes-critical)
   - [4.5 Apple Privacy Manifest (PrivacyInfo.xcprivacy)](#-critical-missing-apple-privacy-manifest-privacyinfoxcprivacy)
   - [4.6 Empty catch blocks](#%EF%B8%8F-high-empty-catch-blocks-swallow-errors)
5. [Code Quality & Cleanup](#5-code-quality--cleanup)
6. [Accessibility (MVP Requirements)](#6-accessibility-mvp-requirements)
7. [iOS App Store Requirements](#7-ios-app-store-requirements)
   - [7.8 Privacy Nutrition Label draft](#78-app-store-privacy-nutrition-label--mvp-draft)
8. [Cloud / Supabase Configuration](#8-cloud--supabase-configuration)
9. [Google Maps Configuration](#9-google-maps-configuration)
10. [Secrets Management](#10-secrets-management)
    - [Secrets-on-CI flow](#secrets-on-ci-getting-secretsxcconfig-to-ci-runners)
11. [CI/CD Pipeline](#11-cicd-pipeline)
12. [Security Scanning & Linting](#12-security-scanning--linting)
13. [Testing Strategy](#13-testing-strategy)
14. [GitHub & Repository Strategy](#14-github--repository-strategy)
15. [Pre-Submission Checklist](#15-pre-submission-checklist)
    - [15.5 Work Sequencing Phases](#155-work-sequencing-phases)
16. [Post-MVP Fast Follows](#16-post-mvp-fast-follows)
17. [Open Questions](#17-open-questions)

---

## 1. Current State Summary

| Area | Status |
|------|--------|
| **Framework** | Flutter 3.x / Dart 3.6, Material 3 |
| **Bundle ID** | `com.beacon.healthApp` → changing to `org.beaconhealth.app` |
| **iOS min target** | 15.0 (Podfile) / 15.6 (Xcode Runner target) — **mismatch** |
| **Backend** | Supabase Free tier, `facilities_il_full` view (~691 rows) |
| **Auth** | Supabase OAuth (Google + Apple) partially wired, not functional for MVP |
| **State mgmt** | Provider + ChangeNotifier |
| **Maps** | Google Maps Flutter plugin, API key via `Secrets.xcconfig` |
| **Localization** | 3 languages (en, es, zh) via `flutter_localizations` + ARB |
| **Demo mode** | Feature-flagged with SharedPreferences; loads local JSON |
| **Tests** | 1 placeholder widget test (broken — references stale text) |
| **CI/CD** | None |
| **Linting** | `flutter_lints` in `pubspec.yaml` but **no `analysis_options.yaml` file** |
| **Security scanning** | None |

### Key Architecture Observations

- **`.env` is bundled as a Flutter asset** (listed in `pubspec.yaml` `assets:` section). This means the file — including `SUPABASE_SERVICE_ROLE_KEY` — ships inside the app binary and can be extracted by anyone. **This is a critical security issue (see §4).**
- **Supabase integration uses the service role key from "legacy API keys"** as the `anonKey`. This is **incorrect** for production — must be replaced with the actual anon key. Service role key bypasses all RLS.
- Location permission (`NSLocationWhenInUseUsageDescription`) is requested but per MVP scope should be removed/deferred.
- `geolocator` package actively requests device GPS in `LocationService.getCurrentLocation()` and in `location_search.dart`.
- No onboarding / zip-code-only flow exists yet; the app jumps straight to the auth gate.
- The `CriteriaPage` collects PII (DOB, income, gender, LGBTQ status, citizenship) — out-of-scope for MVP and will be removed.
- `ProfilePage` also collects PII — will be simplified for MVP guest-only flow.
- **Demo mode** is accessible via long-press on "Version" in Settings — will be hidden for MVP with TODO comment.
- No `analysis_options.yaml` exists at the project root despite `flutter_lints` being a dependency.
- `database/` folder contains raw data-scraping scripts — will be moved to separate repo due to tainted commit history.
- 3 `print()` calls remain in production code (down from 15; majority migrated to `developer.log()`). Remaining: [map_page.dart:334](lib/features/map/presentation/pages/map_page.dart:334), [location_search.dart:87](lib/features/map/presentation/widgets/search/location_search.dart:87), [location_search.dart:150](lib/features/map/presentation/widgets/search/location_search.dart:150).
- **Unused dead code found:** `SearchFilterSection`, `MapControllerService`, `DemoFacilityRepository` (only used when demo mode is active), `isGuest` parameter on `MainNavBar` (declared but never read; `ProfilePage` does use it). `MapPage` mixes in `WidgetsBindingObserver` but never overrides any lifecycle methods. The `web/` folder is vestigial (iOS-only target).
- **Note:** `CustomFilterChip` is actively used by `eligibility_filter.dart`, `category_filter.dart`, and `filter_widgets.dart` — it is **not** dead code, contrary to earlier audit notes.

---

## 2. Application MVP — Feature Work

### 2.0 Architectural Prerequisites (must land before §2.3–§2.5 lock work)

The MVP scopes "Favorites", "Eligibility", and "Preferences" filters as **account-only** features, with a lock icon and "sign in to access" message in guest mode. There is currently **no abstraction layer** for guest vs. authenticated state — components access `Supabase.instance.client` directly. Without an architectural layer, lock-state checks become copy-paste of `Supabase.instance.client.auth.currentUser == null` across every locked surface.

| Task | Priority | Status |
|------|----------|--------|
| Create `GuestModeService` (or `AppAuthState`) `ChangeNotifier` exposing `isGuest`, `isAuthed`, `requireAuth(VoidCallback)` — model on existing [demo_mode_service.dart](lib/core/services/demo_mode_service.dart) singleton + SharedPreferences pattern | **High** | ✅ Done | [guest_mode_service.dart](lib/core/services/guest_mode_service.dart) — subscribes to Supabase auth state changes; handles demo mode + uninitialized Supabase. |
| Create reusable `LockedFeatureGate` widget that wraps a child with a lock overlay + tap handler when guest | **High** | ✅ Done | [locked_feature_gate.dart](lib/core/widgets/locked_feature_gate.dart) — `Stack` + `IgnorePointer` + `GestureDetector → showSignInPromptDialog`. |
| Decide and document UX for "locked feature tapped as guest" — modal? bottom sheet? inline message? | **High** | ✅ Done | **Decision: modal dialog** — keeps the existing `showSignInPromptDialog` pattern used throughout the app. `LockedFeatureGate` calls the same dialog. |
| Refactor existing `isGuest` parameter on `MainNavBar` and `ProfilePage` to read from the new provider rather than being passed by hand | **Medium** | ✅ Done | `isGuest` param removed from `MainNavBar`; `login_page.dart` no longer passes it. `home_page.dart` now reads `context.watch<GuestModeService>().isGuest`. |
| Wire central `ErrorReporter` stub (prints in dev, no-op in release; swappable for Sentry/Crashlytics post-MVP) — fixes the empty `catch` blocks in [home_page.dart](lib/features/home/presentation/pages/home_page.dart) | **Medium** | ✅ Done | [error_reporter.dart](lib/core/services/error_reporter.dart) — all 4 previously-silent catches now log via `ErrorReporter`; outer `_loadData` catch also shows a user-facing snackbar. |

> **Why this is §2.0 and not §16:** Without `GuestModeService` + `LockedFeatureGate`, the §2.3 / §2.4 / §2.5 lock-state items are **blocked** — implementing them ad-hoc creates refactor debt the moment auth lands post-MVP.

### 2.1 Onboarding / Guest Flow

| Task | Priority | Status | Audit notes |
|------|----------|--------|-------------|
| Create a welcome/onboarding page shown on first launch | **High** | ⬜ TODO | No `OnboardingPage` exists; [app.dart:52](lib/app.dart:52) routes straight to `AuthGate`. |
| Show platform-appropriate sign-in buttons (Apple on iOS, Google on Android) — **commented out** with `// TODO: revisit once user authentication is in-scope` | **High** | ⚠️ PARTIAL | Buttons exist but are **active**, not commented out. See [login_page.dart:88-110](lib/features/auth/presentation/pages/login_page.dart:88). |
| Implement "Continue as Guest" button that navigates to zip-code entry page | **High** | ⚠️ PARTIAL | Button exists at [login_page.dart:143-167](lib/features/auth/presentation/pages/login_page.dart:143) but routes to `MainNavBar(isGuest: true)` directly — no zip-entry page in between. |
| Zip-code entry page: prompt user for zip code, store in `SharedPreferences` (local only, no PII on server) | **High** | ⬜ TODO | No zip-entry page; Settings has a zip field but it defaults to `DemoUser.zipCode` and isn't persisted. |
| Use stored zip code as the default center for map/facility queries | **High** | ⬜ TODO | Map/Home currently use `LocationService.getCurrentLocation()` (GPS), not zip. |
| Track first-launch state with `SharedPreferences` (`has_completed_onboarding`) | **High** | ⬜ TODO | No `has_completed_onboarding` key found in codebase. |
| Remove `CriteriaPage` from MVP flow (collects PII out-of-scope) or hide it entirely | **High** | ⬜ TODO | Still wired into routes at [app.dart:55](lib/app.dart:55). |

### 2.2 Location Removal / Zip-Code Default

> **Scope:** Remove GPS from entry paths (onboarding, home first-load, settings) — always default to stored zip. Keep GPS behind an explicit "use my location" tap in map/search with a `// TODO: revisit gating after auth lands` comment.

| Task | Priority | Status | Audit notes |
|------|----------|--------|-------------|
| Remove `geolocator` and `geocoding` location-permission requests from MVP guest entry path | **High** | ⬜ TODO | Both packages still in [pubspec.yaml:22-23](pubspec.yaml:22). Active calls at [home_page.dart:72](lib/features/home/presentation/pages/home_page.dart:72) and [map_page.dart:338-366](lib/features/map/presentation/pages/map_page.dart:338). |
| Comment out `LocationService.getCurrentLocation()` calls in entry paths; replace with zip-code-based geocoding | **High** | ⬜ TODO | `LocationService` (in [location_service.dart:11-43](lib/features/map/presentation/services/location_service.dart:11)) still actively requests GPS. |
| Comment out "Current Location" UI in `LocationSearch` widget — leave `// TODO: revisit once location-based search is in-scope` | **High** | ⬜ TODO | Button still active at [location_search.dart:200-204](lib/features/map/presentation/widgets/search/location_search.dart:200). |
| Remove `NSLocationWhenInUseUsageDescription` from `Info.plist` (or keep if needed for map "blue dot" — verify with Apple guidelines) | **Medium** | ⬜ TODO | Still present at [Info.plist:38-39](ios/Runner/Info.plist:38). Decision required: keep for map blue-dot, or strip entirely. |
| Default `LocationSearch` to display the user's stored zip code | **High** | ⚠️ PARTIAL | Hint text says "Enter zip code" but `_currentLocation` initialized as `'Current Location'` in [map_page.dart:72](lib/features/map/presentation/pages/map_page.dart:72). |
| Update `HomePage._loadData()` to use stored zip → geocoded lat/lng instead of GPS | **High** | ⬜ TODO | Calls `LocationService.getCurrentLocation()` first; depends on zip-code persistence from §2.1. |
| Update `MapPage._tryGetCurrentLocationOnStartup()` similarly | **High** | ⬜ TODO | GPS-first behavior at [map_page.dart:338-366](lib/features/map/presentation/pages/map_page.dart:338). |

### 2.3 Home Page

| Task | Priority | Status | Audit notes |
|------|----------|--------|-------------|
| Map cutout centers on user's zip code (not GPS) | **High** | ⬜ TODO | Currently calls `LocationService.getCurrentLocation()` at [home_page.dart:72](lib/features/home/presentation/pages/home_page.dart:72). |
| 4 category buttons — keep as-is | **Low** | ✅ Done | Verified at [home_page.dart:244-270](lib/features/home/presentation/pages/home_page.dart:244): Health Care, Housing & Shelter, Free Clinics, Food Pantry. |
| Favorites section: show locked state for guests | **High** | ✅ Done | Locked card shown; tap opens `showSignInPromptDialog`. Guest check short-circuits before `Consumer<FacilityProvider>`. |
| `myLocationEnabled` on HomePageGoogleMap — disable for MVP | **Medium** | ✅ Done | Set to `false` with TODO comment. |

### 2.4 Map Page

| Task | Priority | Status | Audit notes |
|------|----------|--------|-------------|
| Comment out "Current Location" row in search area — `// TODO: revisit once location-based search is in-scope` | **High** | ⬜ TODO | See §2.2 — overlaps; keep behind explicit user action per scope split. |
| Facility name search bar — verify it works as keyword search (currently filters by `searchText`) | **Medium** | ⚠️ APPEARS DONE | `FacilitySearch` widget filters by `searchText`; verify with manual test. |
| Distance filter defaults to **1 mile** (currently `distanceOptions.first` = 1.0) | **Low** | ✅ Done | Confirmed: `MapConstants.distanceOptions = [1.0, 3.0, 5.0, 10.0]` at [map_constants.dart:19](lib/features/map/constants/map_constants.dart:19); `_selectedDistance = MapConstants.distanceOptions.first` at [map_page.dart:71](lib/features/map/presentation/pages/map_page.dart:71). |
| **Reorder filter bar** to: Open Now → Favorites → Category → Eligibility → Preferences | **High** | ⬜ TODO | Current order at [filter_bar.dart:40-100](lib/features/map/presentation/widgets/filters/components/filter_bar.dart:40) is: Tune → Distance → Category → Open Now → Favorites → Eligibility. Wrong. |
| **Split Eligibility filter** into two: **Eligibility** (proof of income, residency, insurance, referral) and **Preferences** (walk-ins, appointment only, free services, sliding scale, wheelchair accessible, telehealth, other languages, serves outside area, open to immigrants) | **High** | ⬜ TODO | Single `EligibilityRequirement` enum at [filter_constants.dart:87-101](lib/features/map/constants/filter_constants.dart:87) with all 13 items mixed. Need new `PreferenceRequirement` enum + filter widget. |
| Eligibility filter shows sign-in dialog in guest mode | **High** | ✅ Done | `showSignInPromptDialog` shown when guest. Preferences filter (once split) uses same pattern. |
| Favorites filter: show sign-in dialog in guest mode | **High** | ✅ Done | `showSignInPromptDialog` shown when guest. Auto-wires when auth lands. |
| `myLocationEnabled` on MapPage GoogleMap — disable for MVP | **Medium** | ✅ Done | Set to `false` with TODO comment. Location permission removed from `Info.plist`. |

### 2.5 Settings Page

| Task | Priority | Status | Audit notes |
|------|----------|--------|-------------|
| Account section: show "Guest" state with prompt to sign in (instead of hardcoded `DemoUser` data) | **High** | ⬜ TODO | Currently shows `DemoUser.name` / `DemoUser.email` at [settings_page.dart:92-162](lib/features/settings/presentation/pages/settings_page.dart:92). Depends on §2.0 `GuestModeService`. |
| Zip Code displayed under "Eligibility" subsection alongside actual eligibility toggles | **Medium** | ✅ Done | Already in Eligibility section at [settings_page.dart:238-251](lib/features/settings/presentation/pages/settings_page.dart:238). Persistence still TODO (§2.1). |
| **Split current eligibility toggles** into "Eligibility" and "Preferences" sections matching the map filter split | **High** | ⬜ TODO | All toggles in single `_buildEligibilitySection` at [settings_page.dart:228-348](lib/features/settings/presentation/pages/settings_page.dart:228). Needs split + locks for guest. |
| Privacy Policy button → open website URL via `url_launcher`: `https://beacon-website-pied.vercel.app/privacy-policy` | **Medium** | ⬜ TODO | Empty `onTap: () {}` at [settings_page.dart:395-400](lib/features/settings/presentation/pages/settings_page.dart:395). `url_launcher` is in [pubspec.yaml:24](pubspec.yaml:24) but not imported anywhere. |
| Terms of Use button → open website URL via `url_launcher`: `https://beacon-website-pied.vercel.app/terms-of-use` | **Medium** | ⬜ TODO | Empty `onTap: () {}` at [settings_page.dart:402-407](lib/features/settings/presentation/pages/settings_page.dart:402). |
| Comment out "Sign Out" button — `// TODO: revisit once user authentication is in-scope` | **High** | ⬜ TODO | Active button at [settings_page.dart:487-528](lib/features/settings/presentation/pages/settings_page.dart:487). |
| Version text should pull from `pubspec.yaml` programmatically (currently hardcoded `'0.0.1+1'`; pubspec says `0.1.1`) | **Low** | ⬜ TODO | Hardcoded at [settings_page.dart:391](lib/features/settings/presentation/pages/settings_page.dart:391). Add `package_info_plus` dependency. |
| Hide demo-mode toggle (long-press on Version) — `// TODO: revisit demo-mode use case when live` | **High** | ⬜ TODO | `onLongPress` toggle at [settings_page.dart:374-387](lib/features/settings/presentation/pages/settings_page.dart:374) still active. Recommend gating behind `kDebugMode` rather than fully removing the code. |

---

## 3. Dead & Unused Code Audit

### 3.1 Findings

The following files/functions were identified as unused or out-of-date in the current codebase:

| Item | Location | Status | Action Required |
|------|----------|--------|----------------|
| `SearchFilterSection` widget | [search_filter_section.dart](lib/features/map/presentation/widgets/search/search_filter_section.dart) | Unused | Remove or comment out with TODO |
| `MapControllerService` | [map_controller_service.dart](lib/features/map/presentation/services/map_controller_service.dart) | Unused | Remove or comment out with TODO |
| `DemoFacilityRepository` | [demo_facility_repository.dart](lib/features/map/data/demo_facility_repository.dart) | Conditional | Only used when demo mode is active — will be hidden for MVP (gate behind `kDebugMode`) |
| `isGuest` parameter on `MainNavBar` | [main_nav_bar.dart:10](lib/features/home/presentation/widgets/main_nav_bar.dart:10) | Declared, never read | Remove or wire to `GuestModeService` (§2.0). `ProfilePage` does use it (line 393, 395) — only `MainNavBar` is dangling. |
| `CriteriaPage` | [criteria_page.dart](lib/features/auth/presentation/pages/criteria_page.dart) | Out of scope (PII) | Remove from routes at [app.dart:55](lib/app.dart:55) |
| `flutter_signin_button` dependency | [pubspec.yaml:12](pubspec.yaml:12) | Unused once OAuth buttons commented out | Comment buttons in [login_page.dart:88-110](lib/features/auth/presentation/pages/login_page.dart:88) first; then optionally drop the dep |
| `WidgetsBindingObserver` mixin on `MapPage` | [map_page.dart:39](lib/features/map/presentation/pages/map_page.dart:39) | Mixed in, no overrides | Remove the mixin or implement `didChangeAppLifecycleState` |
| `web/` folder | `/web/` (index.html, manifest.json, icons) | Vestigial — iOS-only target per Decision Log | Recommend delete; record in Decision Log |
| 7 tracked `.DS_Store` files | `.DS_Store`, `.windsurf/.DS_Store`, `.windsurf/rules/.DS_Store`, `android/.DS_Store`, `assets/.DS_Store`, `database/.DS_Store`, `ios/.DS_Store` | Committed to git | `git rm --cached <files>` + add `.DS_Store` to `.gitignore` (currently missing) |

### 3.2 Demo Mode

**Decision:** Demo mode will be hidden for MVP release.

- Demo mode is currently accessible via long-press on "Version" in Settings
- Code related to demo mode toggle should be commented out with TODO: `// TODO: revisit demo-mode use case when live`
- `DemoFacilityRepository` and `DemoUser` can remain in codebase but will not be accessible
- `DemoModeService` can remain for future development use

### 3.3 Action Items

| Priority | Task |
|----------|------|
| **High** | Comment out demo mode toggle in `SettingsPage` with TODO |
| **High** | Remove `CriteriaPage` from routes in `app.dart` |
| **Medium** | Remove or comment out `SearchFilterSection`, `MapControllerService` |
| **Medium** | Remove unused `isGuest` parameter from `MainNavBar` or wire to `GuestModeService` (§2.0) |
| **Low** | Remove `flutter_signin_button` dependency after commenting out OAuth buttons |

### 3.4 Post-Phase-7 Comprehensive Audit (2026-04-16)

Performed after the feature build-out + iOS compliance work landed. Four parallel audit streams covered: dead code, file structure / reuse, Flutter & Dart best practices, and iOS project readiness.

#### 3.4.1 Dead code — safe to delete

| Item | Location | Rationale |
|------|----------|-----------|
| `MapControllerService` | [map_controller_service.dart](lib/features/map/presentation/services/map_controller_service.dart) (103 lines) | Defined but never instantiated; map state lives in `MapPageState` directly. |
| `SearchFilterSection` | [search_filter_section.dart](lib/features/map/presentation/widgets/search/search_filter_section.dart) (115 lines) | Never imported; current UI composes `FacilitySearch` + `LocationSearch` + `FilterBar` directly. |
| `CriteriaPage` | [criteria_page.dart](lib/features/auth/presentation/pages/criteria_page.dart) (630 lines) | Never routed; 19-field PII form abandoned when MVP went guest-only. |
| Orphan asset `app_icon.png` | `assets/app_icon.png` | Not declared in `pubspec.yaml`; only `app_icon_final.jpg` and `tiny_icon.png` are used. |

#### 3.4.2 Dead code — conditionally dead (keep, post-MVP)

| Item | Reason |
|------|--------|
| `LocationService` | GPS deferred post-MVP per §2.2. `ZipCodeService` replaces it in the guest flow. |
| `geolocator` package | Only referenced from `LocationService` (dead now, live post-MVP). |
| `geocoding` package | Actively used by `ZipCodeService.setZipCode()`. **Keep.** |
| `flutter_signin_button` | Used only in `LoginPage` which is unreachable in guest-only flow. Candidate for removal after confirming no hidden entry points. |
| `WidgetsBindingObserver` on `MapPage` | Previously flagged; `didChangeMetrics()` **is** implemented for keyboard visibility. **Not dead** — earlier audit finding stale. |

#### 3.4.3 High-value reuse / deduplication wins

| Pattern | Duplicated at | Proposed extraction |
|---------|---------------|---------------------|
| Frosted-glass lock overlay | [settings_page.dart](lib/features/settings/presentation/pages/settings_page.dart) lines ~405–459 **and** ~543–597 (verbatim) | New `lib/core/widgets/locked_section_overlay.dart` — saves ~50 LOC and removes a drift risk. |
| Theme-aware onboarding gradient | [onboarding_page.dart](lib/features/auth/presentation/pages/onboarding_page.dart), [zip_entry_page.dart](lib/features/auth/presentation/pages/zip_entry_page.dart), [login_page.dart](lib/features/auth/presentation/pages/login_page.dart) (the last is light-mode-only — missed dark support) | New `lib/core/theme/app_gradients.dart` with `AppGradients.onboarding(context)`. Incidentally fixes the login dark-mode gradient bug. |
| `Theme.of(context).colorScheme.onSurface.withValues(alpha: X)` | 36 occurrences across 11 files | Extension on `ColorScheme` in `lib/core/theme/app_colors.dart` — e.g. `context.colors.onSurfaceMuted` / `onSurfaceDisabled`. |

#### 3.4.4 Structure / naming issues (lower priority)

- **Misplaced service:** `lib/services/supabase_facility_service.dart` lives outside the feature tree; should move to `lib/features/map/data/`. Only `map/` feature has the full `presentation/domain/data` split; other features skip domain/data. Decide on a consistent convention and document it.
- **Vague util filenames:** `lib/features/map/utils/facility_display_utils.dart` and `marker_utils.dart` — rename to describe the domain (`facility_formatting.dart`, `marker_icon_factory.dart`).
- **`settings_page.dart` has 19 `_buildXSection` methods** in one class. Consider breaking each section into its own `StatelessWidget` — improves rebuild granularity and readability.

#### 3.4.5 Flutter / Dart best-practice fixes

| Issue | Where | Fix |
|-------|-------|-----|
| Silent `catch (_) {}` in camera animation | [home_page.dart:192](lib/features/home/presentation/pages/home_page.dart) | Route through `ErrorReporter` (already wired in `_loadData`). |
| `try-catch` around `firstWhere` for null | [facility_provider.dart:37](lib/features/map/presentation/providers/facility_provider.dart) | Replace with `.firstWhereOrNull` from `collection`. |
| `Provider.of(context, listen: false)` | [map_page.dart](lib/features/map/presentation/pages/map_page.dart):252, 476, 619 | Use `context.read<T>()` — same semantics, clearer intent. |
| Multiple `setState` in `_loadData` | [home_page.dart](lib/features/home/presentation/pages/home_page.dart):128, 133 | Batch into one `setState`. |
| Missing `const` everywhere | `home_page.dart` has only 36 `const` in 556 lines; should be 100+ | Lint is configured (`very_good_analysis`) — enforce `prefer_const_constructors` and fix. |
| No `RepaintBoundary` around `GoogleMap` | [map_page.dart:677](lib/features/map/presentation/pages/map_page.dart) | Wrap — stops unrelated Stack repaints from invalidating map tiles. |
| Redundant map-controller state | [map_page.dart:40](lib/features/map/presentation/pages/map_page.dart) | `Completer<GoogleMapController>` **and** `_googleMapController` field — pick one. |
| Setstate inside expensive debounced marker compute | [map_page.dart:179–181](lib/features/map/presentation/pages/map_page.dart) | Split compute + setState (compute off-frame, setState with result). |

#### 3.4.6 iOS readiness — status after Phase 7

Result: **TestFlight-ready with one blocker and one polish item.**

- ✅ `Info.plist` clean, portrait-only, GPS correctly commented out.
- ✅ `PrivacyInfo.xcprivacy` valid, wired into `project.pbxproj` Resources phase, required-reason codes accurate (CA92.1, C617.1, 35F9.1, E174.1).
- ✅ `AppDelegate.swift` gracefully handles missing Google Maps key.
- ✅ Bundle ID `org.beaconhealth.app` set consistently across Debug / Release / Profile.
- ✅ `IPHONEOS_DEPLOYMENT_TARGET = 15.0` across Podfile + all Xcode configs.
- ✅ App icon present at all required sizes (1x/2x/3x, 1024 App Store).
- ⚠️ **Blocker:** inconsistent `DEVELOPMENT_TEAM` — Debug uses `DWDZ94L8RD`, Release/Profile use `3VY6L9SG6K`. Pick one and align across all three configs before TestFlight upload.
- ⚠️ **Polish:** `LaunchImage.imageset/*.png` are 68-byte placeholder PNGs. Either replace with a branded splash or (preferred) delete the image set and rely on `LaunchScreen.storyboard` which is already referenced.
- ⬜ `Runner.entitlements` does not exist — not needed for MVP guest-only; add when Sign in with Apple lands post-MVP.

#### 3.4.7 Consolidated action list

Priority-ordered for a single follow-up pass ("Phase 6.5 — cleanup"):

| # | Priority | Task | Effort |
|---|----------|------|--------|
| 1 | **High** | Resolve `DEVELOPMENT_TEAM` mismatch in `project.pbxproj` (pick one team, apply to all configs) | 5 min |
| 2 | **High** | Delete `MapControllerService`, `SearchFilterSection`, `CriteriaPage`, orphan `app_icon.png` | 30 min |
| 3 | **High** | Extract `LockedSectionOverlay` widget; replace both copies in `settings_page.dart` | 30 min |
| 4 | **Medium** | Extract `AppGradients` helper; update `onboarding_page.dart`, `zip_entry_page.dart`, fix `login_page.dart` dark-mode gap | 20 min |
| 5 | **Medium** | Replace `catch (_) {}` in `home_page.dart:192` and `facility_provider.dart:37` with `ErrorReporter` + `.firstWhereOrNull` | 15 min |
| 6 | **Medium** | Swap `Provider.of(context, listen: false)` → `context.read<T>()` (3 sites in `map_page.dart`) | 10 min |
| 7 | **Medium** | Wrap `GoogleMap` in `RepaintBoundary` (both `map_page.dart` and `home_page.dart`) | 5 min |
| 8 | **Medium** | Delete placeholder `LaunchImage.imageset/*.png` or replace with branded assets | 15 min |
| 9 | **Low** | Move `supabase_facility_service.dart` into `lib/features/map/data/`; document feature-layer convention in `README.md` | 45 min |
| 10 | **Low** | Rename `facility_display_utils.dart` → `facility_formatting.dart`; `marker_utils.dart` → `marker_icon_factory.dart` | 15 min |
| 11 | **Low** | Extension `ColorSchemeExt` on `ColorScheme` to replace 36 inline `withValues(alpha:)` calls | 45 min |
| 12 | **Low** | Consolidate `Completer<GoogleMapController>` / `_googleMapController` duplicate state in `map_page.dart` | 15 min |
| 13 | **Low** | Run `dart fix --apply` + `prefer_const_constructors` across `home_page.dart` and other large files | 30 min |

Total: ~4 hours of low-risk cleanup. None of these block TestFlight; item #1 is a blocker for signed upload but not for the build itself.

---

## 4. Security Findings & Fixes (Critical)

### ✅ FIXED: `.env` bundled as an app asset

`.env` removed from `pubspec.yaml` assets. `flutter_dotenv` dependency removed. Secrets now injected via `--dart-define` / `String.fromEnvironment`. Local dev run command:

```bash
flutter run \
  --dart-define=SUPABASE_URL=<your-url> \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

### ✅ FIXED: Service Role Key as anon key

`main.dart` now reads `SUPABASE_ANON_KEY` via `String.fromEnvironment`. **Action still required:** replace the value in your `--dart-define` / GitHub Secret with the actual **publishable key** from Supabase Dashboard → Project Settings → API. (Supabase renamed "anon key" → "publishable API key" — same JWT, new label. `supabase_flutter` still uses `anonKey` parameter.) Also enable RLS on all tables (§8.2).

### ⚠️ HIGH: `print()` statements in production code

✅ All 3 remaining `print()` calls replaced with `developer.log()` (name-tagged for filtering). `analysis_options.yaml` (Phase 4) will enforce `avoid_print: true` going forward.

### ⚠️ HIGH: Google Maps API key restriction

Billing account is set up. Verify in Google Cloud Console that the iOS API key is restricted to:
- iOS apps only (bundle ID: `org.beaconhealth.app` — update from `com.beacon.healthApp`)
- Google Maps SDK for iOS only

An unrestricted key can be abused. Performance testing of Maps usage should be handled post-MVP.

### ✅ FIXED: `debug: true` in Supabase initialization

`debug: kDebugMode` — automatically `false` in release builds.

### 🚨 CRITICAL: Missing Apple Privacy Manifest (`PrivacyInfo.xcprivacy`)

**File:** `ios/Runner/PrivacyInfo.xcprivacy` — **does not exist**

As of **Spring 2024**, Apple requires a `PrivacyInfo.xcprivacy` manifest in any app whose binary or third-party SDKs use **required-reason APIs** (UserDefaults, file timestamp, system boot time, disk space) or that include any of the SDKs on Apple's [commonly-used SDK list](https://developer.apple.com/support/third-party-SDK-requirements/). Beacon currently uses **Google Maps SDK for iOS** (on the list) and indirectly UserDefaults via `shared_preferences`, so this is required.

**Failure mode:** App Store submissions without a valid manifest receive an automated rejection email (no human review).

**Fix (required before TestFlight upload):**

Create [ios/Runner/PrivacyInfo.xcprivacy](ios/Runner/PrivacyInfo.xcprivacy) with at minimum:

1. **`NSPrivacyTracking`** = `false` (guest-only, no tracking)
2. **`NSPrivacyTrackingDomains`** = `[]`
3. **`NSPrivacyCollectedDataTypes`** = `[]` if no analytics/PII; otherwise list categories per Apple's data-type taxonomy
4. **`NSPrivacyAccessedAPITypes`** = entries for each required-reason API used. For Beacon's current dependencies:
   - `NSPrivacyAccessedAPICategoryUserDefaults` (reason `CA92.1` — accessing app's own defaults via `shared_preferences`)
   - `NSPrivacyAccessedAPICategoryFileTimestamp` (reason `C617.1` if any file metadata is read by deps)
   - `NSPrivacyAccessedAPICategorySystemBootTime` (reason `35F9.1` if any dependency reads boot time)
   - `NSPrivacyAccessedAPICategoryDiskSpace` (reason `E174.1` if any dependency checks free space)

**Verification:** Run a TestFlight upload through Transporter or Xcode; if the manifest is missing or malformed, the upload returns an `ITMS-91056` or `ITMS-91065` error.

> **Action:** Survey each plugin (`google_maps_flutter`, `geolocator`, `geocoding`, `supabase_flutter`, `shared_preferences`, `path_provider`, `flutter_dotenv`, `url_launcher`, `flutter_signin_button`) for whether the maintainer ships their own `PrivacyInfo.xcprivacy` (preferred) — if not, declare on the app's behalf.

### ⚠️ HIGH: Empty `catch` blocks swallow errors

**Files:** [home_page.dart:77,140,176](lib/features/home/presentation/pages/home_page.dart:77)

Three `try { ... } catch (_) {}` blocks silently absorb all errors — including the `LocationService` failures and Supabase facility-fetch failures that block the home-page render. Users see an empty screen instead of an error message; engineers have nothing to debug from.

**Fix pattern (lands as part of §2.0 `ErrorReporter` stub):**

```dart
try {
  ...
} catch (e, stackTrace) {
  ErrorReporter.instance.report(e, stackTrace, context: 'HomePage._loadFavorites');
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't load favorites — try again")),
    );
  }
}
```

`ErrorReporter` is a one-method facade (`report(error, stackTrace, {context})`) that prints in dev and is a no-op in release; post-MVP it's swappable for Sentry / Crashlytics without touching call sites.

---

## 5. Code Quality & Cleanup

### 5.1 Missing `analysis_options.yaml`

Despite `flutter_lints` being in `pubspec.yaml`, there is no `analysis_options.yaml` at the project root. **Decision: adopt `very_good_analysis`** (stricter, production-grade). Expect ~1 day of lint fixes at adoption time.

Add dependency and create the file:

```bash
flutter pub add dev:very_good_analysis
```

```yaml
# analysis_options.yaml
include: package:very_good_analysis/analysis_options.yaml

linter:
  rules:
    avoid_print: true  # catches remaining print() calls
```

### 5.2 Dead / Out-of-Scope Code to Remove or Shelve

| File/Area | Issue |
|-----------|-------|
| `lib/features/auth/presentation/pages/criteria_page.dart` | 584-line PII collection page. Out of MVP scope. Remove from routes or hide. |
| `lib/features/profile/presentation/pages/profile_page.dart` | Collects PII (DOB, income, gender). Out of MVP scope. Simplify or hide. |
| `lib/core/models/demo_user.dart` | Hardcoded mock user. Replace with proper guest state for MVP. |
| `database/` directory | Raw data pipeline scripts. Will be moved to separate repo due to tainted commit history. |
| `flutter_signin_button` dependency | Will be unused once OAuth buttons are commented out — remove or keep commented. |
| Demo mode toggle | Currently accessible via long-press on "Version" in Settings. Will be hidden for MVP with TODO comment. |

### 5.3 Code Issues Found

| Issue | File | Line(s) |
|-------|------|---------|
| `_zipCodeController` not marked `late` or `final` | `criteria_page.dart` | 14 |
| `DropdownButtonFormField` uses deprecated `initialValue` (should be `value`) | `profile_page.dart` | 238, 273, 288 |
| Unused `_error` field never cleared when facilities load successfully | `map_page.dart` | 58, ~270 |
| `_currentLocation` string mixing display and state concerns | `map_page.dart` | 72 |
| Empty `catch` blocks silently swallow errors | `home_page.dart` | 77, 140, 176 |
| `.env` loaded with `mergeWith: {}` — redundant | `main.dart` | 18 |
| Version hardcoded as `'0.0.1+1'` in settings, pubspec says `0.1.1` | `settings_page.dart` | 392, `pubspec.yaml` | 6 |

### 5.4 iOS Deployment Target Mismatch

- **Podfile:** `platform :ios, '15.0'`
- **Xcode project-level:** `IPHONEOS_DEPLOYMENT_TARGET = 13.0`
- **Xcode Runner target:** `IPHONEOS_DEPLOYMENT_TARGET = 15.6`

**Fix:** Align all three to `15.0` (or higher if required by a dependency). This avoids build warnings and App Store review issues.

### 5.5 Orientation Lock

`main.dart` locks to portrait via `SystemChrome.setPreferredOrientations`, but `Info.plist` allows landscape. Either:
- Remove landscape orientations from `Info.plist`, or
- Remove the code lock and support both.

**Recommendation:** For MVP, lock to portrait everywhere (code + plist).

---

## 6. Accessibility (MVP Requirements)

### 6.1 iOS Accessibility Standards

Apple requires apps to meet basic accessibility standards for App Store approval. Key areas to address:

| Requirement | Status | Action Required |
|-------------|--------|----------------|
| **VoiceOver compatibility** | ⬜ TODO | Ensure all UI elements have meaningful labels and are accessible via VoiceOver |
| **Dynamic Type support** | ⬜ TODO | Test with larger text sizes; ensure text scales appropriately |
| **Minimum tap target size** | ⬜ TODO | Ensure interactive elements are at least 44x44 points (Apple HIG) |
| **Color contrast ratios** | ⬜ TODO | Verify text meets WCAG AA standards (4.5:1 for normal text, 3:1 for large text) |
| **Focus indication** | ⬜ TODO | Ensure keyboard focus is visible for external keyboard users |
| **Semantic labels** | ⬜ TODO | Use `Semantics` widget for custom widgets without inherent accessibility labels |
| **Reduced Motion support** | ⬜ TODO | Respect user's reduced motion preference in animations |

### 6.3 Healthcare-Specific Considerations

For a healthcare app, accessibility is particularly important:

- **Clear, simple language** for facility descriptions and eligibility information
- **High contrast** for map markers and facility list items
- **Large, readable text** for facility details (address, phone, hours)
- **Accessible navigation** for users with motor impairments

### 6.4 Testing Checklist

- [ ] Test with VoiceOver enabled on iOS device
- [ ] Test with Dynamic Type at largest text size
- [ ] Test with Reduce Motion enabled
- [ ] Test with Invert Colors enabled
- [ ] Verify all buttons have meaningful labels
- [ ] Verify all images have accessibility descriptions where relevant
- [ ] Use Xcode Accessibility Inspector to audit the app

### 6.5 Post-MVP Enhancement

Full accessibility audit (WCAG 2.1 AA compliance) is recommended as a post-MVP fast follow, including:
- Professional accessibility testing
- Screen reader testing with actual users
- Automated accessibility testing tools integration

---

## 7. iOS App Store Requirements

### 7.1 Apple Developer Account

- [x] Enroll in **Apple Developer Program** ($99/year) — required for App Store and TestFlight.
- [ ] Set up the app in **App Store Connect**.
- [ ] Create an **App ID** matching bundle ID `org.beaconhealth.app` (updated from `com.beacon.healthApp`).

| Item | Value |
|------|-------|
| **Team ID** | `3VY6L9SG6K` |
| **Apple ID email** | `hq@beacon-health.com` |
| **App Store Connect API Key ID** | `99WRH2CRMQ` (key file: `AuthKey_99WRH2CRMQ.p8` — gitignored ✅) |
| **App Store Connect Issuer ID** | `33d021fa-95fd-4d15-a247-98d49c5b138c` ✅ |

> **Security:** `*.p8` has been added to `.gitignore`. Move `AuthKey_99WRH2CRMQ.p8` outside the repo directory when possible.

### 7.2 App Metadata (App Store Connect)

| Item | Status | Notes |
|------|--------|-------|
| App name | ⬜ | "Beacon" — verify no trademark conflicts |
| Subtitle | ⬜ | e.g., "Find Free Healthcare Near You" |
| Description | ⬜ | |
| Keywords | ⬜ | healthcare, free clinics, community health, etc. |
| Screenshots (6.7" & 6.5" + optional 12.9" iPad) | ⬜ | Minimum 3 per device size |
| App icon (1024×1024, no alpha) | ⬜ | Have `app_icon_final.jpg` — verify meets spec |
| Privacy Policy URL | ✅ | `https://beacon-website-pied.vercel.app/privacy-policy` |
| Support URL | ✅ | `https://beacon-website-pied.vercel.app/contact` |
| Category | ✅ | "Reference" (similar competitor apps are in this category) |
| Age rating | ⬜ | Complete questionnaire |
| Copyright | ⬜ | |

### 7.3 App Privacy / Data Collection

Apple requires a **privacy nutrition label** in App Store Connect. For MVP guest-only:
- **Data not collected** — if zip code stays local-only and no analytics.
- If Google Maps collects data via its SDK, you must disclose "Location" → "Coarse Location" under third-party SDKs.
- If Supabase anon key queries are logged server-side with IP, disclose "Identifiers" or "Usage Data."

### 7.4 App Review Notes for Guest Flow

**User Request:** Include notes to explain the guest flow for App Store testers.

**Suggested Review Notes:**
```
This app is currently in MVP release with a guest-only flow. No authentication is required.

To test the app:
1. Launch the app and tap "Continue as Guest"
2. Enter any US zip code (e.g., 60613) to search for facilities
3. Browse the map and facility list
4. Note: Favorites, Eligibility filters, and Preferences filters are locked behind sign-in and will show a lock icon in guest mode
5. The app uses zip code-based location search (no GPS permission required for MVP)
```

### 7.5 Signing & Provisioning

- [ ] Create/download iOS Distribution certificate.
- [ ] Create App Store provisioning profile for `org.beaconhealth.app`.
- [ ] Ensure Xcode "Signing & Capabilities" is set to automatic or uses the correct profile.
- [ ] Enable "Sign in with Apple" capability in Xcode (for future auth — can add now).

### 7.6 Xcode Configuration

| Check | Current | Action |
|-------|---------|--------|
| Bundle ID | `com.beacon.healthApp` → `org.beaconhealth.app` | Update in Xcode and App Store Connect |
| Display Name | "Beacon" (`CFBundleName`) | ✅ |
| Version scheme | FLUTTER_BUILD_NAME / FLUTTER_BUILD_NUMBER | ✅ |
| Launch screen | `LaunchScreen.storyboard` | Review design |
| App Transport Security | Default (HTTPS enforced) | ✅ |
| Bitcode | `ENABLE_BITCODE = NO` | ✅ (Flutter doesn't support) |
| Swift version | 5.0 | ✅ |

### 7.7 Required Xcode Entitlements (Current & Future)

- Associated Domains (for Supabase deep links / universal links) — currently using `io.supabase.flutter` URL scheme
- Sign in with Apple — future requirement
- Push Notifications — not needed for MVP

**Status:** No `ios/Runner/Runner.entitlements` file exists in the repo. None is required for the MVP guest-only flow, but one will be needed when:
- Sign in with Apple is enabled (post-MVP)
- Associated Domains are added for universal-link deep linking (post-MVP)

When added, ensure the file is referenced by `CODE_SIGN_ENTITLEMENTS` in [project.pbxproj](ios/Runner.xcodeproj/project.pbxproj) and bundled in the App Store Connect app capabilities.

### 7.8 App Store Privacy Nutrition Label — MVP draft

App Store Connect requires a privacy nutrition label per app version. Based on the guest-only MVP scope, the draft below is what to enter. **Update before launch if analytics or auth land.**

| Question (App Store Connect) | Answer for MVP guest-only | Notes |
|--|--|--|
| Do you or your third-party partners collect data from this app? | **Yes** (Google Maps SDK collects coarse location) | Even if Beacon collects nothing itself, embedded SDKs trigger this. |
| **Contact Info** (Name, Email, Phone, Address, Other Contact Info) | Not collected | Guest-only, no auth in MVP. |
| **Health & Fitness** | Not collected | App browses facilities; doesn't store user health data. |
| **Financial Info** | Not collected | |
| **Location** → Coarse Location | **Collected by third party (Google)**, **not linked to identity**, **not used for tracking** | Google Maps SDK behavior. Disclose. |
| **Location** → Precise Location | Not collected for MVP | If `myLocationEnabled: true` is removed per §2.3/§2.4, this stays "not collected." If kept, switch to "collected by third party, not linked, not tracking." |
| **Sensitive Info** | Not collected | |
| **Contacts** | Not collected | |
| **User Content** | Not collected | Favorites are local-only in MVP; if synced post-auth, update. |
| **Browsing History** | Not collected | |
| **Search History** | Not collected | Facility search is local; not logged. |
| **Identifiers** → User ID, Device ID | Not collected | Confirm Supabase anon-key requests don't log device IDs server-side. |
| **Purchases** | Not collected | |
| **Usage Data** | Not collected | No analytics SDK in MVP. |
| **Diagnostics** | Not collected | Add when Sentry/Crashlytics lands post-MVP. |
| **Other Data** | Not collected | |

**Tracking declaration:** "This app does **not** track users." (No `App Tracking Transparency` prompt required.)

**Action:** When auth (post-MVP §16) or analytics land, revise this section before the next version submission.

---

## 8. Cloud / Supabase Configuration

### 8.1 Current State

- Free tier Supabase project.
- Single view `facilities_il_full` joining `facilities_il` + `DM_Supabase_Eligibility`.
- ~691 facilities, all fetched at once and cached client-side.
- Service layer (`SupabaseFacilityService`) does client-side filtering.

### 8.2 Required Changes for Production

| Task | Priority | Status |
|------|----------|--------|
| **Verify RLS is enabled** on all tables/views, with appropriate read-only policies for anon key | **Critical** | ⬜ TODO |
| **Stop using service role key in client app** — use only the anon (public) key | **Critical** | ⬜ TODO |
| Add a read-only RLS policy: `CREATE POLICY "public_read" ON facilities_il FOR SELECT USING (true);` | **Critical** | ⬜ TODO |
| Set Supabase project's "API Settings" → disable service role key usage from client SDKs if possible | **High** | ⬜ TODO |
| Review Supabase Auth settings for future OAuth (Apple, Google) providers | **Low** | ⬜ TODO |
| Consider upgrading to **Supabase Pro** ($25/mo) before public launch for: 8 GB database, daily backups, 7-day log retention, email support | **Medium** | ⬜ Decide |
| Set up Supabase database backups (included in Pro, otherwise manual `pg_dump`) | **Medium** | ⬜ TODO |
| Review and restrict Supabase dashboard access (MFA for team accounts) | **Medium** | ⬜ TODO |

### 8.3 Supabase Free vs. Pro Tier Comparison

| Feature | Free | Pro ($25/mo) |
|---------|------|-------------|
| Database size | 500 MB | 8 GB |
| Bandwidth | 5 GB | 250 GB |
| Auth MAU | 50K | 100K |
| Backups | None | Daily, 7-day retention |
| Support | Community | Email |
| Custom domains | No | Yes |

**Recommendation:** Free tier is fine for TestFlight/beta. Upgrade to Pro before wide public launch — reassess against actual user numbers at that point; may not be necessary depending on scale.

---

## 9. Google Maps Configuration

### 9.1 Current State

- Google Maps API key is loaded via `ios/Flutter/Secrets.xcconfig` (gitignored)
- API key is passed to `AppDelegate.swift` from `Info.plist`
- Billing account has been set up per user confirmation
- Bundle ID needs to be updated in Google Cloud Console to `org.beaconhealth.app`

### 9.2 Required Actions

| Task | Priority | Status |
|------|----------|--------|
| Update bundle ID restriction in Google Cloud Console to `org.beaconhealth.app` | **High** | ⬜ TODO |
| Verify API key is restricted to iOS apps only | **High** | ⬜ TODO |
| Verify API key is restricted to Google Maps SDK for iOS only | **High** | ⬜ TODO |
| Performance test Maps usage for expected traffic | **Medium** | ⬜ TODO (post-MVP) |

### 9.3 Cost Considerations

- Google Maps Platform free tier: $200/month credit
- For MVP with limited beta users, free tier should be sufficient
- Monitor usage in Google Cloud Console during TestFlight
- Performance testing and cost analysis should be done post-MVP

---

## 10. Secrets Management

### 10.1 Current State

Secrets are in `.env` (gitignored) and `ios/Flutter/Secrets.xcconfig` (gitignored). However, `.env` is bundled as an app asset — **the most urgent fix in this document.**

### 10.2 Options Comparison

| Solution | Cost | Pros | Cons |
|----------|------|------|------|
| **GitHub Secrets + `--dart-define`** | Free | Native to GitHub Actions; no extra tooling; secrets never in source | Requires CI/CD setup; local dev needs `.env` file or script |
| **GitHub Secrets + Fastlane Match** (signing only) | Free | Industry-standard iOS signing; encrypted in git repo | Extra tool to learn; only covers signing, not app secrets |
| **Supabase Vault** | Free (included) | Manages DB-level secrets | Only for server-side; doesn't solve client build secrets |
| **1Password / Doppler** | $5-8/user/mo | Rich UI, team sharing, CI integration | Overkill for small team; recurring cost |
| **SOPS + Age encryption** | Free | Secrets encrypted in-repo; works offline | Learning curve; manual key management |

**Recommendation for MVP:**
1. **GitHub Secrets** for CI/CD builds (inject via `--dart-define`).
2. **Local `.env`** file (gitignored) for developer machines — but **remove it from Flutter assets**.
3. `ios/Flutter/Secrets.xcconfig` for iOS-specific keys (Google Maps) — already gitignored.

### Implementation

```bash
# Build command with secrets injected
flutter build ios \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY
```

In Dart code, access with:
```dart
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
```

### Secrets-on-CI: Getting `Secrets.xcconfig` to CI Runners

The Google Maps API key currently lives in [ios/Flutter/Secrets.xcconfig](ios/Flutter/Secrets.xcconfig), which is gitignored. This is correct for local dev but **CI runners won't have the file** — the build will fail unless you explicitly supply it.

**Two approaches (pick one):**

**Option A — Render from GitHub Secret (recommended for MVP):**

Add a step in the GitHub Actions workflow before `flutter build`:

```yaml
- name: Create Secrets.xcconfig
  run: |
    echo "GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }}" \
      > ios/Flutter/Secrets.xcconfig
```

Then add `GOOGLE_MAPS_API_KEY` to the repository's GitHub Actions secrets.

**Option B — Fastlane Match + Vault (better long-term):**

Use Fastlane `match` for code signing and store the `Secrets.xcconfig` content as an environment variable rendered by a Fastlane lane. More setup but centralises all secrets in one place.

**GitHub Secrets to create before CI is configured:**

| Secret name | Value |
|-------------|-------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase **anon** (public) key (NOT service-role) |
| `GOOGLE_MAPS_API_KEY` | iOS-restricted Google Maps API key |
| `APP_STORE_CONNECT_API_KEY_ID` | For Fastlane TestFlight upload |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | For Fastlane TestFlight upload |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64-encoded `.p8` key file |
| `MATCH_PASSWORD` | Fastlane Match repo encryption password |

---

## 11. CI/CD Pipeline

### 11.1 Options Comparison

| Solution | Cost | Pros | Cons |
|----------|------|------|------|
| **GitHub Actions + Fastlane** | Free (2K min/mo private) | Most popular; huge community; native GitHub integration; Fastlane handles signing/upload | macOS runners are slow (~3-5x Linux); 2K min may be tight for iOS builds |
| **GitHub Actions (no Fastlane)** | Free (2K min/mo) | Simpler setup; `flutter build ios` + `xcodebuild` directly | More manual signing/upload scripting |
| **Codemagic** | Free (500 min/mo) | Flutter-first CI; built-in code signing; auto TestFlight upload; M2 Mac runners | Free tier is limited; paid starts at $75/mo |
| **Bitrise** | Free (credits) | Mobile-first; good Flutter support; many integrations | Fewer free credits than Codemagic; can get expensive |
| **Xcode Cloud** | Free (25 hrs/mo) | Native Apple integration; auto signing; direct TestFlight upload | Flutter support requires custom scripts; limited free tier |

**Recommendation:** **GitHub Actions + Fastlane** for the best balance of cost, ecosystem support, and flexibility. Codemagic is a strong alternative if macOS runner minutes become a bottleneck.

### 11.2 Minimal GitHub Actions Workflow (MVP)

```yaml
# .github/workflows/ios-build.yml
name: iOS Build & Deploy
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - name: Build iOS
        run: |
          flutter build ios --release --no-codesign \
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
      # Add Fastlane for signing + TestFlight upload
```

---

## 12. Security Scanning & Linting

### 12.1 Tool Comparison

| Tool | Type | Cost | Pros | Cons |
|------|------|------|------|------|
| **`flutter_lints`** | Lint rules | Free | Already in project; Dart team maintained | Basic rule set |
| **`very_good_analysis`** | Lint rules | Free | Stricter; used by VGV production apps | May require more refactoring |
| **Dependabot** | Dependency scanning | Free (GitHub) | Auto PRs for vulnerable deps; zero config | Flutter/pub.dev support is limited |
| **`osv-scanner`** | Dependency scanning | Free (Google) | Checks pub.dev advisories; runs in CI | Manual setup; newer tool |
| **Snyk** | SAST + SCA | Free (limited) | Broad language support; GitHub integration | Free tier has scan limits; Dart support is basic |
| **CodeQL** | SAST | Free (GitHub) | Deep semantic analysis; native GitHub integration | No Dart support (as of 2025) |
| **GitGuardian** | Secrets detection | Free (<25 devs) | Catches leaked API keys in commits | Only secrets, not code quality |
| **`gitleaks`** | Secrets detection | Free (OSS) | Runs locally and in CI; fast | Requires CI integration |
| **MobSF** | Mobile security | Free (OSS) | Full IPA/APK security audit; OWASP checks | Requires setup; run as Docker container |

**MVP Stack (all free):**

1. **`very_good_analysis`** + `analysis_options.yaml` (Phase 4 — decided)
2. **`flutter analyze`** in CI (catches lint + type issues)
3. **`gitleaks`** in CI (catches secrets in commits)
4. **Dependabot** enabled on GitHub repo (auto PRs for vulnerable deps)
5. **`osv-scanner`** in CI (pub.dev advisory checks)

**Post-MVP additions:**
- MobSF scan before each App Store submission
- GitGuardian for continuous monitoring

---

## 13. Testing Strategy

### 13.1 Current State

One broken test in `test/widget_test.dart` that references text ("Welcome to Beacon!") that doesn't exist in the app.

### 13.2 MVP Testing Plan

| Layer | What to Test | Tool | Priority |
|-------|-------------|------|----------|
| **Unit** | `Facility.fromSupabase()` parsing, `FacilityFilterService`, `LocationService`, zip-code validation | `flutter_test` | **High** |
| **Unit** | `DemoModeService` persistence, `LocaleProvider` | `flutter_test` + `shared_preferences` mock | **Medium** |
| **Widget** | Onboarding flow renders correctly, guest mode shows lock icons, filter bar order | `flutter_test` + `WidgetTester` | **High** |
| **Widget** | Settings page sections, sign-out hidden in guest mode | `flutter_test` | **Medium** |
| **Integration** | Full guest flow: onboarding → zip entry → home → map → search | `integration_test` | **Medium** |
| **Golden** | Verify UI snapshots for key screens (optional) | `golden_toolkit` | **Low** |

### 13.3 Minimum Test Files to Create

```
test/
  core/
    services/
      demo_mode_service_test.dart
  features/
    map/
      domain/models/
        facility_model_test.dart
      presentation/services/
        facility_filter_service_test.dart
    auth/
      presentation/
        onboarding_test.dart
  integration_test/
    guest_flow_test.dart
```

### 13.4 Testing Commands

```bash
# Unit + widget tests
flutter test

# With coverage
flutter test --coverage
# View: genhtml coverage/lcov.info -o coverage/html

# Integration test (on device/simulator)
flutter test integration_test/
```

---

## 14. GitHub & Repository Strategy

### 14.1 Repository Strategy for database/ Folder

**User Decision:** The `database/` folder should live in a separate repository from the Flutter app.

**Reasoning:**
- The current private repo contains the `database/` folder with data-scraping scripts
- The commit history is already tainted with secrets
- Best approach: Move the Flutter app codebase to a new, secure, production-ready repository
- Keep the current private repo as the data pipeline repository containing only the `database/` folder and related scripts

**Action Required:**
1. Create a new private repository for the production Flutter app
2. Move all Flutter app code (excluding `database/`) to the new repository
3. Keep the current repository as the data pipeline repo
4. Add `database/` to `.gitignore` in the new Flutter app repository
5. Ensure proper access controls are set up for both repositories

### 14.2 Branch Protection

- [ ] **Protect `main` branch:** require PR reviews (≥1), status checks (CI passing), no direct pushes.
- [ ] Create a `develop` branch for ongoing work; merge to `main` for releases.
- [ ] Consider branch naming convention: `feature/`, `bugfix/`, `release/`.

### 14.3 Clean Commit History

- [ ] Squash-merge noisy AI-generated commits before public release.
- [ ] Consider resetting history if the repo has never been public: `git checkout --orphan clean-main && git add -A && git commit -m "Initial MVP release"`.
- [ ] Alternatively, do an interactive rebase to clean up.

### 14.4 `.gitignore` Updates

| Item | Action |
|------|--------|
| `database/` | Add to `.gitignore` in new Flutter app repo — moved to separate data pipeline repo |
| `.venv/` | Already handled |
| `*.lock` | ✅ Done — `*.lock` removed from `.gitignore`; `pubspec.lock` staged via `git add`. |
| `.DS_Store` | ✅ Done — `.DS_Store` and `**/.DS_Store` added to `.gitignore`; all 7 tracked files removed via `git rm --cached`. |
| `ios/Flutter/Secrets.xcconfig` | Already gitignored ✅ — ensure CI renders it from a secret (see §10). |

### 14.5 Repository Settings

- [ ] Ensure repo is private.
- [ ] Enable **Dependabot alerts** (Settings → Code security).
- [ ] Enable **secret scanning** (Settings → Code security).
- [ ] Add a proper `README.md` with setup instructions, architecture overview, and contribution guidelines.
- [ ] Add `CONTRIBUTING.md` if multiple developers will contribute.
- [ ] Add `LICENSE` file if applicable.

---

## 15. Pre-Submission Checklist

### 15.1 Before TestFlight

> Items marked **🚫 UNFIXED — blocks TestFlight** are known to be unresolved as of the last audit (2026-04-14) and must be completed before any upload.

- [x] ✅ `.env` removed from `pubspec.yaml` assets; migrated to `String.fromEnvironment` (§4, §10)
- [x] ✅ `SUPABASE_ANON_KEY` replaces service role key in `main.dart`; **still need to plug in actual anon key value** (§4, §8)
- [x] ✅ `debug: kDebugMode` in Supabase init (§4)
- [x] ✅ [ios/Runner/PrivacyInfo.xcprivacy](ios/Runner/PrivacyInfo.xcprivacy) authored and registered in Xcode project (§4.5, Phase 7)
- [x] ✅ `analysis_options.yaml` created, `flutter analyze --fatal-infos` passes with no issues (§5.1, Phase 4)
- [ ] All MVP features (§2) implemented and manually tested on iOS simulator + physical device
- [ ] Minimum tests pass (`flutter test`)
- [x] App icon meets Apple specs ✅ (`app_icon_final.jpg`; 23 icon sizes in `AppIcon.appiconset/`)
- [x] Launch screen reviewed (`LaunchScreen.storyboard` exists ✅)
- [ ] `pubspec.yaml` version bumped to `1.0.0+1`
- [x] ✅ iOS deployment targets aligned to `15.0` across Podfile, Xcode project-level, and Runner target (§5.4)
- [x] ✅ `Info.plist` portrait-only — LandscapeLeft/LandscapeRight removed (§5.5)
- [x] ✅ No leftover `print()` statements
- [x] ✅ No hardcoded API keys in source files
- [x] ✅ Bundle ID updated to `org.beaconhealth.app` in Xcode `project.pbxproj` — **still need to update Google Cloud Console + App Store Connect** (§7.6, §9.2)
- [x] ✅ `pubspec.lock` staged for commit (§14.4)
- [x] ✅ Tracked `.DS_Store` files removed from git (§14.4)
- [ ] `flutter build ios --release` succeeds
- [ ] Archive and upload to TestFlight via Xcode or Fastlane
- [ ] Test on at least 2 iOS devices (different screen sizes)

### 15.2 Before Public Release (App Store)

- [ ] Privacy Policy URL live and accessible ✅ (`https://beacon-website-pied.vercel.app/privacy-policy`)
- [ ] Terms of Use URL live and accessible ✅ (`https://beacon-website-pied.vercel.app/terms-of-use`)
- [x] Support URL: `https://beacon-website-pied.vercel.app/contact` ✅
- [ ] App Store screenshots created (engineering team, Phase 7)
- [ ] App Store description and metadata written (engineering team, Phase 7; agent drafting available on request)
- [ ] Privacy nutrition label completed (draft in §7.8)
- [ ] Age rating questionnaire completed
- [ ] Export compliance (encryption) questionnaire answered (Supabase uses HTTPS → "Yes, but exempt")
- [ ] Supabase RLS policies verified (§8)
- [ ] CI/CD pipeline operational (§11)
- [ ] At least 1 round of external beta testing (TestFlight)

### 15.5 Work Sequencing Phases

Dependency-ordered. Items within a phase can parallelize; each phase should be merged before the next starts.

---

#### Phase 1 — Doc refresh ✅
This iteration of `MVP_RELEASE.md`. Establishes ground truth before anything else moves.

---

#### Phase 2 — Critical security hotfixes ✅

1. ✅ Removed `.env` from assets; migrated `main.dart` to `String.fromEnvironment`; removed `flutter_dotenv` dependency.
2. ✅ `SUPABASE_ANON_KEY` now used. **Pending:** plug actual anon key value into `--dart-define` / GitHub Secret.
3. ✅ `debug: kDebugMode`.
4. ✅ All 3 `print()` calls replaced with `developer.log()`.
5. ✅ 7 `.DS_Store` files untracked; `**/.DS_Store` added to `.gitignore`.
6. ✅ `*.lock` removed from `.gitignore`; `pubspec.lock` staged.
7. ⏭️ `WidgetsBindingObserver` on `MapPage` — **no action needed**. `didChangeMetrics()` is implemented and actively used for keyboard visibility; `removeObserver` is called in `dispose()`. Audit finding was stale.

---

#### Phase 3 — Repository migration ✅
Clean repo live at `github.com/beacon-health/mobile-app`. Data pipeline at `github.com/beacon-health/beacon-data`.

**Pre-migration audit (2026-04-15) — all items resolved ✅:**

| Check | Result |
|-------|--------|
| No `dotenv` / `flutter_dotenv` references in app code | ✅ Clean |
| No `SUPABASE_SERVICE_ROLE_KEY` references in app code | ✅ Clean |
| No `print()` calls (all `debugPrint`) | ✅ Clean |
| No hardcoded API keys in Dart source | ✅ Clean |
| No hardcoded localhost/dev URLs | ✅ Clean |
| `.env` not tracked in git | ✅ Clean |
| `ios/GoogleService-Info.plist` ×2 untracked | ✅ Fixed (were tracked despite gitignore) |
| `.windsurf/rules/rules.md` untracked | ✅ Fixed |
| `.windsurf/` and `.claude/` in `.gitignore` | ✅ Added |
| `README.md` updated for `--dart-define` workflow | ✅ Updated |
| `test/widget_test.dart` broken (stale text) | ⚠️ Known — fix in Phase 4 |
| Git history tainted with secrets | ⚠️ Known — clean `--orphan` migration resolves this |

**Outcome:**

- ✅ Clean orphan commit pushed to `github.com/beacon-health/mobile-app` (SSH)
- ✅ `database/` moved to `github.com/beacon-health/beacon-data`
- ✅ `web/` excluded from new repo
- ✅ `AuthKey_99WRH2CRMQ.p8` moved to `~/keys/` (outside repo)
- ✅ `README.md` clone URL updated to `mobile-app`
- ⚠️ Archive `github.com/beacon-health/beacon-app` (old repo) via GitHub web UI — Settings → Danger Zone → Archive

---

#### Phase 4 — Dev infrastructure ✅
Builds on clean repo; confidence for bulk feature editing.

1. ✅ `analysis_options.yaml` with `very_good_analysis` (631 → 0 lint issues).
2. ✅ GitHub Actions CI (`flutter analyze` + `dart format` + `flutter test` on push/PR); iOS build workflow (manual trigger → Fastlane TestFlight). `gitleaks` staged but commented out — requires GitHub Advanced Security or public repo to enable.
3. ✅ Fastlane skeleton: `Appfile` (bundle ID, Apple ID, Team ID), `Fastfile` with `beta` + `release` lanes.
4. ✅ CI secret-injection: `Secrets.xcconfig` rendered from `GOOGLE_MAPS_API_KEY`; `SUPABASE_URL` + `SUPABASE_ANON_KEY` via `--dart-define`.
5. ✅ Fixed broken `test/widget_test.dart`. 18 unit tests across `FacilityFilterService`, `Facility.fromSupabase`, `DemoModeService`, `GuestModeService`.
6. ✅ `.github/dependabot.yml` for weekly pub + GitHub Actions updates.

---

#### Phase 5 — Architectural prerequisites ✅
Required before §2.3 / §2.4 / §2.5 lock-state UI work can start.

1. ✅ [GuestModeService](lib/core/services/guest_mode_service.dart) — singleton `ChangeNotifier`; subscribes to Supabase auth state changes; handles demo mode + uninitialized Supabase; provided at app root; tested.
2. ✅ [LockedFeatureGate](lib/core/widgets/locked_feature_gate.dart) — wraps any child with a `GestureDetector` + `IgnorePointer`; shows `showSignInPromptDialog` on tap when guest.
3. ✅ UX decision documented: **modal dialog** (`showSignInPromptDialog`) — consistent with existing locked Favorites/Eligibility pattern throughout the app.
4. ✅ [ErrorReporter](lib/core/services/error_reporter.dart) — single-method facade; `developer.log` in debug, no-op in release; all 4 previously-silent `catch` blocks in `home_page.dart` now report via `ErrorReporter`; outer `_loadData` failure also shows a user snackbar.
5. ✅ `isGuest` param removed from `MainNavBar`; `login_page.dart` updated; `home_page.dart` reads `context.watch<GuestModeService>().isGuest` for reactive rebuilds on auth state changes.

---

#### Phase 6 — MVP feature build-out (~2 weeks, parallelizable within phase)
Depends on Phase 5 (`GuestModeService` + `LockedFeatureGate`).

1. **§2.1 Onboarding** — `OnboardingPage` (welcome → Continue as Guest → zip entry); comment out sign-in buttons with TODO; `SharedPreferences` zip storage + `has_completed_onboarding` flag; remove `CriteriaPage` from routes.
2. **§2.2 Location** — Remove GPS calls from onboarding/home/settings entry paths; replace with stored-zip geocoding. Keep GPS behind explicit "use my location" tap on map/search (with TODO).
3. **§2.3 Home page** — Zip-centered map; `LockedFeatureGate` on Favorites section; disable `myLocationEnabled` for guest.
4. **§2.4 Map page** — Reorder filter bar; split `EligibilityRequirement` → separate `Eligibility` and `Preferences` enums + filter widgets; `LockedFeatureGate` on Favorites/Eligibility/Preferences; disable `myLocationEnabled` for guest.
5. **§2.5 Settings** — Guest account state; eligibility/preferences section split; wire `url_launcher` to legal URLs; comment out Sign Out; `package_info_plus` for version; gate demo-mode toggle behind `kDebugMode`.

---

#### Phase 6.5 — Post-Phase-7 cleanup audit (new, 2026-04-16)

Surfaced by the comprehensive audit after Phase 7 landed. Detailed findings in [§3.4](#34-post-phase-7-comprehensive-audit-2026-04-16). Net ~4 hours of low-risk work.

1. **Blocker (signing):** resolve `DEVELOPMENT_TEAM` mismatch in `project.pbxproj` (Debug `DWDZ94L8RD` vs Release/Profile `3VY6L9SG6K`).
2. **Dead code removal:** delete `MapControllerService`, `SearchFilterSection`, `CriteriaPage`, orphan `app_icon.png`.
3. **Deduplicate:** extract `LockedSectionOverlay` (used 2× in `settings_page.dart`); extract `AppGradients` (used 3×, incidentally fixes `login_page.dart` dark-mode gap).
4. **Error handling:** replace silent `catch (_) {}` in `home_page.dart:192` and `facility_provider.dart:37` with `ErrorReporter` + `.firstWhereOrNull`.
5. **Best practices:** swap `Provider.of(...listen:false)` → `context.read<T>()` (3 sites); wrap `GoogleMap` in `RepaintBoundary`; batch `setState` in `home_page.dart._loadData`; `dart fix --apply` for missing `const`.
6. **Polish:** replace 68-byte placeholder `LaunchImage` PNGs (or delete the image set and rely on `LaunchScreen.storyboard`).

---

#### Phase 7 — Compliance & store readiness ✅ (code-automatable items complete)
Remaining items require human action (App Store Connect web UI, device testing, screenshots).

1. ✅ [ios/Runner/PrivacyInfo.xcprivacy](ios/Runner/PrivacyInfo.xcprivacy) authored per §4.5 and wired into Xcode project (PBXBuildFile + PBXFileReference + Resources phase).
2. ⬜ Complete App Store Privacy Nutrition Label in **App Store Connect** (draft in §7.8). **Human action required.**
3. ✅ `Info.plist` location usage string already commented out for MVP (GPS deferred). No action needed.
4. ✅ iOS deployment targets aligned to `15.0` across Podfile, project-level (`13.0` → `15.0`), and Runner target (`15.6` → `15.0`).
5. ✅ Portrait-only orientation locked in `Info.plist` — LandscapeLeft/LandscapeRight removed from both phone and iPad keys.
6. ✅ Bundle ID updated to `org.beaconhealth.app` in `project.pbxproj`. ⬜ **Still needed:** update in Google Cloud Console (API key restriction) and App Store Connect. **Human action required.**
7. ⬜ Accessibility pass (§6): VoiceOver labels on 4 category buttons, lock-state widgets, search bar; 44pt minimum tap targets; Dynamic Type test. **Owner: dev team, requires device.**
8. ⬜ App Store screenshots and description — **engineering team owns**; agent drafting available for description on request. Support URL already resolved ✅.

---

#### Phase 8 — TestFlight → Public submission (~1–2 days active + Apple review wait)

1. Internal TestFlight build via Fastlane `beta` lane.
2. Smoke test on ≥2 iOS devices (different screen sizes).
3. App Store review notes filled in (template in §7.4).
4. Internal beta distributed to dev team.
5. Submit for App Store review.

---

#### Phase 9 — Post-MVP fast follows (§16)
After initial release: crash reporting, analytics, offline handling, Sign in with Apple, full a11y audit, Android.

---

## 16. Post-MVP Fast Follows

These are improvements to tackle immediately after the initial release:

| Item | Priority | Notes |
|------|----------|-------|
| User authentication (Apple + Google OAuth via Supabase) | **High** | Unlocks Favorites, Eligibility/Preferences filtering, profile; `GuestModeService` (Phase 5) is designed to make this a drop-in. |
| Location-based search (re-enable GPS with proper permission flow) | **High** | §2.2 scope split leaves GPS behind a tap in map/search — just un-comment + add permission UX. |
| Favorites sync (requires auth — stored in Supabase per-user) | **High** | Local favorites possible before auth; post-auth adds cloud sync. |
| Eligibility + Preferences filter unlock (requires auth) | **High** | `LockedFeatureGate` already gates these; just wire auth state. |
| **Crash reporting** | **High (fast follow)** | Supabase has no built-in crash reporting. **Recommendation: Sentry** — free tier (5K errors/mo), `sentry_flutter` is a one-command install, and it plugs directly into the `ErrorReporter` stub (§4.6) with a single line swap. Privacy-conscious (GDPR-friendly, no Google dependency). Firebase Crashlytics is also free but requires adding Firebase to the project. Sentry wins on ease and privacy. |
| Profile page for authenticated users | **Medium** | Simplified post-auth profile (name/email from OAuth); no PII collection beyond what OAuth provides. |
| Push notifications for facility updates | **Medium** | Requires APNs setup + server-side trigger. Not needed for MVP. |
| Full accessibility audit (VoiceOver, Dynamic Type, contrast ratios) | **Medium** | §6 covers MVP minimums; full WCAG 2.1 AA audit is a post-MVP fast follow. Professional testing with actual users recommended. |
| Performance profiling (startup time, map rendering) | **Medium** | Flutter DevTools profiling pass; Google Maps tile-load performance with real user traffic. |
| **Analytics** | **Medium** | Deferred — handle after initial launch. Options when ready: **PostHog** (open-source, self-hostable, privacy-conscious — recommended for healthcare), **Mixpanel** (generous free tier), **Firebase Analytics** (free but data goes to Google). Update §7.8 Privacy Nutrition Label when any analytics land. |
| **Offline / connectivity handling** | **Medium** | Currently no `connectivity_plus` in pubspec; network failures are silently swallowed (§4.6). Add `connectivity_plus`, show an offline banner, and retry on reconnect. |
| Android release (Google Play Store) | **Medium** | Low lift once iOS is live; separate CI lane, Google Maps Android key, Play Store listing. |
| Deeper test coverage (80%+ unit, integration tests for all flows) | **Medium** | §13 scaffolds the baseline tests; invest in broader coverage after initial release. |
| Localization review (professional translation for es, zh) | **Low** | ARB files exist for en/es/zh; machine-translated strings should be reviewed by native speakers before reaching real users. |
| iPad layout optimization | **Low** | App renders but is not iPad-optimised; address after iPhone audience is established. |
| Dark mode polish | **Low** | Dark mode is wired (ThemeModeProvider); polish visual inconsistencies after main feature work. |

---

## 17. Open Questions

No open questions. All decisions resolved. ✅

---
