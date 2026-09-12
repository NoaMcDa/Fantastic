# Testing Design — Fantastic

## Philosophy

Tests exist to catch regressions and encode behaviour contracts — not to inflate coverage numbers. Every test must be able to fail for a real reason. If deleting a test would make the suite less trustworthy, keep it. If it wouldn't, delete it.

Three rules:
1. **Test behaviour, not implementation.** Call public APIs; never assert on private state.
2. **One concept per test.** A test that checks two things is two tests that share a name.
3. **Arrange → Act → Assert, nothing else.** No logic inside a test body.

---

## Test Pyramid

```
                  ┌──────────┐
                  │  E2E /   │  ← few, slow, high confidence
                  │Integration│
                 ┌┴──────────┴┐
                 │   Widget   │  ← moderate, test UI contracts
                ┌┴────────────┴┐
                │    Unit      │  ← many, fast, test every rule
                └──────────────┘
```

| Layer | Count target | Speed | Tooling |
|---|---|---|---|
| Unit | ~200 tests | < 5s total | `dart test`, `mocktail` |
| Widget | ~60 tests | < 30s total | `flutter_test`, `mocktail` |
| Integration | ~11 flows | < 1 min | `integration_test` on `flutter-tester`, headless |

---

## Unit Tests

### What Gets Unit-Tested

Every class in the **domain** and **application** layers gets unit tests. Data and presentation layers are covered by integration and widget tests respectively.

### Domain Layer — Pure Logic, No Mocks Needed

#### `KetoRatioCalculator`
```dart
// test/features/dashboard/domain/keto_ratio_calculator_test.dart

test('returns correct ratio for standard keto macros', () {
  final calc = KetoRatioCalculator();
  expect(calc.calculate(fat: 100, netCarbs: 5, protein: 20), closeTo(4.0, 0.01));
});

test('returns 0 when fat is 0', () {
  expect(calc.calculate(fat: 0, netCarbs: 10, protein: 20), 0.0);
});

test('throws ArgumentError on negative inputs', () {
  expect(() => calc.calculate(fat: -1, netCarbs: 5, protein: 10),
      throwsArgumentError);
});
```

#### `AdaptationPhaseService`
```dart
// test/features/adaptation/application/adaptation_phase_service_test.dart

test('phase is induction on day 1', () {
  final state = StreakState(currentStreak: 1, ...);
  expect(service.currentPhase(state), AdaptationPhase.induction);
});

test('phase transitions to fatAdapted on day 8', () {
  final state = StreakState(currentStreak: 8, ...);
  expect(service.currentPhase(state), AdaptationPhase.fatAdapted);
});

test('phase transitions to deepKetosis on day 29', () {
  final state = StreakState(currentStreak: 29, ...);
  expect(service.currentPhase(state), AdaptationPhase.deepKetosis);
});

test('recording a compliant day increments streak', () {
  final result = service.recordCompliantDay(state, DateTime(2026, 9, 9));
  expect(result.currentStreak, state.currentStreak + 1);
});

test('breach starts grace period, does not reset streak immediately', () {
  final result = service.handleBreach(state, DateTime(2026, 9, 9));
  expect(result.inGracePeriod, true);
  expect(result.currentStreak, state.currentStreak);
});

test('grace period expiry resets streak to zero', () {
  final expiredGrace = StreakState(inGracePeriod: true,
      gracePeriodEnd: DateTime.now().subtract(const Duration(hours: 1)), ...);
  final result = service.handleBreach(expiredGrace, DateTime.now());
  expect(result.currentStreak, 0);
  expect(result.inGracePeriod, false);
});
```

