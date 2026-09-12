import 'package:fantastic/features/recipe/domain/models/outcome_source.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:fantastic/features/recipe/domain/models/substitution.dart';
import 'package:meta/meta.dart';

/// What `SubstitutionEngine.classify` answers for one ingredient line.
///
/// ## Four variants, sealed, not a nullable
///
/// Unknown, already-fine and known-bad are three different answers, and the
/// UI must render all three differently. `מלטיטול` in a recipe is on
/// `IngredientRules`' insulin-spiking list — the app *knows*; rendering it
/// [Unrecognised] says "we do not know" when the truth is "leave it out".
/// Collapsing any two of these four is the failure this hierarchy exists to
/// prevent.
///
/// `design/base_design.md` dropped `Result<T>` before M1 — that ruling is
/// about error propagation from `data/`. This is not that: every case here
/// is a successful classification, never a thrown failure, so `Result<T>` is
/// not reintroduced.
@immutable
sealed class IngredientOutcome {
  const IngredientOutcome(this.ingredient);

  final ParsedIngredient ingredient;
}

/// The ingredient is fine as written — no substitution needed.
@immutable
final class AlreadyKeto extends IngredientOutcome {
  const AlreadyKeto(super.ingredient, {this.source = OutcomeSource.rule});

  final OutcomeSource source;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlreadyKeto &&
          other.ingredient == ingredient &&
          other.source == source;

  @override
  int get hashCode => Object.hash(ingredient, source);

  @override
  String toString() => 'AlreadyKeto(ingredient: $ingredient, source: $source)';
}

/// A known keto replacement exists.
@immutable
final class Substituted extends IngredientOutcome {
  const Substituted(
    super.ingredient, {
    required this.substitution,
    this.source = OutcomeSource.rule,
  });

  final Substitution substitution;
  final OutcomeSource source;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Substituted &&
          other.ingredient == ingredient &&
          other.substitution == substitution &&
          other.source == source;

  @override
  int get hashCode => Object.hash(ingredient, substitution, source);

  @override
  String toString() =>
      'Substituted(ingredient: $ingredient, substitution: $substitution, source: $source)';
}

/// Known non-keto with no substitute in any table — `IngredientRules` flags
/// it. The honest answer is "leave it out", not "unknown".
///
/// No [OutcomeSource]: this answer is always the engine's own — a model
/// (#396) only ever fills in an [Unrecognised] line, never overrides a known
/// rule violation.
@immutable
final class Flagged extends IngredientOutcome {
  const Flagged(super.ingredient);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Flagged && other.ingredient == ingredient;

  @override
  int get hashCode => ingredient.hashCode;

  @override
  String toString() => 'Flagged(ingredient: $ingredient)';
}

/// Genuinely unknown. #396's model pass consumes only these lines.
@immutable
final class Unrecognised extends IngredientOutcome {
  const Unrecognised(super.ingredient);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Unrecognised && other.ingredient == ingredient;

  @override
  int get hashCode => ingredient.hashCode;

  @override
  String toString() => 'Unrecognised(ingredient: $ingredient)';
}
