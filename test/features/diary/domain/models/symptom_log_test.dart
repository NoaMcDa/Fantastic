import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed so every case is deterministic — never DateTime.now().
final _date = DateTime(2026, 9, 9);

SymptomLog _log({
  int? id,
  int energyScore = 3,
  int clarityScore = 3,
  int hungerScore = 3,
  int moodScore = 3,
  Set<PhysicalSymptom> symptoms = const <PhysicalSymptom>{},
  String? notes,
}) => SymptomLog(
  id: id,
  date: _date,
  energyScore: energyScore,
  clarityScore: clarityScore,
  hungerScore: hungerScore,
  moodScore: moodScore,
  symptoms: symptoms,
  notes: notes,
);

void main() {
  group('SymptomLog construction', () {
    test('valid scores 1-5 construct without error', () {
      expect(_log, returnsNormally);
    });

    test('scores of 1 and 5 are both accepted — bounds are inclusive', () {
      expect(() => _log(energyScore: 1), returnsNormally);
      expect(() => _log(energyScore: 5), returnsNormally);
      expect(() => _log(moodScore: 1), returnsNormally);
      expect(() => _log(moodScore: 5), returnsNormally);
    });

    test('id and notes default to null', () {
      expect(_log().id, isNull);
      expect(_log().notes, isNull);
    });

    test('symptoms defaults to empty, not null', () {
      expect(_log().symptoms, isEmpty);
    });

    test('carries all four scales, the fourth being mood', () {
      final log = _log(
        energyScore: 1,
        clarityScore: 2,
        hungerScore: 3,
        moodScore: 4,
      );

      expect(log.energyScore, 1);
      expect(log.clarityScore, 2);
      expect(log.hungerScore, 3);
      expect(log.moodScore, 4);
    });

    test('carries the symptom set it was given', () {
      final log = _log(
        symptoms: const {PhysicalSymptom.headache, PhysicalSymptom.nausea},
      );

      expect(log.symptoms, {PhysicalSymptom.headache, PhysicalSymptom.nausea});
    });
  });

  group('SymptomLog score validation', () {
    test('a score of 0 throws AssertionError', () {
      expect(() => _log(energyScore: 0), throwsA(isA<AssertionError>()));
    });

    test('a score of 6 throws AssertionError', () {
      expect(() => _log(energyScore: 6), throwsA(isA<AssertionError>()));
    });

    test('a negative score throws AssertionError', () {
      expect(() => _log(hungerScore: -1), throwsA(isA<AssertionError>()));
    });

    test('every one of the four scales is validated', () {
      expect(() => _log(energyScore: 9), throwsA(isA<AssertionError>()));
      expect(() => _log(clarityScore: 9), throwsA(isA<AssertionError>()));
      expect(() => _log(hungerScore: 9), throwsA(isA<AssertionError>()));
      expect(() => _log(moodScore: 9), throwsA(isA<AssertionError>()));
    });

    test('the assertion message names the offending field', () {
      expect(
        () => _log(moodScore: 9),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('moodScore'),
          ),
        ),
      );
    });

    test(
      'every PhysicalSymptom is accepted — a closed enum needs no check',
      () {
        expect(
          () => _log(symptoms: PhysicalSymptom.values.toSet()),
          returnsNormally,
        );
      },
    );
  });

  group('SymptomLog.copyWith', () {
    test('returns a new instance, not the same reference', () {
      final original = _log();
      final copy = original.copyWith(energyScore: 5);

      expect(identical(original, copy), isFalse);
      expect(copy.energyScore, 5);
    });

    test('leaves untouched fields unchanged', () {
      final copy = _log(moodScore: 2, notes: 'tired').copyWith(energyScore: 5);

      expect(copy.moodScore, 2);
      expect(copy.notes, 'tired');
      expect(copy.date, _date);
    });

    test('with no arguments returns an equal instance', () {
      final original = _log(notes: 'steady');

      expect(original.copyWith(), original);
    });

    test('an out-of-range override throws AssertionError', () {
      // copyWith re-runs the asserting constructor.
      expect(
        () => _log().copyWith(clarityScore: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('replaces the symptom set rather than merging into it', () {
      final copy = _log(symptoms: const {PhysicalSymptom.headache})
          .copyWith(symptoms: const {PhysicalSymptom.nausea});

      expect(copy.symptoms, {PhysicalSymptom.nausea});
    });

    test('an empty set clears the symptoms — no clearSymptoms flag needed', () {
      final copy = _log(symptoms: const {PhysicalSymptom.headache})
          .copyWith(symptoms: const {});

      expect(copy.symptoms, isEmpty);
    });

    test('a bare null leaves the symptoms alone', () {
      expect(
        _log(symptoms: const {PhysicalSymptom.headache}).copyWith().symptoms,
        {PhysicalSymptom.headache},
      );
    });

    // The trap `StreakState.copyWith` and `UserProfile.copyWith` both carry
    // a flag for: `notes ?? this.notes` resolves a null argument to the
    // existing value, so a bare null cannot clear the field.
    test('a bare null does not clear notes', () {
      expect(_log(notes: 'tired').copyWith(notes: null).notes, 'tired');
    });

    test('clearNotes clears them', () {
      expect(_log(notes: 'tired').copyWith(clearNotes: true).notes, isNull);
    });

    test('clearNotes wins over a value passed alongside it', () {
      final original = _log(notes: 'tired');
      final copy = original.copyWith(notes: 'fresh', clearNotes: true);

      expect(copy.notes, isNull);
    });

    test('clearNotes leaves every other field alone', () {
      final original = _log(moodScore: 2, notes: 'tired');
      final copy = original.copyWith(clearNotes: true);

      expect(copy.moodScore, 2);
      expect(copy.date, _date);
    });
  });

  group('SymptomLog equality', () {
    test('two instances with identical field values are equal', () {
      expect(_log(), _log());
      expect(_log().hashCode, _log().hashCode);
    });

    test('two instances differing only in moodScore are not equal', () {
      expect(_log(moodScore: 2), isNot(_log(moodScore: 4)));
    });

    test('two instances differing only in notes are not equal', () {
      expect(_log(notes: 'a'), isNot(_log()));
    });

    // `Set` inherits `==` from `Object`, so two separately-built sets holding
    // the same values are not identical. Without `SetEquality` these logs
    // compare unequal and every rebuild looks like a change.
    test('equal symptom sets built separately compare equal', () {
      final a = _log(symptoms: {PhysicalSymptom.headache});
      final b = _log(symptoms: {PhysicalSymptom.headache});

      expect(identical(a.symptoms, b.symptoms), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('the same symptoms in a different insertion order compare equal', () {
      final a = _log(
        symptoms: {PhysicalSymptom.nausea, PhysicalSymptom.headache},
      );
      final b = _log(
        symptoms: {PhysicalSymptom.headache, PhysicalSymptom.nausea},
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('two instances differing only in symptoms are not equal', () {
      expect(
        _log(symptoms: const {PhysicalSymptom.headache}),
        isNot(_log(symptoms: const {PhysicalSymptom.nausea})),
      );
    });

    test('an empty symptom set differs from a non-empty one', () {
      expect(_log(), isNot(_log(symptoms: const {PhysicalSymptom.headache})));
    });
  });
}