#### `IngredientClassifier`
```dart
// test/features/keto_lens/domain/ingredient_classifier_test.dart

group('forbidden seed oils', () {
  for (final oil in ['canola', 'soybean', 'corn oil', 'sunflower', 'cottonseed']) {
    test('flags $oil as non-keto', () {
      final verdict = classifier.classify([oil]);
      expect(verdict.badge, VerdictBadge.nonKeto);
      expect(verdict.flaggedIngredients, contains(oil));
    });
  }
});

group('insulin-spiking sweeteners', () {
  for (final s in ['maltitol', 'sorbitol', 'dextrose', 'maltodextrin']) {
    test('flags $s as caution', () {
      final verdict = classifier.classify([s]);
      expect(verdict.badge, VerdictBadge.cautionQuantityDependent);
    });
  }
});

group('clean fats', () {
  for (final fat in ['olive oil', 'avocado oil', 'coconut oil', 'ghee', 'butter']) {
    test('approves $fat', () {
      final verdict = classifier.classify([fat]);
      expect(verdict.badge, VerdictBadge.cleanKeto);
    });
  }
});

test('worst badge wins when mixed ingredients', () {
  final verdict = classifier.classify(['olive oil', 'canola oil']);
  expect(verdict.badge, VerdictBadge.nonKeto);
});
```

#### `HebrewLabelParser`
```dart
// test/features/keto_lens/data/hebrew_label_parser_test.dart

test('extracts fat, net carbs, protein from standard Hebrew label', () {
  const raw = 'שומן 12גר פחמימות 3גר מתוכם סיבים 1גר חלבון 8גר';
  final label = parser.parse(raw);
  expect(label.fatG, 12.0);
  expect(label.netCarbsG, 2.0);  // 3 - 1 fiber
  expect(label.proteinG, 8.0);
});

test('handles OCR mis-read of ג as ג׳', () { ... });
test('returns null macros when label is too garbled to parse', () { ... });
test('extracts ingredients list after "רכיבים:" marker', () { ... });
```

#### `ElectrolyteAdvisor`
```dart
test('recommends high sodium in Phase 1', () {
  final advice = advisor.advise(AdaptationPhase.induction, log);
  expect(advice.sodiumTargetMg, greaterThanOrEqualTo(3000));
});

test('reduces sodium target in Phase 3', () {
  final phase3Advice = advisor.advise(AdaptationPhase.deepKetosis, log);
  expect(phase3Advice.sodiumTargetMg, lessThan(3000));
});
```

---

### Repository Contract Tests

Each repository interface has a shared contract test suite that every concrete implementation must pass. This enforces Liskov Substitution at the test level.

```dart
// test/features/diary/data/meal_repository_contract_test.dart
// Contract tests live beside the implementation they exercise, in data/ —
// they open a real in-memory database, which the domain layer never touches.

void runMealRepositoryContractTests(MealRepository Function() factory) {
  late MealRepository repo;

  setUp(() => repo = factory());

  test('save returns entity with non-zero id', () async {
    final saved = await repo.save(MealEntry.fixture());
    expect(saved.id, isNotNull);
    expect(saved.id, isNot(0));
  });

  test('findByDate returns empty list when no records exist', () async {
    final results = await repo.findByDate(DateTime(2030));
    expect(results, isEmpty);
  });

  test('findById returns null for unknown id', () async {
    expect(await repo.findById(99999), isNull);
  });

  test('delete removes record permanently', () async {
    final saved = await repo.save(MealEntry.fixture());
    await repo.delete(saved.id!);
    expect(await repo.findById(saved.id!), isNull);
  });

  test('findByDate only returns entries for the given date', () async {
    await repo.save(MealEntry.fixture(timestamp: DateTime(2026, 9, 9)));
    await repo.save(MealEntry.fixture(timestamp: DateTime(2026, 9, 10)));
    final results = await repo.findByDate(DateTime(2026, 9, 9));
    expect(results.length, 1);
  });
}

// Run against every implementation:
void main() {
  group('SembastMealRepository', () {
    runMealRepositoryContractTests(
      () => SembastMealRepository(db),
      breakStore: () => db.close(),
    );
  });
}
```

Apply the same pattern to: `DailyLogRepository`, `StreakRepository`, `SymptomLogRepository`, `BiomarkerLogRepository`, `SavedRecipeRepository`.

---

