# Technology Brainstorming — Feature by Feature

For each feature, this document lists the candidate technologies, the recommended choice, and the rationale. All packages are evaluated for iOS support, offline capability, maintenance health, and Hebrew/RTL compatibility.

---

## 1. Keto Lens — Hebrew OCR Label Scanner

### Problem
Read Hebrew nutrition labels from product packaging on-device, with no internet dependency.

### Candidates

| Option | Pros | Cons |
|---|---|---|
| `google_mlkit_text_recognition` | On-device, fast, no API key, strong Hebrew support, Flutter plugin maintained by Google | Requires camera permission setup; OCR quality degrades on low-light / curved labels |
| Tesseract OCR (via `flutter_tesseract_ocr`) | Open-source, self-hostable | Slower, larger bundle, Hebrew model must be bundled manually (~50MB) |
| Apple Vision (`vision` FFI) | Native, best Hebrew quality on-device | No Flutter plugin; requires custom platform channel; complex to maintain |
| AWS Rekognition / Google Cloud Vision API | Best accuracy | Requires network, API cost, privacy concerns with food labels |

**Recommended:** `google_mlkit_text_recognition`

**Rationale:** Zero network dependency, Hebrew is a first-class supported script, fast inference (<1s on iPhone 12+), and the Flutter plugin is actively maintained. Post-OCR normalisation with regex handles common mis-reads.

### Supporting Packages
- `camera` — live viewfinder
- `image_picker` — gallery import
- `image` — pre-processing (contrast, crop) before passing to MLKit

---

## 2. Keto Ratio & Macro Tracking

### Problem
Calculate and track fat/carb/protein ratios and electrolyte intake across meals and days.

### Candidates

| Option | Pros | Cons |
|---|---|---|
| Pure Dart calculation | Zero dependencies, fully testable, instant | Must implement all formula logic |
| `nutritionix_api` | Large food database | Network required, not Israeli-specific, API cost |
| `openfoodfacts` package | Open food database, barcode lookup | Israeli products sparse, requires network |

**Recommended:** Pure Dart `KetoRatioCalculator` service + local `DailyLog` aggregation

**Rationale:** Keto ratio is a simple formula (`fat / (net_carbs + protein)`). No external package is needed. Barcode lookup can be added as a future enhancement via Open Food Facts, but the core tracking is always offline.

### Formula Definitions
```
Keto Ratio         = fatG / (netCarbsG + proteinG)
Net Carbs          = totalCarbsG − dietaryFiberG
Caloric Density    = (fatG × 9) + (proteinG × 4) + (netCarbsG × 4)
```

Electrolyte daily targets (phase-aware):
- Phase 1: Na 3000–5000mg / K 3000–4000mg / Mg 300–500mg
- Phase 2–3: Na 2000–3000mg / K 2500–3500mg / Mg 300–400mg

---

## 3. Adaptation Phase Tracker & Streak Engine

### Problem
Maintain a persistent streak counter, detect compliant vs. non-compliant days, drive a phase state machine, and handle grace periods.

### Candidates

| Option | Pros | Cons |
|---|---|---|
| Pure Dart state machine + local persistence | Full control, testable, offline | Must implement all logic |
| Firebase Firestore | Cloud backup, multi-device | Network dependency, overkill for local streak |
| `hive` for state | Simple API | sembast already chosen for the other stores — redundant |

**Recommended:** Pure Dart `AdaptationPhaseService` state machine persisted as the singleton `StreakState` record

**State Machine:**
```
IDLE ──(first compliant day)──► INDUCTION (Phase 1, days 1–7)
INDUCTION ──(day 8)──► FAT_ADAPTED (Phase 2, days 8–28)
FAT_ADAPTED ──(day 29+)──► DEEP_KETOSIS (Phase 3)
ANY_PHASE ──(breach detected)──► GRACE_PERIOD (24h window)
GRACE_PERIOD ──(compliant within 24h)──► resume previous phase
GRACE_PERIOD ──(24h elapsed)──► reset to INDUCTION, streak = 0
```

**"Breach detected" means:** the day has meals logged and their total net carbs
exceed `KetoConstants.maxCompliantNetCarbsG` (50 g). At or below it the day is
compliant; with nothing logged at all it is neither — an unlogged day that is
not today breaks the streak on its own. The single definition is
`DayCompliance.of` (`lib/features/adaptation/domain/models/day_compliance.dart`),
and nothing else may restate it.

