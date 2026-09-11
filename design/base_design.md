# Base Design — SOLID Abstractions

## Overview

Every abstraction in Fantastic follows the five SOLID principles. This document defines the canonical contracts, their responsibilities, and how they relate across layers.

---

## S — Single Responsibility

Each class owns exactly one reason to change.

### Repository Interfaces (Domain Layer)
Each persisted model gets its own repository interface. A `MealRepository` never touches `StreakState`.

Ids are `int?` throughout — a record key is an `int`, and the domain layer
imports nothing from the persistence package. All methods
return plain futures and throw on failure (see **Error Handling Contract**).

```dart
abstract interface class MealRepository {
  Future<MealEntry> save(MealEntry entry);
  Future<MealEntry?> findById(int id);
  Future<List<MealEntry>> findByDate(DateTime date);
  Future<List<MealEntry>> findAll();
  Future<void> delete(int id);
}

abstract interface class DailyLogRepository {
  Future<DailyLog> save(DailyLog log);          // upsert by date
  Future<DailyLog?> findByDate(DateTime date);
  Future<List<DailyLog>> findAll();
  Future<void> deleteByDate(DateTime date);
}

abstract interface class SymptomLogRepository {
  Future<SymptomLog> save(SymptomLog log);      // upsert by date
  Future<SymptomLog?> findByDate(DateTime date);
  Future<List<SymptomLog>> findAll();
  Future<void> deleteByDate(DateTime date);
}

abstract interface class StreakRepository {
  /// Null before the user's first compliant day — the first-launch sentinel.
  Future<StreakState?> load();
  Future<StreakState> save(StreakState state);
  /// Emits on every write. Required by `streakStateProvider` (#59).
  Stream<StreakState?> watch();
}
```

An earlier draft of this block differed from the M1 issues in four ways, all
resolved in favour of the issues except the last:

- `findById(Id id)` / `delete(Id id)` used a persistence-package type in a domain interface.
  Now `int`.
- `DailyLogRepository.upsert` is named `save`, matching every other repository;
  the upsert semantics are documented rather than encoded in the name.
- `SymptomLogRepository.findRange(from, to)` is replaced by `findAll()`. MVP
  data volumes are one record per day, and the diary's date-strip filters in
  memory; a range query can be added when something needs it.
