# M10 — Recipe Converter: research, pre-flight, and the milestone plan

**Source:** Epic #265 and its three children #118, #119, #120, audited against
the tree at `4225d30` (M15 closed).
**Status:** research complete; issues rewritten and filed per §9.
**Read before:** picking up any M10 issue, and before writing a substitution
rule that nobody with a nutrition background has looked at.

---

## 0. Verdict, in one paragraph

M10 as filed is **three issues that build a screen nobody can reach, from an
engine that cannot produce one of the three answers its own tests demand, on a
rationale that M15 has since made false.** None of #118–#120 is redundant —
nothing here has shipped — but all three need rewriting, the Epic's scope
statement is stale on two counts, and the milestone is missing four issues it
cannot close without: an entry point, a data-layer slice, an end-to-end flow,
and the two one-file promotions to `lib/core/` that the layer rules force. The
substantive design change is that **M10 becomes the hybrid `design/technology.md`
§7 asked for in the first place** — a deterministic, offline rule table first,
and the `LlmChatClient` seam M15 built as an opt-in second pass for the lines the
table does not know. §9 lists the nine issues in build order; §11 marks the line
the product owner can cut at.

---

## 1. What the issue text gets wrong

Seven findings. Three would compile and ship wrong behaviour; four are plan
defects that would send an implementer back to the author.

### 1.1 Nothing navigates to `/recipe`, and no issue adds anything that does

`app_router.dart:100` registers `/recipe` → `RecipePlaceholder`, **outside the
`ShellRoute`**. A grep for every `context.go`, `context.push` and `.go(` in
`lib/` finds the tab bar, the onboarding flow and the phase badge — nothing
reaches `/recipe`. On web a user can type the URL; on the five native targets
the route does not exist as far as any user is concerned.

#119 Step 3 says *"Route this screen in place of `recipe_placeholder.dart`"*
and stops. That ships a screen at an address with no door. `design/user_bugs_handoff.md`
recorded exactly this shape as the first defect a real user found: *"a flow
that exercises one route to a capability is not a test that the capability is
reachable."* The diary shipped without a `+` while a green suite exercised the
dashboard's.

**Correction:** an entry point is part of #119, not a nicety, and the e2e
navigation smoke has to go through it. §7.1 has the recommendation and the
alternative.

### 1.2 `AlreadyKeto` has no data behind it

#118's engine is `SubstitutionEngine({Map<String, Substitution>? rules})` — one
table, of *substitutions*. Its tests include `'classify: a known-keto ingredient
(ביצים, חמאה) returns AlreadyKeto'`. **No table in the issue holds ביצים.**
`IngredientRules.allCleanIngredients` holds seven fats and five sweeteners —
no egg, no meat, no vegetable, no salt — so even reading it (which #118 does
not say to) cannot produce the outcome for eggs. As specified, the only way to
return `AlreadyKeto` is to not match, and the issue forbids that in the very
next line: *"an unknown ingredient returns `Unrecognised`, never `AlreadyKeto`."*

The consequence is not a failed test. It is that a real recipe — eight to
fifteen lines, most of them ביצים, מלח, שמן זית, בצל, עגבניות, גבינה — comes
back **mostly `Unrecognised`**. A converter whose output is 80% "we do not
know" trains the user to ignore the unknown marker, which is precisely how
`design/m6_handoff.md` says a warning stops working.

**Correction:** the engine needs a second table — keto staples — and §5.2
specifies it. `Unrecognised` is then genuinely rare, and it means something.

### 1.3 The LLM rejection cites an invariant that does not apply and an objection M15 answered

#118's *Approach summary* rejects a model on three grounds:

> `CLAUDE.md` states OCR and classification run on-device with no network
> call; `design/technology.md` rejected network dependencies for core
> features; a table is testable against fixtures where a model response is not.

Each was true when written and each is now wrong or inapplicable:

- The no-network invariant is **Keto Lens's** (Epic #10), and `CLAUDE.md`
  states in the same section that M15's estimation *"is a different feature
  and does not relax that."* A recipe converter is a third feature. Nothing
  about a scan changes if a recipe line is sent anywhere.
- The recipe converter is not a core feature. `design/mvp.md` lists it as
  *"nice-to-have; adds complexity without proving core loop."*
- M15 shipped the testing pattern: `LlmChatClient` is an interface, every
  test and every e2e flow fakes it, and `design/m15_meal_entry_research.md`
  §10 records that **no test in the milestone makes a request**. The
  fixture objection is answered by construction.

And `design/technology.md` §7 — the document #118 cites — never recommended
rules-only. Its recommendation is **"Hybrid — local `SubstitutionRuleEngine`
for common ingredients, [a model] for unrecognised ingredients when network is
available."** #118 dropped the second half because it had no way to build it.
M15 built it: `LlmChatClient`, `OpenRouterClient`, BYOK credentials, the
consent flag, the settings section on the Profile tab, and the per-reason
Hebrew failure copy. §5.4 specifies the second pass.

### 1.4 "Macro calculation needs a food database" is stale

Epic #265 puts *"Macro calculation for a converted recipe — needs a food
database, which is not planned for any current milestone"* out of scope. M15
shipped `MacroEstimator`, which turns a Hebrew description into itemised
macros with no food database at all. A converted recipe's ingredient list
**is** a Hebrew description. `design/ui_ux_design.md` §8 wants *"macro totals
for original vs. keto version (per serving)"* and a save to the library, and
the one thing that would connect M10 to the app's core loop — **logging a
serving of the converted recipe as a meal** — is one `MacroEstimator.estimate`
call and one `AddMealBottomSheet.show` with `MacroSource.estimatedFromText`.

