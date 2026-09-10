// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_streak_state.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarStreakStateCollection on Isar {
  IsarCollection<IsarStreakState> get isarStreakStates => this.collection();
}

const IsarStreakStateSchema = CollectionSchema(
  name: r'IsarStreakState',
  id: -830122038575532118,
  properties: {
    r'currentStreak': PropertySchema(
      id: 0,
      name: r'currentStreak',
      type: IsarType.long,
    ),
    r'gracePeriodEnd': PropertySchema(
      id: 1,
      name: r'gracePeriodEnd',
      type: IsarType.dateTime,
    ),
    r'highestStreak': PropertySchema(
      id: 2,
      name: r'highestStreak',
      type: IsarType.long,
    ),
    r'inGracePeriod': PropertySchema(
      id: 3,
      name: r'inGracePeriod',
      type: IsarType.bool,
    ),
    r'lastCompliantDate': PropertySchema(
      id: 4,
      name: r'lastCompliantDate',
      type: IsarType.dateTime,
    ),
    r'phase': PropertySchema(
      id: 5,
      name: r'phase',
      type: IsarType.byte,
      enumMap: _IsarStreakStatephaseEnumValueMap,
    ),
  },

  estimateSize: _isarStreakStateEstimateSize,
  serialize: _isarStreakStateSerialize,
  deserialize: _isarStreakStateDeserialize,
  deserializeProp: _isarStreakStateDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _isarStreakStateGetId,
  getLinks: _isarStreakStateGetLinks,
  attach: _isarStreakStateAttach,
  version: '3.3.2',
);

int _isarStreakStateEstimateSize(
  IsarStreakState object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _isarStreakStateSerialize(
  IsarStreakState object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.currentStreak);
  writer.writeDateTime(offsets[1], object.gracePeriodEnd);
  writer.writeLong(offsets[2], object.highestStreak);
  writer.writeBool(offsets[3], object.inGracePeriod);
  writer.writeDateTime(offsets[4], object.lastCompliantDate);
  writer.writeByte(offsets[5], object.phase.index);
}

IsarStreakState _isarStreakStateDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarStreakState();
  object.currentStreak = reader.readLong(offsets[0]);
  object.gracePeriodEnd = reader.readDateTimeOrNull(offsets[1]);
  object.highestStreak = reader.readLong(offsets[2]);
  object.id = id;
  object.inGracePeriod = reader.readBool(offsets[3]);
  object.lastCompliantDate = reader.readDateTimeOrNull(offsets[4]);
  object.phase =
      _IsarStreakStatephaseValueEnumMap[reader.readByteOrNull(offsets[5])] ??
      AdaptationPhaseIsar.induction;
  return object;
}

P _isarStreakStateDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (_IsarStreakStatephaseValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              AdaptationPhaseIsar.induction)
          as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _IsarStreakStatephaseEnumValueMap = {
  'induction': 0,
  'fatAdapted': 1,
  'deepKetosis': 2,
};
const _IsarStreakStatephaseValueEnumMap = {
  0: AdaptationPhaseIsar.induction,
  1: AdaptationPhaseIsar.fatAdapted,
  2: AdaptationPhaseIsar.deepKetosis,
};

Id _isarStreakStateGetId(IsarStreakState object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarStreakStateGetLinks(IsarStreakState object) {
  return [];
}

void _isarStreakStateAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarStreakState object,
) {
  object.id = id;
}

