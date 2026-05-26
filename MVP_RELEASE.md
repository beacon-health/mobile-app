# Beacon App — MVP Release Plan

> **Living document.** Shared with AI agents for context. Keep concise.
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
| **Auth** | Guest-only for MVP. Supabase OAuth (Google + Apple) wired but deferred. |
| **State mgmt** | Provider + ChangeNotifier |
| **Maps** | Google Maps Flutter plugin, API key via `Secrets.xcconfig` (gitignored) |
| **Localization** | en, es, zh via `flutter_localizations` + ARB |
| **Demo mode** | Feature-flagged, hidden in MVP (gated behind TODO) |
| **Secrets** | `--dart-define` for Supabase URL/key; `Secrets.xcconfig` for Google Maps key. No secrets in source. |
| **Linting** | `very_good_analysis` + `analysis_options.yaml` — 0 issues |
| **Tests** | 18 unit tests (all passing) |
| **CI/CD** | GitHub Actions (`ci.yml` + `ios-build.yml`), Fastlane skeleton |
| **Repo** | `github.com/beacon-health/mobile-app` (clean orphan history) |
| **Data pipeline** | `github.com/beacon-health/beacon-data` (separate repo) |

### Architecture

- **Entry flow:** `AuthGate` checks `ZipCodeService.hasCompletedOnboarding` — shows `OnboardingPage` -> `ZipEntryPage` if first launch, `MainNavBar` if returning.
- **Guest mode:** `GuestModeService` (ChangeNotifier) exposes `isGuest`. `LockedFeatureGate` widget wraps locked features (Favorites, Eligibility, Preferences) with a sign-in dialog.
- **Error handling:** `ErrorReporter` singleton — `developer.log` in debug, no-op in release. Swappable for Sentry post-MVP.
- **Theming:** `AppGradients` for onboarding gradient (dark+light), `ColorSchemeExt` for consistent alpha blends, `LockedSectionOverlay` for frosted-glass lock UI.
- **Location:** GPS deferred for MVP. `ZipCodeService` stores zip -> geocoded lat/lng via `SharedPreferences`. `LocationService` exists but is unused in current flows.
- **Filter bar order:** Tune -> Distance -> Open Now -> Favorites -> Category -> Eligibility -> Preferences. Favorites/Eligibility/Preferences show sign-in dialog in guest mode.

### Key Files

| Purpose | Path |
|---------|------|
| App entry | `lib/main.dart` |
| App routing | `lib/app.dart`, `lib/features/auth/presentation/widgets/auth_gate.dart` |
| Guest mode | `lib/core/services/guest_mode_service.dart` |
| Zip code | `lib/core/services/zip_code_service.dart` |
| Facility data | `lib/features/map/data/facility_repository.dart`, `supabase_facility_service.dart` |
| Map page | `lib/features/map/presentation/pages/map_page.dart` |
| Home page | `lib/features/home/presentation/pages/home_page.dart` |
| Settings | `lib/features/settings/presentation/pages/settings_page.dart` |
| Filter bar | `lib/features/map/presentation/widgets/filters/components/filter_bar.dart` |
| Filter constants | `lib/features/map/constants/filter_constants.dart` |
| iOS project | `ios/Runner.xcodeproj/project.pbxproj` |

---

## 2. Completed Work Summary

All items below are done and verified. Included for agent context — no action needed.

### Security (all resolved)
- `.env` removed from assets; secrets via `--dart-define` + `String.fromEnvironment`.
- Service role key replaced with anon key parameter. `debug: kDebugMode`.
- All `print()` replaced with `developer.log()`. Empty `catch` blocks routed through `ErrorReporter`.
- `PrivacyInfo.xcprivacy` authored and wired into Xcode project (CA92.1, C617.1, 35F9.1, E174.1).

### iOS Compliance
- Bundle ID: `org.beaconhealth.app` across all Xcode configs.
- Deployment target: `15.0` across Podfile + all Xcode build settings.
- Portrait-only orientation locked in code + `Info.plist`.
- `DEVELOPMENT_TEAM = 3VY6L9SG6K` aligned across Debug/Release/Profile.
- LaunchImage placeholder PNGs deleted; `LaunchScreen.storyboard` is the sole launch screen.
- `NSLocationWhenInUseUsageDescription` commented out in `Info.plist`.

