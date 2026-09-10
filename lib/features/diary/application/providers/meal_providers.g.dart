// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every [MealEntry] logged on [date], newest first.
///
/// Returns an empty list when nothing is logged — never null. List screens
/// render "no items", not "no data": an empty day and a missing day look the
/// same to the user, so there is nothing for a null to express.
///
/// This is the individual-meal view; `todaysDailyLogProvider` (#47) is the
/// aggregate. Both are keyed by date and both are invalidated after a write.
///
/// The date is normalised to midnight before the query. **Pass a date-only
/// value** — the family is keyed on the argument as given, so a wall-clock
/// `DateTime.now()` recomputed in a `build` method would allocate a fresh
/// provider on every rebuild and refetch forever.

@ProviderFor(todaysMeals)
const todaysMealsProvider = TodaysMealsFamily._();

/// Every [MealEntry] logged on [date], newest first.
///
/// Returns an empty list when nothing is logged — never null. List screens
/// render "no items", not "no data": an empty day and a missing day look the
/// same to the user, so there is nothing for a null to express.
///
/// This is the individual-meal view; `todaysDailyLogProvider` (#47) is the
/// aggregate. Both are keyed by date and both are invalidated after a write.
///
/// The date is normalised to midnight before the query. **Pass a date-only
/// value** — the family is keyed on the argument as given, so a wall-clock
/// `DateTime.now()` recomputed in a `build` method would allocate a fresh
/// provider on every rebuild and refetch forever.

final class TodaysMealsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MealEntry>>,
          List<MealEntry>,
          FutureOr<List<MealEntry>>
        >
    with $FutureModifier<List<MealEntry>>, $FutureProvider<List<MealEntry>> {
  /// Every [MealEntry] logged on [date], newest first.
  ///
  /// Returns an empty list when nothing is logged — never null. List screens
  /// render "no items", not "no data": an empty day and a missing day look the
  /// same to the user, so there is nothing for a null to express.
  ///
  /// This is the individual-meal view; `todaysDailyLogProvider` (#47) is the
  /// aggregate. Both are keyed by date and both are invalidated after a write.
  ///
  /// The date is normalised to midnight before the query. **Pass a date-only
  /// value** — the family is keyed on the argument as given, so a wall-clock
  /// `DateTime.now()` recomputed in a `build` method would allocate a fresh
  /// provider on every rebuild and refetch forever.
  const TodaysMealsProvider._({
    required TodaysMealsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'todaysMealsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$todaysMealsHash();

  @override
  String toString() {
    return r'todaysMealsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MealEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MealEntry>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return todaysMeals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TodaysMealsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$todaysMealsHash() => r'b4ec62103cc59e0d3362a9c83f7d47841111bd41';

/// Every [MealEntry] logged on [date], newest first.
///
/// Returns an empty list when nothing is logged — never null. List screens
/// render "no items", not "no data": an empty day and a missing day look the
/// same to the user, so there is nothing for a null to express.
///
/// This is the individual-meal view; `todaysDailyLogProvider` (#47) is the
/// aggregate. Both are keyed by date and both are invalidated after a write.
///
/// The date is normalised to midnight before the query. **Pass a date-only
/// value** — the family is keyed on the argument as given, so a wall-clock
/// `DateTime.now()` recomputed in a `build` method would allocate a fresh
/// provider on every rebuild and refetch forever.

final class TodaysMealsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MealEntry>>, DateTime> {
  const TodaysMealsFamily._()
    : super(
        retry: null,
        name: r'todaysMealsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every [MealEntry] logged on [date], newest first.
  ///
  /// Returns an empty list when nothing is logged — never null. List screens
  /// render "no items", not "no data": an empty day and a missing day look the
  /// same to the user, so there is nothing for a null to express.
  ///
  /// This is the individual-meal view; `todaysDailyLogProvider` (#47) is the
  /// aggregate. Both are keyed by date and both are invalidated after a write.
  ///
  /// The date is normalised to midnight before the query. **Pass a date-only
  /// value** — the family is keyed on the argument as given, so a wall-clock
  /// `DateTime.now()` recomputed in a `build` method would allocate a fresh
  /// provider on every rebuild and refetch forever.

  TodaysMealsProvider call(DateTime date) =>
      TodaysMealsProvider._(argument: date, from: this);

  @override
  String toString() => r'todaysMealsProvider';
}