**Correction:** in scope as the last issue (§9, issue 9), with the per-serving
rule that keeps it from being #257 in a new coat. It is also the one issue the
owner can defer without breaking the milestone; §11.

### 1.5 "Reuse the shipped normaliser" from `domain/` is a layer violation

#118 Step 1: create `lib/features/recipe/domain/hebrew_text_normaliser.dart`
*"or reuse the shipped one"* at
`lib/features/keto_lens/data/parsers/hebrew_text_normaliser.dart`. A `domain/`
file importing another feature's `data/` breaks `issue_conventions.md` §3
twice over (domain imports nothing from the project; data is imported by
nobody above it). The issue's own fallback — promote it to `lib/core/` — is the
only legal option, and it is a refactor with its own test file move, so it is
its own issue (§9, issue 1).

**A trap for whoever does it.** #118 also asks for **final-form folding**
(ך→כ, ם→מ, ן→נ, ף→פ, ץ→צ) as normaliser rule 3. **Do not add it to the shared
`normalise`.** `IngredientClassifierImpl` matches `IngredientRules` entries by
`contains` on the normalised input, and `מלטודקסטרין` ends in a final nun.
Folding the input to `מלטודקסטרינ` while the rule keeps `מלטודקסטרין` makes
the insulin-spiking sweetener rule silently stop firing on every label that
prints it — a Keto Lens regression from a recipe-converter refactor, caught by
no test that exists today. Folding belongs inside the substitution engine,
applied to **both** the alias table and the input (§5.1).

### 1.6 #120 is labelled `layer:presentation`, selects `layer:data`, and cites a model that does not exist

Its body ticks `layer:data`; its label is `layer:presentation`. Its approach
summary says *"`DailyLog`, `SymptomLog` and `BiomarkerLog` are keyed on
`dateIndex`"* — `BiomarkerLog` is M9's, unshipped. And it argues against its
own split: *"splitting would leave a repository with no consumer — which §1.3
forbids as a partial implementation."* M1 shipped every repository in the app
with no consumer, by design (*"no UI, no services"*), and `milestone_conventions.md`
§1.3 forbids a PR that leaves `main` red, not a repository nobody reads yet.

**Correction:** #120 keeps its title and label and becomes the screen; a new
`layer:data` issue takes the model, repository, mapper and store (§9, issue 4).

### 1.7 Two "different answers" are collapsed into one

The Epic's invariant is right that *"already keto" and "not recognised" are
different answers*. There is a third the issue never names: **known non-keto
with no substitute**. `מלטיטול` in a recipe is on `IngredientRules`'
insulin-spiking list, so the app *knows* it is a problem — but #118's table
has no swap for it, so it renders `Unrecognised`: "we do not know", when the
truth is "leave it out". A fourth sealed variant, `Flagged`, costs one `case`
at every exhaustive switch and says the true thing.

---

## 2. What the codebase already gives M10

| Asset | Where | M10 use |
|---|---|---|
| Hebrew normalisation — niqqud, bidi controls, geresh, decimal comma, whitespace | `keto_lens/data/parsers/hebrew_text_normaliser.dart` (118-line test) | Promoted to `lib/core/utils/`; the engine's first step |
| `stripPrefix` — one inseparable prefix, ≥4 letters, additive | same file | The `הקמח` → `קמח` retry, exactly as the classifier uses it |
| The forbidden / sweetener / clean lists, both languages | `lib/core/constants/ingredient_rules.dart` | The consistency oracle for every replacement, and the source of `Flagged` |
| `LlmChatClient` + sealed `ChatResult` + provider-agnostic `ChatFailureReason` | `diary/data/estimation/llm_chat_client.dart` | Promoted to `lib/core/llm/`; the second pass's transport |
| `OpenRouterClient`, `UserApiKeyCredentials`, `llmChatClientProvider` | `diary/data/` | Reused as-is; **not** moved — see §5.4 |
| `EstimationSettings.isEnabled`, the consent disclosure, the Profile section | `diary/domain/models/estimation_settings.dart`, `profile/…/estimation_settings_section.dart` | The one gate; the disclosure text gains one clause |
| `EstimateResponseParser`'s posture — fence stripping, `num` decode, `NumericInput.positiveFinite`, bounded lists, "nothing is an instruction" | `diary/data/estimation/estimate_response_parser.dart` | The template for the suggestion parser |
| `EstimateFailureView` — one Hebrew headline and one escape per reason | `diary/presentation/widgets/estimate_failure_view.dart` | The pattern for the suggester's failure copy |
| `MacroEstimator` + `EstimateReviewList` + `AddMealBottomSheet.show(... source:)` | diary | Issue 9: per-serving macros and "log as a meal" |
| Auto-increment store, upsert `save`, `guardPersistence`, `store_names_test` | `sembast_meal_repository.dart` | The template for `saved_recipes` |
| `.name` enum storage with a null-tolerant fallback | `meal_entry_mapper.dart` `_sourceOf` | The outcome discriminator and `OutcomeSource` |
| `listEquals` / `listHash` | `lib/core/utils/list_equality.dart` | `SavedRecipe.==` over its outcome list |
| Static skeletons, `EmptyStateWidget`, `hasError` before `hasValue` | `profile_screen.dart` | The library screen's three states |
| `GramsText.format` | `lib/core/utils/numeric_input.dart` | The ratio-adjusted quantity, one decimal |
| The e2e harness, fake-at-the-interface, zero-call assertions | `integration_test/helpers/app_harness.dart`, `add_meal_photo_flow.dart` | The recipe flow, and the "no request when not configured" proof |

