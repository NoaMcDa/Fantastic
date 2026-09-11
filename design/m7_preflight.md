# M7 Pre-flight — the audit, and the issue list it produced

Read this before picking up any M7 issue.

This is the sixth such file. `m0_handoff.md` catalogued seven things the M0
issue text got wrong; `m1_preflight.md` through `m6_preflight.md` did the same
for their milestones. Every one found the same thing: **the issue text was
written in one sitting before any code existed, and every issue in the
milestone carried at least one defect.**

`design/mvp_handoff.md` predicted M7 would be no different — *"M7's issue list
is stale in the same way every other milestone's was"* — and named four of the
seven as already satisfied or obsolete. This audit checked all eight against
the code rather than against the handoffs, and the prediction held, with one
correction to it: the count was three obsolete, not four.

**Unlike the earlier pre-flights, this one did not stop at a correction layer.**
The issues have been acted on: three closed, four rewritten in place, one left
alone, and nine new ones filed for defects that four separate handoffs had
labelled "M7 work" without ever giving them a number. This file records what
was done and why, so a reader who finds a rewritten issue can see what it said
before and what evidence changed it.

Audited: **#88–#94 and #151, all eight, in full**, plus Epic #11.

M7's backlog is now **14 open work issues**. It was 8.

---

## Part 0 — Three issues that were already done

Each was closed `not_planned` with a comment carrying the evidence below.

### #90 — "full-screen error state for critical **Isar** open failure"

**Isar is gone.** `pubspec.yaml` pins `sembast ^3.8.10` + `sembast_web ^2.4.6`;
the swap landed in `refactor(#197): run on Flutter web by replacing Isar with
sembast`. There is no `isarProvider` to watch, so the issue's Step 2 could not
be written as specified even in principle.

**The capability shipped under another name.** `StartupFailureApp` is at
`lib/main.dart:121-160`, reached from the outer `on Object catch` wrapping the
startup sequence at `:35-100`. Its doc comment explains the design decision the
issue never considered: *"Deliberately dependency-free — no router, no
providers, no localisation delegates: whatever failed in `main` must not be
able to fail again here."* It also logs under `startupFailureLogPrefix`, which
`tool/linux_smoke_test.sh` greps so that a startup fault fails the Linux build
rather than passing as a live-but-dead process.

**Two things the issue asked for that did not ship**, and are deliberately not
being kept open:

- **No retry button.** A cold restart is the only recovery. Re-opening a failed
  sembast database in place is a different problem from the one #90 described,
  and nobody has asked for it.
- **No splash state.** Nothing renders between `ensureInitialized()` and the
  first `runApp`; the platform launch screen covers that window, which is
  #311's subject.

### #93 — Hebrew camera and photo-library usage strings

Both present, in grammatical Hebrew, at `ios/Runner/Info.plist:27-30`, shipped
by M6 under #79 — and each states the privacy fact that matters for App Store
review, which the version proposed in #93 did not:

> `אפליקציית Fantastic משתמשת במצלמה כדי לסרוק תוויות מזון ולנתח אותן לפי עקרונות קטו. הניתוח מתבצע כולו על המכשיר והתמונות אינן נשלחות לשום שרת.`

Both are mirrored verbatim in `macos/Runner/Info.plist`, which #93 never asked
for.

**The third key #93 requires does not exist.** There is no
`NSUserNotificationsUsageDescription` in Apple's API — notification prompts
take their copy from the system, not from the bundle. Implementing #93 as
written would have added a key iOS ignores.

`NSPhotoLibraryAddUsageDescription`, `NSMicrophoneUsageDescription` and
`NSLocationWhenInUseUsageDescription` are correctly absent; nothing in the app
writes to the photo library, records audio, or reads location.

**What is genuinely left is #151**, and it is the reason these strings may not
display in Hebrew at all — see Part 1.

### #94 — `flutter_local_notifications` iOS entitlements

Most of it shipped in M3/M4, and **the one step that did not is wrong.**

