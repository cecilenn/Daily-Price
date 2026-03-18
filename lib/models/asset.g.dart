// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAssetCollection on Isar {
  IsarCollection<Asset> get assets => this.collection();
}

const AssetSchema = CollectionSchema(
  name: r'Asset',
  id: 1,
  properties: {
    r'actualDailyCost': PropertySchema(
      id: 0,
      name: r'actualDailyCost',
      type: IsarType.double,
    ),
    r'actualUsedDays': PropertySchema(
      id: 1,
      name: r'actualUsedDays',
      type: IsarType.long,
    ),
    r'assetName': PropertySchema(
      id: 2,
      name: r'assetName',
      type: IsarType.string,
    ),
    r'category': PropertySchema(
      id: 3,
      name: r'category',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 4,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'dailyCost': PropertySchema(
      id: 5,
      name: r'dailyCost',
      type: IsarType.double,
    ),
    r'depreciatedValue': PropertySchema(
      id: 6,
      name: r'depreciatedValue',
      type: IsarType.double,
    ),
    r'expectedLifespanDays': PropertySchema(
      id: 7,
      name: r'expectedLifespanDays',
      type: IsarType.long,
    ),
    r'expireDate': PropertySchema(
      id: 8,
      name: r'expireDate',
      type: IsarType.dateTime,
    ),
    r'id': PropertySchema(
      id: 9,
      name: r'id',
      type: IsarType.string,
    ),
    r'isExpired': PropertySchema(
      id: 10,
      name: r'isExpired',
      type: IsarType.bool,
    ),
    r'isPinned': PropertySchema(
      id: 11,
      name: r'isPinned',
      type: IsarType.bool,
    ),
    r'isSold': PropertySchema(
      id: 12,
      name: r'isSold',
      type: IsarType.bool,
    ),
    r'purchaseDate': PropertySchema(
      id: 13,
      name: r'purchaseDate',
      type: IsarType.dateTime,
    ),
    r'purchasePrice': PropertySchema(
      id: 14,
      name: r'purchasePrice',
      type: IsarType.double,
    ),
    r'remainingDays': PropertySchema(
      id: 15,
      name: r'remainingDays',
      type: IsarType.long,
    ),
    r'remainingValue': PropertySchema(
      id: 16,
      name: r'remainingValue',
      type: IsarType.double,
    ),
    r'renewalHistoryJson': PropertySchema(
      id: 17,
      name: r'renewalHistoryJson',
      type: IsarType.string,
    ),
    r'soldDate': PropertySchema(
      id: 18,
      name: r'soldDate',
      type: IsarType.dateTime,
    ),
    r'soldPrice': PropertySchema(
      id: 19,
      name: r'soldPrice',
      type: IsarType.double,
    ),
    r'soldProfitOrLoss': PropertySchema(
      id: 20,
      name: r'soldProfitOrLoss',
      type: IsarType.double,
    ),
    r'tags': PropertySchema(
      id: 21,
      name: r'tags',
      type: IsarType.stringList,
    ),
    r'usedDays': PropertySchema(
      id: 22,
      name: r'usedDays',
      type: IsarType.long,
    ),
    r'userId': PropertySchema(
      id: 23,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _assetEstimateSize,
  serialize: _assetSerialize,
  deserialize: _assetDeserialize,
  deserializeProp: _assetDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: 2,
      name: r'id',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _assetGetId,
  getLinks: _assetGetLinks,
  attach: _assetAttach,
  version: '3.1.0+1',
);

int _assetEstimateSize(
  Asset object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.assetName.length * 3;
  bytesCount += 3 + object.category.length * 3;
  {
    final value = object.id;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.renewalHistoryJson.length * 3;
  bytesCount += 3 + object.tags.length * 3;
  {
    for (var i = 0; i < object.tags.length; i++) {
      final value = object.tags[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.userId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _assetSerialize(
  Asset object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.actualDailyCost);
  writer.writeLong(offsets[1], object.actualUsedDays);
  writer.writeString(offsets[2], object.assetName);
  writer.writeString(offsets[3], object.category);
  writer.writeDateTime(offsets[4], object.createdAt);
  writer.writeDouble(offsets[5], object.dailyCost);
  writer.writeDouble(offsets[6], object.depreciatedValue);
  writer.writeLong(offsets[7], object.expectedLifespanDays);
  writer.writeDateTime(offsets[8], object.expireDate);
  writer.writeString(offsets[9], object.id);
  writer.writeBool(offsets[10], object.isExpired);
  writer.writeBool(offsets[11], object.isPinned);
  writer.writeBool(offsets[12], object.isSold);
  writer.writeDateTime(offsets[13], object.purchaseDate);
  writer.writeDouble(offsets[14], object.purchasePrice);
  writer.writeLong(offsets[15], object.remainingDays);
  writer.writeDouble(offsets[16], object.remainingValue);
  writer.writeString(offsets[17], object.renewalHistoryJson);
  writer.writeDateTime(offsets[18], object.soldDate);
  writer.writeDouble(offsets[19], object.soldPrice);
  writer.writeDouble(offsets[20], object.soldProfitOrLoss);
  writer.writeStringList(offsets[21], object.tags);
  writer.writeLong(offsets[22], object.usedDays);
  writer.writeString(offsets[23], object.userId);
}

Asset _assetDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Asset(
    assetName: reader.readString(offsets[2]),
    category: reader.readStringOrNull(offsets[3]) ?? 'physical',
    createdAt: reader.readDateTime(offsets[4]),
    expectedLifespanDays: reader.readLong(offsets[7]),
    expireDate: reader.readDateTimeOrNull(offsets[8]),
    id: reader.readStringOrNull(offsets[9]),
    isPinned: reader.readBoolOrNull(offsets[11]) ?? false,
    isSold: reader.readBoolOrNull(offsets[12]) ?? false,
    isarId: id,
    purchaseDate: reader.readDateTime(offsets[13]),
    purchasePrice: reader.readDouble(offsets[14]),
    soldDate: reader.readDateTimeOrNull(offsets[18]),
    soldPrice: reader.readDoubleOrNull(offsets[19]),
    tags: reader.readStringList(offsets[21]) ?? const [],
    userId: reader.readStringOrNull(offsets[23]),
  );
  object.renewalHistoryJson = reader.readString(offsets[17]);
  return object;
}

P _assetDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset) ?? 'physical') as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 12:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readDouble(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readDouble(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 19:
      return (reader.readDoubleOrNull(offset)) as P;
    case 20:
      return (reader.readDouble(offset)) as P;
    case 21:
      return (reader.readStringList(offset) ?? const []) as P;
    case 22:
      return (reader.readLong(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _assetGetId(Asset object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _assetGetLinks(Asset object) {
  return [];
}

void _assetAttach(IsarCollection<dynamic> col, Id id, Asset object) {
  object.isarId = id;
}

extension AssetQueryWhereSort on QueryBuilder<Asset, Asset, QWhere> {
  QueryBuilder<Asset, Asset, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AssetQueryWhere on QueryBuilder<Asset, Asset, QWhereClause> {
  QueryBuilder<Asset, Asset, QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Asset, Asset, QAfterWhereClause> isarIdGreaterThan(Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<Asset, Asset, QAfterWhereClause> isarIdLessThan(Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<Asset, Asset, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterWhereClause> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [null],
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterWhereClause> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'id',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterWhereClause> idEqualTo(String? id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterWhereClause> idNotEqualTo(String? id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension AssetQueryFilter on QueryBuilder<Asset, Asset, QFilterCondition> {
  QueryBuilder<Asset, Asset, QAfterFilterCondition> actualDailyCostEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actualDailyCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> actualDailyCostGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actualDailyCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> actualDailyCostLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actualDailyCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> actualDailyCostBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actualDailyCost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> actualUsedDaysEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actualUsedDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> actualUsedDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actualUsedDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> actualUsedDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actualUsedDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> actualUsedDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actualUsedDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> assetNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assetName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> assetNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assetName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> assetNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assetName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> assetNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assetName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> assetNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'assetName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> assetNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'assetName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> assetNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'assetName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> assetNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'assetName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> assetNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assetName',
        value: '',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> assetNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assetName',
        value: '',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> categoryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> categoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> categoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> categoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> categoryContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> categoryMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> dailyCostEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dailyCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> dailyCostGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dailyCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> dailyCostLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dailyCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> dailyCostBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dailyCost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> depreciatedValueEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'depreciatedValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> depreciatedValueGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'depreciatedValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> depreciatedValueLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'depreciatedValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> depreciatedValueBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'depreciatedValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> expectedLifespanDaysEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expectedLifespanDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition>
      expectedLifespanDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expectedLifespanDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition>
      expectedLifespanDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expectedLifespanDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> expectedLifespanDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expectedLifespanDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> expireDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'expireDate',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> expireDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'expireDate',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> expireDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expireDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> expireDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expireDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> expireDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expireDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> expireDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expireDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> idEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> idGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> idLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> idBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> idContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> idMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> isExpiredEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isExpired',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> isPinnedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPinned',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> isSoldEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSold',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> purchaseDateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'purchaseDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> purchaseDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'purchaseDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> purchaseDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'purchaseDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> purchaseDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'purchaseDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> purchasePriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'purchasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> purchasePriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'purchasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> purchasePriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'purchasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> purchasePriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'purchasePrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> remainingDaysEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remainingDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> remainingDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remainingDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> remainingDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remainingDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> remainingDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remainingDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> remainingValueEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remainingValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> remainingValueGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remainingValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> remainingValueLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remainingValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> remainingValueBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remainingValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> renewalHistoryJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'renewalHistoryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition>
      renewalHistoryJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'renewalHistoryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> renewalHistoryJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'renewalHistoryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> renewalHistoryJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'renewalHistoryJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition>
      renewalHistoryJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'renewalHistoryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> renewalHistoryJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'renewalHistoryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> renewalHistoryJsonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'renewalHistoryJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> renewalHistoryJsonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'renewalHistoryJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition>
      renewalHistoryJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'renewalHistoryJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition>
      renewalHistoryJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'renewalHistoryJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'soldDate',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'soldDate',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'soldDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'soldDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'soldDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'soldDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'soldPrice',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'soldPrice',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'soldPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'soldPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'soldPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'soldPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldProfitOrLossEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'soldProfitOrLoss',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldProfitOrLossGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'soldProfitOrLoss',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldProfitOrLossLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'soldProfitOrLoss',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> soldProfitOrLossBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'soldProfitOrLoss',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tags',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> tagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> usedDaysEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usedDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> usedDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'usedDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> usedDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'usedDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> usedDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'usedDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> userIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> userIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> userIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> userIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> userIdContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> userIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<Asset, Asset, QAfterFilterCondition> userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension AssetQueryObject on QueryBuilder<Asset, Asset, QFilterCondition> {}

extension AssetQueryLinks on QueryBuilder<Asset, Asset, QFilterCondition> {}

extension AssetQuerySortBy on QueryBuilder<Asset, Asset, QSortBy> {
  QueryBuilder<Asset, Asset, QAfterSortBy> sortByActualDailyCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualDailyCost', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByActualDailyCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualDailyCost', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByActualUsedDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualUsedDays', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByActualUsedDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualUsedDays', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByAssetName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetName', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByAssetNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetName', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByDailyCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyCost', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByDailyCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyCost', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByDepreciatedValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'depreciatedValue', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByDepreciatedValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'depreciatedValue', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByExpectedLifespanDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedLifespanDays', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByExpectedLifespanDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedLifespanDays', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByExpireDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expireDate', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByExpireDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expireDate', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByIsSold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSold', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByIsSoldDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSold', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByPurchaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByPurchaseDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByPurchasePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByRemainingDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingDays', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByRemainingDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingDays', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByRemainingValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingValue', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByRemainingValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingValue', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByRenewalHistoryJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'renewalHistoryJson', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByRenewalHistoryJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'renewalHistoryJson', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortBySoldDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soldDate', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortBySoldDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soldDate', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortBySoldPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soldPrice', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortBySoldPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soldPrice', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortBySoldProfitOrLoss() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soldProfitOrLoss', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortBySoldProfitOrLossDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soldProfitOrLoss', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByUsedDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedDays', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByUsedDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedDays', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension AssetQuerySortThenBy on QueryBuilder<Asset, Asset, QSortThenBy> {
  QueryBuilder<Asset, Asset, QAfterSortBy> thenByActualDailyCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualDailyCost', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByActualDailyCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualDailyCost', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByActualUsedDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualUsedDays', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByActualUsedDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualUsedDays', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByAssetName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetName', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByAssetNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetName', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByDailyCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyCost', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByDailyCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyCost', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByDepreciatedValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'depreciatedValue', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByDepreciatedValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'depreciatedValue', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByExpectedLifespanDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedLifespanDays', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByExpectedLifespanDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedLifespanDays', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByExpireDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expireDate', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByExpireDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expireDate', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByIsSold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSold', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByIsSoldDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSold', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByPurchaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByPurchaseDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByPurchasePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByRemainingDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingDays', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByRemainingDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingDays', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByRemainingValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingValue', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByRemainingValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingValue', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByRenewalHistoryJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'renewalHistoryJson', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByRenewalHistoryJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'renewalHistoryJson', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenBySoldDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soldDate', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenBySoldDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soldDate', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenBySoldPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soldPrice', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenBySoldPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soldPrice', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenBySoldProfitOrLoss() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soldProfitOrLoss', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenBySoldProfitOrLossDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'soldProfitOrLoss', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByUsedDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedDays', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByUsedDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedDays', Sort.desc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<Asset, Asset, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension AssetQueryWhereDistinct on QueryBuilder<Asset, Asset, QDistinct> {
  QueryBuilder<Asset, Asset, QDistinct> distinctByActualDailyCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actualDailyCost');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByActualUsedDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actualUsedDays');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByAssetName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assetName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByDailyCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dailyCost');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByDepreciatedValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'depreciatedValue');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByExpectedLifespanDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expectedLifespanDays');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByExpireDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expireDate');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isExpired');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPinned');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByIsSold() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSold');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByPurchaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purchaseDate');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purchasePrice');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByRemainingDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainingDays');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByRemainingValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainingValue');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByRenewalHistoryJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'renewalHistoryJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctBySoldDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'soldDate');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctBySoldPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'soldPrice');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctBySoldProfitOrLoss() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'soldProfitOrLoss');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByUsedDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usedDays');
    });
  }

  QueryBuilder<Asset, Asset, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension AssetQueryProperty on QueryBuilder<Asset, Asset, QQueryProperty> {
  QueryBuilder<Asset, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<Asset, double, QQueryOperations> actualDailyCostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actualDailyCost');
    });
  }

  QueryBuilder<Asset, int, QQueryOperations> actualUsedDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actualUsedDays');
    });
  }

  QueryBuilder<Asset, String, QQueryOperations> assetNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assetName');
    });
  }

  QueryBuilder<Asset, String, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<Asset, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Asset, double, QQueryOperations> dailyCostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dailyCost');
    });
  }

  QueryBuilder<Asset, double, QQueryOperations> depreciatedValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'depreciatedValue');
    });
  }

  QueryBuilder<Asset, int, QQueryOperations> expectedLifespanDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expectedLifespanDays');
    });
  }

  QueryBuilder<Asset, DateTime?, QQueryOperations> expireDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expireDate');
    });
  }

  QueryBuilder<Asset, String?, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Asset, bool, QQueryOperations> isExpiredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isExpired');
    });
  }

  QueryBuilder<Asset, bool, QQueryOperations> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPinned');
    });
  }

  QueryBuilder<Asset, bool, QQueryOperations> isSoldProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSold');
    });
  }

  QueryBuilder<Asset, DateTime, QQueryOperations> purchaseDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purchaseDate');
    });
  }

  QueryBuilder<Asset, double, QQueryOperations> purchasePriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purchasePrice');
    });
  }

  QueryBuilder<Asset, int, QQueryOperations> remainingDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainingDays');
    });
  }

  QueryBuilder<Asset, double, QQueryOperations> remainingValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainingValue');
    });
  }

  QueryBuilder<Asset, String, QQueryOperations> renewalHistoryJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'renewalHistoryJson');
    });
  }

  QueryBuilder<Asset, DateTime?, QQueryOperations> soldDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'soldDate');
    });
  }

  QueryBuilder<Asset, double?, QQueryOperations> soldPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'soldPrice');
    });
  }

  QueryBuilder<Asset, double, QQueryOperations> soldProfitOrLossProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'soldProfitOrLoss');
    });
  }

  QueryBuilder<Asset, List<String>, QQueryOperations> tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }

  QueryBuilder<Asset, int, QQueryOperations> usedDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usedDays');
    });
  }

  QueryBuilder<Asset, String?, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
