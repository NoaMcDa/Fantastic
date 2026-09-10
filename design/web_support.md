# Web Support — Handoff

**Status:** shipped. `flutter run -d chrome` boots the app, data persists in
IndexedDB across reloads, and `flutter build web` is a CI gate.

Read this before touching `lib/core/database/`, any `data/mappers/` codec, or
anything that adds a plugin dependency.

---

## 1. Why Isar had to go

Two things blocked the browser, and only one of them was fixable in place.

**`path_provider` has no web implementation.** `getApplicationDocumentsDirectory()`
threw a `MissingPluginException` out of `main()` before `runApp`, so the tab
showed a blank page with nothing in the console to act on.

**`isar_community` 3.3.2 cannot open a database on web at all.** Not a flag, not
a config — its web `openIsar()` is a stub whose entire body is:

```dart
throw IsarError(
  'Please use Isar 2.5.0 if you need web support. '
  'A 3.x version with web support will be released soon.',
);
```

The real implementation below it is commented out upstream
(`isar_community-3.3.2/lib/src/web/open.dart`). There is no version of Isar 3
that opens in a browser.

That left two options: keep Isar on native and write a second storage backend
for web, or replace Isar everywhere with one store that runs on both. The second
was chosen — one implementation, one set of contract tests, no drift between two
backends that have to behave identically.

## 2. Why sembast

| Concern | Choice | Why not the alternative |
|---|---|---|
| Store | `sembast` ^3.8.10 | Pure Dart, no native binary, no codegen. Its model — named stores of `Map<String, Object?>` records under `int` keys, plus record streams — is a near-exact match for what the four repositories already did, so the interfaces did not move. |
| Browser backend | `sembast_web` ^2.4.6 | IndexedDB via `package:web`, **not** the deprecated `dart:html`. That is what keeps `flutter build web --wasm` available; the wasm dry run already passes. |
| Tests | `newDatabaseFactoryMemory()` | Replaces a 150-line helper that imported `dart:io` and `dart:ffi` and dlopened `libisar.so` out of the pub cache. |
| Rejected | `drift` | Relational, and its web build needs `sqlite3.wasm` + a worker script committed into `web/`. Heavier than document-shaped data needs. |
| Rejected | `hive_ce` | Viable, but weaker query and stream story than sembast for `findAll` ordering and the streak `watch()`. |

Dropping `isar_community_generator` also removed the `analyzer` pin that forced
the original `isar` → `isar_community` swap. `build_runner` stays, for
`@riverpod` only.

## 3. What the migration cost

**Nothing above `data/`.** Not one widget, service, or provider signature
changed. Every feature already exposed its repositories through a domain
interface (`MealRepository`, `DailyLogRepository`, `SymptomLogRepository`,
`StreakRepository`), and the contract suites were already factory-parameterised
— `runMealRepositoryContractTests(factory, {required breakStore})` — with a
comment saying they existed "so any future backing store runs against the same
cases". This was that case, and **the contract bodies were not edited at all**.
Only each `main()` changed, to hand in a sembast repository and a
`breakStore: () => db.close()`.

That is the single most useful thing to know about this codebase: the
abstraction was not decoration, and it paid for itself.

## 4. Decisions a later change must not undo

- **`DailyLog.id` and `SymptomLog.id` are now the yyyyMMdd key**, not a
  generated id. Keying the record on its own date is what makes `save` an
  upsert without a unique index. Both are per-day aggregates only ever fetched
  by date, so nothing treats the id as an opaque handle.
- **Enums persist by `.name`.** `AdaptationPhase`'s doc comment used to say
  "append only" because Isar stored an ordinal through a mirror enum. That
  mirror enum is gone. Reordering the enum is now safe; **renaming a value is
  what orphans stored records.**
- **`DateTime` persists as epoch milliseconds.** Not a `DateTime` (sembast
  rejects it on write) and not an ISO string (lexicographic sort is only
  chronological while every record shares one UTC offset — DST reorders the
  diary).
- **Decode every number through `num`.** `(record['fatG']! as num).toDouble()`.
  IndexedDB's JSON hands a whole `40.0` back as an `int`, and `as double`
  throws. There is a regression test for this in each mapper suite.
- **Copy lists out of a record, do not cast them.** sembast returns an
  `ImmutableMap`/immutable list that throws `StateError` on mutation.
- **`lib/core/database/database_factory.dart` is the firewall.** It defaults to
  the *web* file and switches to io on `dart.library.io`, so every non-VM
  target gets the browser factory, including ones that do not exist yet. A
  `path_provider` or `dart:io` import anywhere else in `lib/` analyses clean and
  breaks only the web build — which is exactly why CI compiles for web.

## 5. Gotchas that cost time

- **`Finder` is ambiguous in tests.** `flutter_test` and `package:sembast` both
  export one. A test that needs sembast's must import it prefixed.
- **`flutter create --platforms=web .` silently drops other platforms from
  `.metadata`.** It deleted the `ios` block; it was restored by hand. Diff
  `.metadata` deliberately after ever running `flutter create`.
- **`onSnapshot` does fire immediately**, emitting the current record — or
  `null` when there is none — before any write. That is what `StreakRepository.watch()`'s
  contract requires, and it is a direct replacement for Isar's
  `fireImmediately: true`. Verified against the sembast source, not assumed.
- **A closed database throws `DatabaseException` from every store access**, and
  `onSnapshot` delivers that failure *asynchronously* on the stream rather than
  as a synchronous throw. `guardPersistenceStream` already guarded both halves.
- **CanvasKit is fetched from `gstatic.com` at run time by default**, so the app
  will not boot offline. `--no-web-resources-cdn` bundles it into the build, and
  the CI step uses that flag. Use it for any deploy.

## 6. Known gap — Hebrew glyphs on web depend on a font download

CanvasKit has no Hebrew glyphs of its own. It fetches Noto Sans Hebrew from
`fonts.gstatic.com` on first paint. With a working connection this is invisible.
**Offline, or behind a network that blocks Google Fonts, every Hebrew string
renders as tofu boxes** — verified in a sandboxed Chromium, where the layout,
theme, RTL direction and data were all correct and only the glyphs were missing.

The fix is to bundle a Hebrew font as an asset and set `fontFamily` on
`AppTheme.dark`. That is deliberately **not** in this change: it adds a binary
asset, changes typography on iOS as well as web, and the font choice belongs to
`design/ui_ux_design.md` and `design/design_system.md` rather than to a storage
migration. It should be its own issue.

## 7. Verification performed

- `dart format`, `flutter analyze` — clean.
- `flutter test` — 486 tests pass, including the four unedited contract suites
  now running against sembast.
- `flutter build web --release` — succeeds; the wasm dry run also passes.
- Booted in headless Chromium: dashboard renders RTL on `#1C1C1E` with no white
  flash, `fantastic.db` appears in IndexedDB, zero console errors.
- **Logged a meal through the UI, hard-reloaded the page, and the meal came
  back** — the actual proof that IndexedDB persistence works end to end.
