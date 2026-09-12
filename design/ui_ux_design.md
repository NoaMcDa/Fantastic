# UI/UX Design — Fantastic

## Design Language

- **Direction:** RTL (Right-to-Left) throughout, Hebrew as primary locale
- **Style:** Clean, clinical-modern with warm keto accent colours. Not another green-smoothie wellness app — darker, more serious, medical-adjacent.
- **Typography:** System font (SF Pro) for body; a condensed display face for macros/numbers
- **Colour Palette:**

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#1C1C1E` | Backgrounds (dark-mode first) |
| `surface` | `#2C2C2E` | Cards, sheets |
| `accent` | `#F5A623` | Keto gold — streak rings, CTAs |
| `success` | `#30D158` | Clean Keto badge |
| `caution` | `#FFD60A` | Caution badge |
| `danger` | `#FF453A` | Non-keto badge, streak break |
| `outline` | `#8E8E93` | The edge of an unfilled interactive control — an unselected score button, an unfilled score dot. Material's `surfaceContainerHighest` is within a few points of `surface` on this palette, so a fill alone is not an affordance (#307) |
| `text-primary` | `#FFFFFF` | Primary text |
| `text-secondary` | `#EBEBF5` at 60% | Supporting text |

- **Motion:** Functional only — no decorative animation. Streak ring fill animates on log completion.
- **Haptics:** Light impact on badge reveal; success notification on streak increment.

---

## App Structure

Tab bar (bottom, 6 items):

```
index    0        1         2        3         4          5
       [ בית ]  [ מצלמה ]  [ יומן ]  [ התאמה ]  [ מתכונים ]  [ פרופיל ]
        Home     Lens      Diary    Adaptation  Recipes     Profile
```

Home is index 0 and the default tab. Listed in `kTabPaths` index order, which
is what `AppShell` renders and what every `Key('tab_*')` finder addresses — the
bar itself is RTL, so index 0 paints **rightmost** on screen.

**This diagram was wrong in two independent ways until M10 corrected it**, and
both were the same mistake: it drew the plan rather than the app.

- It listed `מסעדות` (Directory), which has never been built — M11 is still
  open. A designer reading it would have laid out a tab that does not exist.
- It omitted `התאמה` (Adaptation), which shipped in M3 and has been a tab ever
  since.

