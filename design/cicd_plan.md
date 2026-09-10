# CI/CD Plan

Status: **proposal** — nothing in this document is implemented yet.

---

## 1. What exists today

**Nothing.** There is no `.github/` directory in the repository — no workflows,
no dependabot config, no issue or PR templates. No pipeline has ever run against
this codebase. Every quality gate the project claims is, in practice, a manual
pre-commit habit:

| Gate | Where it is defined | Who enforces it today |
|---|---|---|
| `flutter analyze` clean | `design/developing_rules.md` §4 | the developer, by hand |
| `dart format` clean | `design/developing_rules.md` §4 | the developer, by hand |
| `flutter test` green | `design/developing_rules.md` §4 | the developer, by hand |
| 80% coverage, `domain/` + `application/` | `design/tests.md` §CI Integration | **nobody — never measured** |
| Codegen up to date | `CLAUDE.md` §Common Commands | the developer, by hand |
| Integration tests | `design/tests.md` §CI Integration | nobody — none written |

`design/pr_conventions.md:171` states the position exactly: *"CI must be green on
the merge commit before merging is allowed, **once the CI workflow (issue #102,
M8) exists**. Until then, the local validation gate is the only gate."*

### What is planned

CI is a single issue — **#102**, "Set up GitHub Actions CI workflow" — sitting at
the very end of **M8**, the last milestone before App Store submission. It is
blocked by #95–#101 (the seven integration tests) and carries a full YAML
snippet in its Implementation Plan.

**CD does not appear anywhere.** No design document mentions code signing,
provisioning profiles, App Store Connect API keys, build-number strategy,
TestFlight automation, or release branching. The only trace is four unchecked
manual checkboxes in `design/tasks.md` under "App Store Submission":

```
- [ ] Add Hebrew App Store Connect metadata (description, keywords, screenshots)
- [ ] Complete Apple privacy nutrition labels
- [ ] Submit for TestFlight review with 20–30 beta users
- [ ] Address beta feedback; submit to App Store
```

So: **the answer to "do we have any?" is no — we have one planned CI issue,
scheduled last, and no CD plan at all.** This document is that plan.

---

## 2. The headline recommendation: move CI forward, now

CI is currently the ~100th issue to be merged. The project is at **M2 of M8**.
Scheduling the regression gate to arrive after the regressions is backwards, and
three concrete facts make it worse than a general principle:

1. **Three tests have never been observed passing.** `design/m0_handoff.md`
   §"Known issues" records that all of `test/helpers/test_isar_test.dart` fails
   in this environment because `Isar.initializeIsarCore(download: true)` fetches
   the native engine from `binaries.isar-community.dev`, which the sandbox
   blocks (403, policy — not transient). A GitHub-hosted runner has unrestricted
   egress. **The first CI run is the first honest `flutter test` this project has
   ever had**, and every repository contract test in M1 is built on that helper.
2. **The coverage gate has never been measured.** 80% on `domain/` +
   `application/` is asserted in two documents and enforced by nothing. Nobody
   knows the current number.
3. **The gate is currently vacuous on half its scope.** `lib/` contains
   **zero** files under any `application/` directory (14 under `domain/`). A
   gate written naively against "domain + application" passes today by having
   nothing to measure — see §5.3.

Bringing analyze/format/test online during M2 costs one afternoon and starts
paying immediately. The coverage gate and integration tests can still land in
M8; they are separable, and §7 phases them.

---

## 3. Corrections to issue #102

Issue #102's YAML is a reasonable sketch but it will not work as written. Per
this repo's pre-flight convention (`design/m1_preflight.md`,
`design/m2_preflight.md`), the corrections are recorded here rather than
discovered at 2am.

