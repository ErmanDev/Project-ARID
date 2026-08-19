// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetReportCollection on Isar {
  IsarCollection<Report> get reports => this.collection();
}

const ReportSchema = CollectionSchema(
  name: r'Report',
  id: 4107730612455750309,
  properties: {
    r'capturedAt': PropertySchema(
      id: 0,
      name: r'capturedAt',
      type: IsarType.dateTime,
    ),
    r'classification': PropertySchema(
      id: 1,
      name: r'classification',
      type: IsarType.byte,
      enumMap: _ReportclassificationEnumValueMap,
    ),
    r'confidenceScore': PropertySchema(
      id: 2,
      name: r'confidenceScore',
      type: IsarType.double,
    ),
    r'gpsAccuracy': PropertySchema(
      id: 3,
      name: r'gpsAccuracy',
      type: IsarType.double,
    ),
    r'gpsManual': PropertySchema(
      id: 4,
      name: r'gpsManual',
      type: IsarType.bool,
    ),
    r'groundTruth': PropertySchema(
      id: 5,
      name: r'groundTruth',
      type: IsarType.byte,
      enumMap: _ReportgroundTruthEnumValueMap,
    ),
    r'id': PropertySchema(id: 6, name: r'id', type: IsarType.string),
    r'imagePath': PropertySchema(
      id: 7,
      name: r'imagePath',
      type: IsarType.string,
    ),
    r'imageRemoteUrl': PropertySchema(
      id: 8,
      name: r'imageRemoteUrl',
      type: IsarType.string,
    ),
    r'lastSyncAttempt': PropertySchema(
      id: 9,
      name: r'lastSyncAttempt',
      type: IsarType.dateTime,
    ),
    r'latitude': PropertySchema(
      id: 10,
      name: r'latitude',
      type: IsarType.double,
    ),
    r'longitude': PropertySchema(
      id: 11,
      name: r'longitude',
      type: IsarType.double,
    ),
    r'pointsAwarded': PropertySchema(
      id: 12,
      name: r'pointsAwarded',
      type: IsarType.long,
    ),
    r'pointsStatus': PropertySchema(
      id: 13,
      name: r'pointsStatus',
      type: IsarType.byte,
      enumMap: _ReportpointsStatusEnumValueMap,
    ),
    r'riskLevel': PropertySchema(
      id: 14,
      name: r'riskLevel',
      type: IsarType.byte,
      enumMap: _ReportriskLevelEnumValueMap,
    ),
    r'syncStatus': PropertySchema(
      id: 15,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _ReportsyncStatusEnumValueMap,
    ),
    r'userId': PropertySchema(id: 16, name: r'userId', type: IsarType.string),
  },

  estimateSize: _reportEstimateSize,
  serialize: _reportSerialize,
  deserialize: _reportDeserialize,
  deserializeProp: _reportDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'riskLevel': IndexSchema(
      id: -5764699641590423344,
      name: r'riskLevel',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'riskLevel',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'capturedAt': IndexSchema(
      id: 7947551681198035194,
      name: r'capturedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'capturedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'syncStatus': IndexSchema(
      id: 8239539375045684509,
      name: r'syncStatus',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'syncStatus',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _reportGetId,
  getLinks: _reportGetLinks,
  attach: _reportAttach,
  version: '3.3.2',
);

int _reportEstimateSize(
  Report object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.imagePath.length * 3;
  {
    final value = object.imageRemoteUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _reportSerialize(
  Report object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.capturedAt);
  writer.writeByte(offsets[1], object.classification.index);
  writer.writeDouble(offsets[2], object.confidenceScore);
  writer.writeDouble(offsets[3], object.gpsAccuracy);
  writer.writeBool(offsets[4], object.gpsManual);
  writer.writeByte(offsets[5], object.groundTruth.index);
  writer.writeString(offsets[6], object.id);
  writer.writeString(offsets[7], object.imagePath);
  writer.writeString(offsets[8], object.imageRemoteUrl);
  writer.writeDateTime(offsets[9], object.lastSyncAttempt);
  writer.writeDouble(offsets[10], object.latitude);
  writer.writeDouble(offsets[11], object.longitude);
  writer.writeLong(offsets[12], object.pointsAwarded);
  writer.writeByte(offsets[13], object.pointsStatus.index);
  writer.writeByte(offsets[14], object.riskLevel.index);
  writer.writeByte(offsets[15], object.syncStatus.index);
  writer.writeString(offsets[16], object.userId);
}

Report _reportDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Report();
  object.capturedAt = reader.readDateTime(offsets[0]);
  object.classification =
      _ReportclassificationValueEnumMap[reader.readByteOrNull(offsets[1])] ??
      Classification.breeding;
  object.confidenceScore = reader.readDouble(offsets[2]);
  object.gpsAccuracy = reader.readDouble(offsets[3]);
  object.gpsManual = reader.readBool(offsets[4]);
  object.groundTruth =
      _ReportgroundTruthValueEnumMap[reader.readByteOrNull(offsets[5])] ??
      GroundTruth.unlabeled;
  object.id = reader.readString(offsets[6]);
  object.imagePath = reader.readString(offsets[7]);
  object.imageRemoteUrl = reader.readStringOrNull(offsets[8]);
  object.isarId = id;
  object.lastSyncAttempt = reader.readDateTimeOrNull(offsets[9]);
  object.latitude = reader.readDouble(offsets[10]);
  object.longitude = reader.readDouble(offsets[11]);
  object.pointsAwarded = reader.readLong(offsets[12]);
  object.pointsStatus =
      _ReportpointsStatusValueEnumMap[reader.readByteOrNull(offsets[13])] ??
      PointsStatus.provisional;
  object.riskLevel =
      _ReportriskLevelValueEnumMap[reader.readByteOrNull(offsets[14])] ??
      RiskLevel.red;
  object.syncStatus =
      _ReportsyncStatusValueEnumMap[reader.readByteOrNull(offsets[15])] ??
      SyncStatus.pendingUpload;
  object.userId = reader.readString(offsets[16]);
  return object;
}

P _reportDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (_ReportclassificationValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              Classification.breeding)
          as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (_ReportgroundTruthValueEnumMap[reader.readByteOrNull(offset)] ??
              GroundTruth.unlabeled)
          as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (_ReportpointsStatusValueEnumMap[reader.readByteOrNull(offset)] ??
              PointsStatus.provisional)
          as P;
    case 14:
      return (_ReportriskLevelValueEnumMap[reader.readByteOrNull(offset)] ??
              RiskLevel.red)
          as P;
    case 15:
      return (_ReportsyncStatusValueEnumMap[reader.readByteOrNull(offset)] ??
              SyncStatus.pendingUpload)
          as P;
    case 16:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ReportclassificationEnumValueMap = {'breeding': 0, 'nonBreeding': 1};
const _ReportclassificationValueEnumMap = {
  0: Classification.breeding,
  1: Classification.nonBreeding,
};
const _ReportgroundTruthEnumValueMap = {
  'unlabeled': 0,
  'breeding': 1,
  'nonBreeding': 2,
};
const _ReportgroundTruthValueEnumMap = {
  0: GroundTruth.unlabeled,
  1: GroundTruth.breeding,
  2: GroundTruth.nonBreeding,
};
const _ReportpointsStatusEnumValueMap = {'provisional': 0, 'verified': 1};
const _ReportpointsStatusValueEnumMap = {
  0: PointsStatus.provisional,
  1: PointsStatus.verified,
};
const _ReportriskLevelEnumValueMap = {'red': 0, 'yellow': 1, 'green': 2};
const _ReportriskLevelValueEnumMap = {
  0: RiskLevel.red,
  1: RiskLevel.yellow,
  2: RiskLevel.green,
};
const _ReportsyncStatusEnumValueMap = {
  'pendingUpload': 0,
  'uploading': 1,
  'synced': 2,
  'failed': 3,
};
const _ReportsyncStatusValueEnumMap = {
  0: SyncStatus.pendingUpload,
  1: SyncStatus.uploading,
  2: SyncStatus.synced,
  3: SyncStatus.failed,
};

Id _reportGetId(Report object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _reportGetLinks(Report object) {
  return [];
}

void _reportAttach(IsarCollection<dynamic> col, Id id, Report object) {
  object.isarId = id;
}

extension ReportByIndex on IsarCollection<Report> {
  Future<Report?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  Report? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<Report?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<Report?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(Report object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(Report object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<Report> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<Report> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension ReportQueryWhereSort on QueryBuilder<Report, Report, QWhere> {
  QueryBuilder<Report, Report, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Report, Report, QAfterWhere> anyRiskLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'riskLevel'),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhere> anyCapturedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'capturedAt'),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhere> anySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'syncStatus'),
      );
    });
  }
}