**The two dead ends in the placeholder are the whole feature directory.**
`lib/features/recipe/` holds one nine-line widget. Everything below is new
files.

---

## 3. What a converter is for, and what it must never do

A keto converter's failure mode is a *plausible* wrong answer, the same shape
`design/m15_meal_entry_research.md` §3 measured for the estimator and #257
measured for the scan. Three of its rules carry straight over and two are new:

1. **A ratio is applied to the quantity, always.** Almond flour for wheat
   flour at 1:1 is a common rule; coconut flour is a quarter. `2 כוסות קמח` at
   0.25 must render `0.5 כוסות`, not `2 כוסות` of the replacement — #119 already
   calls this the most damaging possible bug on the screen, and it is right.
2. **Unknown, already-fine, and known-bad are three visibly different
   answers.** Collapsing any two lets a bad ingredient render as approved or a
   good one render as suspect.
3. **The app never contradicts itself.** Every replacement — from the table or
   from a model — is checked against `IngredientRules`. If the converter
   recommends what Keto Lens flags, one of them is lying.
4. **A model's suggestion is labelled as one, in the row.** Same reasoning as
   `MacroSource`: a week later, in the library, the user must be able to tell a
   curated rule from a guess. `OutcomeSource { rule, suggested }`.
5. **A recipe is a batch, not a meal.** When a serving of the converted recipe
   is logged (issue 9), the macros are divided by the servings count the user
   enters, never logged whole. Logging a whole cake as one meal is #257 with the
   sign reversed.

---

## 4. The engine decision

Four shapes were considered.

| | Rules only (as filed) | **Hybrid: rules, then model for the rest** | Model only | Model with rules as a post-check |
|---|---|---|---|---|
| Works with no key, offline | Yes | **Yes** — the first pass is complete on its own | No | No |
| Deterministic for the common pantry | Yes | **Yes** | No — two runs, two answers | No |
| Coverage of a real 12-line recipe | Poor without a staples table; fair with one | **Good** | Good | Good |
| Requests per recipe | 0 | **0 or 1** — one batched call for the unrecognised lines only | 1 | 1 |
| Testable without a network | Yes | **Yes** — the M15 pattern | Yes, but every behaviour is a fake's | Yes |
| Consistency with Keto Lens enforceable | Yes | **Yes — on both passes** | Only as a post-check | Yes |
| What leaves the device | Nothing | **Only the lines the table did not know**, only when the user asks | The whole recipe | The whole recipe |

> ### Decision: hybrid, deterministic first, and the deterministic half ships alone before the model half exists
>
> This is `design/technology.md` §7's recommendation, buildable now because
> M15 built the half #118 could not. The rule table plus a staples table is a
> complete, offline, key-less converter and is the milestone's first shippable
> state (issues 1–3 in §9). The model pass is additive: it consumes
> `Unrecognised` lines only, one request per tap, gated on the same
> `EstimationSettings.isEnabled` the estimator uses, and every replacement it
> proposes goes through the same `IngredientRules` check the table does.
>
> **Rejected: model only.** It removes the offline, key-less path entirely and
> makes every answer non-deterministic, including קמח → קמח שקדים, which no
> user should need a key or a network to be told.
>
> **Rejected: rules only.** §1.2 — with a staples table it is usable, and it is
> what issue 3 ships; without the second pass it has no answer for סילאן
> variants, brand names, or anything the twelve-row seed table did not
> anticipate, and its honest answer to those is a screen full of "unknown".

The two passes share one sealed result type and one provenance enum, so the
screen renders both with one exhaustive switch and the mapper stores both with
one codec.

---

## 5. Architecture

### 5.1 The deterministic engine — `lib/features/recipe/domain/`

```
paste → split lines → IngredientLineParser → ParsedIngredient
      → SubstitutionEngine.classify:
          key = foldFinals(lower(normalise(name)))
          1. substitution aliases   exact → whole-word longest → stripPrefix retry   → Substituted(rule)
          2. staple aliases         same procedure                                   → AlreadyKeto(rule)
          3. IngredientRules        contains, as the classifier does                 → Flagged
          4.                                                                         → Unrecognised
```

- **`HebrewTextNormaliser.normalise` runs first and is not modified.** It
  lives in `lib/core/utils/` after issue 1. Final-form folding is a private
  step of the engine applied to both sides — §1.5 has the regression it
  would cause anywhere else.
- **Aliases, not stemming.** Singular and plural are listed (`ביצה`, `ביצים`;
  `תפוח אדמה`, `תפוחי אדמה`). A fuzzy or morphological matcher is what maps
  `סולת` to `סלט`; #118 was right to refuse it.
- **Whole-word, longest alias first.** `קמח כוסמין` must reach its own row
  before `קמח` can claim it. Whole-word rather than bare substring, so `סלט`
  cannot fire inside `סלטים` if a `סלט` alias is ever added.
- **`stripPrefix` is the shipped one**, additive, on the first word only, and
  tried after the exact forms fail — the classifier's rule, for the
  classifier's reason.
- **Exact after normalisation, no corrupted-letter tolerance.** Pasted text is
  typed, not OCR'd. `HebrewLabelParser`'s one-letter absorption exists for
  Tesseract and would be wrong here.
- **Never throws.** An unparseable line is `ParsedIngredient(name: line,
  quantity: null)`. An empty list converts to an empty list.