Shipped: `flutter_local_notifications ^22.3.0` with `timezone ^0.11.1`;
`lib/core/services/notification_service.dart` initialising per-platform
settings for all five initialisable targets with the Darwin request flags
`false` so the prompt can be deferred; `requestPermission()` dispatching per
platform — including **Android 13+ `requestNotificationsPermission()`**, which
the class doc records as a real bug caught late (asking iOS-only meant API 33
silently dropped every reminder); `AndroidManifest.xml` carrying
`RECEIVE_BOOT_COMPLETED` and both plugin receivers; macOS carrying both
entitlements files, wired through `CODE_SIGN_ENTITLEMENTS`. The prompt is
requested at `onboarding_service.dart:161`, inside `completeOnboarding`.

**Step 1 is wrong and must not be implemented.** `aps-environment` is the
entitlement for **remote** push (APNs). This app sends only local
notifications, which need no entitlement at all. Adding
`aps-environment: development` to an `ios/Runner/Runner.entitlements` would
declare a capability the App ID does not carry and can fail provisioning — a
regression in exchange for nothing. That is why `ios/` has no `.entitlements`
file and no `CODE_SIGN_ENTITLEMENTS` build setting, and why it should stay that
way until something actually needs remote push.

**What was genuinely left became #309 and #310**, split because #94's title
needed the word "and": the status query, and a screen to put it on.

---

## Part 1 — Four issues rewritten in place

Numbers and milestone kept; bodies replaced per `design/issue_conventions.md`
§4. The originals are in each issue's edit history.

### #88 — loading skeletons

Four corrections, one of which changes the shape of the work:

1. **`lib/core/widgets/` does not exist.** `lib/core/` holds
   `constants/ database/ error/ providers/ router/ services/ theme/ time/
   utils/` and no widget directory. Every shared widget lives under some
   feature's `presentation/widgets/` — which is why `MacroSummaryCard`, a
   dashboard widget, imports `EmptyMealsState` across a feature boundary from
   `features/diary/`. Creating the directory is shared with #91.
2. **Five widgets have loading branches, not three.** The issue named
   `MacroSummaryCard`, `MealListSection` and `StreakRingWidget`; it missed
   `PhaseDetailScreen` (`:55-58`) and `SymptomDiarySection` (`:33-36`).
   `ElectrolytesCard` has a sixth, currently `SizedBox.shrink()`, which #302
   turns into a real one.
3. **A shimmer is a forever-repeating animation, and that is the hazard the
   issue never mentions.** `design/m6_handoff.md:180-184`: *"An indeterminate
   `CircularProgressIndicator` on a tab screen hangs `test/widget_test.dart`.
   `pumpAndSettle` never returns while one animates… `CameraScreen`'s opening
   state is a static icon and a line of text for exactly this reason. Two
   router tests went red before it was found."* Swapping one forever-animation
   for another changes nothing, and a shimmer covers more of the screen and
   more screens. `onboarding_flow_test.dart:89-94` already carries a bespoke
   bounded `settle` for this, and `m8_preflight.md` bounds every e2e settle
   because riverpod 3 retries a failed provider on a backoff. The rewritten
   issue makes choosing between a static skeleton, a bounded animation, or an
   animation plus harness changes an explicit decision with a recorded reason.
4. **The tests are not free.** Six assert the spinner is *present* and will
   fail; roughly a dozen assert it is *absent* in failure states, encoding M6
   convention 9, and must be extended rather than replaced or the convention
   silently stops being enforced. `integration_test/flows/storage_failure_flow.dart:70-78,100-107`
   is in the same position.

Also: the issue's snippet used `Colors.grey.shade300` / `shade100` — light-mode
values, invisible on `#1C1C1E`. `EmptyMealsState` already documents that trap.
And `shimmer: ^3.0.0` predates the pinned Flutter 3.47.3 / Dart `^3.13.2` and
must be re-resolved, not copied forward.

### #89 — global error snackbar

**The issue's `ProviderObserver` snippet does not compile against riverpod 3.**
`pubspec.lock` pins `riverpod 3.0.3`. The
`didUpdateProvider(ProviderBase, Object?, Object?, ProviderContainer)`
signature it overrides was removed; every observer method now takes a
`ProviderObserverContext` first.