**The keto ratio does not decide compliance**, and until #303 it did:
`ketoRatioAvg >= 2.0`. Since the ratio is `fat / (netCarbs + protein)`, protein
sat in the denominator beside carbs, so a disciplined 8 g-carb day with 90 g of
protein scored 0.31 and broke the streak while 100 g of fat with 50 g of carbs
scored exactly 2.0 and passed. The ratio keeps every other job it has — the
ring arc, the macro card, `DailyLog.ketoRatioAvg`.

**The counter is derived, not accumulated.** `AdaptationPhaseService.recomputeFor`
walks back over `DailyLog` from today on every write, so a retroactive edit is
honoured by construction rather than by back-dated arithmetic.

**Notification trigger:** `flutter_local_notifications` fires a warning at 20:00 if no meal logged that day.

---

## 4. Dashboard & Data Visualisation

### Problem
Show macro progress rings, streak rings, trend sparklines, and electrolyte gauges in a performant, RTL-aware way.

### Candidates

| Option | Pros | Cons |
|---|---|---|
| `fl_chart` | Best-in-class Flutter charts, arc/line/bar, actively maintained | Verbose API for custom arcs |
| `syncfusion_flutter_charts` | Rich features, good docs | Commercial licence required for production |
| `charts_flutter` (Google) | Simple | Deprecated, unmaintained |
| Custom `CustomPainter` | Full control, zero dependencies | More code to maintain |

**Recommended:** `fl_chart` for trend charts and bar charts; `CustomPainter` for the streak ring (keto ratio arc)

**Rationale:** `fl_chart` handles sparklines and bar charts cleanly. The streak ring is a single arc widget — `CustomPainter` is simpler and gives full design control without workarounds.

### Animations
- `flutter_animate` for sequential card entrance animations
- Streak ring fills via `AnimatedBuilder` + `Tween<double>`

---

## 5. Restaurant Directory

### Problem
Curate and serve a directory of keto-friendly Israeli restaurants with map integration, filtering, and offline access.

### Candidates for Data Source

| Option | Pros | Cons |
|---|---|---|
| Bundled static JSON | Fully offline, fast, version-controlled | Manual updates required; no community contributions |
| Firestore remote config | Real-time updates, scalable | Network required; setup complexity |
| Supabase (PostgreSQL) | SQL queries, open-source backend | Server infra to maintain |
| Google Places API | Rich data | Not keto-curated; API cost per call |

**Recommended (v1):** Bundled static JSON, served from `assets/data/directory.json`, cached in a `DirectoryEntry` store on first load. Future: Firestore for real-time community updates.

### Map Integration

| Option | Pros | Cons |
|---|---|---|
| `google_maps_flutter` | Rich, familiar API, Hebrew support | Requires API key, billing, Google dependency |
| `flutter_map` (Leaflet) | Open-source, no API key needed | Less polished; custom tile server needed for Hebrew tiles |
| `mapkit_flutter` (Apple MapKit) | Native iOS quality, Hebrew labels, free | iOS-only (fits our scope), newer Flutter plugin less mature |

**Recommended:** `mapkit_flutter` (Apple MapKit)

**Rationale:** iOS-only app, no API key, Hebrew place labels out of the box, better battery performance than Google Maps.

---

## 6. Restaurant Menu Analyzer

### Problem
Point the camera at a physical restaurant menu and get per-dish keto suitability estimates.

### Candidates

| Option | Pros | Cons |
|---|---|---|
| MLKit OCR → rule-based dish matching | Fully offline | Accuracy limited without NLP context |
| MLKit OCR → Claude API for analysis | High accuracy, understands Hebrew culinary terms | Network required, API cost |
| Vision + Core ML custom model | Native, offline | Requires custom model training for Israeli dishes |

**Recommended (v1):** MLKit OCR + rule-based matching using a curated dish database  
**Recommended (v2):** Optional Claude API analysis for ambiguous dishes when network is available

**Rationale:** Most restaurant menus have recognisable dish patterns (שיפודים, חומוס, סלט, etc.). Rule-based matching covers 70–80% of cases offline. Claude API as an opt-in enhancement for v2 keeps the app functional without network.

---

## 7. Recipe Converter

