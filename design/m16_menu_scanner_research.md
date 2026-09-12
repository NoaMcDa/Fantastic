# M16 — AI Menu Scanner: research

## 0. What this document is, and what it is not yet

**This file was opened by issue #373, and it is deliberately incomplete.**

#373's Definition of Done ends with *"Write down what was found, in
`design/m16_menu_scanner_research.md` §10, whatever it is."* That document did
not exist. Neither did §5, which **#352 and #372 both cite** — #352 says the
corpus *"settles the one question the research document could not (§5)"*, and
#372 is built around answering it. Three open issues reference a file nobody
had written.

That is the project's own pattern rather than a surprise: `mvp_handoff.md`
records that the issue text *"was never right, once, in seven milestones."*
It is recorded here rather than fixed silently.

So this file currently holds **two measured sections and nothing else**:

| Section | State |
|---|---|
| §1–§4 — problem, prior art, engine options, the vision-model question | **Not written.** Owed by #352 / Epic #351 |
| **§5 — engine settings, and whether `psm 4` suits a menu** | **Measured.** Written below |
| §6–§9 — prompt design, parser contract, cost model, privacy | **Not written.** Owed by #352 / Epic #351 |
| **§10 — the photographed-menu corpus and what it reads** | **Measured.** Written below |

Whoever writes the research proper should fill the gaps around these two, not
renumber them: the numbering is what three open issues already point at.

Everything below was measured on this repository's own toolchain —
**tesseract 5.3.4**, the bundled `heb.traineddata` + `eng.traineddata`, the
app's own `ScalingTextRecognizer.prepare` — on the one photographed menu the
corpus now has. The environment was verified before any of it was trusted:
`tool/capture_ocr_fixtures.sh` regenerated the committed
`test/fixtures/real_ocr_fixture.dart` **byte-identically** (MD5
`c1d1063a…`), which is the check #372 describes as the proof that a capture
here is the real engine's output and not a fiction.

---

## 5. The engine settings, and whether `psm 4` suits a menu

### 5.1 The question

Keto Lens pins `psm 4`, `heb+eng`, `oem 1` and an explicit `user_defined_dpi`.
Every one of those was chosen against **a bordered nutrition label**, and
`design/m6_platform_handoff.md` is specific about why: `psm 6` flattened a
bordered two-column table and six of the label's nine rows came back as
punctuation.

Nothing about that finding was ever about menus. #352 and #372 ask the obvious
follow-up: does `psm 4` read across a menu's columns and interleave them, or
keep each dish with its price?

### 5.2 The answer: the columns held

**`psm 4` kept the rows whole.** On the photographed menu, dish text and its
price land on the same output line; there is no line anywhere in the transcript
that is a run of bare prices with the dishes elsewhere. `real_menu_pipeline_test.dart`
pins that as an assertion rather than leaving it as prose.

So **the column risk this section was opened to investigate is not what goes
wrong on a real menu.** The prompt's planned "columns may be interleaved"
instruction is not load-bearing for this layout, and the vision swap does not
need to be filed on account of column interleaving. Something else goes wrong
instead — see §10.

### 5.3 But `psm 4` is not obviously the right mode for a menu

Measured on the same photograph, same models, same DPI, varying only the page
segmentation mode:

| psm | chars | lines | Hebrew lines | dish rows keeping a number | prices correct |
|---|---|---|---|---|---|
| 3 | 842 | 22 | 21 | 12 | 2 |
| **4 (shipped)** | **843** | **22** | **21** | **12** | **2** |
| **6** | **1022** | **27** | **24** | **20** | **1** |
| 11 | 926 | 50 | 34 | 8 | 1 |
| 12 | 915 | 48 | 33 | 9 | 1 |

`psm 6` returned **21% more text** than the shipped `psm 4` and kept **20 of
the 23 dish rows** against `psm 4`'s 12 — recovering most of a third menu
section that `psm 4` dropped from its output entirely. It degrades into noise
at the very bottom of the frame, where the restaurant's logo is, which `psm 4`
avoids by stopping early.

Neither mode reads the prices (§10).

**This is a finding, not yet a recommendation.** It is one photograph. Changing
the shipped constant would change Keto Lens too, where `psm 4` was chosen for a
measured reason on the failure that produced it, so a menu scanner wanting
`psm 6` should pass its own mode rather than re-pin the shared one. Filing that
decision needs the other two menus #373 asks for.

### 5.4 Resolution is not the lever