### Dev Infrastructure
- `very_good_analysis` linting — 0 issues.
- GitHub Actions CI (analyze + format + test on push/PR) + iOS build workflow (manual trigger).
- Fastlane skeleton (`Appfile` + `Fastfile` with `beta`/`release` lanes).
- CI secret injection for Supabase + Google Maps keys.
- 18 unit tests: `FacilityFilterService`, `Facility.fromSupabase`, `DemoModeService`, `GuestModeService`.
- Dependabot for weekly pub + GitHub Actions dependency updates.

### Repo Hygiene
- Clean orphan commit at `github.com/beacon-health/mobile-app`.
- `database/` moved to `github.com/beacon-health/beacon-data`.
- `.DS_Store` files untracked; `.gitignore` covers `.DS_Store`, `.env`, `Secrets.xcconfig`, `.claude/`, `.windsurf/`.

### Feature Build-out (Phases 5-6)
- **Onboarding:** `OnboardingPage` -> `ZipEntryPage` -> `MainNavBar`. Zip stored in `SharedPreferences` with `has_completed_onboarding` flag.
- **Home page:** Map centers on zip coordinates. 4 category buttons. Favorites locked for guests. `myLocationEnabled: false`.
- **Map page:** Search bar, filter bar with Eligibility/Preferences split, facility cards. Distance defaults to 1 mi. Favorites/Eligibility/Preferences locked for guests. `myLocationEnabled: false`. GPS entry paths removed from main flows.
- **Settings:** Guest account state (lock icon + prompt). Zip edit dialog. Language + appearance selectors. Eligibility and Preferences sections split with lock overlay. Privacy Policy + Terms of Use wired to URLs via `url_launcher`. Version from `package_info_plus`. Sign-out commented out. Demo toggle hidden.
- **Dead code removed:** `MapControllerService`, `SearchFilterSection`, `CriteriaPage`, orphan `app_icon.png`, `LaunchImage` assets.

### Code Quality (Phase 6.5 cleanup)
- `LockedSectionOverlay` extracted (deduped from `settings_page.dart`).
- `AppGradients.onboarding()` extracted (deduped across 3 onboarding pages; fixed `login_page.dart` dark-mode gap).
- `ColorSchemeExt` with `onSurfaceMuted`, `onSurfaceSecondary`, `onSurfaceFaded`, `onSurfaceStrong`.
- `Provider.of(context, listen: false)` -> `context.read<T>()` everywhere.
- `GoogleMap` wrapped in `RepaintBoundary` (home + map pages).
- `Completer<GoogleMapController>` duplicate state removed from `map_page.dart`.
- File renames: `supabase_facility_service.dart` -> `lib/features/map/data/`, `facility_display_utils.dart` -> `facility_formatting.dart`, `marker_utils.dart` -> `marker_icon_factory.dart`.

---

## 3. Remaining Code Tasks

| # | Priority | Task | Notes |
|---|----------|------|-------|
| 1 | **High** | Bump `pubspec.yaml` version to `1.0.0+1` | Currently `0.1.1` |
| 2 | **Medium** | Remove `WidgetsBindingObserver` mixin from `MapPage` if no lifecycle overrides are used, OR verify `didChangeMetrics` is actively needed | Previous audit found it implemented — re-verify |
| 3 | **Low** | Remove `flutter_signin_button` dependency if sign-in buttons are unreachable in guest-only flow | `LoginPage` is only reachable from `OnboardingPage` via auth — currently bypassed by guest flow |
| 4 | **Low** | Remove `geolocator` package if `LocationService` is fully unused in MVP flows | Keep `geocoding` — used by `ZipCodeService` |
| 5 | **Low** | Consider breaking `settings_page.dart` (560 lines, 8 `_build*` methods) into separate widgets per section | Improves rebuild granularity |
| 6 | **Low** | `LocationService` file still contains active GPS code — comment out with TODO or delete if fully replaced by `ZipCodeService` | Currently unused but importable |

---

## 4. Pre-TestFlight Checklist

### Code (engineer)
- [ ] Bump version to `1.0.0+1`
- [ ] `flutter build ios --release` succeeds
- [ ] Test on >= 2 iOS devices (different screen sizes)
- [ ] Manual smoke test: onboarding -> zip entry -> home -> map -> search -> settings