### Problem
Take an arbitrary recipe (Hebrew or English text) and produce a keto-equivalent with ingredient substitutions and updated macros.

### Candidates

| Option | Pros | Cons |
|---|---|---|
| Rule-based substitution engine (local) | Fully offline, predictable | Handles only known ingredients |
| Claude API (AI conversion) | Handles arbitrary recipes, understands context | Network required, API cost, latency |
| Hybrid: local rules + AI fallback | Best of both worlds | More complex |

**Recommended:** Hybrid — local `SubstitutionRuleEngine` for common ingredients, Claude API (Haiku, cheapest) for unrecognised ingredients when network is available.

**Local substitution table (sample):**
```
flour (קמח)          → almond flour (קמח שקדים) + psyllium husk
sugar (סוכר)         → erythritol / allulose
canola/soy oil       → olive oil / butter / ghee
breadcrumbs          → crushed pork rinds / almond meal
milk (250ml)         → unsweetened almond milk (240ml)
potato (תפוח אדמה)   → turnip / celeriac / cauliflower
cornstarch           → xanthan gum (⅛ ratio)
```

**API call structure (when online):**
```
POST /v1/messages (claude-haiku-4-5)
System: "You are a keto diet expert. Convert this recipe ingredient list to keto-compliant substitutes..."
```

---

## 8. Biomarker & Symptom Diary

### Problem
Log blood/breath ketones, glucose, body weight, and subjective symptoms over time, then display trends.

### Candidates

| Option | Pros | Cons |
|---|---|---|
| Pure local storage | Offline, fast, private | Manual entry only |
| HealthKit integration | Auto-imports weight, glucose (if CGM paired) | iOS-only (fits scope), requires HealthKit entitlement |
| Dexcom / Abbott API | Real-time CGM data | Very few Israeli users have CGM; complex OAuth |

**Recommended:** local storage as primary + HealthKit read for body weight and write for active energy.

**HealthKit quantities to integrate:**
- Read: `HKQuantityTypeIdentifierBodyMass` (body weight)
- Read: `HKQuantityTypeIdentifierBloodGlucose` (if user has CGM)
- Write: `HKQuantityTypeIdentifierDietaryFatTotal`, `...DietaryCarbohydrates`, `...DietaryProtein`

**Flutter package:** `health` (pub.dev) — wraps HealthKit cleanly.

**Trend Visualisation:** `fl_chart` `LineChart` for ketones and glucose over 30 days; `BarChart` for weight.

---

## 9. State Management (Cross-Feature)

### Candidates

| Option | Pros | Cons |
|---|---|---|
| Riverpod (code-gen) | Compile-safe, testable, scales well, no `BuildContext` required | Learning curve |
| BLoC | Well-established | Verbose; `BuildContext` still needed in some cases |
| Provider | Simple | Global state gets messy at scale |
| MobX | Reactive, less boilerplate than BLoC | Smaller community; less Flutter-idiomatic |

**Recommended:** `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`

**Rationale:** Compile-time safety, no `BuildContext` in services, first-class async support, and the code-generation workflow is the only one left in the project (sembast needs no generator).

---

## 10. Local Notifications

### Problem
Remind users to log meals, warn about streak risk, and prompt daily symptom check-ins.

### Candidates

| Option | Pros | Cons |
|---|---|---|
| `flutter_local_notifications` | Most complete, iOS + Android, rich API | Verbose setup |
| `awesome_notifications` | Rich UI notifications | Larger dependency |
| `notification_permissions` + `UserNotifications` (native) | Fully native | Requires platform channels |

**Recommended:** `flutter_local_notifications`

**Notification schedule:**
- 08:00 — "בוקר טוב! אל תשכח להתחיל לרשום" (morning log reminder)
- 20:00 — if no meal logged: "יש לך 4 שעות לשמור על הסטריק שלך" (streak risk warning)
- On-demand: symptom check-in prompt after meal log

---

## 11. Routing & Navigation

### Candidates

| Option | Pros | Cons |
|---|---|---|
| `go_router` | Declarative, deep link support, maintained by Flutter team | Slight learning curve for shell routes |
| `auto_route` | Code-generated, type-safe | More setup; another generator to run |
| `Navigator 2.0` directly | Full control | Extremely verbose |

**Recommended:** `go_router`

---

## 12. Camera

### Candidates