**riverpod 3 added the hook the issue actually wants, and the issue does not
know about it.** `providerDidFail(ProviderObserverContext, Object, StackTrace)`
fires when a provider throws. riverpod 2 had no equivalent, which is why the
original reached for `didUpdateProvider` plus an `AsyncError` match.

**That match is the forbidden pattern.** `design/mvp_handoff.md` calls it the
bug that cost four milestones in four disguises: a provider that fails before
ever producing a value is `AsyncLoading` **with an error attached**, so
`if (newValue is AsyncError)` never fires for a first-read failure — which is
most of them. The issue would have shipped an error reporter that silently
missed the common case.

**`ProviderScope(observers: [...])` is not how this app mounts.**
`lib/main.dart:37-39` builds a `ProviderContainer` by hand and `:86-90` mounts
it with `UncontrolledProviderScope`. The observer goes on the container
constructor. `MaterialApp.router` at `:110-116` needs a `scaffoldMessengerKey`
it does not have.

Two things the rewrite adds that the original had no way to anticipate:
**de-duplication**, because riverpod 3's retry backoff would otherwise queue
one snackbar per attempt; and **leaving `StartupFailureApp` alone**, whose doc
comment says it carries no providers precisely so that whatever failed in
`main` cannot fail again in the screen reporting it.

The issue's premise that error states "render silent `SizedBox.shrink()`
widgets throughout the app" has also been overtaken — only `ElectrolytesCard`
still does, and #302 fixes it directly. #89 is now about failures no screen
owns.

Snackbar duration: #89 said 3 s, `design/tasks.md:412` says 4 s. The rewrite
takes 4, as the written spec.

### #91 — empty states

**The issue named the wrong two screens.** `DiaryScreen` always renders 30 date
chips and can never be empty; `StreakCalendarWidget`'s month grid is a fixed
walk and its `SizedBox.shrink()` at `:79` is for leading blank cells before the
1st. Neither needs an empty state.

