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

- **Color roles:** `--color-primary` (reseda green: primary actions,
  selection, switches), `--color-secondary` (Payne's gray: onboarding CTAs,
  section headers, list icons, selected filter chips), `--color-tertiary`
  (bittersweet: links, next-step icons, destructive actions),
  `--color-background`, `--color-card`, `--color-on-surface`,
  `--color-on-surface-variant` (secondary text), `--color-outline-variant`
  (dividers, borders), `--color-error`. Text on a filled role uses its
  `--color-on-*` pair (`--color-on-primary`, `--color-on-secondary`, …).
- **Facility categories** (tags, map pins, quick actions):
  `--color-category-health-care`, `-mental-health`, `-basic-needs`,
  `-housing-shelter`, `-community-resources`, `-specialized-services`.
- **Type classes:** `.text-headline-medium` (onboarding titles),
  `.text-title-large` (section headings, app bar, dialogs),
  `.text-title-medium`, `.text-title-small` (list-row titles),
  `.text-body-large` / `-medium` / `-small`, `.text-label-large` (buttons),
  `.text-label-medium` (links, chips), `.text-label-small` (badges, hours).
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

- **Buttons:** 48px tall, `--radius-sm`, `.text-label-large`. Primary fills
  `--color-primary`; onboarding CTA fills `--color-secondary`; secondary is a
  1px `--color-primary` outline; text buttons are bare, destructive ones use
  `--color-tertiary`.
- **Tag chip:** tinted fill, 30% outline, `--radius-md`, `.text-label-small`
  in the chip color, optional 14px icon.
- **Filter chip:** `--color-card` fill, `--color-outline-variant` border,
  `--radius-md`, `--shadow-card`; selected fills `--color-secondary`.
- **Card of rows:** `--color-card`, `--radius-md`, rows divided by
  `--color-outline-variant`, 24px `--color-secondary` leading icons, trailing
  values in `.text-body-medium` `--color-on-surface-variant`, grouped under a
  `.text-title-small` `--color-secondary` section header.
- **Sheets and dialogs:** `--color-card`, `--radius-xl`; sheets have a 40×4
  pill handle.
- **Navigation:** centered `.text-title-large` app bar on
  `--color-background`; a four-tab bottom bar (Home, Map, Profile, Settings)
  on `--color-nav-bar`, active tab `--color-brand-bittersweet`.

## Rules

- Touch targets are at least 48px (`--size-min-touch-target`).
- iOS and Android look the same, except sign-in: black "Continue with Apple"
  on iOS, white "Continue with Google" on Android — never both on one screen.
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
  <span class="text-label-small" style="color: var(--color-primary);
      background: color-mix(in srgb, var(--color-primary) 12%, transparent);
      border: 1px solid color-mix(in srgb, var(--color-primary) 30%, transparent);
      border-radius: var(--radius-md);
      padding: var(--space-xs) var(--space-sm);">Walk-ins</span>
</div>
```