| Option | Pros | Cons |
|---|---|---|
| `camera` | Low-level control, live preview, torch control | More setup code |
| `image_picker` | Simple one-shot capture | No live viewfinder; less control |

---

## Macro estimation (M15)

The app's **first and only outbound network call**, added by M15. It is a
different feature from Keto Lens and **does not relax Keto Lens's no-network
invariant**: a scan still makes no request, everything it needs is bundled,
and Epic #10's first architectural invariant forbids adding one. See
`design/m15_meal_entry_research.md` §4.

| Concern | Choice | Why |
|---|---|---|
| The seam | `LlmChatClient` (interface) | The destination is **known to be temporary**. BYOK ships now because the free tier is 50 requests/day *per key*; our own backend replaces it later, and that swap must be a new implementation of this interface and nothing else — no change to the estimator, the prompt, the parser or any widget |
| Transport | `http` ^1.2.0 | Already a dependency. One `post`, behind the client |
| Provider | OpenRouter, named in exactly **two** files | `open_router_client.dart` and the one provider that constructs it. A domain interface that named it would be the first crack in the invariant it exists to hold |
| Credentials | The user's own key, in its own `estimation_settings` sembast store | **Never in `user_profile`**, whose record existence is the first-launch sentinel. A key shipped inside the app would be exhausted by a handful of users before lunch, and a key in a Flutter bundle is extractable anyway |
| Image budget | `image` ^4.3.0 → 1024 px longest edge, JPEG q80, 3 MB ceiling | Already a dependency. The **opposite** of `OcrImagePrep`, which scales *up* for Tesseract's LSTM |
| Failure shape | Sealed `MealEstimate` / `ChatResult` | The same reason `ScanResult` is sealed: a failure must not be expressible as a degenerate success |

**What the user is told, and when.** Estimation is opt-in behind a consent
checkbox in Profile, with an always-visible disclosure. When it is on, a
meal **description** and, in photo mode, a **downscaled photograph** are sent
to the configured provider. Nothing else leaves the device, and nothing at
all leaves it while estimation is off.

**Recommended:** `camera` for the Keto Lens (needs live viewfinder + torch) + `image_picker` as a fallback for gallery import.

---

## 13. Dependency Injection & App Initialisation

All dependencies are wired via Riverpod providers. `main.dart` is responsible only for:
1. Opening the database
2. Requesting HealthKit authorisation (if granted in settings)
3. Registering notification handlers
4. Wrapping the app in `ProviderScope`

No service locator (`get_it`) is used — Riverpod handles all injection.

---

## Full Dependency List (pubspec.yaml candidates)

```yaml
# NOTE: this block is the original pre-M0 evaluation, not the shipped
# pubspec.yaml. Five entries below did not survive contact with a real
# resolve — see design/m0_handoff.md §1-§3. The authoritative list is
# pubspec.yaml itself, which is now committed alongside pubspec.lock.
#
#   isar / isar_flutter_libs / isar_generator  ->  isar_community*  ^3.3.2
#                                              ->  then sembast ^3.8.10 +
#                                                  sembast_web ^2.4.6 when web
#                                                  support landed; Isar 3 cannot
#                                                  open a database in a browser
#                                                  at all. See
#                                                  design/web_support.md.
#   flutter_riverpod / riverpod_* ^2.x         ->  ^3.0.2
#   riverpod_test                              ->  dropped; use
#                                                  ProviderContainer.test()
#   json_serializable                          ->  never added; nothing uses
#                                                  @JsonSerializable
#   meta                                       ->  added (#156), needed for
#                                                  @immutable in domain/

dependencies:
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  sembast: ^3.8.10
  sembast_web: ^2.4.6
  go_router: ^14.x
  google_mlkit_text_recognition: ^0.x
  camera: ^0.x
  image_picker: ^1.x
  image: ^4.x
  fl_chart: ^0.x
  flutter_animate: ^4.x
  health: ^10.x
  flutter_local_notifications: ^17.x
  mapkit_flutter: ^0.x
  anthropic_sdk_dart: ^0.x          # recipe converter AI fallback
  path_provider: ^2.x
  share_plus: ^9.x

dev_dependencies:
  riverpod_generator: ^2.x
  build_runner: ^2.x
  json_serializable: ^6.x
  mocktail: ^1.x
  riverpod_test: ^2.x
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```
