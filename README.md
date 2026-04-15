# Beacon

A Flutter iOS app helping users find free and low-cost healthcare facilities in Illinois.

## Prerequisites

- Flutter 3.x / Dart 3.6+
- Xcode 15+ (for iOS builds)
- A Supabase project with the `facilities_il_full` view
- A Google Maps API key restricted to iOS / Maps SDK

## Getting Started

1. **Clone the repository:**
   ```sh
   git clone https://github.com/beacon-health/mobile-app.git
   cd mobile-app
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Create a local secrets file** for the Google Maps API key (already gitignored):
   ```sh
   echo "GOOGLE_MAPS_API_KEY=<your-ios-maps-key>" > ios/Flutter/Secrets.xcconfig
   ```

4. **Run the app** with Supabase credentials injected at build time:
   ```sh
   flutter run \
     --dart-define=SUPABASE_URL=https://<project>.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=<your-publishable-key>
   ```

> **Note:** Secrets are never stored in source code. They are injected via
> `--dart-define` (local dev / CI) and `Secrets.xcconfig` (iOS Maps key).
> See `MVP_RELEASE.md` §10 for the full secrets management strategy.

## Project Structure

```
lib/
  app.dart                  # MaterialApp, routing
  main.dart                 # Entry point, Supabase init
  core/                     # Shared services, theme, widgets
  features/
    auth/                   # Login, onboarding (guest-only MVP)
    home/                   # Home page, nav bar
    map/                    # Map, filters, facility cards
    settings/               # Settings page
  l10n/                     # Localisation (en, es, zh)
```

## Architecture

See `MVP_RELEASE.md` for the full release plan, security findings, and work sequencing.
