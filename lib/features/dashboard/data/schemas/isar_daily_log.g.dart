// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_daily_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarDailyLogCollection on Isar {
  IsarCollection<IsarDailyLog> get isarDailyLogs => this.collection();
}

const IsarDailyLogSchema = CollectionSchema(
  name: r'IsarDailyLog',
  id: -2918960461383991608,
  properties: {
    r'date': PropertySchema(id: 0, name: r'date', type: IsarType.dateTime),
    r'dateIndex': PropertySchema(
      id: 1,
      name: r'dateIndex',
      type: IsarType.long,
    ),
    r'ketoRatioAvg': PropertySchema(
      id: 2,
      name: r'ketoRatioAvg',
      type: IsarType.double,
    ),
    r'magnesiumMg': PropertySchema(
      id: 3,
      name: r'magnesiumMg',
      type: IsarType.double,
    ),
    r'potassiumMg': PropertySchema(
      id: 4,
      name: r'potassiumMg',
      type: IsarType.double,
    ),
    r'sodiumMg': PropertySchema(
      id: 5,
      name: r'sodiumMg',
      type: IsarType.double,
    ),
    r'totalFatG': PropertySchema(
      id: 6,
      name: r'totalFatG',
      type: IsarType.double,
    ),
    r'totalNetCarbsG': PropertySchema(
      id: 7,
      name: r'totalNetCarbsG',
      type: IsarType.double,
    ),
    r'totalProteinG': PropertySchema(
      id: 8,
      name: r'totalProteinG',
      type: IsarType.double,
    ),
    r'waterMl': PropertySchema(id: 9, name: r'waterMl', type: IsarType.double),
  },

  estimateSize: _isarDailyLogEstimateSize,
  serialize: _isarDailyLogSerialize,
  deserialize: _isarDailyLogDeserialize,
  deserializeProp: _isarDailyLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateIndex': IndexSchema(
      id: 5202930406488400928,
      name: r'dateIndex',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dateIndex',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarDailyLogGetId,
  getLinks: _isarDailyLogGetLinks,
  attach: _isarDailyLogAttach,
  version: '3.3.2',
);

int _isarDailyLogEstimateSize(
  IsarDailyLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _isarDailyLogSerialize(
  IsarDailyLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.date);
  writer.writeLong(offsets[1], object.dateIndex);
  writer.writeDouble(offsets[2], object.ketoRatioAvg);
  writer.writeDouble(offsets[3], object.magnesiumMg);
  writer.writeDouble(offsets[4], object.potassiumMg);
  writer.writeDouble(offsets[5], object.sodiumMg);
  writer.writeDouble(offsets[6], object.totalFatG);
  writer.writeDouble(offsets[7], object.totalNetCarbsG);
  writer.writeDouble(offsets[8], object.totalProteinG);
  writer.writeDouble(offsets[9], object.waterMl);
}

IsarDailyLog _isarDailyLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarDailyLog();
  object.date = reader.readDateTime(offsets[0]);
  object.dateIndex = reader.readLong(offsets[1]);
  object.id = id;
  object.ketoRatioAvg = reader.readDouble(offsets[2]);
  object.magnesiumMg = reader.readDouble(offsets[3]);
  object.potassiumMg = reader.readDouble(offsets[4]);
  object.sodiumMg = reader.readDouble(offsets[5]);
  object.totalFatG = reader.readDouble(offsets[6]);
  object.totalNetCarbsG = reader.readDouble(offsets[7]);
  object.totalProteinG = reader.readDouble(offsets[8]);
  object.waterMl = reader.readDouble(offsets[9]);
  return object;
}

P _isarDailyLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarDailyLogGetId(IsarDailyLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarDailyLogGetLinks(IsarDailyLog object) {
  return [];
}

void _isarDailyLogAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarDailyLog object,
) {
  object.id = id;
}

extension IsarDailyLogByIndex on IsarCollection<IsarDailyLog> {
  Future<IsarDailyLog?> getByDateIndex(int dateIndex) {
    return getByIndex(r'dateIndex', [dateIndex]);
  }

  IsarDailyLog? getByDateIndexSync(int dateIndex) {
    return getByIndexSync(r'dateIndex', [dateIndex]);
  }

  Future<bool> deleteByDateIndex(int dateIndex) {
    return deleteByIndex(r'dateIndex', [dateIndex]);
  }

