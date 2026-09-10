/// Element-wise list comparison and hashing for domain value objects.
///
/// Flutter's `listEquals` lives in `package:flutter/foundation.dart`, which the
/// domain layer may not import (`CLAUDE.md` layer rules), and `package:collection`
/// is not a dependency. Domain models that hold a `List` field — `MealEntry`,
/// `ParsedLabel`, `IngredientVerdict` — need value equality over that field, so
/// the comparison lives here once rather than being hand-written in each.
library;

/// Whether [a] and [b] hold equal elements in the same order.
///
/// Two nulls are equal; a null and an empty list are not.
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null || a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Order-sensitive hash of [list], consistent with [listEquals].
///
/// Two lists that satisfy [listEquals] always produce the same value, so a
/// model can safely combine this into its own `hashCode`.
int listHash<T>(List<T>? list) =>
    list == null ? null.hashCode : Object.hashAll(list);