**The two surfaces that genuinely render the wrong thing on an empty day are
`MacroSummaryCard` and `ElectrolytesCard`** — and both are *wrong* empty
states, not missing ones, so they became `type:fix` issues (#301, #302) rather
than part of a refactor.

**What is actually left is that two empty states exist and neither can be
reused.** `EmptyMealsState` is public, 8-tests, well reasoned — and used in
exactly one place, across a feature boundary. The symptom equivalent is a
*private* `_Empty` inside `symptom_diary_section.dart:59-88` that made a
different CTA decision without either widget knowing about the other. #91 is
now a `type:refactor` that shares one widget and changes no rendered output.

**Screens that correctly have none, and must keep having none:**
`MealListSection` (commented at `:72-73` — *"MacroSummaryCard above already
shows one… and two would stack"*), `DiaryScreen`, `StreakCalendarWidget`,
`PhaseDetailScreen`, `GracePeriodBanner`, `PhaseBadgeWidget`, and
`ScanResultSheet`'s flagged-ingredient list, where empty is the *good* outcome.

One thing found and deliberately not fixed there: the symptom empty state says
`'לא הוקלטו תסמינים'` where `design/ui_ux_design.md:186` specifies
`'לא הוקלטו תסמינים להיום'`. A copy change is a behaviour change and #91 is a
refactor; it is noted in the issue, not silently applied.

### #92 — app icon

**Written iOS-only, before the app targeted six platforms.** Every one of them
still ships the stock Flutter logo — verified by rendering the images, not by
reading filenames — and **Linux ships no icon at all**, nor a `.desktop` entry.
Android has no adaptive icon (`mipmap-anydpi-v26/` absent), so it renders as a
legacy bitmap on every modern launcher. macOS `CFBundleIconFile` is an empty
string.

**Its title needed the word "and"**, which `issue_conventions.md` §1.3 says is
two issues. The launch screen is now **#311**; #92 keeps the icon.

**Its acceptance criterion is unverifiable here.** "App icon appears correctly
in simulator" — there is no simulator, no iOS device and no macOS host
(`mvp_handoff.md`). Epic #4 is open on exactly that. The rewrite says which
platforms can be *seen* (web, Linux) and which can only be *built*.

**Its real blocker is not an issue at all: there is no icon design.**
`design/design_system.md` covers colour, type, spacing, elevation, icons-in-UI,
buttons, inputs, cards, badges and modals — and no app mark. `assets/` holds
fonts and `tessdata` and nothing else. The rewrite makes the artwork brief
Step 1, with the constraints that actually bind: legible at 16×16, survives a
circular/squircle/rounded-square mask, no Hebrew glyphs in the mark.

Also folded in, because it is in the same tree and visible in the same places:
`windows/runner/Runner.rc:92-98` declares the app as lowercase `"fantastic"`
while `main.cpp:30` and `CMakeLists.txt:7` use `"Fantastic"`.

### #151 — kept as written

`CFBundleLocalizations` is confirmed absent from **both** `ios/Runner/Info.plist`
and `macos/Runner/Info.plist`, and `CFBundleDevelopmentRegion` is still the
stock `$(DEVELOPMENT_LANGUAGE)` — with nothing assigning `DEVELOPMENT_LANGUAGE`
anywhere in `ios/Runner.xcodeproj/project.pbxproj`, so it resolves to Xcode's
default `en`. iOS therefore treats the bundle as English-only, which is why
#93's Hebrew strings may never display in Hebrew.

The one extension: apply it to `macos/Runner/Info.plist` too, which #151 did
not ask for and which has the identical gap.

---

## Part 2 — Nine issues filed

Each was named as M7 work in a handoff and had no issue number. None is
speculative; each cites a `file:line`.

| Issue | Defect | Source |
|---|---|---|
| **#301** | `MacroSummaryCard` renders `EmptyMealsState` whenever the day has no `DailyLog` (`:62-65`), so a user who just agreed to 149/20/64 g sees none of it on the screen they land on | `m8_preflight.md` Part 10 defect 1. The e2e suite asserts the wrong behaviour **on purpose**, with a comment, at `onboarding_flow.dart:46-55` |
| **#302** | `ElectrolytesCard` returns `SizedBox.shrink()` on loading, on error **and** on a day with no log (`:47-51`) — three defects in five lines, and the last loading-first `.when` in the codebase | `m5_handoff.md`, twice |
| **#304** | Three gram formatters, two of which interpolate a raw double: `0.17999999999999988` is what the user is asked to save | `m8_preflight.md` Part 10 defect 4 — and **wider than it recorded**: `scan_result_sheet.dart:319` has the same bug as `add_meal_bottom_sheet.dart:101`, not just the latter |
| **#305** | The ring colours the ratio by band (`streak_ring_widget.dart:167-175`); the macro card's ratio row is a **fixed** accent (`:125-134`) that never moves. Same number, two widgets, one screen | `m3_handoff.md`, `mvp_handoff.md` |
| **#307** | Unselected score buttons fill with `surfaceContainerHighest`, which sits very close to the sheet's own surface — five numbers, not five buttons | `m5_handoff.md`: *"the browser screenshot is what showed it; no test could"* |
| **#308** | `GracePeriodBannerText.describe` falls through to `'פחות מדקה'` for **any** duration under a minute, including a negative one, and `_graceEnd` trusts the persisted `inGracePeriod`. The ring shows a streak already lost | `m3_handoff.md`, `mvp_handoff.md` — the display half of "the streak resets lazily" |
| **#309** | `NotificationService` can ask for permission but not report it. Its own doc says *"Called after onboarding (M4) or from profile settings"* | Salvaged from the closed #94, minus its wrong entitlement step |
| **#310** | `lib/features/profile/` is one 16-line `Center(child: Text('פרופיל'))`, wired as one of five tabs | `m4_handoff.md`; `GoalCopy`'s doc comment was written *for* this screen |
| **#311** | iOS `LaunchScreen.storyboard:22` is white with three 68-byte blank PNGs; Android `values/styles.xml` parents `LaunchTheme` to `Theme.Light` | Split out of #92 |

**Two notes on #302 and #311, where the audit corrected a handoff.**

`mvp_handoff.md` lists `MealListSection` as still using the loading-first
`.when`. It does not — `meal_list_section.dart:44-73` was fixed, with a comment
citing `m8_preflight.md` Part 10 defect 2. `ElectrolytesCard` is the only one
left.

`m8_preflight.md` describes the Android launch screen problem as living in
`drawable/launch_background.xml`, the file with the word "white" in it. **It
does not.** On API 21+ that file is shadowed by `drawable-v21/launch_background.xml`,
which is `?android:colorBackground` — a *theme reference*. The colour is
decided by `LaunchTheme`'s parent, and `values-night/styles.xml` already gets
it right. Editing the obvious file would change nothing on a real device.

---

## Part 3 — Build order

1. **#91**, then **#88.** Both create `lib/core/widgets/`; #91 is the smaller
   and establishes the shared-widget pattern #88 follows.
2. **#301**, **#302.** The two empty-state defects, once the shared widget
   exists. #302 also removes the last loading-first `.when`.
3. **#304**, **#305**, **#307**, **#308.** Independent single-widget fixes,
   parallelisable. Note #305 and #301 touch adjacent lines of
   `macro_summary_card.dart` — a conflict to resolve, not a dependency.
4. **#309**, then **#310.** The toggle cannot be honest without the query.
5. **#89.** Better last: once the screens that should report failures
   themselves already do, what the observer catches is genuinely the residue.
6. **#92**, **#311**, **#151.** Platform work, independent of all the above.
   **#92 is blocked on artwork that does not exist** and should not be picked
   up expecting a tooling task.

---

## Part 4 — Constraints M7 code inherits

M7 touches more loading and error branches than any other milestone, which
makes it the likeliest place to reintroduce the project's recurring bugs.

1. **`hasError` before `hasValue`. No `AsyncValue.when`. No `is AsyncError`.**
   riverpod 3 reports a provider that failed before its first value as
   `AsyncLoading` with an error attached. Four milestones learned this; #89's
   original text would have shipped it a fifth time.
2. **riverpod 3 retries a failed provider on an exponential backoff.** A screen
   over a broken store never settles, and a naive per-failure handler fires
   repeatedly. Never a bare `pumpAndSettle()`; use the `app_harness.dart`
   helpers.
3. **No animation that never ends on a tab screen.** The router tests visit
   every tab knowing nothing about what is on it.
4. **Every failure-state test asserts the loading indicator is absent** — M6
   convention 9. Whatever replaces the spinner inherits the assertion.
5. **A failed read and an empty day must not look alike.** An empty state
   standing in for a failure tells the user something false about their own
   data.
6. **Colours from `AppTheme`, never `Colors.grey`, and never colour alone** —
   M6 convention 8. The palette is dark-first; a light-mode grey is invisible.
7. **Digit runs carry `TextDirection.ltr`.**
8. **No magic numbers, no TODO comments.** `developing_rules.md:75` requires a
   follow-up issue instead of a TODO, and the rule has held — the only TODO in
   the repository is Flutter's own template line in
   `android/app/build.gradle.kts:53`.

---

## Part 5 — Deferred, so it is not lost

The audit surfaced more than M7 should absorb. `milestone_conventions.md` §1
forbids adding scope to an open milestone, so these are recorded rather than
filed. Each is real and each has a `file:line`.

**Accessibility — the largest completely unrepresented category.** Not
mentioned in a single design document.
- Three `Semantics` in all of `lib/` (`goal_card.dart:32`,
  `symptom_check_in_strip.dart:115`, and a comment in
  `verdict_badge_widget.dart:44`). Nothing on the dashboard, the macro card,
  the streak ring, the electrolyte gauges, the camera screen, or the five tabs.
- One `semanticLabel` in the codebase, correctly set to `null`
  (`empty_meals_state.dart:33`). Zero `ExcludeSemantics`.
- `minTouchTarget = 44` declared **twice**, as private statics in two files
  that do not import each other (`symptom_log_sheet.dart:319`,
  `symptom_check_in_strip.dart:108`), plus a hand-rolled `BoxConstraints` in
  `diary_screen.dart:148` and a comment-only mention in
  `verdict_badge_widget.dart:112`. There is no `AppTheme.minTouchTarget`.
  Dashboard, adaptation, onboarding and camera enforce nothing.
- **Zero text-scaling handling.** No `MediaQuery.textScaler`, no
  `withClampedTextScaling`. `onboarding_screen2.dart:68` notes the hazard in a
  comment and does not generalise it — and `m5_handoff.md` already records the
  dashboard overflowing a 600pt viewport at *default* scale.
- **Zero** uses of `meetsGuideline`, `androidTapTargetGuideline`,
  `textContrastGuideline` or `find.bySemanticsLabel` anywhere. #307 is written
  to be the first caller.

Worth 2–3 issues and a design decision. It is not polish.

**Product and UX, unfiled:**
- `_NotFoundScreen` (`app_router.dart:177-183`) is `Center(child: Text('עמוד לא נמצא'))`
  — no back button, no route home. A dead end.
- The desktop lens copy (`camera_screen.dart:61-72`) says to install Tesseract
  and names no package, no command and no link. `CLAUDE.md` has the exact
  apt/brew lines; the user-facing string does not. `m6_platform_handoff.md`
  adds that an installer story does not exist.
- `TesseractJsTextRecognizer.warmUp()` exists and **nothing calls it** — the
  first browser scan of a session pays the model load.
- `ScanFailed.rawText` is carried and never shown. A debug affordance would pay
  for itself during #256.
- Two dead placeholder widgets the router never imports —
  `dashboard_placeholder.dart`, `diary_placeholder.dart`.
- The dashboard is six sections long; `m5_handoff.md` notes the symptom strip
  pushed the last one off a 600pt viewport.

**Correctness, unfiled:**
- **An app left in the foreground across midnight still shows a stale `today`.**
  `today_tracker.dart` covers resume-from-background only; its doc comment
  explains that closing the gap needs a timer, and a pending timer at the end
  of a `testWidgets` body fails the test.
- **Release APKs are signed with the debug key.**
  `android/app/build.gradle.kts:53-55` still carries Flutter's template TODO,
  and `build-android.yml:135` explicitly acknowledges it. This blocks any real
  Android release and belongs with `epic:release-v1`.
- The Windows daily reminder is one-shot — the Windows path silently drops
  `matchDateTimeComponents`, so a user who stops opening the app stops being
  reminded.
- **The macOS App Sandbox may block the Homebrew libtesseract dylib.**
  `m6_platform_handoff.md` says it *"wants its own issue"* and that it is not
  resolvable without a Mac.
- `ios/Podfile.lock` is gitignored by the root `*.lock` rule.
- `EntityNotFoundException` still has no throw site, from M1.
- CI does not check codegen freshness — `cicd_plan.md` Phase 1.

**Already filed elsewhere, listed so nobody re-files them:** #234 (reminder
fires on compliant days), #262 (no way to skip onboarding), #256 (OCR accuracy
unmeasured), #258 (camera/gallery adapter coverage), #165 (M2 issue text).
**#257 is closed** — fixed in PR #281; several docs still describe it as the
highest-value open defect and are struck through. Image pre-processing is now
the cheapest remaining accuracy win, and it is Epic #10's.

---

## Part 6 — What this audit could not verify

Stated plainly, because M7 has more platform work than any milestone since M0.

- **No iOS device and no macOS host.** `flutter run` has never executed on
  either. #92's icon, #311's launch colour and #151's localisation are all
  build-verified and **never seen**. Epic #4 stays open on this.
- **No camera.** Unchanged from M6.
- **Android and Windows compile and only compile** — no window has opened on
  either. #311's Android theme change is reasoned from the resource-resolution
  rules, not observed.
- **Web and Linux can be looked at**, and should be: the browser check has
  found a bug in every milestone that used it, including one that 482 passing
  tests missed. #307's contrast defect was found that way and by no other
  means. Any M7 issue touching a visible surface should ship a browser
  screenshot in its PR.
