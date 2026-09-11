/// Biological sex, as the Mifflin-St Jeor BMR equation needs it.
///
/// Two values because the formula has two forms — a `+5` constant for male
/// and a `-161` constant for female. This is a physiological input to an
/// equation, not a statement about identity, and nothing else in the app
/// reads it.
///
/// Stored by `name`, never by ordinal (`CLAUDE.md` §Local Persistence).
enum BiologicalSex { male, female }
