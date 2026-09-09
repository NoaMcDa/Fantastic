# Fantastic
All-in-one clean keto companion built with Flutter. Features on-device Hebrew label OCR, true keto ratio &amp; electrolyte tracking, adaptation phases &amp; streaks, restaurant menu analyzer with dining tips, recipe converter, biomarker/symptom diary, and a curated deli directory.


## Key Features

* **Keto Lens (Hebrew OCR Scanner):** On-device camera scanning of Israeli nutritional labels and ingredient lists. Detects net carbs, flags industrial seed oils (canola, soybean, corn, sunflower), and identifies hidden sweeteners (e.g., maltitol, dextrose).
* **Keto Ratio & Electrolyte Dashboard:** Computes the true ketogenic ratio:
  $$\text{Keto Ratio} = \frac{\text{Fat (g)}}{\text{Net Carbs (g)} + \text{Protein (g)}}$$
  Monitors sodium, potassium, and magnesium thresholds to prevent keto flu.
* **Keto Streak & Adaptation Engine:** Tracks consecutive days in ketosis, adjusts streaks dynamically upon threshold breaks, and maps user progress across biological phases (Induction $\rightarrow$ Fat Adaptation $\rightarrow$ Deep Ketosis).
* **Keto Dining Assistant:** Parses restaurant menus to recommend compliant dishes, custom ingredient swaps, and specific inquiries for waiting staff.
* **KetoSwap Engine:** Converts standard recipes into 100% whole-food keto alternatives with precise baking ratios and natural sweetener equivalents.
* **Symptom & Biomarker Diary:** Correlates blood/breath ketone levels and weight against subjective logs (mental clarity, physical energy, hunger signals, sleep quality).
* **Curated Keto Directory:** Direct links, addresses, and recommendations for specialty keto delis, whole-food butcheries, and clean pantry staples in Israel.

---

## Tech Stack & Architecture

* **Framework:** Flutter (Targeting iOS native performance via Xcode)
* **Language:** Dart
* **Architecture:** Feature-first layered architecture (Presentation, Application, Domain, Data)
* **State Management:** Riverpod
* **Local Persistence:** Isar Database / Hive (Fast, offline-first NoSQL storage)
* **Machine Learning / OCR:** `google_mlkit_text_recognition` (On-device text processing with Hebrew script support)
* **Data Visualization:** `fl_chart`

---

## Project Roadmap & Tasks

### Milestone 1: Core Foundation & Local Persistence
- [ ] Initialize Flutter project configured for iOS deployment (`fantastic`).
- [ ] Set up Isar/Hive local schemas:
  - `MealEntry`: Macros, ingredients, timestamp, image reference.
  - `DailyLog`: Net carbs, total fats, protein, water, sodium, potassium, magnesium.
  - `SymptomLog`: Energy level (1-5), mental clarity (1-5), hunger rating, physical symptoms.
  - `BiomarkerLog`: Blood/breath ketones, fasting glucose, body weight.
  - `StreakState`: Current streak, highest streak, phase enumeration, last reset timestamp.
- [ ] Implement base repository layer with full CRUD operations.

### Milestone 2: Nutrition Engine & Keto Streak Tracking
- [ ] Implement mathematical calculations for net carbs and macronutrient ratios.
- [ ] Build streak calculation service:
  - Increments on compliant net-carb and fat-ratio days.
  - Handles reset or grace-period workflows on threshold breaks.
- [ ] Build adaptation phase state machine:
  - **Phase 1 (Days 1–7):** Induction & Keto-Flu Management.
  - **Phase 2 (Days 8–28):** Fat-Adapted Transition.
  - **Phase 3 (Days 28+):** Deep Ketosis & Long-Term Maintenance.
- [ ] Implement customizable push alerts for electrolyte replenishment and streak updates.

### Milestone 3: OCR Scanner (Keto Lens)
- [ ] Integrate camera controller and `google_mlkit_text_recognition`.
- [ ] Build Hebrew text normalization and regex parsing pipeline for standard Israeli nutritional tables.
- [ ] Implement rule-based ingredient verification engine:
  - **Forbidden Seed Oils:** Canola, soybean, corn, sunflower, cottonseed, safflower.
  - **Insulin-Spiking Sweeteners:** Maltitol, sorbitol, dextrose, maltodextrin, high-fructose corn syrup.
  - **Clean Approvals:** Olive oil, avocado oil, coconut oil, butter, ghee, tallow, monk fruit, stevia, allulose, erythritol.
- [ ] Design instant feedback UI badge: `Clean Keto`, `Caution / Quantity Dependent`, or `Non-Keto`.

### Milestone 4: Restaurant Dining Assistant & Recipe Converter
- [ ] Create UI for pasting or capturing restaurant menu items.
- [ ] Develop heuristic parser to detect concealed starches, glazes, breading, and dressings.
- [ ] Implement actionable suggestion generator (e.g., "Substitute fries for leafy greens dressed in extra virgin olive oil and lemon on the side").
- [ ] Build pre-filled question checklist for restaurant staff (grilling fat type, marinade sugar content).
- [ ] Develop **KetoSwap Engine** conversion tables:
  - Wheat flour $\rightarrow$ Almond flour / Coconut flour ratios.
  - Refined sugars $\rightarrow$ Clean natural sweeteners (sweetness equivalency scale).

### Milestone 5: Symptom & Biomarker Analytics
- [ ] Build quick-entry interface for daily subjective feelings and ketone measurements.
- [ ] Create correlation visualization screens using `fl_chart`:
  - Ketone levels vs. reported mental clarity.
  - Sodium/water intake vs. keto-flu symptoms (headache, fatigue, muscle cramps).
- [ ] Add CSV export for personal health records.

### Milestone 6: Specialty Directory & Polish
- [ ] Implement category-based UI for Israeli keto resources (Delis, clean butcheries, bakeries, specialty importers).
- [ ] Add bookmarking functionality for favorite products and locations.
- [ ] UI/UX polishing for iOS human interface guidelines (haptics, smooth transitions, dark mode support).
