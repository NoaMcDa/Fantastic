// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_meal_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarMealEntryCollection on Isar {
  IsarCollection<IsarMealEntry> get isarMealEntrys => this.collection();
}

const IsarMealEntrySchema = CollectionSchema(
  name: r'IsarMealEntry',
  id: -7959243741780225423,
  properties: {
    r'dateIndex': PropertySchema(
      id: 0,
      name: r'dateIndex',
      type: IsarType.long,
    ),
    r'fatG': PropertySchema(id: 1, name: r'fatG', type: IsarType.double),
    r'imageRef': PropertySchema(
      id: 2,
      name: r'imageRef',
      type: IsarType.string,
    ),
    r'ingredients': PropertySchema(
      id: 3,
      name: r'ingredients',
      type: IsarType.stringList,
    ),
    r'mealName': PropertySchema(
      id: 4,
      name: r'mealName',
      type: IsarType.string,
    ),
    r'netCarbsG': PropertySchema(
      id: 5,
      name: r'netCarbsG',
      type: IsarType.double,
    ),
    r'proteinG': PropertySchema(
      id: 6,
      name: r'proteinG',
      type: IsarType.double,
    ),
    r'timestamp': PropertySchema(
      id: 7,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _isarMealEntryEstimateSize,
  serialize: _isarMealEntrySerialize,
  deserialize: _isarMealEntryDeserialize,
  deserializeProp: _isarMealEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateIndex': IndexSchema(
      id: 5202930406488400928,
      name: r'dateIndex',
      unique: false,
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

  getId: _isarMealEntryGetId,
  getLinks: _isarMealEntryGetLinks,
  attach: _isarMealEntryAttach,
  version: '3.3.2',
);

int _isarMealEntryEstimateSize(
  IsarMealEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.imageRef;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.ingredients.length * 3;
  {
    for (var i = 0; i < object.ingredients.length; i++) {
      final value = object.ingredients[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.mealName.length * 3;
  return bytesCount;
}

void _isarMealEntrySerialize(
  IsarMealEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.dateIndex);
  writer.writeDouble(offsets[1], object.fatG);
  writer.writeString(offsets[2], object.imageRef);
  writer.writeStringList(offsets[3], object.ingredients);
  writer.writeString(offsets[4], object.mealName);
  writer.writeDouble(offsets[5], object.netCarbsG);
  writer.writeDouble(offsets[6], object.proteinG);
  writer.writeDateTime(offsets[7], object.timestamp);
}

IsarMealEntry _isarMealEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarMealEntry();
  object.dateIndex = reader.readLong(offsets[0]);
  object.fatG = reader.readDouble(offsets[1]);
  object.id = id;
  object.imageRef = reader.readStringOrNull(offsets[2]);
  object.ingredients = reader.readStringList(offsets[3]) ?? [];
  object.mealName = reader.readString(offsets[4]);
  object.netCarbsG = reader.readDouble(offsets[5]);
  object.proteinG = reader.readDouble(offsets[6]);
  object.timestamp = reader.readDateTime(offsets[7]);
  return object;
}

P _isarMealEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarMealEntryGetId(IsarMealEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarMealEntryGetLinks(IsarMealEntry object) {
  return [];
}

void _isarMealEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarMealEntry object,
) {
  object.id = id;
}

extension IsarMealEntryQueryWhereSort
    on QueryBuilder<IsarMealEntry, IsarMealEntry, QWhere> {
  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterWhere> anyDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dateIndex'),
      );
    });
  }
}