### 5.2 The tables — `lib/core/constants/substitution_rules.dart`

Beside `ingredient_rules.dart`, same kind of data, same place. Plain Dart
records so `lib/core/` imports nothing from a feature:

```dart
typedef SubstitutionRow = ({
  List<String> aliases,   // Hebrew and English, singular and plural, lowercase
  String replacement,
  double ratio,           // quantity multiplier; 0.25 = a quarter as much
  String reason,          // one short Hebrew line
});

abstract final class SubstitutionRules {
  static const List<SubstitutionRow> substitutions = [ /* §5.2.1 */ ];
  static const List<String> ketoStaples = [ /* §5.2.2 */ ];
}
```

#### 5.2.1 The seed substitutions

#118's eleven rows, corrected and extended. **Nobody with a nutrition
background has reviewed this table**, and every row is a seed to be revised,
not a fact — §10.

| Aliases | Replacement | Ratio | Reason |
|---|---|---|---|
| קמח · קמח לבן · קמח חיטה · flour · wheat flour | קמח שקדים | 1.0 | עתיר פחמימות |
| קמח כוסמין · קמח מלא · spelt flour · whole wheat flour | קמח שקדים | 1.0 | עתיר פחמימות |
| קמח תירס · cornflour · cornstarch · קורנפלור | קסנטן גאם | 0.125 | עמילן טהור; מסמיך חזק בהרבה |
| סולת · semolina | קמח שקדים גס | 1.0 | עתיר פחמימות |
| פירורי לחם · breadcrumbs | קמח שקדים | 1.0 | עתיר פחמימות |
| סוכר · סוכר לבן · סוכר חום · sugar · brown sugar | אריתריטול | 1.0 | מעלה אינסולין |
| אבקת סוכר · powdered sugar · icing sugar | אריתריטול טחון | 1.0 | מעלה אינסולין |
| דבש · סילאן · מייפל · סירופ מייפל · honey · maple syrup · date syrup | סירופ אריתריטול | 1.0 | סוכר נוזלי |
| תפוח אדמה · תפוחי אדמה · potato · potatoes | קולורבי | 1.0 | עתיר עמילן |
| בטטה · sweet potato | דלעת | 1.0 | עתיר עמילן |
| אורז · rice | אורז כרובית | 1.0 | עתיר פחמימות |
| פסטה · ספגטי · אטריות · pasta · spaghetti · noodles | נודלס קישוא | 1.0 | עתיר פחמימות |
| חלב · milk | שמנת מתוקה מדוללת במים | 1.0 | לקטוז |
| מרגרינה · margarine | חמאה | 1.0 | שומן מעובד |
| שמן קנולה · שמן סויה · שמן תירס · שמן חמניות · שמן צמחי · canola oil · soybean oil · corn oil · sunflower oil · vegetable oil | שמן זית | 1.0 | שמן זרעים מעובד |
| לחם · לחמניה · לחמניות · פיתה · bread · pita | לחם שקדים | 1.0 | עתיר פחמימות |

Changes from #118's table, and why:

- **`קמח כוסמין → קמח קוקוס` at 0.25 became `קמח שקדים` at 1.0.** Spelt is a
  wheat; there is no reason it takes a different substitute from wheat flour,
  and a reader would be right to ask why one flour becomes almond and the next
  coconut. Coconut flour at ¼ is a legitimate rule for *any* flour, but it
  needs added egg and liquid to work — too much to say in one reason line.
- **`סירופ נזיר` became `סירופ אריתריטול`.** "Monk fruit syrup" is a category,
  not an Israeli shelf product, and several commercial monk-fruit syrups are
  blended with maltitol — which `IngredientRules` flags. The consistency test
  in §5.3 cannot check a product name against a blend; naming the sweetener
  itself avoids the question.
- **Sunflower oil was missing from the oils row** while `IngredientRules`
  forbids it. Added, plus the unspecified `שמן צמחי` the classifier already
  cautions on.
- **Cornstarch, powdered sugar, sweet potato, bread and pita added.** They are
  in `design/technology.md` §7's sample or in every second Israeli recipe.

#### 5.2.2 The staples list

What `AlreadyKeto` is drawn from. Not a nutrition database — the fifty or so
things an Israeli recipe names that need no substitute:

- **Eggs, dairy, fats:** ביצה · ביצים · חמאה · שמנת · שמנת מתוקה · שמנת חמוצה · גבינה · גבינה צהובה · גבינת שמנת · גבינה לבנה · קוטג' · פרמזן · מוצרלה · פטה · בולגרית · לאבנה · שמן זית · שמן קוקוס · שמן אבוקדו · גהי · טחינה גולמית · butter · cream · cheese · olive oil · coconut oil
- **Protein:** עוף · חזה עוף · שוקיים · בקר · טחון · כבש · דג · סלמון · טונה · שרימפס · הודו · chicken · beef · fish · salmon · tuna
- **Keto flours and thickeners (so a recipe already converted reads as fine):** קמח שקדים · קמח קוקוס · פסיליום · קסנטן גאם · אריתריטול · סטיביה · almond flour · coconut flour · erythritol · stevia
- **Vegetables:** כרובית · קישוא · קישואים · ברוקולי · תרד · חסה · מלפפון · פטריות · פלפל · בצל ירוק · שום · אבוקדו · זיתים · עגבניה · עגבניות · בצל · cauliflower · zucchini · spinach · mushrooms · garlic · avocado
- **Seasoning and the rest:** מלח · פלפל שחור · כמון · פפריקה · כורכום · אבקת אפייה · סודה לשתייה · וניל · תמצית וניל · לימון · מיץ לימון · חומץ · מים · salt · pepper · baking powder · vanilla · lemon · water