### External Config (requires human / web UI)
- [ ] **Supabase:** Verify RLS is enabled on all tables/views with read-only anon policy
- [ ] **Supabase:** Confirm `SUPABASE_ANON_KEY` in `--dart-define` / GitHub Secret is the publishable key (not service role)
- [ ] **Google Cloud Console:** Update API key bundle ID restriction to `org.beaconhealth.app`
- [ ] **Google Cloud Console:** Verify API key restricted to iOS apps + Maps SDK for iOS only
- [ ] **Xcode:** Create/download iOS Distribution certificate
- [ ] **Xcode:** Create App Store provisioning profile for `org.beaconhealth.app`
- [ ] **Xcode:** Archive and upload to TestFlight

### App Store Connect (requires human / web UI)
- [ ] Create App ID matching `org.beaconhealth.app`
- [ ] Set up the app in App Store Connect
- [ ] App name: "Beacon" (verify no trademark conflicts)
- [ ] Subtitle (e.g., "Find Free Healthcare Near You")
- [ ] Description + keywords
- [ ] Screenshots (6.7" + 6.5" minimum)
- [ ] App icon: verify `app_icon_final.jpg` meets 1024x1024 no-alpha spec
- [ ] Age rating questionnaire
- [ ] Copyright
- [ ] Privacy nutrition label (see draft below)
- [ ] Export compliance: "Yes, but exempt" (HTTPS only)
- [ ] App Review notes for guest flow (see template below)

### Apple Developer Account
| Item | Value |
|------|-------|
| **Team ID** | `3VY6L9SG6K` |
| **Apple ID email** | `hq@beacon-health.com` |
| **App Store Connect API Key ID** | `99WRH2CRMQ` |
| **App Store Connect Issuer ID** | `33d021fa-95fd-4d15-a247-98d49c5b138c` |

---

## 5. Privacy Nutrition Label (MVP Draft)

Guest-only MVP — no auth, no analytics, no PII collection.

| Data type | Collected? | Notes |
|-----------|-----------|-------|
| **Location (Coarse)** | Yes — by Google Maps SDK | Third-party, not linked to identity, not tracking |
| **Location (Precise)** | No | `myLocationEnabled: false` in MVP |
| All other categories | Not collected | No auth, no analytics, no crash reporting in MVP |

**Tracking declaration:** "This app does not track users." No ATT prompt needed.

**Update required when:** auth, analytics (PostHog/Sentry), or crash reporting land post-MVP.

---

## 6. App Review Notes Template

```
This app uses a guest-only flow. No authentication is required.

To test:
1. Launch the app and tap "Get Started"
2. Enter any US zip code (e.g., 60613)
3. Browse the map and facility list
4. Favorites, Eligibility, and Preferences filters show a lock icon — these require sign-in (post-MVP feature)
5. The app uses zip code-based location (no GPS permission required)
```

---

## 7. Secrets & CI

**Local dev:**
```bash
flutter run \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```
Google Maps key comes from `ios/Flutter/Secrets.xcconfig` (gitignored).

**CI (GitHub Actions):**
Secrets to configure in repo settings:

| Secret | Purpose |
|--------|---------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Publishable API key |
| `GOOGLE_MAPS_API_KEY` | iOS-restricted Maps key |
| `APP_STORE_CONNECT_API_KEY_ID` | Fastlane TestFlight upload |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | Fastlane TestFlight upload |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64-encoded `.p8` key |
| `MATCH_PASSWORD` | Fastlane Match encryption |

---

## 8. Post-MVP Fast Follows

| Priority | Item |
|----------|------|
| **High** | User auth (Apple + Google OAuth via Supabase) — unlocks Favorites sync, Eligibility/Preferences filtering |
| **High** | GPS re-enable with proper permission flow (code is preserved, just commented out) |
| **High** | Crash reporting (Sentry recommended — plugs into existing `ErrorReporter`) |
| **Medium** | Analytics (PostHog recommended for healthcare privacy) |
| **Medium** | Offline/connectivity handling (`connectivity_plus` + offline banner) |
| **Medium** | Full accessibility audit (VoiceOver, Dynamic Type, WCAG 2.1 AA) |
| **Medium** | Android release |
| **Low** | Professional localization review (es, zh) |
| **Low** | iPad layout optimization |
| **Low** | Supabase Pro upgrade ($25/mo) — evaluate based on user volume |

---
