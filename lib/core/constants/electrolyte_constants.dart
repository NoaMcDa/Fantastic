/// Phase-aware daily electrolyte intake targets.
///
/// See `design/technology.md` §2 and `design/architecture.md` for the
/// adaptation-phase model these targets are keyed to.
abstract final class ElectrolyteConstants {
  // Phase 1 (Induction).
  static const double phase1SodiumMinMg = 3000;
  static const double phase1SodiumMaxMg = 5000;
  static const double phase1PotassiumMinMg = 3000;
  static const double phase1PotassiumMaxMg = 4000;
  static const double phase1MagnesiumMinMg = 300;
  static const double phase1MagnesiumMaxMg = 500;

  // Phase 2 & 3 (Fat Adapted / Deep Ketosis).
  static const double phase23SodiumMinMg = 2000;
  static const double phase23SodiumMaxMg = 3000;
  static const double phase23PotassiumMinMg = 2500;
  static const double phase23PotassiumMaxMg = 3500;
  static const double phase23MagnesiumMinMg = 300;
  static const double phase23MagnesiumMaxMg = 400;
}