| # | Issue #102 says | Reality | Fix |
|---|---|---|---|
| 1 | `dart run build_runner build --delete-conflicting-outputs` | The flag **was removed** in build_runner 2.15.1, which prints `W These options have been removed and were ignored` (`design/m1_handoff.md` §"Two related notes") | Drop the flag |
| 2 | `- run: dart run build_runner build ...` as a plain step | `build_runner` **completes its work and then never exits** — ~1s of work, then it idles in `futex_do_wait` forever (`design/m1_handoff.md` §"The `build_runner` hang"). A bare step hangs the job until GitHub's 6-hour limit | Wrap in `timeout`, treat exit 124 as success, verify by diff |
| 3 | CI regenerates `.g.dart` before testing | All 10 `.g.dart` files are **committed** and not gitignored | CI should **verify committed codegen is current**, not regenerate it. This is a drift check, and it is strictly more useful |
| 4 | `very_good_coverage` on `coverage/lcov.info` | This project's lcov output has **no `LF:`/`LH:` summary lines**, only `DA:` records (`design/m1_handoff.md`). An `LF`-based reader computes `0/0` and reports **100% for every file** | Custom `DA:`-counting script (§5.3). A gate that always passes is worse than no gate |
| 5 | `min_coverage: 80` over the whole report | The stated gate is 80% on **`domain/` + `application/` only**; `data/` and `presentation/` are explicitly excluded (`design/tests.md`) | Filter by path before computing the percentage |
| 6 | `flutter-version: '3.27.x'` | `pubspec.yaml` requires Dart `^3.13.2`, and `.metadata` pins revision `d3b14c876900e553bc736ca19295fc09e3853e8e` on `stable`. Flutter 3.27 ships Dart 3.6 and **cannot resolve this pubspec** | Pin an exact version matching `.metadata`. Confirm with `flutter --version` on the machine that produced it before writing the number down |
| 7 | Three jobs, each installing Flutter | Runner setup (~1–2 min) dominates; `analyze` and `format` take seconds. Three jobs triples the setup cost for a serial gain of nothing | One `verify` job, steps ordered cheapest-first. Split only if per-check status granularity is wanted for branch protection |

An eighth, not a correction but an operational note: **the Isar native binary is
downloaded from `binaries.isar-community.dev` on every test run.** That is a
third-party host in the critical path of every CI run. Cache it (§5.4) so an
outage there does not turn every PR red.

---

## 4. Target pipeline

```
                        ┌───────────────────────────────────────┐
  PR → main             │ ci.yml           (ubuntu, ~4 min)     │
  push → main           │  • analyze                            │
                        │  • format --set-exit-if-changed       │
                        │  • test --coverage                    │
                        │  • coverage gate (domain+application) │
                        │  • codegen drift check                │
                        └───────────────────────────────────────┘
                                          │ required check
                                          ▼
                        ┌───────────────────────────────────────┐
  push → main           │ testflight.yml   (macOS, ~15 min)     │
                        │  • build ipa, signed                  │
                        │  • upload → TestFlight internal       │
                        └───────────────────────────────────────┘
                                          │
                                          ▼
                        ┌───────────────────────────────────────┐
  tag v*.*.*            │ release.yml      (macOS + approval)   │
                        │  • promote build → App Store review   │
                        └───────────────────────────────────────┘

  nightly 02:00 UTC     ┌───────────────────────────────────────┐
                        │ integration.yml  (macOS, simulator)   │
                        │  • integration_test/ on iPhone sim    │
                        └───────────────────────────────────────┘
```

Four workflow files, plus `dependabot.yml`. Trigger rules:

| Workflow | Trigger | Runner | Blocking? |
|---|---|---|---|
| `ci.yml` | `pull_request` → `main`, `push` → `main` | `ubuntu-latest` | **Yes** — required check |
| `integration.yml` | `schedule` nightly, `workflow_dispatch` | `macos-latest` | No — reported, not blocking |
| `testflight.yml` | `push` → `main`, `workflow_dispatch` | `macos-latest` | n/a |
| `release.yml` | `push` tag `v*.*.*` | `macos-latest` + environment approval | n/a |

Why iOS builds are absent from `ci.yml`: `flutter build ios` requires a macOS
runner, billed at **10× the minute rate** of Linux. Running it per-PR on a
private repo burns the whole free allowance in a week (§8). A compile break that
is iOS-specific — and not caught by `flutter analyze`, which is
platform-independent — is rare enough to catch on merge rather than on every
push. Revisit if it ever bites.

---

## 5. CI design (`ci.yml`)

### 5.1 Workflow

