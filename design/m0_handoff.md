# M0 Foundation — Handoff

> **Superseded in part:** Isar was replaced by **sembast + sembast_web** when web
> support landed — see `design/web_support.md` and `CLAUDE.md` §Local Persistence.
> Everything below is kept as a record of what was true at the time and is not a
> description of the current data layer.

State of the project as M0 closed, and what M1 needs to know before starting.
Written at the end of the session that implemented M0 (issues #14–#24).

## Status

**M0 is complete and merged to `main`.** All 11 issues (#14–#24) are closed and
their code is on `main` as of PR #145. Epic #4 is still open — it needs a
closure comment and its checklist ticked (see Loose ends).

`main` currently passes: `flutter analyze` (zero issues), `dart format --check`
(zero diffs), `dart run build_runner build` (no diffs — all `.g.dart` are
current), and **19 of 22 tests** (the 3 failures are environment-only — see
Known issues).

What M0 actually delivered:

| Area | Files |
|---|---|
| Dependencies | `pubspec.yaml` — riverpod, isar_community, go_router, path_provider, flutter_localizations, + codegen/test dev deps |
| Lints | `analysis_options.yaml` — 10 strict rules, `.g.dart`/`.freezed.dart` excluded |
| Codegen | `lib/core/utils/app_version.dart` (+`.g.dart`) — proves the `build_runner` pipeline |
| Routing | `lib/core/router/app_router.dart` (+`.g.dart`), `app_shell.dart` — `GoRouter` + `ShellRoute` + Material 3 `NavigationBar`, 5 MVP tabs |
| Theme | `lib/core/theme/app_theme.dart`, `lib/main.dart` — RTL root, Hebrew locale, dark theme |
| Constants | `lib/core/constants/` — keto ratio, electrolyte-per-phase, ingredient rule lists + barrel |
| Persistence | `lib/core/database/isar_provider.dart` (+`.g.dart`), `lib/main.dart` — Isar opened at startup, injected via `isarProvider` |
| Feature scaffolds | `lib/features/*/presentation/*_placeholder.dart` — 8 screens, all routed |
| Test infra | `test/fixtures/` (stubs), `test/helpers/test_isar.dart` (+ smoke test) |

Tests: 22 cases across `test/widget_test.dart` (6), `test/core/router/app_shell_test.dart` (6),
`test/core/constants/constants_test.dart` (6), `test/core/database/isar_provider_test.dart` (1),
`test/helpers/test_isar_test.dart` (3).

## Corrections made to the issue specs — read this before trusting a closed issue

Seven things in the M0 issue text did not survive contact with a real build. The
code on `main` is correct; **the closed issues still describe the broken
version.** M1 issues written against the same assumptions may carry the same
mistakes.

1. **`isar` → `isar_community`.** The original `isar`/`isar_flutter_libs`/`isar_generator`
   `^3.1.0` pin `analyzer <6.0.0` and cannot resolve alongside `riverpod_generator`
   at any version. Swapped to the community fork (`isar_community*` `^3.3.2`,
   same API). **All M1 schema work uses `package:isar_community/isar.dart`.**
2. **riverpod `^2.6.1` → `^3.0.2`** (`flutter_riverpod`, `riverpod_annotation`,
   `riverpod_generator` together) — 2.6.x's generator can't co-resolve with
   `isar_community_generator`. `@riverpod`, `Ref`, `ConsumerWidget`, `ProviderScope`
   are unchanged; note riverpod 3 wraps provider-thrown errors in an internal
   `ProviderException` (not publicly exported — assert on `toString()`).
3. **`riverpod_test ^2.4.0` does not exist** (real package tops out at 0.1.9 and
   pins riverpod 2.x). Dropped — use riverpod 3's own `ProviderContainer.test()`.
   `design/architecture.md` still lists `riverpod_test`; it is not a dependency.
4. **`path_provider` and `flutter_localizations`** were needed by #21/#18 but
   listed in no issue's dependency table. Both are in `pubspec.yaml` now.
5. **#16's `missing_required_param: error` is not a real diagnostic code** (it
   predates null safety; the modern one, `missing_required_argument`, is already
   a compile error). An unrecognised code in `analysis_options.yaml` breaks
   `flutter analyze` itself. Dropped.
6. **#24's `Isar.initializeIsarCore(download: false)` is wrong** — `flutter test`
   runs headless with no plugin-bundled native lib. Uses `download: true`,
   matching `design/tests.md`'s own reference snippet.
7. **#22's placeholder set didn't match #17/#19's tab list.** There is no
   `profile` feature among `architecture.md`'s 7, yet `/profile` is the 5th MVP
   tab; conversely restaurant/recipe/directory have no tab. Resolved per
   `CLAUDE.md`'s MVP Scope (restaurant + recipe are v1.1): added an 8th
   `lib/features/profile/`, and wired restaurant/recipe/directory as non-tab
   top-level routes (`/restaurants`, `/recipe`, `/directory`) outside the
   `ShellRoute`. `design/ui_ux_design.md`'s tab-bar sketch (Restaurants instead
   of Adaptation) is **stale** — it predates the MVP-scoping decision.

