# Design System — Handoff

A visual design system for Fantastic: colour, typography, spacing, elevation,
iconography, and a Hebrew RTL component library (buttons, inputs, cards,
badges, modal states). It implements and extends the palette and page specs
in `design/ui_ux_design.md` into a full, implementation-ready token set.

## Where to look at it

The system is published as an interactive canvas (10 artboards, one per
section, pannable/zoomable):

**https://claude.ai/code/artifact/e323de65-33c4-473c-a56d-0fdb7980bf0c**

The Buttons board has live hover/press states; the Modals board is a
clickable phone frame that switches between five modal states via a
segmented control. Everything else is a static specimen board with the spec
written next to it.

Source is in `design/design-system/*.dc.html` (+ `canvas.json` for layout).
These are Design-Components source files for Claude's design-canvas editor,
not app code — they exist to be viewed/edited on the canvas above, not
imported into Flutter. Treat them as the reference artifact; re-open the
link rather than reading the raw HTML.

## Board index

| # | Board | Covers |
|---|---|---|
| 01 | Color | Surface ladder, accent ramp, verdict/status colours (with tints + measured contrast), text levels, macro & electrolyte data-series colours |
| 02 | Typography | Assistant (Hebrew/Latin UI) + Archivo Narrow (tabular numerals), full type scale from metric/xl down to label, Hebrew-specific rules |
| 03 | Spacing & layout | 4pt spacing scale, corner-radius scale, screen gutter/rhythm, touch-target and RTL-mirroring rules |
| 04 | Elevation | 5-level elevation system for dark mode (surface lightness carries height, shadow supports it), focus ring, hairlines, scrim |
| 05 | Iconography | Construction rules (24pt grid, 1.75 stroke), sizes/states, ~28 icons across navigation / actions / verdict / keto-domain |
| 06 | Buttons | Primary/secondary/tertiary/destructive, all states, 3 sizes, icon/FAB/segmented, anatomy |
| 07 | Inputs | Text field states, numeric stepper, 1–5 symptom scale, toggle/radio/checkbox, textarea, picker rows |
| 08 | Cards | Streak/phase hero, macro summary, meal row w/ verdict, electrolyte gauges, empty states |
| 09 | Badges & progress | Full-width verdict badge (the core product component), inline badges/chips/pills, linear & ring progress, trend indicators |
| 10 | Modal states | Bottom sheet, destructive dialog, processing state, streak-break dialog, toast — as one clickable phone-frame demo |

## Key token decisions (not fully specified in `ui_ux_design.md`)

These were designed to extend the existing 8-token palette; treat them as
proposed defaults, not settled:

- **Surface ladder** (5 steps, `ui_ux_design.md` only specified 2):
  `#0E0E10` sunken → `#1C1C1E` base → `#2C2C2E` raised (cards) →
  `#3A3A3C` overlay (sheets/dialogs) → hairline `rgba(235,235,245,0.16)`.
- **Accent ramp**: `#FFBE55` (hover) / `#F5A623` (base) / `#D98E17`
  (pressed) / `rgba(245,166,35,0.16)` (tint — selected chip, ring track).
- **Verdict tints**: all three verdict colours get one shared tint step,
  16%, on a 35%-alpha border of the same hue.
- **Macro series** (not in the source doc): fat reuses accent gold
  (`#F5A623` — deliberate, fat is the hero macro), net carbs `#BF5AF2`,
  protein `#64D2FF`.
- **Electrolyte series** (not in the source doc): Na `#5E5CE6`, K
  `#66D4CF`, Mg `#FF6482` — kept as a visually separate trio from the
  macro series so the two never get confused on one chart.
- **Typography**: `ui_ux_design.md` calls for "a condensed display face for
  macros" without naming one — chose Archivo Narrow (Google Fonts) paired
  with Assistant for Hebrew/Latin UI text (SF Pro is not available outside
  an Apple toolchain and has no Google Fonts equivalent; Assistant matches
  its x-height and weight range closely for Hebrew).
- **4pt spacing / radius scale**: base grid 2/4/8/12/16/20/24/32/40/48/64;
  radii 8 (chips) / 12 (buttons, inputs) / 16 (cards) / 20 (dialogs) / 24
  top-only (sheets) / pill (999px).
- **Elevation**: a 5-level system built for dark mode specifically — shadow
  alone barely reads on `#1C1C1E`, so height is signalled first by surface
  lightness, second by a hairline, and only third by a shadow.

## Known open questions for product/eng

- **Font licensing** — *resolved for Assistant.* It is SIL OFL 1.1, and
  **Assistant 400/700 is now bundled** in `assets/fonts/` with the licence
  vendored beside it, named by `AppTheme.fontFamily`. Web support forced the
  question: CanvasKit carries no Hebrew glyphs, so an unbundled app renders
  its whole UI as tofu boxes offline (`design/web_support.md` §6). The
  "swap for SF Pro if iOS-only distribution makes that preferable" option is
  therefore closed — distribution is no longer iOS-only.
  **Archivo Narrow (tabular numerals) is still open**: its licence is equally
  fine, but nothing bundles or applies it yet, and doing so is a type-scale
  change rather than a rendering fix.
- **Data-series colours** (macro trio, electrolyte trio) are new and don't
  appear in `ui_ux_design.md` — worth a product sign-off since they'll show
  up on every dashboard chart.
- The **verdict badge** (board 09) was treated as the single most important
  component in the app (it's the Keto Lens payoff) and got more variants
  than the original 3-badge sketch in `ui_ux_design.md` — inline chip,
  full-width sheet header, and list-row versions. Confirm this matches
  intended scope before Keto Lens issues (#79–#87) are picked up.

## Review status

The canvas went through one self-review pass after first publish: a
background check compared every board's stated spec against its own
rendered specimen and against the other boards, and against
`ui_ux_design.md`. Fixed in the second (current) published version:
overflowing frames, an inverted RTL toggle, incorrect contrast-ratio
labels, inconsistent tint/radius values, a font-fallback gap for Hebrew
numerals, sub-floor type sizes, and a few Hebrew copy/register issues
(`לא הוקלטו` → `לא נרשמו`; `יום תואם` → `יום שעומד ביעד`). See the
`design: correct design system tokens after review pass` commit for the
full list.

Not yet done: no one has looked at this on an actual device or compared it
side-by-side against `ui_ux_design.md`'s page-by-page layouts (it's a
component library, not a screen-by-screen mock) — that comparison is worth
doing before M0/M1 implementation starts consuming these tokens.