Onion and tomato are on the list deliberately: they carry carbs, but a keto
recipe uses them and a converter that flags בצל on every recipe is a converter
nobody trusts. **Quantity-dependent vegetables are a product question**, §11.

### 5.3 Consistency, enforced by a test over two constant files

`test/core/constants/substitution_rules_test.dart`, table-driven:

- No `replacement` contains any entry of `IngredientRules.allForbiddenSeedOils`
  or `allInsulinSpikingSweeteners` (lowercased `contains`, the classifier's
  own rule). *If the converter recommends what Keto Lens flags, the app
  contradicts itself.*
- No substitution alias appears in `ketoStaples`, and no staple appears in
  `IngredientRules.allForbiddenSeedOils` or `allInsulinSpikingSweeteners`. One
  ingredient, one answer.
- No alias appears in two rows. Longest-first matching makes a duplicate
  silently win by length.
- Every `ratio` is finite and positive; every `reason` and `replacement` is
  non-empty.
- Every alias equals its own `foldFinals(lower(normalise(alias)))` — so the
  table is stored in matching form and no row can be unreachable because of a
  niqqud mark or a stray capital in the source file.

### 5.4 The second pass — `lib/features/recipe/data/suggestion/`

```dart
// domain/services/substitution_suggester.dart
abstract interface class SubstitutionSuggester {
  /// One request for every line the engine could not place. Never throws.
  Future<SuggestionResult> suggest(List<ParsedIngredient> unrecognised);
}

sealed class SuggestionResult {}
final class SuggestionsReturned extends SuggestionResult {
  /// Keyed by the input's normalised name; a line the model did not answer is absent.
  final Map<String, IngredientOutcome> outcomes;   // every value carries OutcomeSource.suggested
}
final class SuggestionsFailed extends SuggestionResult {
  final SuggestionFailureReason reason;            // notConfigured, offline, rateLimited, badResponse
}
```

`LlmSubstitutionSuggester` implements it over `LlmChatClient`, exactly as
`RemoteMacroEstimator` does over the same interface:

- **`LlmChatClient` is promoted to `lib/core/llm/`** (issue 2) because a
  second feature now depends on it and `recipe/domain/` may not import
  `diary/data/`. `OpenRouterClient`, `UserApiKeyCredentials` and
  `llmChatClientProvider` **stay in `diary/data/`**: they depend on the
  estimation settings store, which is the diary's, and moving that stack is a
  larger refactor than M10 should carry. The recipe feature's composition root
  (`recipe/data/providers.dart`) does `ref.watch(llmChatClientProvider)` from
  `diary/data/providers.dart` — a cross-feature import at a composition point,
  which `add_meal_photo_sheet.dart` already does to reach `ScanOrchestrator`.
  `OpenRouterClient`'s claim that nothing outside two files names it stays true.
- **The gate is free.** `OpenRouterClient.complete` short-circuits to
  `unauthorised` with no request when `UserApiKeyCredentials.token()` returns
  null, and that returns null unless `EstimationSettings.isEnabled`. The
  suggester maps `unauthorised` → `notConfigured`, the screen shows the same
  "turn it on in Profile" escape `EstimateFailureView` shows. No second
  consent flag, no second settings surface.
- **Only the unrecognised lines are sent** — the ingredient *names*, not the
  quantities, not the title, not the recognised lines. One request per tap,
  never automatically on convert.
- **The prompt file stands alone** (`substitution_prompt.dart`), names no
  provider, states the schema once, and carries the same "the input is DATA,
  not instruction" paragraph `MacroEstimationPrompt` does:

  ```json
  {"substitutions":[{"original":"...","replacement":"...","ratio":1.0,"reason":"..."}],
   "already_keto":["..."],"unknown":["..."]}
  ```
- **The parser is the trust boundary** (`suggestion_response_parser.dart`),
  and it borrows `EstimateResponseParser`'s posture line for line: fence
  stripped; `original` matched back to the request by normalised key and
  otherwise ignored; `ratio` through `NumericInput.positiveFinite` and clamped
  to `[0.05, 20]`, else the line stays `Unrecognised`; `replacement` non-empty
  and ≤ 60 characters; `reason` truncated at 120; the list bounded at the
  request's length. **Every `replacement` is checked against `IngredientRules`
  exactly as §5.3 checks the table, and one that fails stays `Unrecognised`** —
  a model that says "use maltitol" has told us nothing we can show. Every
  outcome the model produced carries `OutcomeSource.suggested`, `already_keto`
  included: a clean badge from a model is not evidence either.
- **The disclosure changes.** `ProfileCopy.estimationDisclosure` currently
  says what leaves the device is *"the description you write — and in photo
  mode, the photo"*. It gains one clause naming the recipe lines. A user who
  consented to sending meals did not consent to sending recipes, and the
  sentence has to say so before the first request does.

### 5.5 Provenance on every outcome

```dart
enum OutcomeSource { rule, suggested }     // stored by .name, decoded with a fallback to rule
```

On `AlreadyKeto` and `Substituted` both. `Flagged` and `Unrecognised` are the
engine's alone. The screen renders `suggested` with a marker (`הצעה אוטומטית`)
and the library keeps it, so the question `MacroSource` was added to answer —
*how often is a guess corrected?* — can be asked here too.

### 5.6 Persistence — `saved_recipes`

