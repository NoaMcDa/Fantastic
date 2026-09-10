# MVP — Fantastic v1.0

## North Star

Deliver the one experience no other app gives Israeli keto users: **scan a Hebrew label, know instantly if it's keto, and track your adaptation journey day by day.**

Everything in the MVP serves one of those two goals. Features that don't serve them are deferred.

---

## What the MVP Is NOT

- Not a full restaurant directory (static data takes time to curate)
- Not a recipe converter (useful, not critical to first-week retention)
- Not a menu analyzer (complex ML flow, v2)
- Not a social / community feature
- Not a cloud-sync product (offline-first, iCloud backup deferred to v1.1)

---

## Core MVP Features (Must Ship)

### 1. Keto Lens — Hebrew Label Scanner
**Why first:** This is the unique hook. No competitor has it. It is the reason an Israeli keto dieter downloads Fantastic over Carb Manager.

**Scope:**
- Camera viewfinder with crop overlay
- On-device Hebrew OCR via `google_mlkit_text_recognition`
- Ingredient classification: Clean Keto / Caution / Non-Keto badge
- Macro extraction: fat, net carbs, protein per 100g and per serving
- Flagged ingredients list with one-line reason per flag
- "Add to diary" action from result screen
- Gallery import as fallback

**Out of scope for MVP:** saving scan history, sharing verdict cards

---

### 2. Daily Macro Tracker (Dashboard)
**Why:** Without tracking, users can't know if they're actually in ketosis. This is the daily engagement loop.

**Scope:**
- Log meals manually (name + fat/carbs/protein input)
- Log meals from a Keto Lens scan (pre-filled macros)
- Dashboard showing today's totals: fat, net carbs, protein, keto ratio
- Progress bars vs. personalised targets
- Electrolyte tracking (Na / K / Mg) — manual input
- Date-based diary view (last 30 days)
- Swipe-to-delete meal entries

**Out of scope for MVP:** food database search, barcode scanner, calorie tracking

---

### 3. Adaptation Phase Tracker & Streak
**Why:** This is the retention engine and the emotional core. Users who see their streak and phase progress come back every day.

**Scope:**
- Streak counter: compliant days logged consecutively
- Three phases with day ranges and plain-language descriptions:
  - Phase 1 (Days 1–7): Induction & Keto-Flu Management
  - Phase 2 (Days 8–28): Fat-Adapted Transition
  - Phase 3 (Days 28+): Deep Ketosis
- Phase state machine: compliant day → advance; breach → grace period (24h) → reset
- Phase detail screen: what to expect, electrolyte advice for current phase
- Streak ring animation on the dashboard (keto ratio arc)
- Push notification at 20:00 if no meal logged ("streak at risk")
- Monthly calendar showing compliant vs. breach days

**Out of scope for MVP:** streak recovery purchases, gamification badges

---

### 4. Onboarding Flow
**Why:** Without it, macro targets and phase tracking can't be personalised, and the app feels generic.

**Scope:**
- 4-screen flow: Welcome → About You (sex, age, weight, height) → Goals (weight loss / energy / medical) → Calculated Targets (editable)
- "Already on keto?" toggle → seed streak from a past start date
- Skippable (defaults used if skipped)

---

### 5. Symptom Diary (Lightweight)
**Why:** Keto flu in Phase 1 is the #1 reason beginners quit. If users can log symptoms and see the app validate their experience ("this is normal in Phase 1"), they stay.

**Scope:**
- Daily 1–5 scale ratings: energy, mental clarity, hunger, mood, physical symptoms
- Inline from the dashboard (quick tap strip)
- Historical view in diary

**Out of scope for MVP:** charts, trend analysis, correlation with macros

---

## Deferred to v1.1

| Feature | Reason deferred |
|---|---|
| Restaurant directory | Requires manual content curation of Israeli venues |
| Menu analyzer | Complex second ML pipeline; OCR + NLP |
| Recipe converter | Nice-to-have; adds complexity without proving core loop |
| Biomarker logging (ketones, glucose, weight) | Valuable but not day-1 critical |
| Apple Health integration | Requires HealthKit entitlement review |
| iCloud backup | Offline-first is sufficient for v1 |
| Food database / barcode scanner | Manual entry covers MVP; Open Food Facts integration for v1.1 |
| Sharing / social features | Post-retention problem |

---

## MVP Success Metrics

| Metric | Target at 30 days post-launch |
|---|---|
| Day-7 retention | ≥ 40% |
| Scans per active user per week | ≥ 3 |
| Users completing Phase 1 (Day 7) | ≥ 25% of Day-1 users |
| Crash-free sessions | ≥ 99% |
| App Store rating | ≥ 4.3 |

---

## MVP Build Order

Build in this sequence — each milestone is shippable to TestFlight.

### Milestone 1 — Skeleton (Week 1–2)
- Flutter project, routing, tab bar, RTL theme
- Database setup, all persistence schemas
- Riverpod provider wiring
- Onboarding flow (data collection only, no personalisation logic yet)

### Milestone 2 — Tracking Core (Week 3–4)
- Manual meal logging
- Daily macro aggregation
- Dashboard with macro progress bars and keto ratio
- Date-based diary view

### Milestone 3 — Adaptation Engine (Week 5–6)
- Streak state machine
- Phase detection and detail screen
- Streak ring animation on dashboard
- Push notification for streak risk
- Symptom diary (quick-tap strip)

### Milestone 4 — Keto Lens (Week 7–8)
- Camera screen with Hebrew OCR
- Label parser and ingredient classifier
- Result sheet with badge, macros, flagged ingredients
- "Add to diary" integration
- Gallery import

### Milestone 5 — Polish & Launch (Week 9–10)
- Onboarding personalisation (computed macro targets)
- Empty states, error states, loading skeletons
- App icon, launch screen
- TestFlight beta with 20–30 Israeli keto users
- Crash fix cycle → App Store submission

---

## Definition of Done for MVP

- All 5 core features work offline on an iPhone 12 or newer
- Hebrew OCR correctly classifies ≥ 80% of tested Israeli products
- Streak state machine handles all edge cases (timezone changes, grace period expiry)
- No data loss on app restart or device reboot
- Passes App Store review (privacy labels, Hebrew localisation, camera usage description)