- `StreakRepository.watch()` is **kept**, because `streakStateProvider` (#59)
  is specified as a stream watching this repository. `DailyLogRepository`'s
  `watchDate` was dropped — the dashboard refreshes by provider invalidation
  after a meal log, which needs no stream.

`BiomarkerLogRepository` is deferred with biomarker logging to **M9** (#103) and
has no M1 issue.

### Service Classes (Application Layer)
One service per use-case group. Never mix meal-logging logic with adaptation-phase logic.

```dart
class KetoRatioCalculator {
  double calculate(double fatG, double netCarbsG, double proteinG);
}

class AdaptationPhaseService {
  AdaptationPhase currentPhase(StreakState state);
  StreakState recordCompliantDay(StreakState state, DateTime date);
  StreakState handleBreach(StreakState state, DateTime date);
}

class ElectrolyteAdvisor {
  ElectrolyteAdvice advise(AdaptationPhase phase, DailyLog log);
}

class LabelParser {
  ParsedLabel parse(String rawOcrText);
}

class IngredientClassifier {
  IngredientVerdict classify(List<String> ingredients);
}
```

---

## O — Open/Closed

Open for extension, closed for modification. New behaviour is added by implementing existing interfaces, not by editing them.

### Extension Points

| Interface | Extend by adding... |
|---|---|
| `MealRepository` | New persistence backend (e.g., CloudKit sync) |
| `IngredientClassifier` | New rule sets per dietary protocol |
| `LabelParser` | New locale parsers (Arabic, Russian) without touching Hebrew parser |
| `DirectorySource` | New data sources (remote API, static JSON) |

### Example — Parser Strategy

```dart
abstract interface class LabelParser {
  bool canParse(String rawText);
  ParsedLabel parse(String rawText);
}

class HebrewLabelParser implements LabelParser { ... }
class ArabicLabelParser  implements LabelParser { ... }  // future extension

class LabelParserRegistry {
  final List<LabelParser> _parsers;
  ParsedLabel parse(String rawText) =>
    _parsers.firstWhere((p) => p.canParse(rawText)).parse(rawText);
}
```

---

## L — Liskov Substitution

Any implementation of a repository or service interface must be a drop-in replacement for any other without callers needing to know.

### Contract Rules for Repositories
- `save()` must always return the persisted entity (with a valid `id`).
- `findByDate()` returns an empty list — never throws — when no records exist.
- `watch()` streams must emit the current value on subscription.
- Implementations must never expose sembast-specific types to callers.

### Verified via Tests
Each feature contains an `abstract_repository_contract_test.dart` that runs the same behavioural test suite against every concrete implementation.

```dart
void runMealRepositoryContractTests(MealRepository repo) {
  test('save returns entity with non-zero id', () async { ... });
  test('findByDate returns empty list when no records', () async { ... });
  test('delete removes record permanently', () async { ... });
}
```

---

## I — Interface Segregation

No class is forced to implement methods it does not use. Large interfaces are split along caller boundaries.

### OCR Pipeline — Split Interfaces

Instead of one fat `OcrService`:

```dart
abstract interface class ImageCapture {
  Future<XFile?> captureFromCamera();
  Future<XFile?> pickFromGallery();
}

abstract interface class TextRecognizer {
  Future<String> recognize(XFile image);
}

abstract interface class LabelParser {
  bool canParse(String rawText);
  ParsedLabel parse(String rawText);
}

abstract interface class IngredientClassifier {
  IngredientVerdict classify(List<String> ingredients);
}
```

The screen only depends on `ImageCapture`; the classifier only depends on `IngredientClassifier`. Nothing is forced to import OCR logic to display a verdict badge.

### Directory Feature — Split Read/Write

```dart
abstract interface class DirectoryReader {
  Future<List<DirectoryEntry>> search(String query, DirectoryFilter filter);
  Future<DirectoryEntry?> findById(String id);
}

abstract interface class DirectoryWriter {
  Future<void> submitSuggestion(DirectoryEntry entry);
}
```

Read-only screens depend only on `DirectoryReader`.

---

## D — Dependency Inversion

High-level modules (application layer) depend on abstractions (domain interfaces), not on concrete sembast implementations (data layer). Wiring happens exclusively at the Riverpod provider level.

### Wiring Pattern

```dart
// data/providers.dart — only place that knows about sembast
@riverpod
MealRepository mealRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return SembastMealRepository(db);
}

// application/providers.dart — depends only on domain interface
@riverpod
MealLoggingService mealLoggingService(Ref ref) {
  final repo = ref.watch(mealRepositoryProvider);  // domain interface
  final dailyLog = ref.watch(dailyLogRepositoryProvider);
  return MealLoggingService(repo, dailyLog);
}

// presentation/ — depends only on application service
@riverpod
Future<List<MealEntry>> todaysMeals(Ref ref) {
  final service = ref.watch(mealLoggingServiceProvider);
  return service.fetchToday();
}
```

### Dependency Graph

```
Presentation  →  Application Service  →  Domain Interface  ←  Data Implementation
(widgets)        (use-case logic)         (abstract)           (sembast)
```

No arrow ever points left. Widgets never import `sembast_meal_repository.dart`.

---

## Domain Models (Pure Dart)

All domain models are immutable value objects with no Flutter or persistence annotations.

```dart
@immutable
class MealEntry {
  // `int?` — the record key. The domain layer imports nothing from the
  // persistence package; the data layer converts.
  final int? id;
  final DateTime timestamp;
  final double fatG;
  final double netCarbsG;
  final double proteinG;
  final String mealName;
  final List<String> ingredients;
  final String? imageRef;

  /// Computed, never stored — a persisted copy can go stale against its macros.
  double get ketoRatio =>
      (netCarbsG + proteinG) == 0 ? 0 : fatG / (netCarbsG + proteinG);

  const MealEntry({...});
  MealEntry copyWith({...});
}

@immutable
class DailyLog {
  final int? id;
  final DateTime date;
  final double totalFatG;
  final double totalNetCarbsG;
  final double totalProteinG;
  final double waterMl;
  final double sodiumMg;
  final double potassiumMg;
  final double magnesiumMg;
  final double ketoRatioAvg;

  const DailyLog({...});
}

@immutable
class StreakState {
  final int currentStreak;
  final int highestStreak;
  final AdaptationPhase phase;
  final DateTime? lastCompliantDate;
  final bool inGracePeriod;
  /// When the 24-hour grace period expires. Null unless [inGracePeriod].
  final DateTime? gracePeriodEnd;

  const StreakState({...});
}

enum AdaptationPhase { induction, fatAdapted, deepKetosis }

@immutable
class IngredientVerdict {
  final VerdictBadge badge;
  final List<String> flaggedIngredients;
  final String? cautionReason;

  const IngredientVerdict({...});
}

enum VerdictBadge { cleanKeto, cautionQuantityDependent, nonKeto }
```

---

## Error Handling Contract

Repository methods return a plain `Future<T>` and **throw** a typed domain
exception on failure. Services let those exceptions propagate — they do not
catch to convert. Presentation reads them as `AsyncValue.error` from the
provider that wrapped the call.

```dart
// Domain layer — one exception type per failure mode, no persistence or Flutter imports.
sealed class RepositoryException implements Exception {
  const RepositoryException(this.message);
  final String message;
}

final class EntityNotFoundException extends RepositoryException {
  const EntityNotFoundException(super.message);
}

final class PersistenceException extends RepositoryException {
  const PersistenceException(super.message, this.cause);
  final Object cause;
}
```

```dart
// Presentation — the error surfaces through AsyncValue, not a second channel.
ref.watch(todaysMealsProvider).when(
  data: (meals) => MealListSection(meals: meals),
  loading: () => const MealListSkeleton(),
  error: (error, _) => ErrorState(message: error.toString()),
);
```

### Why not `Result<T>`

An earlier draft of this document specified that every repository method return
a `sealed class Result<T>` with `Success` / `Failure` variants, and that widgets
pattern-match on it. That was dropped before M1.

Riverpod already models success, loading and failure as `AsyncValue` at exactly
the boundary where the UI consumes a repository call. Returning `Result<T>`
underneath it produces two parallel error channels — an `AsyncValue.data`
wrapping a `Result.failure` — and every provider has to unwrap one to populate
the other. Throwing lets a single mechanism carry the failure the whole way.

The decision is recorded rather than deleted so it is not silently
re-litigated: if a future milestone needs an error channel that survives
outside a provider, revisit it there rather than reintroducing `Result<T>`
across all five repository interfaces.