Neither error was catchable by a test, because no test reads this file. The
authority on what tabs exist is `kTabPaths` in `lib/core/router/app_router.dart`
and `AppShell._labels` beside it; when they and this diagram disagree, they are
right. `מתכונים` (#119) is the sixth and the first post-MVP tab.

---

## Page-by-Page Design

---

### 1. Onboarding Flow

**Goal:** Collect enough data to personalise phase tracking and macro targets. Maximum 4 screens.

#### 1a. Welcome
- Full-screen illustration: keto plate (avocado, eggs, salmon, olive oil) with Hebrew tagline
- CTA: "בואו נתחיל" (Let's start)
- No account sub-link: there are no accounts in the MVP — Epic #8 lists social login and
  account creation as explicitly out of scope. See `design/m4_preflight.md` §6.3.

#### 1b. About You
- Fields: Sex, Age, Weight (kg), Height (cm)
- Toggle: "כבר בקטו?" (Already on keto?) → if yes, ask start date to seed streak

#### 1c. Goals
- Three cards (single-select), matching the shipped `KetoGoal` enum:
  - ירידה במשקל (Weight loss) — `KetoGoal.weightLoss`
  - בריאות מטבולית (Metabolic health) — `KetoGoal.metabolicHealth`
  - ביצועים ספורטיביים (Athletic performance) — `KetoGoal.athleticPerformance`
- Only `weightLoss` changes the arithmetic today (a 20% TDEE deficit). This list was
  previously "Energy & focus / Medical condition management"; it was reconciled with
  the enum #71 defines and #73 codes against — see `design/m4_preflight.md` §6.1, which
  also records why the choice is worth revisiting.
- Post-MVP, the goal seeds the emphasis of the dashboard (weight graph vs. energy diary
  vs. biomarker tracking)

#### 1d. Daily Targets
- Auto-calculated macro targets shown (editable)
- Fat: `__g` Carbs: `__g` Protein: `__g`
- Electrolyte targets are **not** shown here: they are per-phase, not per-user, owned by
  `ElectrolyteConstants` and rendered by the dashboard's electrolytes card. There is
  nothing for onboarding to compute or save. See `design/m4_preflight.md` §6.4.
- CTA: "התחל את המסע" (Start the journey)

---

### 2. Home (Dashboard)

**Layout:** Scroll view with sticky header showing today's date and streak.

#### Header Bar
```
[streak flame + count]     [today's date]     [notification bell]
```

#### Streak & Phase Card (hero card, full-width)
- Circular ring: today's keto ratio progress
- Inside ring: current streak day count + flame
- Below ring: phase name badge ("שלב 2 — מותאם לשומן")
- Phase description: 1–2 lines of what to expect this week
- Tappable → expands to Adaptation Phase detail screen

#### Macro Summary Card
Four horizontal progress bars:
- שומן (Fat) — progress / target
- פחמימות נטו (Net Carbs) — progress / target
- חלבון (Protein) — progress / target
- יחס קטו (Keto Ratio) — current value + target range badge

#### Electrolytes Card (collapsible)
Three circular mini-gauges: Na / K / Mg — progress vs. target
Tap any → opens diary log sheet for that electrolyte

#### Today's Meals List
Chronological cards, each showing:
- Meal name / label
- Macro mini-bar (fat / carbs / protein split colour-coded)
- Keto badge (Clean / Caution / Non-Keto)
- Swipe left → delete

FAB (bottom-right): "＋" → bottom sheet with options: "סרוק תווית" / "הוסף ידנית" / "מסעדה"

#### Quick Symptom Check-In Strip
Horizontal scrollable row of emoji-scale buttons (energy, hunger, clarity, mood)
Tap any → opens a modal log sheet for that symptom

---

### 3. Keto Lens (Scanner)

**Trigger:** Camera tab or FAB → "סרוק תווית"

#### 3a. Camera View
- Full-screen camera viewfinder
- Overlay: rounded rectangle crop guide with Hebrew label "כוון לתווית"
- Torch toggle (top-right)
- Gallery picker (bottom-left)
- Capture button (bottom-center, large)

#### 3b. Processing State
- Dimmed freeze-frame of captured image
- Spinner + "מנתח תווית..." text
- This is fully on-device — typically < 1s

#### 3c. Results Sheet (slides up from bottom, 2/3 screen)

**Header:** Product name (parsed from label) + verdict badge (large, colour-coded)

**Badge variants:**
```
┌─────────────────────────┐
│  ✅  קטו נקי            │  Green — no red-flag ingredients
└─────────────────────────┘

┌─────────────────────────┐
│  ⚠️  זהירות / כמות       │  Yellow — insulin-spiking sweeteners in small amount
└─────────────────────────┘

> **"In small amount" is now tested rather than asserted (#306).** Until the
> scan read the nutrition panel, nothing in the app could check that claim —
> the classifier sees tokens, not grams. `LabelVerdict.combine` escalates this
> amber badge to red when a flagged insulin-spiking sweetener meets a
> `moderation`-or-worse macro verdict, because the panel has falsified the
> premise of the caution. It does **not** escalate the other source of an amber
> badge, an unspecified vegetable oil: that caution is about *identity* — the
> oil may be palm or coconut — and carbohydrate says nothing about which it is.
>
> A fourth, neutral chip exists for a scan where neither the ingredients nor the
> panel carried evidence: `לא ניתן לקבוע — בדקו את התווית`, on `AppTheme.surface`
> with no new colour token.

┌─────────────────────────┐
│  ❌  לא קטו              │  Red — seed oils or high-carb sweeteners present
└─────────────────────────┘
```

**Macro strip:** Fat / Net Carbs / Protein per 100g + per serving

**Flagged Ingredients list:** Red-tagged ingredients with a one-line reason each
e.g. "שמן קנולה — שמן זרעים דלקתי" (Canola oil — inflammatory seed oil)

**Actions row:**
- "הוסף ליומן" (Add to diary) → pre-fills meal log with macros
- "שתף" (Share) → share verdict card as image

---

### 4. Diary (Daily Log)

**Layout:** Date picker header + sectioned scroll view

#### Date Picker
Horizontal scrollable date strip (last 30 days) with today highlighted in accent colour.

#### Meals Section
Same as dashboard meal list but for the selected date.
Tap any meal → meal detail / edit sheet.

#### Symptoms Section
4 rows, each with a label and a 1–5 scale selector:
- אנרגיה (Energy)
- ריכוז (Mental clarity)
- רעב (Hunger)
- מצב רוח (Mood)

Below the scales, **תסמינים פיזיים** is a multi-select chip grid, not a scale.
A single 1–5 number said the user felt bad without saying what they felt,
which is the one thing that would have made the field actionable. Eight
chips, ordered by reported occurrence rate:

| Chip | Symptom |
|---|---|
| ריח פה | Halitosis |
| עצירות | Constipation |
| התכווצויות שרירים | Muscle cramps |
| כאב ראש | Headache |
| שלשול | Diarrhea |
| סחרחורת | Dizziness |
| בחילה | Nausea |
| נדודי שינה | Insomnia |

The list is deliberately somatic only — fatigue, brain fog, irritability and
appetite change are all already covered by one of the four scales, and listing
them twice would let the same day be reported two different ways.

Empty states, which mean different things and must not look alike:
- Nothing logged for the day → "לא הוקלטו תסמינים להיום" with a ＋ button.
- Logged, no symptoms marked → "לא דווחו תסמינים פיזיים".

#### Biomarkers Section
Cards for each recorded biomarker:
- קטונים בדם / בנשיפה (Blood / breath ketones)
- גלוקוז בצום (Fasting glucose)
- משקל גוף (Body weight)

Each card shows the value, trend arrow vs. previous entry, and a small sparkline.
＋ button opens a log sheet for adding a new reading.

#### Electrolytes Section
Three progress bars (Na / K / Mg) with today's intake vs. target.
Tap → opens an edit sheet to log electrolyte supplement intake.

---

### 5. Adaptation Phase Detail

**Accessed from:** Streak card on Home (tap)

**Layout:** Full-screen modal with close button

#### Phase Progress Timeline
Vertical stepper:
- ● Phase 1 (Days 1–7): Induction — current or completed
- ● Phase 2 (Days 8–27): Fat Adaptation — current or locked
- ● Phase 3 (Days 28+): Deep Ketosis — current or locked

Current phase card is expanded with:
- Phase name + day range
- 3–4 bullet points: what to expect, what to watch for
- Electrolyte recommendation for this phase
- "לומד עוד" (Learn more) → educational content sheet

#### Streak Break / Grace Period Banner (conditional)
Shown in danger colour when streak is broken or grace period is active.
"הסטריק נשבר — יש לך 24 שעות לחזור למסלול"

#### Streak History Mini Calendar
Monthly grid showing compliant days (gold dots) vs. breach days (red dots).

---

### 6. Restaurant Directory

**Layout:** Search + filter header + map/list toggle

#### Search Bar (RTL)
"חפש מסעדה, עיר, קטגוריה..."
Filter chips below: קטו ידידותי / כשר / טבעוני / עם משלוח

#### List View (default)
Cards with:
- Restaurant name (Hebrew) + category tag
- Area / city
- Keto score badge (★★★ / ★★☆ / ★☆☆)
- "קטו אפשרויות:" — 2–3 recommended dishes inline
- Distance (if location permitted)

#### Map View
MapKit map with custom keto pin markers.
Tap pin → bottom card with restaurant summary and "נווט" button.

#### Restaurant Detail Sheet
- Full name, address, phone, hours
- Keto menu highlights (dish list with macros if available)
- Notes: "ניתן להחליף את הלחם בחסה" (can substitute bread with lettuce)
- User ratings / tips section
- "הצע עדכון" (Suggest an update) → form

---

### 7. Menu Scanner (M16 — supersedes this section's original design)

**This section originally specified a FAB → "מסעדה" entry point, a camera-only
capture flow and an "הוסף לסל" button logging a dish to the diary. None of
that shipped.** M16's audit (`design/m16_menu_scanner_research.md`) found the
restaurant directory (M11) not yet built, so there is no restaurant detail to
launch from, and decision 4 there records why a dish verdict is not loggable
as a macro — a menu's Green/Modifiable/Red badge is not a nutrition estimate.
What shipped instead:

**Accessed from:** the lens tab's `תפריט` chip, pinned beside `תווית` at the
top of every Keto Lens camera state (`/lens/menu`) — the smallest entry point
per decision 5, and the tab bar stays on the lens tab since it is a child
route of `/lens`.

#### Input — three modes, `הדביקו טקסט` selected by default
- **`הדביקו טקסט`** — a multi-line field for pasted menu text, and `נתחו`.
- **`צלמו עמודים`** — the same camera UX as Keto Lens (viewfinder, torch,
  gallery import), collecting up to 8 pages with a thumbnail strip and a page
  counter, before the identical `נתחו` call. OCR runs on the device first —
  the photograph itself is never sent, only the recognised text.
- **`קובץ PDF`** (M16, #405–#408) — a single `בחרו קובץ PDF` button; the
  chosen file's name is shown with a `הסירו קובץ` clear control. Each page's
  text layer is extracted on the device; a page with no usable Hebrew text
  (mojibake or a scan) is rasterised and read through the same OCR path as
  `צלמו עמודים`, invisibly to the user — one `נתחו` call either way. A pick
  that fails (bad file, password-protected, or — the web case — a platform
  path that never arrives) shows `לא ניתן היה לפתוח את הקובץ שנבחר`, not a
  silent no-op. A PDF with no OCR-capable build and no readable text layer on
  any page shows `לא ניתן לקרוא את התפריט הסרוק`, pointing at `הדביקו טקסט`.
  The page cap (8) and a menu long enough to be silently truncated both now
  surface as one-line notices, shared with the photo tab.

All three modes feed the same analyser call; a screen with no working OCR
engine still offers the pasted-text path via a `הדביקו את הטקסט במקום` link.

#### Result — grouped, not a flat list
- A legend naming what each of the three badges means.
- **אפשר להזמין** (green) dishes, then **אפשר עם שינוי** (yellow), each dish
  card collapsed to its name and badge, expanding on tap to its *why* and —
  for a yellow dish — the modification instruction with a copy button.
- **לא מתאים לקטו** (red) dishes are grouped under a header showing the count,
  collapsed by default — never hidden, never filtered out, but not the first
  thing a screen full of red opens on.
- A **לא ניתן לקבוע** section for any name the model could not place, reported
  rather than dropped.
- A page OCR could not read is named in a warning line, not silently skipped.

No "הוסף לסל" or any other diary-logging affordance: research decision 4
records the honest bridge as a follow-up ("estimate this dish" into M15's
description sheet, prefilled with the dish name), filed separately and not
part of M16.

---

### 8. Recipe Converter (M10 — shipped)

**Layout:** one column of stacked rows, one per ingredient line. **Not two
columns** — a side-by-side original/keto table does not survive 320 px in RTL,
and the original amount of an ingredient being replaced describes a different,
inedible recipe, so showing it as a peer of the replacement gives it a standing
it has not earned.

#### Input Section
- Text area: paste an ingredient list, one ingredient per line.
- **Paste only.** The `סרוק ממתכון` camera import this section originally
  specified was not built and is not planned for M10: Keto Lens reads a printed
  *nutrition panel*, and a recipe card is prose in arbitrary layout. Scanning one
  is a different OCR problem from the one the app has solved.

#### Conversion Results
Every non-blank line becomes exactly one of four outcomes, each visually
distinct, with its own row key (`outcome_<variant>_<index>`):

| Outcome | What it means | Shows |
|---|---|---|
| `Substituted` | The table knows a keto replacement | The replacement, the **ratio-adjusted** quantity, and the reason |
| `AlreadyKeto` | The line is fine as written | An approval mark |
| `Flagged` | Remove it — no replacement works | `הסירו מהמתכון — לא מתאים לקטו` |
| `Unrecognised` | Nothing in the table knows this line | `לא זוהה`, and **never styled as approved** |

That fourth row is the point of the design. An unknown ingredient silently
rendered as fine is how a 40 g-carb line becomes invisible — the same failure
`EstimateReviewList` exists to prevent for estimated meals.

A row whose outcome came from the **model pass** (#396) additionally carries
`RecipeCopy.suggestedMarker` — `הצעה אוטומטית — בדקו`. A clean claim from a
model is not evidence, and a badge that does not distinguish the two trains
people to ignore it.

#### Per-serving macros (#397)
Below the results, once the recipe is **saved**: a servings field, `ערכים למנה`,
the itemised review list the description mode uses, and a per-serving row.

- **Only the per-serving figures are shown as "per serving", and only they can
  be logged.** A recipe is a batch, not a meal.
- **The original is never estimated.** This section used to ask for "macro totals
  for original vs. keto version"; that costs a second request and a quota slot
  for a number nobody logs, so only the converted list is estimated.
- `Flagged` and `Unrecognised` lines are excluded from the estimate and listed
  as unidentified, so their absence from the total is visible.
- `הוסיפו מנה ליומן` hands one serving to `AddMealBottomSheet` as
  `MacroSource.estimatedFromText` — the same editable form as every other way
  of logging a meal.

#### Recipe Library
`/recipe/library`, reached from the converter's app-bar action. **A list, newest
first — not a grid, and no thumbnail:** nothing photographs a pasted recipe, so a
thumbnail slot would be permanently empty. Each card shows the title, the save
date, a counts line, and a per-serving macro line **only when one is stored** —
an absent estimate is not zero. Swipe to delete; tap to reopen the conversion
exactly as it was saved.

---

### 9. Profile & Settings

**Layout:** Grouped settings list

#### Profile Section
- Avatar (initials fallback)
- Name, age, weight (current vs. start)
- Days on keto counter
- Total streak count

#### Targets Section
- Edit macro targets
- Edit electrolyte targets
- Recalculate from body stats

#### Notifications Section
- Daily log reminder (time picker)
- Streak warning (toggle)
- Symptom check-in reminder

#### Data Section
- Export diary as CSV
- Apple Health sync toggle (weight, steps)
- iCloud backup toggle

#### App Section
- Language (Hebrew / English)
- Theme (dark / light / system)
- Rate the app
- Privacy policy / Terms

---

## Accessibility & RTL Notes

- All layouts use `Directionality(textDirection: TextDirection.rtl)` at the app root.
- All icons that imply direction (arrows, back chevrons) are mirrored.
- Text fields use `TextAlign.right` by default.
- Minimum touch target: 44×44pt (Apple HIG).
- All colour combinations meet WCAG AA contrast ratio.
- VoiceOver labels provided for all icon-only buttons.