```yaml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

# A new push to a PR makes the in-flight run obsolete. Cancel it.
concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

env:
  # Must match .metadata's pinned revision. See §3 correction 6 — confirm the
  # exact patch with `flutter --version` before changing this.
  FLUTTER_VERSION: '3.35.x'

jobs:
  verify:
    name: analyze · format · test
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
          cache: true

      - name: Resolve dependencies
        # pubspec.lock is committed (#159) so this must not drift.
        run: flutter pub get

      # Cheapest checks first: a formatting slip should fail in 5s, not 4min.
      - name: Format
        run: dart format --output=none --set-exit-if-changed lib/ test/

      - name: Analyze
        run: flutter analyze --no-pub

      - name: Cache Isar native engine
        # initializeIsarCore(download: true) pulls libisar from
        # binaries.isar-community.dev on every run. Cache it so a third-party
        # outage does not redden every PR. Confirm the emitted path on the
        # first green run and correct this glob if needed.
        uses: actions/cache@v4
        with:
          path: |
            libisar*.so
            .dart_tool/isar*
          key: isar-${{ runner.os }}-${{ hashFiles('pubspec.lock') }}

      - name: Test
        run: flutter test --coverage --no-pub

      - name: Coverage gate — domain + application ≥ 80%
        run: tool/check_coverage.sh coverage/lcov.info 80

      - name: Upload coverage artifact
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: lcov
          path: coverage/lcov.info
          retention-days: 14

  codegen:
    name: codegen drift
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
          cache: true

      - run: flutter pub get

      - name: Regenerate
        # build_runner finishes in ~1s and then never exits (m1_handoff.md).
        # Exit 124 from `timeout` is the expected success path; the real
        # verdict is whether any tracked file changed.
        run: timeout 180 dart run build_runner build --verbose || true

      - name: Assert committed .g.dart files are current
        run: |
          if ! git diff --exit-code -- '*.g.dart'; then
            echo "::error::Generated code is stale. Run 'timeout 120 dart run build_runner build --verbose' and commit the result."
            exit 1
          fi
```

`codegen` is a second job on purpose — it is the one check that can be slow and
flaky (cold `.dart_tool/build` cache: minutes), and isolating it keeps a
`build_runner` hiccup from masking a genuine test failure.

### 5.2 Why not three jobs

Issue #102 proposes `analyze` / `format` / `test` as separate jobs. Each pays
~1–2 min of Flutter installation for a check that takes seconds. Merged into one
`verify` job and ordered cheapest-first, the same information arrives sooner and
costs a third as much. The only thing lost is a per-check green tick in the PR
status list — recoverable via step annotations, and not worth 2× the runtime.

### 5.3 The coverage gate — `tool/check_coverage.sh`

Two independent traps make the off-the-shelf action unsuitable:

- **No `LF:`/`LH:` lines.** `very_good_coverage` and most lcov readers derive
  the percentage from those summary records. This project emits only
  `DA:<line>,<hits>`, so a naive reader sees `0/0` and reports 100%. The gate
  would pass forever, silently.
- **Scope.** The contract is 80% on `domain/` + `application/`, not on `lib/`.
  Including `data/` and `presentation/` — which are covered by contract and
  widget tests instead — measures the wrong thing in both directions.

```bash
#!/usr/bin/env bash
# tool/check_coverage.sh — enforce the domain + application line-coverage gate.
#
# Counts DA: records directly: this project's lcov.info carries no LF:/LH:
# summary lines, and an LF-based reader reports a misleading 100% for every
# file (see design/m1_handoff.md).
set -euo pipefail

LCOV="${1:-coverage/lcov.info}"
MIN="${2:-80}"

[ -f "$LCOV" ] || { echo "No coverage file at $LCOV"; exit 1; }

awk -v min="$MIN" '
  /^SF:/ {
    file  = substr($0, 4)
    gated = (file ~ /\/domain\// || file ~ /\/application\//) && file !~ /\.g\.dart$/
    tot = 0; hit = 0
  }
  /^DA:/ { split(substr($0, 4), a, ","); tot++; if (a[2] + 0 > 0) hit++ }
  /^end_of_record/ {
    if (gated && tot > 0) {
      total += tot; hits += hit
      printf "  %-58s %3d/%3d\n", file, hit, tot
    }
  }
  END {
    if (total == 0) {
      print "FAIL: no gated lines found — refusing to pass a vacuous gate."
      exit 1
    }
    pct = 100 * hits / total
    printf "\nGated coverage (domain + application): %d/%d = %.2f%% (min %d%%)\n",
           hits, total, pct, min
    exit (pct + 0 < min + 0) ? 1 : 0
  }
' "$LCOV"
```

