import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed so every case is deterministic — never DateTime.now().
final _date = DateTime(2026, 9, 9);

SymptomLog _log({
  int? id,
  int energyScore = 3,
  int clarityScore = 3,
  int hungerScore = 3,
  int physicalScore = 3,
  int moodScore = 3,
  String? notes,
}) => SymptomLog(
  id: id,
  date: _date,
  energyScore: energyScore,
  clarityScore: clarityScore,
  hungerScore: hungerScore,
  physicalScore: physicalScore,
  moodScore: moodScore,
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

    test('carries all five scales, the fifth being mood', () {
      final log = _log(
        energyScore: 1,
        clarityScore: 2,
        hungerScore: 3,
        physicalScore: 4,
        moodScore: 5,
      );

      expect(log.energyScore, 1);
      expect(log.clarityScore, 2);
      expect(log.hungerScore, 3);
      expect(log.physicalScore, 4);
      expect(log.moodScore, 5);
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

    test('every one of the five scales is validated', () {
      expect(() => _log(energyScore: 9), throwsA(isA<AssertionError>()));
      expect(() => _log(clarityScore: 9), throwsA(isA<AssertionError>()));
      expect(() => _log(hungerScore: 9), throwsA(isA<AssertionError>()));
      expect(() => _log(physicalScore: 9), throwsA(isA<AssertionError>()));
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
  });
}
