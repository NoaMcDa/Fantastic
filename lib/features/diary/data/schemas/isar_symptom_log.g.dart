// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_symptom_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarSymptomLogCollection on Isar {
  IsarCollection<IsarSymptomLog> get isarSymptomLogs => this.collection();
}

const IsarSymptomLogSchema = CollectionSchema(
  name: r'IsarSymptomLog',
  id: -7806229248286879724,
  properties: {
    r'clarityScore': PropertySchema(
      id: 0,
      name: r'clarityScore',
      type: IsarType.long,
    ),
    r'date': PropertySchema(id: 1, name: r'date', type: IsarType.dateTime),
    r'dateIndex': PropertySchema(
      id: 2,
      name: r'dateIndex',
      type: IsarType.long,
    ),
    r'energyScore': PropertySchema(
      id: 3,
      name: r'energyScore',
      type: IsarType.long,
    ),
    r'hungerScore': PropertySchema(
      id: 4,
      name: r'hungerScore',
      type: IsarType.long,
    ),
    r'moodScore': PropertySchema(
      id: 5,
      name: r'moodScore',
      type: IsarType.long,
    ),
    r'notes': PropertySchema(id: 6, name: r'notes', type: IsarType.string),
    r'physicalScore': PropertySchema(
      id: 7,
      name: r'physicalScore',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarSymptomLogEstimateSize,
  serialize: _isarSymptomLogSerialize,
  deserialize: _isarSymptomLogDeserialize,
  deserializeProp: _isarSymptomLogDeserializeProp,
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

  getId: _isarSymptomLogGetId,
  getLinks: _isarSymptomLogGetLinks,
  attach: _isarSymptomLogAttach,
  version: '3.3.2',
);

int _isarSymptomLogEstimateSize(
  IsarSymptomLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarSymptomLogSerialize(
  IsarSymptomLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.clarityScore);
  writer.writeDateTime(offsets[1], object.date);
  writer.writeLong(offsets[2], object.dateIndex);
  writer.writeLong(offsets[3], object.energyScore);
  writer.writeLong(offsets[4], object.hungerScore);
  writer.writeLong(offsets[5], object.moodScore);
  writer.writeString(offsets[6], object.notes);
  writer.writeLong(offsets[7], object.physicalScore);
}

IsarSymptomLog _isarSymptomLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarSymptomLog();
  object.clarityScore = reader.readLong(offsets[0]);
  object.date = reader.readDateTime(offsets[1]);
  object.dateIndex = reader.readLong(offsets[2]);
  object.energyScore = reader.readLong(offsets[3]);
  object.hungerScore = reader.readLong(offsets[4]);
  object.id = id;
  object.moodScore = reader.readLong(offsets[5]);
  object.notes = reader.readStringOrNull(offsets[6]);
  object.physicalScore = reader.readLong(offsets[7]);
  return object;
}

P _isarSymptomLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarSymptomLogGetId(IsarSymptomLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarSymptomLogGetLinks(IsarSymptomLog object) {
  return [];
}

void _isarSymptomLogAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarSymptomLog object,
) {
  object.id = id;
}

extension IsarSymptomLogByIndex on IsarCollection<IsarSymptomLog> {
  Future<IsarSymptomLog?> getByDateIndex(int dateIndex) {
    return getByIndex(r'dateIndex', [dateIndex]);
  }

  IsarSymptomLog? getByDateIndexSync(int dateIndex) {
    return getByIndexSync(r'dateIndex', [dateIndex]);
  }

  Future<bool> deleteByDateIndex(int dateIndex) {
    return deleteByIndex(r'dateIndex', [dateIndex]);
  }

  bool deleteByDateIndexSync(int dateIndex) {
    return deleteByIndexSync(r'dateIndex', [dateIndex]);
  }

  Future<List<IsarSymptomLog?>> getAllByDateIndex(List<int> dateIndexValues) {
    final values = dateIndexValues.map((e) => [e]).toList();
    return getAllByIndex(r'dateIndex', values);
  }

  List<IsarSymptomLog?> getAllByDateIndexSync(List<int> dateIndexValues) {
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

  Future<Id> putByDateIndex(IsarSymptomLog object) {
    return putByIndex(r'dateIndex', object);
  }

  Id putByDateIndexSync(IsarSymptomLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'dateIndex', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateIndex(List<IsarSymptomLog> objects) {
    return putAllByIndex(r'dateIndex', objects);
  }

  List<Id> putAllByDateIndexSync(
    List<IsarSymptomLog> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'dateIndex', objects, saveLinks: saveLinks);
  }
}

extension IsarSymptomLogQueryWhereSort
    on QueryBuilder<IsarSymptomLog, IsarSymptomLog, QWhere> {
  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterWhere> anyDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dateIndex'),
      );
    });
  }
}

