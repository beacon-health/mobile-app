# Beacon design system

Beacon is a mobile app (iOS and Android, built in Flutter) that helps people
find free and low-cost healthcare and social services. Designs made here are
blueprints: Claude Code rebuilds them in Flutter with these same tokens, so
stay inside this system.

## Setup

- Link `styles.css`. It loads the tokens (`tokens/tokens.css`), the Inter
  font, and Google's Material Icons; `body` already uses
  `var(--font-family)`.
- Design phone screens at **390×844**, portrait. Light mode first; add dark
  mode with `<html data-theme="dark">` when it matters.
- There are no importable web components. Build with plain HTML/React styled
  only by these tokens, following the component patterns below. The cards in
  `guidelines/components/` and `guidelines/screens/` are renders of the real
  app: match them.

## Styling vocabulary

Use these, never raw hex or pixel values:

- **Color roles:** `--color-primary` (reseda green: filled buttons,
  selection, switches), `--color-secondary` (Payne's gray: onboarding CTAs,
  section headers, list icons, selected filter chips, the focus ring),
  `--color-tertiary` (bittersweet: fills and icons only), `--color-error`
  (destructive actions and error text), `--color-background`, `--color-card`,
  `--color-facility-card` (facility rows and the facility sheet),
  `--color-on-surface`, `--color-on-surface-variant` (secondary text),
  `--color-outline` (input and chip borders), `--color-outline-variant`
  (dividers). Text on a filled role uses its `--color-on-*` pair
  (`--color-on-primary`, `--color-on-secondary`, …).
- **Colored text** never uses a brand color directly — bittersweet is 2.7:1
  on white. Use `--color-tertiary-text` (links, the active tab label, chip
  text) and `--color-primary-text` (text buttons, outlined-button labels,
  selected options, chip text). All text is at least 11px and 4.5:1.
- **Facility categories** (map pins, quick-action icons, category tiles):
  `--color-category-health-care`, `-mental-health`, `-basic-needs`,
  `-housing-shelter`, `-community-resources`, `-specialized-services`. Icons
  only: labels beside them stay `--color-on-surface`.
- **Type classes:** `.text-headline-medium` (onboarding titles),
  `.text-title-large` (section headings, app bar, dialogs),
  `.text-title-medium`, `.text-title-small` (list-row titles),
  `.text-body-large` / `-medium` / `-small`, `.text-label-large` (buttons),
  `.text-label-medium` (links, quick-action labels), `.text-label-small`
  (badges, hours), `.text-nav-label` (tab labels; the active one is 700).
- **Spacing:** `--space-xxs` … `--space-huge` (2, 4, 8, 12, 16, 20, 24, 32,
  48). Page gutter `--space-page-gutter`; onboarding
  `--space-onboarding-gutter`.
- **Radius:** `--radius-sm` (buttons, inputs), `--radius-md` (cards, chips),
  `--radius-lg`, `--radius-xl` (sheets, dialogs), `--radius-pill`.
- **Shadow:** `--shadow-card` (resting), `--shadow-raised` (floating over the
  map), `--shadow-sheet` (casts upward). Everything else is flat.
- **Tints:** selected and chip backgrounds are the color at 12%, outlines at
  30%: `color-mix(in srgb, var(--color-primary) 12%, transparent)`.
- **Icons:** Material Icons (`<span class="material-icons">home</span>`,
  outlined via `material-icons-outlined`), 20px in rows, 24px elsewhere.

## Component patterns

- **Buttons:** at least 48px tall (never a fixed height), `--radius-sm`,
  `.text-label-large`. Primary fills `--color-primary`; onboarding CTA fills
  `--color-secondary`, with a `--color-secondary` outlined button as the
  quieter choice beside it; secondary is a 1px `--color-primary` outline with
  a `--color-primary-text` label; text buttons are bare in
  `--color-primary-text`, destructive ones in `--color-error`.
- **Tag chip:** tinted fill, 30% outline, `--radius-md`, `.text-label-small`,
  optional 14px icon — all in `--color-primary-text` or
  `--color-tertiary-text`.
- **Filter chip:** at least 48px tall, `.text-body-large`, `--color-card`
  fill, `--color-outline` border, `--radius-md`, `--shadow-card`; selected
  fills `--color-secondary`. One that needs an account looks the same with a
  leading lock — never faded. The chip that opens the filter sheet fills
  `--color-primary-container` and says "Filters" beside its icon.
