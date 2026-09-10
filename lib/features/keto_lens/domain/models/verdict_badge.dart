/// The keto verdict a scanned label earns, and the reduction rule that picks
/// one badge for a mixed ingredient list.
enum VerdictBadge {
  cleanKeto,
  cautionQuantityDependent,
  nonKeto;

  /// The most severe badge in [badges].
  ///
  /// Severity: `nonKeto` > `cautionQuantityDependent` > `cleanKeto`.
  /// An empty list is [cleanKeto] — nothing flagged means nothing wrong.
  ///
  /// Checks membership rather than comparing ordinals, so reordering this
  /// enum cannot silently invert severity.
  static VerdictBadge worst(List<VerdictBadge> badges) {
    if (badges.contains(nonKeto)) {
      return nonKeto;
    }
    if (badges.contains(cautionQuantityDependent)) {
      return cautionQuantityDependent;
    }
    return cleanKeto;
  }
}