**The `total == 0` guard is load-bearing.** `lib/` has no `application/`
directory yet; without the guard, a future refactor that renames a layer would
turn the gate into a no-op and nobody would notice.

**Known gap — untested files are invisible.** `flutter test --coverage` emits an
`SF:` record only for files some test imports. A `domain/` file with no test at
all does not appear in `lcov.info` and therefore cannot drag the percentage
down. Close it with a companion check:

```bash
# Every gated source file must appear in the report.
comm -23 \
  <(find lib -path '*/domain/*' -o -path '*/application/*' | grep -v '\.g\.dart$' | sort) \
  <(grep '^SF:' coverage/lcov.info | cut -c4- | sort) \
  | grep . && { echo "::error::Files above have no coverage record — no test imports them."; exit 1; } || true
```

Land this as part of Phase 2, once M2 has produced enough `application/` code
for the number to mean something. Enabling an 80% gate against 14 domain files
today mostly measures fixture quality.

### 5.4 Caching

| What | Key | Saves |
|---|---|---|
| Flutter SDK + pub cache | `subosito/flutter-action`'s `cache: true` | ~90s/run |
| Isar native engine | `pubspec.lock` hash | ~10s + removes a third-party host from the critical path |
| `.dart_tool/build` | `pubspec.lock` hash, `codegen` job only | minutes on a cold builder cache |

### 5.5 Branch protection

Once `ci.yml` has one green run on `main`, configure on `main`:

- Require status checks to pass: **`analyze · format · test`**, **`codegen drift`**
- Require branches to be up to date before merging
- Require a pull request before merging (already the convention in
  `design/pr_conventions.md`; this makes it mechanical)
- Squash merge only, matching `design/pr_conventions.md` §Review & merge

---

## 6. CD design

Nothing here exists yet in any form; all of it is new.

### 6.1 Choosing a build host

| Option | Cost | Verdict |
|---|---|---|
| **GitHub Actions, `macos-latest` + fastlane** | 10× minute multiplier; ~200 effective macOS min/mo on the free private-repo tier | **Recommended.** One CI system, one secrets store, same review surface as the code. The multiplier is affordable because iOS builds run on merge and tag, not per-PR |
| Codemagic | Free tier ~500 min/mo, Flutter-native | Strong alternative — better out-of-the-box signing UX. Costs a second system, a second secrets store, and a second place to debug |
| Xcode Cloud | Bundled with the Apple Developer account | Poor fit: Flutter support is bolt-on, and configuration lives in App Store Connect rather than in the repo |

Recommendation: **GitHub Actions + fastlane.** Revisit if macOS minutes become
the binding constraint.

Note the environment reality from `design/m1_handoff.md` §"Known blockers": *no
macOS host has ever run this app* — `flutter run` on a simulator has never been
verified, which is why Epic #4 is still open. **The first `testflight.yml` run
is also the first iOS build this project has ever had.** Budget a day for it,
not an hour, and expect the failures to be Podfile/entitlement-shaped rather
than pipeline-shaped. `ios/` currently has no `Podfile` — it is generated on the
first `flutter build ios` with plugins present.

### 6.2 Signing

**fastlane match**, backed by a private git repository of encrypted
certificates and profiles. The alternative — importing a `.p12` from secrets on
each run — works but puts certificate rotation back in a human's hands.

Set up once, on a Mac:

```bash
cd ios && fastlane match init          # points at the private certs repo
fastlane match appstore                # creates + stores the distribution identity
```

Then `ios/fastlane/Fastfile`:

```ruby
default_platform(:ios)

platform :ios do
  desc "Build and upload to TestFlight (internal testers)"
  lane :beta do
    setup_ci                            # keychain handling on ephemeral runners

    app_store_connect_api_key(
      key_id:      ENV["ASC_KEY_ID"],
      issuer_id:   ENV["ASC_ISSUER_ID"],
      key_content: ENV["ASC_KEY_P8"],
      in_house:    false,
    )

    match(type: "appstore", readonly: true)

    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store",
    )

    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      distribute_external: false,        # internal group only; external needs review
      changelog: ENV["CHANGELOG"] || "Automated build from main.",
    )
  end

  desc "Promote the latest TestFlight build to App Store review"
  lane :release do
    app_store_connect_api_key(
      key_id:      ENV["ASC_KEY_ID"],
      issuer_id:   ENV["ASC_ISSUER_ID"],
      key_content: ENV["ASC_KEY_P8"],
    )
    deliver(
      submit_for_review: true,
      automatic_release: false,          # a human presses "release" in ASC
      force: true,                       # no interactive HTML preview on CI
      skip_binary_upload: true,
      skip_screenshots: true,            # Hebrew screenshots managed manually (tasks.md)
      precheck_include_in_app_purchases: false,
    )
  end
end
```

### 6.3 Versioning

`pubspec.yaml` carries `version: 1.0.0+1`. Two rules:

- **Build number** (`+N`, `CFBundleVersion`) must be strictly increasing per
  upload or App Store Connect rejects it. Derive it from
  `${{ github.run_number }}` — monotonic, unique, and never needs a commit.
- **Build name** (`1.0.0`, `CFBundleShortVersionString`) comes from
  `pubspec.yaml` on `main` builds, and from the git tag on releases (`v1.2.3` →
  `1.2.3`), with the workflow asserting the two agree before a release build.

```bash
flutter build ipa --release \
  --build-name="${BUILD_NAME}" \
  --build-number="${{ github.run_number }}"
```

This keeps `pubspec.yaml` the single human-edited source of the marketing
version and takes the mechanical counter out of the diff entirely.

### 6.4 `testflight.yml`

```yaml
name: TestFlight

on:
  push:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: testflight            # never two uploads at once
  cancel-in-progress: false

jobs:
  build:
    runs-on: macos-latest
    timeout-minutes: 45
    environment: testflight    # secrets scoped here, not repo-wide
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.x'
          channel: stable
          cache: true

      - run: flutter pub get

      - name: Build IPA
        run: |
          BUILD_NAME=$(grep '^version:' pubspec.yaml | sed 's/version: //' | cut -d+ -f1)
          flutter build ipa --release \
            --build-name="$BUILD_NAME" \
            --build-number="${{ github.run_number }}" \
            --export-options-plist=ios/ExportOptions.plist

      - name: Upload to TestFlight
        working-directory: ios
        env:
          ASC_KEY_ID:      ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID:   ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_P8:      ${{ secrets.ASC_KEY_P8 }}
          MATCH_PASSWORD:  ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_BASIC_AUTHORIZATION: ${{ secrets.MATCH_GIT_BASIC_AUTHORIZATION }}
          CHANGELOG: ${{ github.event.head_commit.message }}
        run: bundle exec fastlane beta
```

`release.yml` is the same shape on a `v*.*.*` tag, calling `fastlane release`,
with its `environment:` configured to **require a manual reviewer approval** —
that approval is the one deliberate human gate between a green pipeline and
Apple's review queue.

### 6.5 `integration.yml`

`design/tests.md` already specifies nightly, not per-PR ("too slow"). Seven
flows are scoped as #95–#101.

```yaml
name: Integration tests

on:
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:

jobs:
  simulator:
    runs-on: macos-latest
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.35.x', channel: stable, cache: true }
      - run: flutter pub get
      - name: Boot simulator
        run: |
          xcrun simctl boot "iPhone 16" || true
          xcrun simctl list devices booted
      - run: flutter test integration_test/ -d "iPhone 16"
```

Failures notify rather than block. A nightly that blocks nothing but is watched
by nobody is theatre — assign it an owner or route it to a channel.

### 6.6 Secrets inventory

Store in a GitHub **Environment** (`testflight` / `release`), not as repo-wide
secrets, so the App Store credentials are unreachable from a PR workflow.

| Secret | Source | Used by |
|---|---|---|
| `ASC_KEY_ID` | App Store Connect → Users and Access → Integrations → App Store Connect API | fastlane |
| `ASC_ISSUER_ID` | same page | fastlane |
| `ASC_KEY_P8` | the downloaded `.p8`, whole file contents | fastlane |
| `MATCH_PASSWORD` | chosen at `match init` | match decryption |
| `MATCH_GIT_BASIC_AUTHORIZATION` | base64 `user:token` for the private certs repo | match checkout |