## Known issues

> **⚠️ SUPERSEDED — this section is no longer true.** The helper was rewritten
> during M1: `test/helpers/test_isar.dart` resolves `libisar.so` from the
> installed `isar_community_flutter_libs` package via
> `.dart_tool/package_config.json` instead of downloading it, so no network
> access is involved. All 316 tests, these three included, pass on Linux.
> Verified 2026-09-10 while implementing CI (`design/cicd_plan.md` §10). The
> account below is kept as the historical record of why the helper changed.

**3 failing tests — `test/helpers/test_isar_test.dart`** (`openTestIsar returns
an open Isar instance`, `two sequential calls return different instances`,
`a closed instance cannot be reused`).

All three fail identically at the same first step: `openTestIsar()` calls
`Isar.initializeIsarCore(download: true)`, which downloads Isar's native engine
binary from `binaries.isar-community.dev` — a host blocked by the Claude Code
remote sandbox's egress policy (confirmed 403 policy denial, not transient).
On a real machine or CI runner with normal internet this should just work; in a
real *app* build the binary ships bundled by `isar_community_flutter_libs` and
no download happens at all.

The code is `analyze`-clean and matches `design/tests.md`'s reference
implementation, but **it has never been observed passing.** Run `flutter test`
once on a machine with unrestricted network before M1 builds repository
contract tests on top of this helper — if the helper is subtly wrong, better to
find out now than after a dozen contract-test files depend on it.

Related: `test/core/database/isar_provider_test.dart` covers the
"throws when not overridden" case but **not** "resolves via
`overrideWithValue`" — that needs a real `Isar` instance, blocked for the same
reason. Worth adding in M1 once a real DB can be opened.

## Notes for a fresh session in this environment

- **Flutter is not installed** in a new Claude Code remote container. Install:
  `git clone --depth 1 -b stable https://github.com/flutter/flutter.git /opt/flutter`,
  then symlink `flutter`/`dart` into `/usr/local/bin` (a `PATH` export does not
  survive between tool calls). ~3 min including the Dart SDK download.
- `pub.dev` and the Flutter release CDN are reachable; `binaries.isar-community.dev`
  is not (see above).
- **`build_runner` sometimes hangs on shutdown** after finishing its work — the
  codegen completes in seconds, then the process sits at near-zero CPU instead of
  exiting. Run it with a `timeout` and check `git status`: if no `.g.dart` changed,
  the build was a no-op and the hang is harmless.
- iOS simulator checks in every issue's Definition of Done are impossible here
  (Linux, no Xcode). Widget tests were written as the automated substitute;
  the simulator pass still needs doing on a Mac.

## Loose ends

- **Epic #4 is still open.** Per `design/milestone_conventions.md` §2 it needs:
  child checkboxes ticked, and a closure comment summarising what shipped.
- **`design/design_system.md` never reached `main`.** It was merged (PR #131)
  into `claude/design-7xblq9` *after* that branch had already merged to `main`,
  so it is stranded. Recover with:
  `git checkout -b docs/restore-design-system main && git cherry-pick 1b5093f`
  (adds the design-system handoff doc + its `CLAUDE.md` table row). The canvas
  itself is fine: https://claude.ai/code/artifact/e323de65-33c4-473c-a56d-0fdb7980bf0c
- **Stacked PRs cost more than they saved.** M0 used the `pr_conventions.md` §2
  stacked pattern (each PR based on the previous). Every PR merged correctly —
  into its parent branch — but only #14 ever reached `main`, and recovering
  needed a consolidation PR (#145). For M1, prefer merging each PR to `main`
  before branching the next, or keep stacks to two levels.
- Branches from M0 (`chore/issue-14-*` … `chore/issue-22-*`,
  `feat/m0-foundation-consolidated`) are all merged and can be deleted.

## Next: M1 — Domain & Data (issues #25–#43, Epic #5)

Domain models, repository interfaces, Isar schemas, mappers, contract tests —
no UI. Starting points already in place from M0: `isarProvider` (register
schemas in `Isar.open([...])` in `lib/main.dart` as each lands),
`test/helpers/test_isar.dart` for contract tests, and `test/fixtures/*` stubs
whose doc comments carry the intended fixture API for each model — fill each in
as its domain model lands.