### Application Service Tests — With Mocks

Services in the application layer are tested with `mocktail` mocks of the domain interfaces. The real database never runs in unit tests.

```dart
// test/features/adaptation/application/adaptation_phase_service_test.dart

class MockStreakRepository extends Mock implements StreakRepository {}

void main() {
  late MockStreakRepository mockRepo;
  late AdaptationPhaseService service;

  setUp(() {
    mockRepo = MockStreakRepository();
    service = AdaptationPhaseService(mockRepo);
  });

  test('recordCompliantDay saves updated state', () async {
    final initial = StreakState.initial();
    when(() => mockRepo.load()).thenAnswer((_) async => initial);
    when(() => mockRepo.save(any())).thenAnswer((_) async {});

    await service.recordCompliantDay(DateTime.now());

    final captured = verify(() => mockRepo.save(captureAny())).captured.single
        as StreakState;
    expect(captured.currentStreak, 1);
  });
}
```

---

## Widget Tests

### What Gets Widget-Tested

Widgets that contain non-trivial logic or layout — not every widget. Tested with `flutter_test` and a `ProviderScope` override to inject mocked providers.

### Pattern — Override Providers in Tests

```dart
// test/features/dashboard/presentation/dashboard_screen_test.dart

void main() {
  testWidgets('shows correct keto ratio on dashboard', (tester) async {
    final fakeLog = DailyLog.fixture(fatG: 100, netCarbsG: 5, proteinG: 20);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todaysDailyLogProvider.overrideWith((_) async => fakeLog),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('4.0'), findsOneWidget);  // keto ratio display
  });

  testWidgets('shows empty state when no meals logged', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todaysDailyLogProvider.overrideWith((_) async => null),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('לא נרשמו ארוחות להיום'), findsOneWidget);
  });
}
```

### Key Widget Test Scenarios

#### DashboardScreen
- Macro progress bars fill proportionally to logged vs. target
- Streak ring renders at correct fill percentage
- Phase badge shows correct phase name for current streak
- "＋" FAB opens bottom sheet with meal entry options
- Tapping a meal row opens meal detail sheet

#### CameraScreen (Keto Lens)
- Capture button is disabled until camera permission granted
- Permission denied state shows settings redirect message
- Result sheet slides up after capture (mock `ScanOrchestrator`)

#### ResultSheet
- `VerdictBadge.cleanKeto` renders green badge with correct Hebrew text
- `VerdictBadge.nonKeto` renders red badge
- Flagged ingredient list appears when badge is non-keto
- "הוסף ליומן" button calls `mealLoggingService.logMeal()`

#### PhaseDetailScreen
- Timeline stepper shows correct active phase
- Completed phases are rendered differently from locked phases
- Grace period banner is visible when `inGracePeriod == true`

#### DiaryScreen
- Selecting a past date loads that day's entries
- Symptom row updates immediately on scale tap (optimistic UI)
- Empty diary date shows appropriate empty state

---

## Integration Tests

> **Superseded in part by `design/m8_preflight.md` Part 0 — read it before
> writing one.** Integration tests do **not** need an iOS simulator and are not
> nightly-only: they run headless on Linux with
> `flutter test -d flutter-tester integration_test/app_test.dart`, in seconds,
> per PR. The sketch below is right about the *shape* of a flow test and wrong
> about where it runs, how the app is booted (`app.main()` reaches
> `path_provider`; the harness composes `FantasticApp` over an injected
> in-memory database instead), and about several of the Hebrew strings and keys
> it taps. The corrected flow list is `m8_preflight.md` Part 3.

Integration tests run against a real (but ephemeral) database. Each test starts with a clean database.