  bool deleteByDateIndexSync(int dateIndex) {
    return deleteByIndexSync(r'dateIndex', [dateIndex]);
  }

  Future<List<IsarDailyLog?>> getAllByDateIndex(List<int> dateIndexValues) {
    final values = dateIndexValues.map((e) => [e]).toList();
    return getAllByIndex(r'dateIndex', values);
  }

  List<IsarDailyLog?> getAllByDateIndexSync(List<int> dateIndexValues) {
    final values = dateIndexValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'dateIndex', values);
  }

  Future<int> deleteAllByDateIndex(List<int> dateIndexValues) {
    final values = dateIndexValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'dateIndex', values);
  }

  int deleteAllByDateIndexSync(List<int> dateIndexValues) {
    final values = dateIndexValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'dateIndex', values);
  }

  Future<Id> putByDateIndex(IsarDailyLog object) {
    return putByIndex(r'dateIndex', object);
  }

  Id putByDateIndexSync(IsarDailyLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'dateIndex', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateIndex(List<IsarDailyLog> objects) {
    return putAllByIndex(r'dateIndex', objects);
  }

  List<Id> putAllByDateIndexSync(
    List<IsarDailyLog> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'dateIndex', objects, saveLinks: saveLinks);
  }
}

extension IsarDailyLogQueryWhereSort
    on QueryBuilder<IsarDailyLog, IsarDailyLog, QWhere> {
  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterWhere> anyDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dateIndex'),
      );
    });
  }
}

extension IsarDailyLogQueryWhere
    on QueryBuilder<IsarDailyLog, IsarDailyLog, QWhereClause> {
  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterWhereClause> dateIndexEqualTo(
    int dateIndex,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'dateIndex', value: [dateIndex]),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterWhereClause>
  dateIndexNotEqualTo(int dateIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateIndex',
                lower: [],
                upper: [dateIndex],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateIndex',
                lower: [dateIndex],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateIndex',
                lower: [dateIndex],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateIndex',
                lower: [],
                upper: [dateIndex],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterWhereClause>
  dateIndexGreaterThan(int dateIndex, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dateIndex',
          lower: [dateIndex],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterWhereClause> dateIndexLessThan(
    int dateIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dateIndex',
          lower: [],
          upper: [dateIndex],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterWhereClause> dateIndexBetween(
    int lowerDateIndex,
    int upperDateIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dateIndex',
          lower: [lowerDateIndex],
          includeLower: includeLower,
          upper: [upperDateIndex],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarDailyLogQueryFilter
    on QueryBuilder<IsarDailyLog, IsarDailyLog, QFilterCondition> {
  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition> dateEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'date', value: value),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  dateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'date',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'date',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'date',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  dateIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateIndex', value: value),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  dateIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dateIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  dateIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dateIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  dateIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dateIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  ketoRatioAvgEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ketoRatioAvg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  ketoRatioAvgGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ketoRatioAvg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  ketoRatioAvgLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ketoRatioAvg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  ketoRatioAvgBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ketoRatioAvg',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  magnesiumMgEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'magnesiumMg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  magnesiumMgGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'magnesiumMg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  magnesiumMgLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'magnesiumMg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  magnesiumMgBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'magnesiumMg',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  potassiumMgEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'potassiumMg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  potassiumMgGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'potassiumMg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  potassiumMgLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'potassiumMg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  potassiumMgBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'potassiumMg',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  sodiumMgEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sodiumMg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  sodiumMgGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sodiumMg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  sodiumMgLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sodiumMg',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  sodiumMgBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sodiumMg',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  totalFatGEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'totalFatG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  totalFatGGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalFatG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  totalFatGLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalFatG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  totalFatGBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalFatG',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  totalNetCarbsGEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'totalNetCarbsG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  totalNetCarbsGGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalNetCarbsG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  totalNetCarbsGLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalNetCarbsG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  totalNetCarbsGBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalNetCarbsG',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  totalProteinGEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'totalProteinG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  totalProteinGGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalProteinG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  totalProteinGLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalProteinG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  totalProteinGBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalProteinG',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  waterMlEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'waterMl',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  waterMlGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'waterMl',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  waterMlLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'waterMl',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterFilterCondition>
  waterMlBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'waterMl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension IsarDailyLogQueryObject
    on QueryBuilder<IsarDailyLog, IsarDailyLog, QFilterCondition> {}

extension IsarDailyLogQueryLinks
    on QueryBuilder<IsarDailyLog, IsarDailyLog, QFilterCondition> {}

extension IsarDailyLogQuerySortBy
    on QueryBuilder<IsarDailyLog, IsarDailyLog, QSortBy> {
  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> sortByDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> sortByDateIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> sortByKetoRatioAvg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ketoRatioAvg', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy>
  sortByKetoRatioAvgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ketoRatioAvg', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> sortByMagnesiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy>
  sortByMagnesiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> sortByPotassiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy>
  sortByPotassiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> sortBySodiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> sortBySodiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> sortByTotalFatG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFatG', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> sortByTotalFatGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFatG', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy>
  sortByTotalNetCarbsG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetCarbsG', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy>
  sortByTotalNetCarbsGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetCarbsG', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> sortByTotalProteinG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalProteinG', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy>
  sortByTotalProteinGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalProteinG', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> sortByWaterMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterMl', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> sortByWaterMlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterMl', Sort.desc);
    });
  }
}

extension IsarDailyLogQuerySortThenBy
    on QueryBuilder<IsarDailyLog, IsarDailyLog, QSortThenBy> {
  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenByDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenByDateIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenByKetoRatioAvg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ketoRatioAvg', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy>
  thenByKetoRatioAvgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ketoRatioAvg', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenByMagnesiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy>
  thenByMagnesiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenByPotassiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy>
  thenByPotassiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenBySodiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenBySodiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenByTotalFatG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFatG', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenByTotalFatGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFatG', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy>
  thenByTotalNetCarbsG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetCarbsG', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy>
  thenByTotalNetCarbsGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalNetCarbsG', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenByTotalProteinG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalProteinG', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy>
  thenByTotalProteinGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalProteinG', Sort.desc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenByWaterMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterMl', Sort.asc);
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QAfterSortBy> thenByWaterMlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterMl', Sort.desc);
    });
  }
}

