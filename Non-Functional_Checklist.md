# Beacon — Non-Functional Pre-Launch Checklist

Launch prep that needs **no code** — App Store Connect listing, visual assets,
and compliance/legal — plus the **Privacy Nutrition Label** to enter in App
Store Connect → App Privacy. Hand this file to whoever owns the App Store
submission; everything here can be done without an engineer.

App Review notes (the "how to test" text for Apple's reviewer) live in
`MVP_RELEASE.md` §5.

---

## A. App Store Connect listing (text metadata)

- [ ] App name: **"Beacon"** (confirm no trademark conflict in the App Store)
- [ ] Subtitle (≤30 chars), e.g. "Find Free Healthcare Near You"
- [ ] Description (long-form: what it does, who it helps, that it's free)
- [ ] Keywords (100 chars, comma-separated — e.g. free clinic, healthcare, low cost, uninsured, shelter)
- [ ] Primary category: **Medical** (secondary: Health & Fitness)
- [ ] Support URL (**required** — a reachable page or a `mailto:` support address)
- [ ] Marketing URL (optional)
- [ ] Copyright (e.g. "© 2026 Beacon Health")

## B. Visual assets

- [ ] App icon **1024×1024 PNG, no alpha / no rounded corners** (export from `app_icon_final.jpg`)
- [ ] Screenshots — **6.7"** (iPhone 15 Pro Max) + **6.5"**, ≥3 each: map view, facility detail, filters, Favorites
- [ ] App preview video (optional)

## C. Compliance & legal

- [ ] Privacy **nutrition label** — enter the answers from the table below
- [ ] **Privacy Policy URL** — live and reachable (already linked in-app via `LegalUrls`)
- [ ] **Terms of Service URL** — live and reachable
- [ ] Age rating questionnaire (likely **4+**; answer the medical-info questions honestly)
- [ ] Export compliance: uses encryption? **Yes → exempt** (standard HTTPS only)
- [ ] Confirm **"Does not track"** — no ATT prompt needed

---

## Privacy Nutrition Label

MVP includes auth (Apple), GPS (opt-in), crash reporting, and feedback
submission. Enter this table in App Store Connect → App Privacy.

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