- **Selected option** (filter-sheet category): 2px `--color-primary` outline,
  12% tint, and a leading check mark — state shows in shape, not just color.
- **Facility card:** `--color-facility-card`, `--radius-md`; category icon
  tile, name (two lines), address, two-line preview; a 48px heart and a 48px
  expand control at the trailing edge. Opened: Directions (filled) / Call /
  Website (outlined) in a row under the name, then the details.
- **Text input:** outlined, `--color-outline` (2px `--color-primary` on
  focus), `--radius-sm`, with a label that stays visible while typing and
  helper or error text beneath.
- **Card of rows:** `--color-card`, `--radius-md`, rows divided by
  `--color-outline-variant`, 24px `--color-secondary` leading icons, trailing
  values in `.text-body-medium` `--color-on-surface-variant`, grouped under a
  `.text-title-small` `--color-secondary` section header.
- **Sheets and dialogs:** `--color-card`, `--radius-xl`, over
  `--color-scrim`; sheets have a 40×4 pill handle. The facility sheet is full
  width, on `--color-facility-card`.
- **Navigation:** centered `.text-title-large` app bar on
  `--color-background`; a four-tab bottom bar (Home, Map, Profile, Settings)
  on `--color-nav-bar`. The active tab has a `--color-nav-indicator` pill
  behind a filled icon and a bold `--color-tertiary-text` label; the others
  are outlined icons in `--color-on-surface-variant`.
- **Onboarding step:** a back arrow, a segmented progress bar with "Step n of
  2" under it, a `.text-headline-medium` title in `--color-secondary`, and
  the primary action in `--color-secondary`.

## Map screens

Never draw a map by hand. Compose it from the map kit (`map/map-kit.css`,
already loaded by `styles.css`):

- `<div class="beacon-map beacon-map--neighborhood">` (or `--city`) is a
  390×844 real Google Map in Beacon's styles; it follows the theme.
- Inside it, place `<span class="beacon-pin beacon-pin--health-care">` (any
  facility category, or `--fallback`) with `left` / `top`; pins are centered
  on that point. `.beacon-pin-label` at the same point adds the facility name
  beneath (street zoom only). `<span class="beacon-cluster">12</span>` groups
  facilities (`--medium` for 10–99, `--large` for 100+).
- Build overlays from tokens on top: a `--radius-pill` search bar with
  `--shadow-raised`, a row of filter chips, and a results panel with
  `--radius-xl` top corners and `--shadow-sheet`.
- Keep the Google logo (bottom left of the map) visible: under a bottom
  panel, set `style="--map-inset-bottom: <panel height>px"` on the
  `.beacon-map`, which lifts the map above the panel like the app does.

## Rules

- Touch targets are at least 48px (`--size-min-touch-target`), and every
  icon-only control has a name.
- Sentence case everywhere ("Open now", "Delete account"); "ZIP code" is
  always spelled that way.
- Dark mode: surfaces step up in lightness as they rise (background, card,
  tab bar) and cards take a 1px `--color-outline-variant` outline, since
  shadows don't show.
- iOS and Android look the same, except sign-in: "Continue with Apple" on iOS
  (black; white in dark mode), "Continue with Google" on Android (white; near
  black in dark mode) — never both on one screen.
- Mobile only: no hover-only affordances, sidebars, or desktop navigation.
- Copy is short and plain. The app ships in English, Spanish, and Chinese, so
  leave room for strings about 30% longer.

## Example

```html
<div style="background: var(--color-card); border-radius: var(--radius-md);
            box-shadow: var(--shadow-card); padding: var(--space-lg);">
  <div class="text-title-small">Near North Health Service</div>
  <div class="text-body-small" style="color: var(--color-on-surface-variant)">
    1276 N Clybourn Ave, Chicago, IL
  </div>
  <span class="text-label-small" style="color: var(--color-primary-text);
      background: color-mix(in srgb, var(--color-primary-text) 12%, transparent);
      border: 1px solid color-mix(in srgb, var(--color-primary-text) 30%, transparent);
      border-radius: var(--radius-md);
      padding: var(--space-xs) var(--space-sm);">Walk-ins</span>
</div>
```