```dart
// integration_test/flows/meal_logging_flow_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user logs a meal and sees dashboard update', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Navigate past onboarding
    await tester.tap(find.text('דלג'));
    await tester.pumpAndSettle();

    // Open meal log sheet
    await tester.tap(find.byKey(const Key('add_meal_fab')));
    await tester.pumpAndSettle();

    // Fill manual meal form
    await tester.enterText(find.byKey(const Key('meal_name_field')), 'ביצים וחמאה');
    await tester.enterText(find.byKey(const Key('fat_field')), '20');
    await tester.enterText(find.byKey(const Key('carbs_field')), '1');
    await tester.enterText(find.byKey(const Key('protein_field')), '12');
    await tester.tap(find.text('שמור'));
    await tester.pumpAndSettle();

    // Dashboard should reflect new totals
    expect(find.text('20g'), findsOneWidget);  // fat total
    expect(find.text('ביצים וחמאה'), findsOneWidget);
  });
}
```

### Integration Flow Coverage

| Flow | File |
|---|---|
| Onboarding → Dashboard seeded with targets | `onboarding_flow_test.dart` |
| Log meal manually → Dashboard updates | `meal_logging_flow_test.dart` |
| Scan label → Add to diary → Dashboard updates | `keto_lens_flow_test.dart` |
| Complete day → Streak increments → Phase advances on day 8 | `streak_flow_test.dart` |
| Breach detected → Grace period active → Breach again → Streak resets | `grace_period_flow_test.dart` |
| Log symptoms → View in diary | `symptom_diary_flow_test.dart` |
| Navigate all tabs without crash | `navigation_smoke_test.dart` |

---

## Test Utilities & Fixtures

All fixtures live in `test/fixtures/`. Never construct domain objects inline in tests — always use fixtures with named overrides.

```dart
// test/fixtures/meal_entry_fixture.dart
extension MealEntryFixture on MealEntry {
  static MealEntry fixture({
    double fatG = 20,
    double netCarbsG = 5,
    double proteinG = 15,
    DateTime? timestamp,
  }) => MealEntry(
    fatG: fatG,
    netCarbsG: netCarbsG,
    proteinG: proteinG,
    timestamp: timestamp ?? DateTime(2026, 9, 9, 12, 0),
  );
}

// test/fixtures/streak_state_fixture.dart
extension StreakStateFixture on StreakState {
  static StreakState initial() => const StreakState(
    currentStreak: 0,
    highestStreak: 0,
    phase: AdaptationPhase.induction,
    inGracePeriod: false,
  );

  static StreakState withStreak(int days) =>
    initial().copyWith(currentStreak: days, highestStreak: days);
}
```

### In-Memory sembast for Contract Tests

```dart
// test/helpers/test_database.dart
Future<Database> openTestDatabase() =>
    newDatabaseFactoryMemory().openDatabase('test.db');

Future<void> closeTestDatabase(Database db) async {
  try {
    await db.close();
  } on DatabaseException {
    // Already closed by breakStore.
  }
}
```

`newDatabaseFactoryMemory()` returns a fresh factory each call, so every contract test gets its own store — tests never share database state. It is pure Dart: no `dart:io`, no `dart:ffi`, no native binary to resolve, which is what makes the data-layer suite runnable under `flutter test --platform chrome`.

---

## What Not to Test

| Skip | Reason |
|---|---|
| sembast query internals | sembast is a dependency, not our code |
| Flutter framework widgets (Text, Column) | Framework is tested by the Flutter team |
| Generated `.g.dart` files | Generated code, not authored |
| Constants and enums with no logic | No behaviour to assert on |
| One-liner getters that delegate to a field | Noise, not signal |

---

## CI Integration

All unit and widget tests run on every PR:

```bash
flutter test --coverage
```

Integration tests run per-PR in their own `ubuntu-latest` job — **not nightly,
and not on a simulator** (`design/m8_preflight.md` Part 0 and §4):

```bash
# One aggregator file, not the directory: a second file in the same
# invocation cannot launch (m8_preflight.md §6.1).
flutter test -d flutter-tester integration_test/app_test.dart
```

Coverage gate: **80% line coverage on application and domain layers.** Data and presentation layers are excluded from the coverage gate (covered by contract and widget tests instead).

Coverage report generated with `lcov` and uploaded to Codecov.