Also measured, so that nobody spends the effort: re-running the same photograph
at 1600 (the app's own `targetWidth`), 2400, 3200, 4000 and 4500 px wide, on
the app's own greyscale-then-linear kernel:

| output width | numbers returned | distinct prices correct (of 19) |
|---|---|---|
| 1600 (shipped) | 12 | 2 |
| 2400 | 12 | 1 |
| 3200 | 14 | 1 |
| 4000 | 20 | 3 |
| 4500 | 19 | 3 |

Upscaling cannot invent strokes a 480 px source never recorded. The app's own
`OcrImagePrep.targetWidth` is as good as any larger number here, and its
`maxUpscale` cap of 4 is not what costs the digits. `OcrImagePrep`'s own
docstring guessed the other way — *"a real camera photo has several times the
detail and none of this brittleness is expected to apply to it"* — and flagged
itself as unverified. It is now verified, and it was optimistic for a
photograph that has been through a messaging app.

---

## 10. The photographed-menu corpus, and what it reads

### 10.1 What the corpus now has, and what it still lacks

M16's corpus has three provenance tiers, mirroring the three the repo keeps for
labels:

| Tier | Artefact | State |
|---|---|---|
| Hand-typed menu text | `HebrewMenuFixture` (#352) | **Not collected** |
| Rendered menu → real engine output | `RenderedMenuOcrFixture` (#372) | **Not collected** |
| **Photographed menu → real engine output** | `PhotographedMenuOcrFixture` (#373) | **One menu of the three** |

`test/fixtures/images/vivie_restaurant_menu.jpg` is a real Israeli restaurant
menu photographed off a table, supplied by the owner. It is the first menu of
any kind in this repository.

**It is one menu, and #373 asks for three deliberately differing ones** — a
multi-column layout, a laminated sheet with glare, and a bilingual
Hebrew/English card. This is none of those three on purpose; it is simply the
menu somebody had. **#373 stays open.**

The photograph arrived at **480×640, 40 KB** — a phone photo after a messaging
app had had it. Nothing here downscaled it further. That is not a defect of the
corpus, it is the normal path by which a photograph reaches an app that accepts
one from the gallery, and §5.4 shows it is the binding constraint.

### 10.2 The finding: the dish names read, the prices do not

The two halves point in opposite directions, and the split is the most useful
thing M16 has learned about its own input.

**Dish names survive.** Scored by edit distance against the printed menu, of
the 23 dish names:

- **9 came back character-perfect** — `צלחת חריפים`, `ריזוטו, פטריות בלו אויסטר`,
  `פילה דג ים, אורז אסור, ביסק סרטנים`.
- **17 scored 0.75 or better**, the band where a name is plainly recognisable
  through one or two corrupted letters (`ברוסקטה סרדינים כבושיט` for
  `...כבושים`).
- **19 scored 0.70 or better.**
- The **4 that failed** (0.33–0.55) are the last four dishes on the page,
  nearest the foot of the photograph where the frame falls off. That is a
  property of where they sat in the shot, not of the dishes.

**Prices do not survive, and they fail in the dangerous direction.** The menu
prints 23 prices, 19 of them distinct. The pipeline returned **12 numbers**.
**Two were right.** The other ten match nothing printed anywhere on the menu,
and they are wrong in one consistent way: the left-hand digit is gone and the
right-hand one survives.

| printed | returned |
|---|---|
| 28 | 8 |
| 18 | 8 |
| 52 | 2 |
| 74 | 4 |
| 63 | 3 |
| 58 | 8 |
| 72 | **72** |
| 79 | **79** |

The nine dishes of the third section returned no number at all.

### 10.3 Why that asymmetry is good news, with one hard rule attached

**A keto classifier reads ingredients, not prices.** The payload M16 needs is
the payload that survives. This is the exact inverse of Keto Lens, where the
numbers are the whole point and the Hebrew is scaffolding — and it means the
menu scanner's core function is viable on real photographs in a way the label
scanner's was not until `psm 4` + `heb+eng` + `user_defined_dpi` were found.

The rule that follows is not optional:

> **M16 must never present a scanned price as fact.**

A price that comes back as nothing is a safe failure. A 28 shekel dish
displayed as 8 shekels is not — it is a *plausible wrong number*, the failure
#257 was, and the user has no way to tell it from a correct one by looking at
it. If prices are surfaced at all they must be shown as the user's to confirm,
exactly as `ScanResultSheet` treats an unknown `ServingBasis`. The safest
reading of this measurement is that M16 should not extract prices at all in its
first version.

`real_menu_pipeline_test.dart` pins the deficiency, in the same spirit as
`real_ocr_pipeline_test.dart` pinning the lost carbohydrate row of the pointed
wafer. **If that test fails because the engine started reading prices, that is
good news and the fix is to rewrite this section — not to loosen the test.**

### 10.4 A menu is not a nutrition label, and the shipped scanner agrees

Worth stating because it was never checked before and M16 makes it reachable:
once a second scanner exists in the same tab shell with the same camera, the
most likely wrong thing for a user to point Keto Lens at is a menu.

Fed this transcript, `ScanOrchestrator` returns `ScanFailed(notALabel)` and
carries the raw text through for the user to see. No macro parses out of it —
not from `שמן זית` in a dish description, not from anything. That is #83's rule
holding on an input class it was never tested against, and it is now a test.

### 10.5 What is still unverified

- **No menu has been read through the app's own camera.** There is no camera in
  this repository. This is a photograph handed to the gallery path.
- **One menu is not an accuracy figure.** Nothing here claims a percentage for
  menus in general, and the 9-of-23-perfect result is one page, one restaurant,
  one typeface, one light.
- **No laminated menu, no glare, no bilingual card.** The three shapes #373
  names as the point of the exercise are all still missing.
- **`psm 6` is a measurement, not a decision** (§5.3).
