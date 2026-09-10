/// Barrel export for `test/fixtures/`.
///
/// Tests import this file alone — one import line per test file — rather than
/// reaching for individual fixtures. Per `design/tests.md`: all fixtures live
/// here, and tests never construct domain objects inline.
library;

export 'daily_log_fixture.dart';
export 'meal_entry_fixture.dart';
export 'streak_state_fixture.dart';
export 'symptom_log_fixture.dart';