extension IsarDailyLogQueryWhereDistinct
    on QueryBuilder<IsarDailyLog, IsarDailyLog, QDistinct> {
  QueryBuilder<IsarDailyLog, IsarDailyLog, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QDistinct> distinctByDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateIndex');
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QDistinct> distinctByKetoRatioAvg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ketoRatioAvg');
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QDistinct> distinctByMagnesiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'magnesiumMg');
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QDistinct> distinctByPotassiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'potassiumMg');
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QDistinct> distinctBySodiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sodiumMg');
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QDistinct> distinctByTotalFatG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalFatG');
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QDistinct>
  distinctByTotalNetCarbsG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalNetCarbsG');
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QDistinct>
  distinctByTotalProteinG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalProteinG');
    });
  }

  QueryBuilder<IsarDailyLog, IsarDailyLog, QDistinct> distinctByWaterMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waterMl');
    });
  }
}

extension IsarDailyLogQueryProperty
    on QueryBuilder<IsarDailyLog, IsarDailyLog, QQueryProperty> {
  QueryBuilder<IsarDailyLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarDailyLog, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<IsarDailyLog, int, QQueryOperations> dateIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateIndex');
    });
  }

  QueryBuilder<IsarDailyLog, double, QQueryOperations> ketoRatioAvgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ketoRatioAvg');
    });
  }

  QueryBuilder<IsarDailyLog, double, QQueryOperations> magnesiumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'magnesiumMg');
    });
  }

  QueryBuilder<IsarDailyLog, double, QQueryOperations> potassiumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'potassiumMg');
    });
  }

  QueryBuilder<IsarDailyLog, double, QQueryOperations> sodiumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sodiumMg');
    });
  }

  QueryBuilder<IsarDailyLog, double, QQueryOperations> totalFatGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalFatG');
    });
  }

  QueryBuilder<IsarDailyLog, double, QQueryOperations>
  totalNetCarbsGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalNetCarbsG');
    });
  }

  QueryBuilder<IsarDailyLog, double, QQueryOperations> totalProteinGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalProteinG');
    });
  }

  QueryBuilder<IsarDailyLog, double, QQueryOperations> waterMlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waterMl');
    });
  }
}
