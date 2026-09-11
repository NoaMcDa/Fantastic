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

Tab bar (bottom, 5 items):

```
[ מצלמה ]  [ יומן ]  [ בית ]  [ מסעדות ]  [ פרופיל ]
 Lens       Diary    Home    Directory   Profile
```

Home is the default tab.

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

### 7. Restaurant Menu Analyzer

**Accessed from:** FAB → "מסעדה" or within restaurant detail

#### Camera / Upload View
Same camera UX as Keto Lens.
Prompt overlay: "כוון לתפריט"

#### Results Sheet
List of dishes detected with:
- Dish name
- Estimated macro breakdown (fat / carbs / protein)
- Keto suitability badge
- Modification tip inline ("בקש ללא לחם" / "Request without bread")

"הוסף לסל" button logs selected dish to today's diary.

---

### 8. Recipe Converter

**Layout:** Two-column flow — Original → Keto

#### Input Section
- Text area: paste any recipe (Hebrew or English)
- Or: "סרוק ממתכון" (scan from a recipe card — uses camera)

#### Conversion Results
Side-by-side ingredient substitution list:
```
קמח חיטה (200g)  →  קמח שקדים (180g) + פסיליום (20g)
סוכר (100g)      →  אריתריטול (80g)
שמן סויה          →  שמן זית / חמאה
```

Below: macro totals for original vs. keto version (fat / carbs / protein per serving).

Save button → saved to Recipe library.

#### Recipe Library
Grid of saved converted recipes with a thumbnail (if photo taken) and macro badge.

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