extension IsarMealEntryQueryWhere
    on QueryBuilder<IsarMealEntry, IsarMealEntry, QWhereClause> {
  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterWhereClause>
  dateIndexEqualTo(int dateIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'dateIndex', value: [dateIndex]),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterWhereClause>
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

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterWhereClause>
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

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterWhereClause>
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

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterWhereClause>
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

extension IsarMealEntryQueryFilter
    on QueryBuilder<IsarMealEntry, IsarMealEntry, QFilterCondition> {
  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  dateIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateIndex', value: value),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
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

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
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

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
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

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition> fatGEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fatG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  fatGGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fatG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  fatGLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fatG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition> fatGBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fatG',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
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

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  imageRefIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'imageRef'),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  imageRefIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'imageRef'),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  imageRefEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'imageRef',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  imageRefGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'imageRef',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  imageRefLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'imageRef',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  imageRefBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'imageRef',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  imageRefStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'imageRef',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  imageRefEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'imageRef',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  imageRefContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'imageRef',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  imageRefMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'imageRef',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  imageRefIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'imageRef', value: ''),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  imageRefIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'imageRef', value: ''),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ingredients',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ingredients',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ingredients',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ingredients',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ingredients',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ingredients',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ingredients',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ingredients',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ingredients', value: ''),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ingredients', value: ''),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'ingredients', length, true, length, true);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'ingredients', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'ingredients', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'ingredients', 0, true, length, include);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'ingredients', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  ingredientsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'ingredients',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  mealNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mealName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  mealNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mealName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  mealNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mealName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  mealNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mealName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  mealNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mealName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  mealNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mealName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  mealNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mealName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  mealNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mealName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  mealNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mealName', value: ''),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  mealNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mealName', value: ''),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  netCarbsGEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'netCarbsG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  netCarbsGGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'netCarbsG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  netCarbsGLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'netCarbsG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  netCarbsGBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'netCarbsG',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  proteinGEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'proteinG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  proteinGGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'proteinG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  proteinGLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'proteinG',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  proteinGBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'proteinG',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timestamp', value: value),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  timestampGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  timestampLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterFilterCondition>
  timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'timestamp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarMealEntryQueryObject
    on QueryBuilder<IsarMealEntry, IsarMealEntry, QFilterCondition> {}

extension IsarMealEntryQueryLinks
    on QueryBuilder<IsarMealEntry, IsarMealEntry, QFilterCondition> {}

extension IsarMealEntryQuerySortBy
    on QueryBuilder<IsarMealEntry, IsarMealEntry, QSortBy> {
  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> sortByDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy>
  sortByDateIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> sortByFatG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatG', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> sortByFatGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatG', Sort.desc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> sortByImageRef() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageRef', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy>
  sortByImageRefDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageRef', Sort.desc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> sortByMealName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealName', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy>
  sortByMealNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealName', Sort.desc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> sortByNetCarbsG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netCarbsG', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy>
  sortByNetCarbsGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netCarbsG', Sort.desc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> sortByProteinG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinG', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy>
  sortByProteinGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinG', Sort.desc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy>
  sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension IsarMealEntryQuerySortThenBy
    on QueryBuilder<IsarMealEntry, IsarMealEntry, QSortThenBy> {
  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> thenByDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy>
  thenByDateIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> thenByFatG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatG', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> thenByFatGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatG', Sort.desc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> thenByImageRef() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageRef', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy>
  thenByImageRefDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageRef', Sort.desc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> thenByMealName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealName', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy>
  thenByMealNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealName', Sort.desc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> thenByNetCarbsG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netCarbsG', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy>
  thenByNetCarbsGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netCarbsG', Sort.desc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> thenByProteinG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinG', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy>
  thenByProteinGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinG', Sort.desc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QAfterSortBy>
  thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension IsarMealEntryQueryWhereDistinct
    on QueryBuilder<IsarMealEntry, IsarMealEntry, QDistinct> {
  QueryBuilder<IsarMealEntry, IsarMealEntry, QDistinct> distinctByDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateIndex');
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QDistinct> distinctByFatG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fatG');
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QDistinct> distinctByImageRef({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageRef', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QDistinct>
  distinctByIngredients() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ingredients');
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QDistinct> distinctByMealName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mealName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QDistinct> distinctByNetCarbsG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'netCarbsG');
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QDistinct> distinctByProteinG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'proteinG');
    });
  }

  QueryBuilder<IsarMealEntry, IsarMealEntry, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension IsarMealEntryQueryProperty
    on QueryBuilder<IsarMealEntry, IsarMealEntry, QQueryProperty> {
  QueryBuilder<IsarMealEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarMealEntry, int, QQueryOperations> dateIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateIndex');
    });
  }

  QueryBuilder<IsarMealEntry, double, QQueryOperations> fatGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fatG');
    });
  }

  QueryBuilder<IsarMealEntry, String?, QQueryOperations> imageRefProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageRef');
    });
  }

  QueryBuilder<IsarMealEntry, List<String>, QQueryOperations>
  ingredientsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ingredients');
    });
  }

  QueryBuilder<IsarMealEntry, String, QQueryOperations> mealNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mealName');
    });
  }

  QueryBuilder<IsarMealEntry, double, QQueryOperations> netCarbsGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'netCarbsG');
    });
  }

  QueryBuilder<IsarMealEntry, double, QQueryOperations> proteinGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'proteinG');
    });
  }

  QueryBuilder<IsarMealEntry, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}