None of these may ever be referenced from `ci.yml` — `pull_request` workflows
run on untrusted contributor code.

---

## 7. Phased rollout

Each phase is independently shippable and leaves the repo in a valid state,
per `design/issue_conventions.md` §atomicity.

| Phase | When | Contents | Proposed issues |
|---|---|---|---|
| **0** | **Now (during M2)** | `ci.yml` `verify` job: analyze, format, test. No coverage gate yet. Branch protection on. | Re-scope **#102**, pull out of M8 |
| **1** | Now + 1 | `codegen` drift job; Isar binary cache; `dependabot.yml` for `pub` + `github-actions` | new |
| **2** | M4–M5, once `application/` has real services | `tool/check_coverage.sh`, gate at 80%, missing-file check; ratchet the number up as it rises | new |
| **3** | M8, after #95–#101 land | `integration.yml` nightly on simulator | new, alongside **#150** |
| **4** | M8 / post-M8 | fastlane, match, `ExportOptions.plist`, `testflight.yml` — **the first iOS build** | new |
| **5** | Pre-submission | `release.yml`, tag flow, environment approval, Hebrew metadata via `deliver` | new; folds in `tasks.md` App Store items |

Phase 0 is the one that matters. Phases 4–5 need an Apple Developer account, a
bundle identifier, and at least one person with a Mac — obtain those before the
phase, not during it.

### Effect on existing issues

- **#102** — keep the issue, re-scope to Phase 0 only, move out of M8 to an
  infrastructure milestone that can run now, and correct its Implementation
  Plan per §3. Its current Upstream Dependencies ("blocked by #95–#101") should
  be deleted: analyze/format/test depend on none of them.
- **#150** (`integration_test` scaffold) — unchanged; it gates Phase 3.
- **Epic #12** — gains Phases 3–5; Phase 0–2 move to the new infra milestone.
- `design/pr_conventions.md:171-172` — update once Phase 0 is green, since the
  "until then" clause it describes will no longer apply.

---

## 8. Cost

GitHub Actions, private repo, free tier: 2,000 min/mo, macOS billed **10×**.

| Workflow | Runner | Est. duration | Frequency | Effective min/mo |
|---|---|---|---|---|
| `ci.yml` | ubuntu | ~4 min × 2 jobs | ~60 runs | ~480 |
| `integration.yml` | macOS | ~20 min | 30 nightly | ~6,000 ⚠️ |
| `testflight.yml` | macOS | ~15 min | ~8 merges | ~1,200 ⚠️ |
| `release.yml` | macOS | ~15 min | ~1 | ~150 |

**The nightly integration run alone exceeds the free tier by 3×.** Mitigations,
in order of preference: run it weekly rather than nightly until the suite earns
its keep; make the repository public (unlimited Actions minutes); or move macOS
work to Codemagic's free tier and keep Linux CI on GitHub. Decide before Phase 3
— this is the one line item that forces a real choice.

---

## 9. Open questions

1. **Apple Developer account** — does one exist? Individual or Organization?
   Everything from Phase 4 on is blocked on it, and enrolment can take days.
2. **Bundle identifier** — not yet set to anything real; needs deciding before
   the first App Store Connect app record.
3. **macOS access** — who runs the one-time `fastlane match init`? It cannot be
   done from a Linux container.
4. **Nightly budget** — public repo, weekly cadence, or Codemagic? (§8)
5. **Codecov** — `design/tests.md` says coverage is "uploaded to Codecov". Worth
   the third-party integration, or is the artifact + gate enough? Recommendation:
   artifact + gate for now; add Codecov if PR-level coverage diffs are wanted.
6. **Flutter version pinning** — resolve `.metadata`'s revision to an exact
   version and record it in one place. An `.fvmrc` would make the workflow, the
   docs, and every developer's machine agree.

---

## 10. Verification status

Nothing in this document has been executed. Flutter is not installed in this
container (`design/m0_handoff.md` §"Notes for a fresh session"), and the YAML
here has never been run by GitHub Actions. It is written against the repository
as it stands and against the corrections recorded in the M0/M1 handoffs, but the
first run of Phase 0 will find something — expect the Flutter version pin and
the Isar cache path (§5.4) to be the two most likely to need adjusting.
