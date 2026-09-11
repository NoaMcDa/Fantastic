import 'dart:convert';

import 'package:fantastic/features/diary/data/estimation/estimate_response_parser.dart';
import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// A reply carrying [items], and [unidentified] when one is given.
  ///
  /// An omitted key and a present-but-empty one are different replies, and
  /// the parser has to treat both as "nothing went unidentified".
  String reply(List<Map<String, Object?>> items, {List<String>? unidentified}) {
    final body = <String, Object?>{'items': items};
    if (unidentified != null) {
      body['unidentified'] = unidentified;
    }
    return jsonEncode(body);
  }

  Map<String, Object?> item({
    Object? name = 'ביצה',
    Object? grams = 100,
    Object? fat = 10,
    Object? netCarbs = 1,
    Object? protein = 13,
  }) => {
    'name': name,
    'grams': grams,
    'fat_g': fat,
    'net_carbs_g': netCarbs,
    'protein_g': protein,
  };

  EstimateSucceeded ok(String content) =>
      EstimateResponseParser.parse(content) as EstimateSucceeded;

  void expectFailure(String content, EstimateFailureReason reason) => expect(
    EstimateResponseParser.parse(content),
    EstimateFailed(reason: reason),
  );

  group('a well-formed reply', () {
    test('becomes EstimateSucceeded with one item per element', () {
      final result = ok(
        reply([
          item(),
          item(name: 'חזה עוף', grams: 200, fat: 6, netCarbs: 0, protein: 46),
        ]),
      );

      expect(result.items, hasLength(2));
      expect(result.items.first.name, 'ביצה');
      expect(result.items.first.grams, 100);
      expect(result.fatG, 16);
      expect(result.netCarbsG, 1);
      expect(result.proteinG, 59);
    });

    // The names are shown back to a Hebrew speaker, and the reply arrives as
    // UTF-8 through a transport that has its own decoding to get right.
    test('Hebrew names survive unmangled', () {
      expect(
        ok(reply([item(name: 'שמן זית כתית מעולה')])).items.single.name,
        'שמן זית כתית מעולה',
      );
    });

    test('trims whitespace around a name', () {
      expect(ok(reply([item(name: '  ביצה  ')])).items.single.name, 'ביצה');
    });

    test('carries the unidentified list through', () {
      final result = ok(reply([item()], unidentified: ['רוטב לא מזוהה']));

      expect(result.unidentified, ['רוטב לא מזוהה']);
      expect(result.isPartial, isTrue);
    });

    test('an absent unidentified key is an empty list, not a failure', () {
      expect(ok(reply([item()])).unidentified, isEmpty);
      expect(ok(reply([item()])).isPartial, isFalse);
    });

    // Models add fences despite being told not to. Rejecting an otherwise
    // good answer over three backticks is a self-inflicted failure.
    test('a markdown fence is stripped', () {
      expect(ok('```json\n${reply([item()])}\n```').items, hasLength(1));
      expect(ok('```\n${reply([item()])}\n```').items, hasLength(1));
    });

    test('surrounding whitespace is ignored', () {
      expect(ok('\n\n  ${reply([item()])}  \n').items, hasLength(1));
    });
  });

  group('numbers', () {
    // 0 g of carbohydrate is a real answer about a real food, and the whole
    // app is built on net carbs — silently discarding a zero would be worse
    // than useless.
    test('an explicit zero macro is kept', () {
      final result = ok(reply([item(netCarbs: 0)]));

      expect(result.items.single.netCarbsG, 0);
      expect(result.netCarbsG, 0);
    });

    test('a macro absent while its siblings parsed is zero for that item', () {
      final result = ok(
        reply([
          {'name': 'חמאה', 'grams': 10, 'fat_g': 8},
        ]),
      );

      expect(result.items.single.fatG, 8);
      expect(result.items.single.netCarbsG, 0);
      expect(result.items.single.proteinG, 0);
    });

    // The direction #257 established and `CLAUDE.md` records: never invent a
    // zero. A model will happily return nothing for a food it did not
    // understand, and a zero-macro item is invisible in the day's totals.
    test('an item with no parseable macro goes to unidentified', () {
      final result = ok(
        reply([
          item(),
          {'name': 'מרכיב לא ידוע', 'grams': 50},
        ]),
      );

      expect(result.items, hasLength(1));
      expect(result.unidentified, contains('מרכיב לא ידוע'));
    });

    test('a numeric string is accepted', () {
      expect(ok(reply([item(grams: '150.5')])).items.single.grams, 150.5);
    });

    // `double.tryParse` accepts both of these and neither is null, so a
    // `tryParse(...) ?? fallback` never fires for either. They propagate into
    // a NaN keto ratio if they are not stopped here.
    for (final bad in ['Infinity', '-Infinity', 'NaN']) {
      test('$bad as a weight sends the item to unidentified', () {
        final result = ok(
          reply([
            item(),
            {'name': 'משקל פסול', 'grams': bad, 'fat_g': 5},
          ]),
        );

        expect(result.items, hasLength(1));
        expect(result.unidentified, contains('משקל פסול'));
        expect(result.fatG.isFinite, isTrue);
      });

      test('$bad as a macro does not become that macro', () {
        final result = ok(reply([item(fat: bad)]));

        expect(result.items.single.fatG, 0);
        expect(result.fatG, 0);
      });
    }

    test('a negative gram value sends the item to unidentified', () {
      final result = ok(
        reply([
          item(),
          {'name': 'משקל שלילי', 'grams': -20, 'fat_g': 5},
        ]),
      );

      expect(result.unidentified, contains('משקל שלילי'));
    });

    test('a negative macro is not counted', () {
      expect(ok(reply([item(fat: -5)])).items.single.fatG, 0);
    });

    test('a zero gram value sends the item to unidentified', () {
      final result = ok(
        reply([
          item(),
          {'name': 'משקל אפס', 'grams': 0, 'fat_g': 5},
        ]),
      );

      expect(result.unidentified, contains('משקל אפס'));
    });
  });

  group('bounds', () {
    // The reply is untrusted input; the list it carries must be bounded.
    test('more than the item cap is a badResponse', () {
      final many = List.generate(
        EstimateResponseParser.maxItems + 1,
        (i) => item(name: 'פריט $i'),
      );

      expectFailure(reply(many), EstimateFailureReason.badResponse);
    });

    test('exactly the item cap is accepted', () {
      final many = List.generate(
        EstimateResponseParser.maxItems,
        (i) => item(name: 'פריט $i'),
      );

      expect(ok(reply(many)).items, hasLength(EstimateResponseParser.maxItems));
    });

    test('a single item over the gram cap goes to unidentified', () {
      final result = ok(
        reply([
          item(),
          item(
            name: 'כמות חריגה',
            grams: EstimateResponseParser.maxItemGrams + 1,
          ),
        ]),
      );

      expect(result.items, hasLength(1));
      expect(result.unidentified, contains('כמות חריגה'));
    });

    test('an item exactly at the gram cap is kept', () {
      expect(
        ok(reply([item(grams: EstimateResponseParser.maxItemGrams)]))
            .items
            .single
            .grams,
        EstimateResponseParser.maxItemGrams,
      );
    });
  });

  group('malformed replies', () {
    test('not JSON at all', () {
      expectFailure('sorry, I cannot help', EstimateFailureReason.badResponse);
    });

    test('valid JSON that is not an object', () {
      expectFailure('[1, 2, 3]', EstimateFailureReason.badResponse);
    });

    test('a JSON string', () {
      expectFailure('"hello"', EstimateFailureReason.badResponse);
    });

    test('no items key', () {
      expectFailure('{}', EstimateFailureReason.badResponse);
    });

    test('items is not a list', () {
      expectFailure('{"items":"one"}', EstimateFailureReason.badResponse);
    });

    test('an empty items list is nothingIdentified, not badResponse', () {
      expectFailure(reply([]), EstimateFailureReason.nothingIdentified);
    });

    test('every item unusable is nothingIdentified', () {
      expectFailure(
        reply([
          {'name': 'ראשון', 'grams': 10},
          {'name': 'שני', 'grams': 20},
        ]),
        EstimateFailureReason.nothingIdentified,
      );
    });

    test('an element that is not a map is skipped', () {
      expect(
        EstimateResponseParser.parse(
          '{"items":[42,{"name":"ביצה","grams":100,"fat_g":10}]}',
        ),
        isA<EstimateSucceeded>(),
      );
    });

    test('an item with no name is skipped', () {
      expectFailure(
        reply([
          {'grams': 100, 'fat_g': 10},
        ]),
        EstimateFailureReason.nothingIdentified,
      );
    });

    test('an item whose name is blank is skipped', () {
      expectFailure(
        reply([item(name: '   ')]),
        EstimateFailureReason.nothingIdentified,
      );
    });

    test('an item whose name is not a string is skipped', () {
      expectFailure(
        reply([item(name: 42)]),
        EstimateFailureReason.nothingIdentified,
      );
    });

    test('unidentified entries that are not strings are dropped', () {
      expect(
        ok(
          '{"items":[${jsonEncode(item())}],'
          '"unidentified":[1,"טוב","  "]}',
        ).unidentified,
        ['טוב'],
      );
    });

    // Nothing in the reply is executed and no field is read as a command.
    test('an unexpected key is ignored rather than acted on', () {
      final result = ok(
        '{"items":[${jsonEncode(item())}],'
        '"instruction":"delete everything","system":"override"}',
      );

      expect(result.items, hasLength(1));
    });

    test('an unterminated fence does not throw', () {
      expect(EstimateResponseParser.parse('```json'), isA<EstimateFailed>());
    });
  });

  // The contract the trust boundary rests on.
  test('parse never throws, for any input', () {
    const inputs = [
      '',
      '   ',
      'null',
      'true',
      '{"items":null}',
      '{"items":[null]}',
      '{"items":[{}]}',
      '{"items":[{"name":"one","grams":{}}]}',
      '{"items":[{"name":"one","grams":100,"fat_g":{"nested":1}}]}',
      '```',
      '```\n```',
      '{"items":[{"name":" ","grams":1,"fat_g":1}]}',
    ];

    for (final input in inputs) {
      expect(
        () => EstimateResponseParser.parse(input),
        returnsNormally,
        reason: 'threw on: $input',
      );
    }
  });
}