Auto-increment, following `mealsStore`; **not** `dateIndex`, because a user
may save three recipes in one afternoon and the daily-store pattern would
overwrite two of them. Record shape:

```
title: String · originalText: String · savedAt: int (epoch ms)
outcomes: List<Map> — each {type: 'alreadyKeto'|'substituted'|'flagged'|'unrecognised',
                            name, quantity?, unit?, raw,
                            replacement?, ratio? (decoded through num), reason?,
                            source: 'rule'|'suggested'}
servings?: int · perServing?: {fatG, netCarbsG, proteinG}     ← issue 9, nullable
```

`type` and `source` by `.name`, never ordinal, decoded with the
`MealEntryMapper._sourceOf` fallback shape. `ratio` through `num` — most seed
ratios are `1.0` and IndexedDB hands `1.0` back as `1`. `originalText` is kept
so a stale conversion can be re-run after the table grows. The store name goes
into `store_names_test.dart`; the interface goes onto `tool/coverage_ignore.txt`.

### 5.7 Layer map

```
lib/core/utils/hebrew_text_normaliser.dart          (moved, issue 1)
lib/core/llm/llm_chat_client.dart                    (moved, issue 2)
lib/core/constants/substitution_rules.dart           (issue 3)
lib/core/constants/recipe_copy.dart                  (issue 5)

lib/features/recipe/
  domain/models/   parsed_ingredient · substitution · ingredient_outcome (sealed, 4) · outcome_source
                   saved_recipe · suggestion_result (sealed) · suggestion_failure_reason
  domain/          ingredient_line_parser · substitution_engine
  domain/repositories/ saved_recipe_repository
  domain/services/     substitution_suggester
  data/mappers/    saved_recipe_mapper
  data/repositories/ sembast_saved_recipe_repository   (savedRecipesStore)
  data/suggestion/ llm_substitution_suggester · substitution_prompt · suggestion_response_parser
  data/providers.dart          savedRecipeRepository · substitutionSuggester
  application/providers/       substitutionEngine · savedRecipes · savedRecipe(id)
  presentation/screens/        recipe_converter_screen · recipe_library_screen
  presentation/widgets/        ingredient_outcome_row · save_recipe_dialog · recipe_macros_section
```

`domain/` imports `lib/core/` only. `data/` imports `domain/`, `lib/core/`, and
— at the composition root only — `diary/data/providers.dart`. `presentation/`
imports `application/`, `domain/`, `lib/core/`, and the two diary widgets issue
9 reuses.

---

## 6. Where the screen lives, and how it is reached

### 6.1 Routes

```
/recipe                 RecipeConverterScreen        (exists as a placeholder; outside the ShellRoute)
/recipe/library         RecipeLibraryScreen          (new)
/recipe/saved/:id       RecipeConverterScreen seeded from savedRecipeProvider(id)   (new)
```

All three stay **outside the `ShellRoute`**, as `/recipe` already is: they are
pushed screens with an `AppBar` back affordance, not tabs. The saved-recipe
route carries an `id`, not an `extra`, so a browser reload reopens the same
recipe rather than an empty converter — the onboarding flow's `extra` loss
(`app_router.dart` line 112) is the precedent for why. A missing `id` renders
the converter empty with a one-line notice, never a crash.

### 6.2 The entry point

**Recommendation: an action in the dashboard's `SliverAppBar`** —
`IconButton(Icons.menu_book_outlined)`, tooltip `המרת מתכון`,
`Key('open_recipe_converter')`, `context.push('/recipe')`. Home is the default
tab, the app bar is empty on the trailing side, and it costs no layout on a
320 px screen.

**The alternative is a sixth tab.** `kTabPaths` is documented as *"the 5 MVP
tab routes"*, `AppShell` has five labels, and `design/ui_ux_design.md` §App
Structure draws five (with a *Directory* tab that has not been built). A sixth
`NavigationDestination` fits at 360 px and is cramped at 320; it also promotes
a "nice-to-have" to the same rank as the diary. That is a product call (§11),
and the router change is small either way. The e2e navigation smoke goes
through whichever is chosen.

### 6.3 The converter screen

- One multiline `TextField`, one `חשבו המרה` button disabled while empty, a
  result list, and — once results exist — `שמרו למתכונים`, `הצעות לשורות שלא
  זוהו` (issue 7, shown only when an `Unrecognised` line exists), and `ערכים
  למנה` (issue 9).
- **Stacked rows, not two columns.** #119's "side-by-side" layout puts two
  Hebrew ingredient strings on one line; `EstimateReviewList._totalRow` records
  overflowing by 145 px at 320 px with less text than that. Each line is a
  card: the original struck through on the first line, the replacement with
  its adjusted quantity on the second, the reason beneath in `bodySmall`.
  Under RTL the strike-through row reads naturally and nothing depends on
  column order.
- **One exhaustive switch over four variants**, each with its own icon and
  `AppTheme` token: `Substituted` accent, `AlreadyKeto` success, `Flagged`
  error with `הסירו מהמתכון`, `Unrecognised` caution with `לא זוהה`.
  `suggested` adds the marker from §5.5.
- **Quantity × ratio through `GramsText.format`**, unit carried unchanged, no
  quantity → no quantity shown. Never invented.
- Results are `State`, not a provider: they die with the screen, and
  `design/m2_handoff.md` prefers parameters over un-overridable providers.
  Converting twice replaces.
- Copy in `lib/core/constants/recipe_copy.dart`, per `AddMealCopy`.

### 6.4 The library screen