extension IsarSymptomLogQueryWhere
    on QueryBuilder<IsarSymptomLog, IsarSymptomLog, QWhereClause> {
  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterWhereClause>
  dateIndexEqualTo(int dateIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'dateIndex', value: [dateIndex]),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterWhereClause>
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

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterWhereClause>
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

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterWhereClause>
  dateIndexLessThan(int dateIndex, {bool include = false}) {
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

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterWhereClause>
  dateIndexBetween(
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

extension IsarSymptomLogQueryFilter
    on QueryBuilder<IsarSymptomLog, IsarSymptomLog, QFilterCondition> {
  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  clarityScoreEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'clarityScore', value: value),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  clarityScoreGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'clarityScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  clarityScoreLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'clarityScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  clarityScoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'clarityScore',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'date', value: value),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
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

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  dateLessThan(DateTime value, {bool include = false}) {
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

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  dateBetween(
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

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  dateIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateIndex', value: value),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
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

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
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

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
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

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  energyScoreEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'energyScore', value: value),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  energyScoreGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'energyScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  energyScoreLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'energyScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  energyScoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'energyScore',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  hungerScoreEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hungerScore', value: value),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  hungerScoreGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'hungerScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  hungerScoreLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'hungerScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  hungerScoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'hungerScore',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
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

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
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

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  moodScoreEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'moodScore', value: value),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  moodScoreGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'moodScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  moodScoreLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'moodScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  moodScoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'moodScore',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  notesEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'notes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  notesStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  notesEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'notes',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  physicalScoreEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'physicalScore', value: value),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  physicalScoreGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'physicalScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  physicalScoreLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'physicalScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterFilterCondition>
  physicalScoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'physicalScore',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarSymptomLogQueryObject
    on QueryBuilder<IsarSymptomLog, IsarSymptomLog, QFilterCondition> {}

extension IsarSymptomLogQueryLinks
    on QueryBuilder<IsarSymptomLog, IsarSymptomLog, QFilterCondition> {}

extension IsarSymptomLogQuerySortBy
    on QueryBuilder<IsarSymptomLog, IsarSymptomLog, QSortBy> {
  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  sortByClarityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clarityScore', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  sortByClarityScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clarityScore', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy> sortByDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  sortByDateIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  sortByEnergyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'energyScore', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  sortByEnergyScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'energyScore', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  sortByHungerScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hungerScore', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  sortByHungerScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hungerScore', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy> sortByMoodScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  sortByMoodScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  sortByPhysicalScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'physicalScore', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  sortByPhysicalScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'physicalScore', Sort.desc);
    });
  }
}

extension IsarSymptomLogQuerySortThenBy
    on QueryBuilder<IsarSymptomLog, IsarSymptomLog, QSortThenBy> {
  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  thenByClarityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clarityScore', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  thenByClarityScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clarityScore', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy> thenByDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  thenByDateIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  thenByEnergyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'energyScore', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  thenByEnergyScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'energyScore', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  thenByHungerScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hungerScore', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  thenByHungerScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hungerScore', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy> thenByMoodScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  thenByMoodScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  thenByPhysicalScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'physicalScore', Sort.asc);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QAfterSortBy>
  thenByPhysicalScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'physicalScore', Sort.desc);
    });
  }
}

extension IsarSymptomLogQueryWhereDistinct
    on QueryBuilder<IsarSymptomLog, IsarSymptomLog, QDistinct> {
  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QDistinct>
  distinctByClarityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clarityScore');
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QDistinct>
  distinctByDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateIndex');
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QDistinct>
  distinctByEnergyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'energyScore');
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QDistinct>
  distinctByHungerScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hungerScore');
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QDistinct>
  distinctByMoodScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'moodScore');
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QDistinct> distinctByNotes({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSymptomLog, IsarSymptomLog, QDistinct>
  distinctByPhysicalScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'physicalScore');
    });
  }
}

extension IsarSymptomLogQueryProperty
    on QueryBuilder<IsarSymptomLog, IsarSymptomLog, QQueryProperty> {
  QueryBuilder<IsarSymptomLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarSymptomLog, int, QQueryOperations> clarityScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clarityScore');
    });
  }

  QueryBuilder<IsarSymptomLog, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<IsarSymptomLog, int, QQueryOperations> dateIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateIndex');
    });
  }

  QueryBuilder<IsarSymptomLog, int, QQueryOperations> energyScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'energyScore');
    });
  }

  QueryBuilder<IsarSymptomLog, int, QQueryOperations> hungerScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hungerScore');
    });
  }

  QueryBuilder<IsarSymptomLog, int, QQueryOperations> moodScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'moodScore');
    });
  }

  QueryBuilder<IsarSymptomLog, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<IsarSymptomLog, int, QQueryOperations> physicalScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'physicalScore');
    });
  }
}
