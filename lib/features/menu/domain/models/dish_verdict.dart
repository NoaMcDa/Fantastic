/// Green / yellow / red for one dish.
///
/// Its own enum, not `VerdictBadge`: Keto Lens's amber means "quantity
/// dependent"; this amber means "order it with a change". Stored nowhere, so
/// no `.name` rule applies — but matched by name in the parser, never by
/// ordinal, so reordering cannot reinterpret a response.
enum DishVerdict {
  /// Suitable as printed.
  orderAsIs,

  /// Contains something removable or swappable; carries an instruction.
  modifiable,

  /// Structurally carbohydrate-heavy; no instruction saves it.
  nonKeto;

  /// The order the result list groups by: green, then yellow, then red.
  static List<DishVerdict> get displayOrder => const [
    orderAsIs,
    modifiable,
    nonKeto,
  ];
}