A list, not a grid — `ui_ux_design.md` §8 drew a grid *with thumbnails*, and
M10 has no photos. `savedRecipesProvider` rendered with `hasError` before
`hasValue`, a **static** skeleton (a shimmer hangs `pumpAndSettle` on any
screen the router tests visit), `EmptyStateWidget` for `טרם נשמרו מתכונים`,
`Dismissible` handled the way `MealListSection` handles it. Tap → `/recipe/saved/:id`.

---

## 7. Testing

- **Domain: no mocks.** The parser, the engine, `foldFinals`, and the sealed
  types at 100%. Table-driven over `SubstitutionRules.substitutions` and
  `ketoStaples` so a new row is covered the day it is added. Named cases for
  the traps: `קמח כוסמין` reaches its own row; `הקמח` reaches `קמח`; `קָמַח`
  reaches `קמח`; `מלטיטול` is `Flagged`, not `Unrecognised`; `2 כוסות קמח`
  at 0.25 carries quantity 2 so the screen can show 0.5.
- **Constants: the consistency suite of §5.3**, in `test/core/constants/`
  beside the existing rule-length assertions.
- **Data: a factory-parameterised contract suite**,
  `runSavedRecipeRepositoryContractTests(factory, {required breakStore})`,
  including two saves on one day both persisting, `ratio: 1.0` round-tripping
  as a `double`, an unknown `type` surfacing as `PersistenceException`, and
  four `breakStore` assertions. A mapper suite asserting sembast-legal output.
- **Suggester: against a fake `LlmChatClient`** — fence, missing fields,
  `ratio: "Infinity"`, a replacement naming maltitol (stays `Unrecognised`),
  `original` not in the request (ignored), each `ChatFailureReason` mapping,
  and **zero calls when the client reports `unauthorised`** is not needed
  because the client itself makes none — but the e2e flow asserts it end to
  end, as `add_meal_photo_flow.dart` asserts zero estimator calls on a
  successful scan.
- **Widgets: provider overrides**, a small fixed table, both screens' three
  states, the four-variant rendering, the ratio on screen, no
  `EdgeInsets.only(left:)`.
- **e2e: `recipe_converter_flow.dart`** through the real entry point: paste a
  `test/fixtures/recipe_fixture.dart` recipe carrying one line of each
  variant → convert → adjusted quantity visible → save → library → reopen by
  id → delete. A second group with a fake `LlmChatClient`: unconfigured →
  zero calls and the profile escape; configured with a fixed reply → the
  `suggested` marker; a reply proposing a forbidden replacement → the line
  stays unknown. `navigation_smoke_flow.dart` gains the entry point.
- **Coverage bookkeeping:** `SavedRecipeRepository`, `SubstitutionSuggester`
  and the bare `OutcomeSource` / `SuggestionFailureReason` enums go on
  `tool/coverage_ignore.txt` with a reason each; `saved_recipes` goes into
  `store_names_test.dart`.

---

## 8. The milestone

### North Star

A user pastes a Hebrew or English recipe and gets it back line by line — each
ingredient marked as fine, swapped for a keto substitute with its adjusted
quantity and a one-line reason, flagged as one to leave out, or honestly
marked unknown — with the option, when they have turned estimation on, to ask
a model about the unknown lines and to log a serving of the result as a meal.
Every answer says where it came from, and the app never recommends what Keto
Lens would flag.

### Explicitly out of scope

- **Scanning a recipe from a photo.** Paste-only, as Epic #265 already decided
  — still a scope decision rather than a dependency.
- **Editing a saved recipe's text or outcomes.** Re-paste and re-save.
- **Sharing or exporting.** M14's backup carries the store like every other.
- **A hosted key proxy, accounts, login.** BYOK, as M15 ships it.
- **Community rules, a nutrition review of the table** — §10 says the table is
  unreviewed; reviewing it is a content task, not an engineering one.
- **Changing Keto Lens or the manual meal form.** Both are regression
  surfaces here.

### Architectural invariants

1. The engine is pure Dart in `domain/`, imports `lib/core/` only, and never
   throws on any input.
2. `IngredientOutcome` is sealed with four variants; every switch is
   exhaustive; unknown, already-fine and known-bad never render alike.
3. Every replacement — table or model — passes the `IngredientRules` check,
   asserted by a test over the constants and by the parser at run time.
4. `HebrewTextNormaliser.normalise` is shared and unchanged; final-form
   folding lives inside the engine and is applied to both sides.
5. A model is consulted only for `Unrecognised` lines, only on a tap, only
   with the ingredient names, and only through `LlmChatClient`; every outcome
   it produces carries `OutcomeSource.suggested`.
6. Keto Lens's no-network invariant is untouched. A scan still makes no
   request; nothing in `keto_lens/` imports anything in `recipe/`.
7. The deterministic path works with no key, no consent and no network, and
   is the milestone's first shippable state.
8. `saved_recipes` is auto-increment; `type`, `source` by `.name`; `ratio`
   through `num`; every method under `guardPersistence`.
9. A serving logged as a meal is divided by a servings count the user typed,
   passes through `AddMealBottomSheet`, and carries
   `MacroSource.estimatedFromText`.
10. The screen is reachable from the tab shell, and the e2e navigation smoke
    proves it.
11. No test, unit or e2e, makes a network call.

### Definition of Done

`milestone_conventions.md` §3's list, plus:

- [ ] `/recipe` reachable from Home in the e2e navigation smoke
- [ ] `recipe_converter_flow.dart` green in the `e2e flows` job, including the
      zero-request assertion
