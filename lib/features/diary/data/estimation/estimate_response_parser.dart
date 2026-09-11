import 'dart:convert';

import 'package:fantastic/core/utils/numeric_input.dart';
import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/estimated_item.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';

/// Turns a model's reply into a [MealEstimate].
///
/// **This is the trust boundary.** The reply is JSON from a third party,
/// shaped by text the user typed, and the numbers in it feed
/// `MealLoggingService` -> `DailyLog` -> the streak. Everything below treats
/// it as hostile input: nothing is executed, no field is read as a command,
/// an unexpected key is ignored rather than acted on, and every number goes
/// through [NumericInput.positiveFinite].
///
/// **A macro is never invented as zero.** `CLAUDE.md` records the direction
/// this app must not take — after #257, an unparseable amount falls back to
/// the printed figures and never to zero, because a zero-macro meal saves
/// without complaint and is invisible in the day's totals. A model will
/// happily return `0` for a food it did not understand, so an item with no
/// parseable macro at all is reported as unidentified rather than counted as
/// nothing.
///
/// Transport-agnostic on purpose: the schema is
/// [MacroEstimationPrompt.schema], which a future backend must also satisfy,
/// and that is what lets one parser serve both.
abstract final class EstimateResponseParser {
  /// The most items a single meal may contain.
  ///
  /// The reply is untrusted, so the list it carries must be bounded — an
  /// unbounded one is a way to make the review sheet unusable from the far
  /// side of a network.
  static const int maxItems = 50;

  /// The most a single item may weigh, in grams.
  ///
  /// Five kilograms of one food is not a meal. Capping it stops one absurd
  /// number from producing an absurd day total.
  static const double maxItemGrams = 5000;

  /// Parses [content] into a [MealEstimate].
  ///
  /// **Never throws.** Every malformed shape returns
  /// [EstimateFailureReason.badResponse].
  static MealEstimate parse(String content) {
    final Object? decoded;
    try {
      decoded = jsonDecode(_withoutFence(content));
    } on Object catch (_) {
      // `Object`, not `Exception`: a malformed document throws a
      // `FormatException` but a pathological one can throw an `Error` out of
      // the decoder, and an `on Exception` clause would miss it.
      return const EstimateFailed(reason: EstimateFailureReason.badResponse);
    }

    if (decoded is! Map) {
      return const EstimateFailed(reason: EstimateFailureReason.badResponse);
    }

    final rawItems = decoded['items'];
    if (rawItems is! List) {
      return const EstimateFailed(reason: EstimateFailureReason.badResponse);
    }
    if (rawItems.length > maxItems) {
      return const EstimateFailed(reason: EstimateFailureReason.badResponse);
    }

    final items = <EstimatedItem>[];
    // Whatever the model could not identify, plus whatever it claimed to
    // identify and then described unusably. Both are the same fact to a user:
    // this food is not in the totals, and you need to look at it.
    final unidentified = _strings(decoded['unidentified']);

    for (final raw in rawItems) {
      if (raw is! Map) {
        continue;
      }
      final name = raw['name'];
      if (name is! String || name.trim().isEmpty) {
        continue;
      }

      final grams = NumericInput.positiveFinite(raw['grams']?.toString());
      if (grams == null || grams > maxItemGrams) {
        unidentified.add(name.trim());
        continue;
      }

      final fat = _macro(raw['fat_g']);
      final netCarbs = _macro(raw['net_carbs_g']);
      final protein = _macro(raw['protein_g']);
      if (fat == null && netCarbs == null && protein == null) {
        // Named, weighed, and described by nothing. Counting it as three
        // zeroes would put a food in the day's totals contributing nothing,
        // which is exactly the silent-undercount this milestone exists to
        // avoid.
        unidentified.add(name.trim());
        continue;
      }

      items.add(
        EstimatedItem(
          name: name.trim(),
          grams: grams,
          // A macro that is absent while its siblings parsed is zero for this
          // item, and that is a real answer: a food genuinely has 0 g of
          // carbohydrate. A wholly undescribed item is the case above.
          fatG: fat ?? 0,
          netCarbsG: netCarbs ?? 0,
          proteinG: protein ?? 0,
        ),
      );
    }

    if (items.isEmpty) {
      return const EstimateFailed(
        reason: EstimateFailureReason.nothingIdentified,
      );
    }

    return EstimateSucceeded(items: items, unidentified: unidentified);
  }

  /// One macro value, or null when it is absent or unusable.
  ///
  /// **Zero is kept and everything else invalid is not**, which is why this
  /// cannot be [NumericInput.positiveFinite] alone: that guard rejects `<= 0`
  /// together with `NaN` and `Infinity`, and a printed zero has to be told
  /// apart from them. It is still *called* rather than reimplemented — the
  /// second parse only asks the one question it cannot answer.
  static double? _macro(Object? raw) {
    final text = raw?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    final positive = NumericInput.positiveFinite(text);
    if (positive != null) {
      return positive;
    }
    return double.tryParse(text) == 0 ? 0 : null;
  }

  /// The non-empty strings in [raw], or an empty list.
  static List<String> _strings(Object? raw) {
    if (raw is! List) {
      return [];
    }
    return [
      for (final entry in raw)
        if (entry is String && entry.trim().isNotEmpty) entry.trim(),
    ];
  }

  /// [content] with a markdown fence stripped, if it has one.
  ///
  /// Models add them despite being told not to, and rejecting an otherwise
  /// good answer over three backticks is a self-inflicted failure.
  static String _withoutFence(String content) {
    var text = content.trim();
    if (!text.startsWith('```')) {
      return text;
    }
    final firstBreak = text.indexOf('\n');
    if (firstBreak == -1) {
      return text;
    }
    // Drops the opening fence and its optional language tag.
    text = text.substring(firstBreak + 1);
    final closing = text.lastIndexOf('```');
    return (closing == -1 ? text : text.substring(0, closing)).trim();
  }
}