extension IsarStreakStateQueryWhereSort
    on QueryBuilder<IsarStreakState, IsarStreakState, QWhere> {
  QueryBuilder<IsarStreakState, IsarStreakState, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarStreakStateQueryWhere
    on QueryBuilder<IsarStreakState, IsarStreakState, QWhereClause> {
  QueryBuilder<IsarStreakState, IsarStreakState, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarStreakStateQueryFilter
    on QueryBuilder<IsarStreakState, IsarStreakState, QFilterCondition> {
  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  currentStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'currentStreak', value: value),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  currentStreakGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'currentStreak',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  currentStreakLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'currentStreak',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  currentStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'currentStreak',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  gracePeriodEndIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'gracePeriodEnd'),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  gracePeriodEndIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'gracePeriodEnd'),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  gracePeriodEndEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'gracePeriodEnd', value: value),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  gracePeriodEndGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'gracePeriodEnd',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  gracePeriodEndLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'gracePeriodEnd',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  gracePeriodEndBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'gracePeriodEnd',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  highestStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'highestStreak', value: value),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  highestStreakGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'highestStreak',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  highestStreakLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'highestStreak',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  highestStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'highestStreak',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  inGracePeriodEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'inGracePeriod', value: value),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  lastCompliantDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastCompliantDate'),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  lastCompliantDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastCompliantDate'),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  lastCompliantDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastCompliantDate', value: value),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  lastCompliantDateGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastCompliantDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  lastCompliantDateLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastCompliantDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  lastCompliantDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastCompliantDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  phaseEqualTo(AdaptationPhaseIsar value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'phase', value: value),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  phaseGreaterThan(AdaptationPhaseIsar value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'phase',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  phaseLessThan(AdaptationPhaseIsar value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'phase',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterFilterCondition>
  phaseBetween(
    AdaptationPhaseIsar lower,
    AdaptationPhaseIsar upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'phase',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarStreakStateQueryObject
    on QueryBuilder<IsarStreakState, IsarStreakState, QFilterCondition> {}

extension IsarStreakStateQueryLinks
    on QueryBuilder<IsarStreakState, IsarStreakState, QFilterCondition> {}

extension IsarStreakStateQuerySortBy
    on QueryBuilder<IsarStreakState, IsarStreakState, QSortBy> {
  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  sortByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  sortByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  sortByGracePeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gracePeriodEnd', Sort.asc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  sortByGracePeriodEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gracePeriodEnd', Sort.desc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  sortByHighestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'highestStreak', Sort.asc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  sortByHighestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'highestStreak', Sort.desc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  sortByInGracePeriod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inGracePeriod', Sort.asc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  sortByInGracePeriodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inGracePeriod', Sort.desc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  sortByLastCompliantDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCompliantDate', Sort.asc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  sortByLastCompliantDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCompliantDate', Sort.desc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy> sortByPhase() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phase', Sort.asc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  sortByPhaseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phase', Sort.desc);
    });
  }
}

extension IsarStreakStateQuerySortThenBy
    on QueryBuilder<IsarStreakState, IsarStreakState, QSortThenBy> {
  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  thenByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  thenByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  thenByGracePeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gracePeriodEnd', Sort.asc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  thenByGracePeriodEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gracePeriodEnd', Sort.desc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  thenByHighestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'highestStreak', Sort.asc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  thenByHighestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'highestStreak', Sort.desc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  thenByInGracePeriod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inGracePeriod', Sort.asc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  thenByInGracePeriodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inGracePeriod', Sort.desc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  thenByLastCompliantDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCompliantDate', Sort.asc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  thenByLastCompliantDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCompliantDate', Sort.desc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy> thenByPhase() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phase', Sort.asc);
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QAfterSortBy>
  thenByPhaseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phase', Sort.desc);
    });
  }
}

extension IsarStreakStateQueryWhereDistinct
    on QueryBuilder<IsarStreakState, IsarStreakState, QDistinct> {
  QueryBuilder<IsarStreakState, IsarStreakState, QDistinct>
  distinctByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentStreak');
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QDistinct>
  distinctByGracePeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gracePeriodEnd');
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QDistinct>
  distinctByHighestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'highestStreak');
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QDistinct>
  distinctByInGracePeriod() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inGracePeriod');
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QDistinct>
  distinctByLastCompliantDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastCompliantDate');
    });
  }

  QueryBuilder<IsarStreakState, IsarStreakState, QDistinct> distinctByPhase() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'phase');
    });
  }
}

extension IsarStreakStateQueryProperty
    on QueryBuilder<IsarStreakState, IsarStreakState, QQueryProperty> {
  QueryBuilder<IsarStreakState, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarStreakState, int, QQueryOperations> currentStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentStreak');
    });
  }

  QueryBuilder<IsarStreakState, DateTime?, QQueryOperations>
  gracePeriodEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gracePeriodEnd');
    });
  }

  QueryBuilder<IsarStreakState, int, QQueryOperations> highestStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'highestStreak');
    });
  }

  QueryBuilder<IsarStreakState, bool, QQueryOperations>
  inGracePeriodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inGracePeriod');
    });
  }

  QueryBuilder<IsarStreakState, DateTime?, QQueryOperations>
  lastCompliantDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastCompliantDate');
    });
  }

  QueryBuilder<IsarStreakState, AdaptationPhaseIsar, QQueryOperations>
  phaseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'phase');
    });
  }
}