extension ReportQueryWhere on QueryBuilder<Report, Report, QWhereClause> {
  QueryBuilder<Report, Report, QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
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

  QueryBuilder<Report, Report, QAfterWhereClause> isarIdGreaterThan(
    Id isarId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> isarIdLessThan(
    Id isarId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'id', value: [id]),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [],
                upper: [id],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [id],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [id],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [],
                upper: [id],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> riskLevelEqualTo(
    RiskLevel riskLevel,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'riskLevel', value: [riskLevel]),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> riskLevelNotEqualTo(
    RiskLevel riskLevel,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'riskLevel',
                lower: [],
                upper: [riskLevel],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'riskLevel',
                lower: [riskLevel],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'riskLevel',
                lower: [riskLevel],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'riskLevel',
                lower: [],
                upper: [riskLevel],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> riskLevelGreaterThan(
    RiskLevel riskLevel, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'riskLevel',
          lower: [riskLevel],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> riskLevelLessThan(
    RiskLevel riskLevel, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'riskLevel',
          lower: [],
          upper: [riskLevel],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> riskLevelBetween(
    RiskLevel lowerRiskLevel,
    RiskLevel upperRiskLevel, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'riskLevel',
          lower: [lowerRiskLevel],
          includeLower: includeLower,
          upper: [upperRiskLevel],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> capturedAtEqualTo(
    DateTime capturedAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'capturedAt', value: [capturedAt]),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> capturedAtNotEqualTo(
    DateTime capturedAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'capturedAt',
                lower: [],
                upper: [capturedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'capturedAt',
                lower: [capturedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'capturedAt',
                lower: [capturedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'capturedAt',
                lower: [],
                upper: [capturedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> capturedAtGreaterThan(
    DateTime capturedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'capturedAt',
          lower: [capturedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> capturedAtLessThan(
    DateTime capturedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'capturedAt',
          lower: [],
          upper: [capturedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> capturedAtBetween(
    DateTime lowerCapturedAt,
    DateTime upperCapturedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'capturedAt',
          lower: [lowerCapturedAt],
          includeLower: includeLower,
          upper: [upperCapturedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> syncStatusEqualTo(
    SyncStatus syncStatus,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'syncStatus', value: [syncStatus]),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> syncStatusNotEqualTo(
    SyncStatus syncStatus,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'syncStatus',
                lower: [],
                upper: [syncStatus],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'syncStatus',
                lower: [syncStatus],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'syncStatus',
                lower: [syncStatus],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'syncStatus',
                lower: [],
                upper: [syncStatus],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> syncStatusGreaterThan(
    SyncStatus syncStatus, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'syncStatus',
          lower: [syncStatus],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> syncStatusLessThan(
    SyncStatus syncStatus, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'syncStatus',
          lower: [],
          upper: [syncStatus],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterWhereClause> syncStatusBetween(
    SyncStatus lowerSyncStatus,
    SyncStatus upperSyncStatus, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'syncStatus',
          lower: [lowerSyncStatus],
          includeLower: includeLower,
          upper: [upperSyncStatus],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ReportQueryFilter on QueryBuilder<Report, Report, QFilterCondition> {
  QueryBuilder<Report, Report, QAfterFilterCondition> capturedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'capturedAt', value: value),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> capturedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'capturedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> capturedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'capturedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> capturedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'capturedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> classificationEqualTo(
    Classification value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'classification', value: value),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> classificationGreaterThan(
    Classification value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'classification',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> classificationLessThan(
    Classification value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'classification',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> classificationBetween(
    Classification lower,
    Classification upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'classification',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> confidenceScoreEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'confidenceScore',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition>
  confidenceScoreGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'confidenceScore',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> confidenceScoreLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'confidenceScore',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> confidenceScoreBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'confidenceScore',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> gpsAccuracyEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'gpsAccuracy',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> gpsAccuracyGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'gpsAccuracy',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> gpsAccuracyLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'gpsAccuracy',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> gpsAccuracyBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'gpsAccuracy',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> gpsManualEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'gpsManual', value: value),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> groundTruthEqualTo(
    GroundTruth value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'groundTruth', value: value),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> groundTruthGreaterThan(
    GroundTruth value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'groundTruth',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> groundTruthLessThan(
    GroundTruth value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'groundTruth',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> groundTruthBetween(
    GroundTruth lower,
    GroundTruth upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'groundTruth',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> idContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> idMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'id',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imagePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'imagePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imagePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'imagePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imagePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'imagePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imagePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'imagePath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'imagePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'imagePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imagePathContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'imagePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imagePathMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'imagePath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'imagePath', value: ''),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'imagePath', value: ''),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imageRemoteUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'imageRemoteUrl'),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition>
  imageRemoteUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'imageRemoteUrl'),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imageRemoteUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'imageRemoteUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imageRemoteUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'imageRemoteUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imageRemoteUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'imageRemoteUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imageRemoteUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'imageRemoteUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imageRemoteUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'imageRemoteUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imageRemoteUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'imageRemoteUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imageRemoteUrlContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'imageRemoteUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imageRemoteUrlMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'imageRemoteUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> imageRemoteUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'imageRemoteUrl', value: ''),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition>
  imageRemoteUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'imageRemoteUrl', value: ''),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> lastSyncAttemptIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastSyncAttempt'),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition>
  lastSyncAttemptIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastSyncAttempt'),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> lastSyncAttemptEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastSyncAttempt', value: value),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition>
  lastSyncAttemptGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastSyncAttempt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> lastSyncAttemptLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastSyncAttempt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> lastSyncAttemptBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastSyncAttempt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> latitudeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> latitudeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> latitudeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> latitudeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'latitude',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> longitudeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> longitudeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> longitudeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> longitudeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'longitude',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> pointsAwardedEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pointsAwarded', value: value),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> pointsAwardedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pointsAwarded',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> pointsAwardedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pointsAwarded',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> pointsAwardedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pointsAwarded',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> pointsStatusEqualTo(
    PointsStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pointsStatus', value: value),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> pointsStatusGreaterThan(
    PointsStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pointsStatus',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> pointsStatusLessThan(
    PointsStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pointsStatus',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> pointsStatusBetween(
    PointsStatus lower,
    PointsStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pointsStatus',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> riskLevelEqualTo(
    RiskLevel value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'riskLevel', value: value),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> riskLevelGreaterThan(
    RiskLevel value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'riskLevel',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> riskLevelLessThan(
    RiskLevel value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'riskLevel',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> riskLevelBetween(
    RiskLevel lower,
    RiskLevel upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'riskLevel',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> syncStatusEqualTo(
    SyncStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> syncStatusGreaterThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'syncStatus',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> syncStatusLessThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'syncStatus',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> syncStatusBetween(
    SyncStatus lower,
    SyncStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'syncStatus',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> userIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> userIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userId', value: ''),
      );
    });
  }

  QueryBuilder<Report, Report, QAfterFilterCondition> userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userId', value: ''),
      );
    });
  }
}

extension ReportQueryObject on QueryBuilder<Report, Report, QFilterCondition> {}

extension ReportQueryLinks on QueryBuilder<Report, Report, QFilterCondition> {}

extension ReportQuerySortBy on QueryBuilder<Report, Report, QSortBy> {
  QueryBuilder<Report, Report, QAfterSortBy> sortByCapturedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capturedAt', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByCapturedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capturedAt', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByClassification() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classification', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByClassificationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classification', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByConfidenceScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidenceScore', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByConfidenceScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidenceScore', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByGpsAccuracy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsAccuracy', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByGpsAccuracyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsAccuracy', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByGpsManual() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsManual', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByGpsManualDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsManual', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByGroundTruth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groundTruth', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByGroundTruthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groundTruth', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByImageRemoteUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageRemoteUrl', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByImageRemoteUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageRemoteUrl', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByLastSyncAttempt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAttempt', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByLastSyncAttemptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAttempt', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByPointsAwarded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pointsAwarded', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByPointsAwardedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pointsAwarded', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByPointsStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pointsStatus', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByPointsStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pointsStatus', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByRiskLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'riskLevel', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByRiskLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'riskLevel', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension ReportQuerySortThenBy on QueryBuilder<Report, Report, QSortThenBy> {
  QueryBuilder<Report, Report, QAfterSortBy> thenByCapturedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capturedAt', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByCapturedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capturedAt', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByClassification() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classification', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByClassificationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classification', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByConfidenceScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidenceScore', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByConfidenceScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidenceScore', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByGpsAccuracy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsAccuracy', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByGpsAccuracyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsAccuracy', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByGpsManual() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsManual', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByGpsManualDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gpsManual', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByGroundTruth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groundTruth', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByGroundTruthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groundTruth', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByImageRemoteUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageRemoteUrl', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByImageRemoteUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageRemoteUrl', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByLastSyncAttempt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAttempt', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByLastSyncAttemptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAttempt', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByPointsAwarded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pointsAwarded', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByPointsAwardedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pointsAwarded', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByPointsStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pointsStatus', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByPointsStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pointsStatus', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByRiskLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'riskLevel', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByRiskLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'riskLevel', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<Report, Report, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension ReportQueryWhereDistinct on QueryBuilder<Report, Report, QDistinct> {
  QueryBuilder<Report, Report, QDistinct> distinctByCapturedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'capturedAt');
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctByClassification() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'classification');
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctByConfidenceScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confidenceScore');
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctByGpsAccuracy() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gpsAccuracy');
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctByGpsManual() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gpsManual');
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctByGroundTruth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groundTruth');
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctById({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctByImagePath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctByImageRemoteUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'imageRemoteUrl',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctByLastSyncAttempt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAttempt');
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitude');
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitude');
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctByPointsAwarded() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pointsAwarded');
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctByPointsStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pointsStatus');
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctByRiskLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'riskLevel');
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<Report, Report, QDistinct> distinctByUserId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension ReportQueryProperty on QueryBuilder<Report, Report, QQueryProperty> {
  QueryBuilder<Report, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<Report, DateTime, QQueryOperations> capturedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'capturedAt');
    });
  }

  QueryBuilder<Report, Classification, QQueryOperations>
  classificationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'classification');
    });
  }

  QueryBuilder<Report, double, QQueryOperations> confidenceScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confidenceScore');
    });
  }

  QueryBuilder<Report, double, QQueryOperations> gpsAccuracyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gpsAccuracy');
    });
  }

  QueryBuilder<Report, bool, QQueryOperations> gpsManualProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gpsManual');
    });
  }

  QueryBuilder<Report, GroundTruth, QQueryOperations> groundTruthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groundTruth');
    });
  }

  QueryBuilder<Report, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Report, String, QQueryOperations> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagePath');
    });
  }

  QueryBuilder<Report, String?, QQueryOperations> imageRemoteUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageRemoteUrl');
    });
  }

  QueryBuilder<Report, DateTime?, QQueryOperations> lastSyncAttemptProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAttempt');
    });
  }

  QueryBuilder<Report, double, QQueryOperations> latitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitude');
    });
  }

  QueryBuilder<Report, double, QQueryOperations> longitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitude');
    });
  }

  QueryBuilder<Report, int, QQueryOperations> pointsAwardedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pointsAwarded');
    });
  }

  QueryBuilder<Report, PointsStatus, QQueryOperations> pointsStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pointsStatus');
    });
  }

  QueryBuilder<Report, RiskLevel, QQueryOperations> riskLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'riskLevel');
    });
  }

  QueryBuilder<Report, SyncStatus, QQueryOperations> syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<Report, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