- [ ] The §5.3 consistency suite green over the shipped table
- [ ] `ProfileCopy.estimationDisclosure` names recipe lines
- [ ] `design/architecture.md`, `technology.md` §7, `ui_ux_design.md` §8,
      `tests.md`, `tasks.md`, `CLAUDE.md` and this file's status line updated

---

## 9. The nine issues, in build order

Dependencies point backwards only. Every issue leaves `main` green alone.
Issues 1–3 are the offline converter; 4–5 the library; 6–7 the model pass;
8 the macros; 9 the proof and the paperwork.

| # | Issue | Type · Layer | Depends on |
|---|---|---|---|
| 1 | **#393** Promote `HebrewTextNormaliser` to `lib/core/utils/` — file move, import updates, doc comment un-ML-Kit'd, zero behaviour change | refactor · core | — |
| 2 | **#118** (rewritten) Substitution engine — parser, `foldFinals`, four-variant sealed outcome, `OutcomeSource`, the two tables, the consistency suite | feat · domain | 1 |
| 3 | **#119** (rewritten) `RecipeConverterScreen` — paste, stacked per-line output, ratio applied, **entry point on Home**, route | feat · presentation | 2 |
| 4 | **#395** `SavedRecipe`, `SavedRecipeRepository`, mapper, `saved_recipes` store, contract suite, `store_names_test` | feat · data | 2 |
| 5 | **#120** (rewritten) `RecipeLibraryScreen` — list, reopen by id, delete; save affordance on the converter | feat · presentation | 3, 4 |
| 6 | **#394** Promote `LlmChatClient` to `lib/core/llm/` — interface only; the OpenRouter stack stays | refactor · core | — |
| 7 | **#396** `SubstitutionSuggester` — prompt, parser with the `IngredientRules` check, `LlmSubstitutionSuggester`, provider, the converter's suggest affordance and `suggested` marker, disclosure clause | feat · data | 2, 3, 6 |
| 8 | **#397** Per-serving macros via `MacroEstimator` and "log a serving" through `AddMealBottomSheet`; nullable `servings` / `perServing` on `SavedRecipe` | feat · presentation | 4, 5 |
| 9 | **#398** `recipe_converter_flow.dart`, the navigation smoke, the fixture, and the docs closeout | test · test | 3, 5, 7, 8 |

Issues 1 and 6 have no dependencies and are each an afternoon. **Issue 3 is
the first moment a user can do anything**, and it needs nothing from the model
half.

### What was closed as redundant

**Nothing.** All three original issues describe work that has not shipped and
is still wanted; they were rewritten in place rather than closed, so their
numbers and their place in the Epic's history survive. What *was* retired is
text: the Epic's "needs a food database" exclusion, #118's LLM rejection
rationale, #119's "side-by-side" and #120's "grid" layouts, #120's
`BiomarkerLog` reference, and its argument against its own split.

---

## 10. What is not verified, and not claimed

- **The substitution table has been reviewed by nobody with a nutrition
  background.** Every ratio is a common rule of thumb; none has been baked.
  The consistency suite proves the table agrees with Keto Lens, not that a
  cake made from it rises. Treat every row as a seed.
- **The staples list is a judgment call**, and §11's first question is its
  weakest point.
- **No model has ever answered the substitution prompt.** As with M15, every
  test fakes `LlmChatClient`. Nothing here measures whether the suggestions
  are good, only that bad ones cannot reach the screen as approved.
- **No real Hebrew recipe has been pasted.** The parser's coverage of how
  Israeli food blogs actually write a quantity — `2 כוסות`, `כוס וחצי`,
  `1/2 כפית`, `½ כוס`, `קמח - 2 כוסות` — is asserted against fixtures written
  by the same hands that wrote the parser. `design/m6_handoff.md` says what
  that is worth. Collecting fifty real recipe ingredient lists needs no app
  and no device and would be the most valuable hour anyone spends on this
  milestone.
- **The quota argument** (50 requests/day, one per convert) is inherited from
  M15's reading of OpenRouter's published tier and has not been observed.

---

## 11. Open decisions for the product owner

1. **Entry point: dashboard action or sixth tab?** §6.2. *Recommendation: the
   app-bar action. Promote it to a tab if usage says so.*
2. **Are onion and tomato staples?** They carry 8–9 g and 3–4 g of net carbs
   per 100 g, and every second keto recipe uses them. *Recommendation: staples.
   A converter that flags בצל is a converter nobody trusts; the day's total is
   the diary's job.*
3. **Is issue 8 (per-serving macros, log a serving) in M10 or its own
   follow-up?** It is the one issue that ties the converter to the core loop,
   and the one that widens `SavedRecipe`. *Recommendation: in, last. It is the
   answer to `mvp.md`'s "does not prove the core loop".*
4. **Should the model pass run automatically on convert when estimation is
   on?** *Recommendation: no — a tap, and only when unknown lines exist. A
   recipe with no unknown lines costs nothing, and a user should not spend a
   quota slot without meaning to.*

---

## Sources

- `design/technology.md` §7 — the original hybrid recommendation
- `design/m15_meal_entry_research.md` — the engine seam, the accuracy bar, the
  BYOK and consent decisions this milestone inherits
- `design/user_bugs_handoff.md` — reachability as a test obligation
- `design/m6_handoff.md` — a clean badge is not evidence; normalise before
  matching; a warning that fires on everything stops working
- `design/v1_1_split.md` §6 — how to create a label or milestone from a
  session (none was needed here; M10 already has both)
