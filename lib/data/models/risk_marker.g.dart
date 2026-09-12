// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'risk_marker.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRiskMarkerCollection on Isar {
  IsarCollection<RiskMarker> get riskMarkers => this.collection();
}

const RiskMarkerSchema = CollectionSchema(
  name: r'RiskMarker',
  id: 4546282367697018073,
  properties: {
    r'code': PropertySchema(
      id: 0,
      name: r'code',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 1,
      name: r'description',
      type: IsarType.string,
    ),
    r'example': PropertySchema(
      id: 2,
      name: r'example',
      type: IsarType.string,
    ),
    r'pattern': PropertySchema(
      id: 3,
      name: r'pattern',
      type: IsarType.string,
    ),
    r'severity': PropertySchema(
      id: 4,
      name: r'severity',
      type: IsarType.byte,
      enumMap: _RiskMarkerseverityEnumValueMap,
    ),
    r'suggestion': PropertySchema(
      id: 5,
      name: r'suggestion',
      type: IsarType.string,
    )
  },
  estimateSize: _riskMarkerEstimateSize,
  serialize: _riskMarkerSerialize,
  deserialize: _riskMarkerDeserialize,
  deserializeProp: _riskMarkerDeserializeProp,
  idName: r'id',
  indexes: {
    r'code': IndexSchema(
      id: 329780482934683790,
      name: r'code',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'code',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'severity': IndexSchema(
      id: -5078743595604092464,
      name: r'severity',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'severity',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _riskMarkerGetId,
  getLinks: _riskMarkerGetLinks,
  attach: _riskMarkerAttach,
  version: '3.1.0+1',
);

int _riskMarkerEstimateSize(
  RiskMarker object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.code.length * 3;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.example.length * 3;
  bytesCount += 3 + object.pattern.length * 3;
  bytesCount += 3 + object.suggestion.length * 3;
  return bytesCount;
}

void _riskMarkerSerialize(
  RiskMarker object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.code);
  writer.writeString(offsets[1], object.description);
  writer.writeString(offsets[2], object.example);
  writer.writeString(offsets[3], object.pattern);
  writer.writeByte(offsets[4], object.severity.index);
  writer.writeString(offsets[5], object.suggestion);
}

RiskMarker _riskMarkerDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RiskMarker(
    code: reader.readString(offsets[0]),
    description: reader.readString(offsets[1]),
    example: reader.readString(offsets[2]),
    pattern: reader.readString(offsets[3]),
    severity:
        _RiskMarkerseverityValueEnumMap[reader.readByteOrNull(offsets[4])] ??
            RiskSeverity.critical,
    suggestion: reader.readString(offsets[5]),
  );
  object.id = id;
  return object;
}

P _riskMarkerDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (_RiskMarkerseverityValueEnumMap[reader.readByteOrNull(offset)] ??
          RiskSeverity.critical) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _RiskMarkerseverityEnumValueMap = {
  'critical': 0,
  'medium': 1,
  'low': 2,
};
const _RiskMarkerseverityValueEnumMap = {
  0: RiskSeverity.critical,
  1: RiskSeverity.medium,
  2: RiskSeverity.low,
};

Id _riskMarkerGetId(RiskMarker object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _riskMarkerGetLinks(RiskMarker object) {
  return [];
}

void _riskMarkerAttach(IsarCollection<dynamic> col, Id id, RiskMarker object) {
  object.id = id;
}

extension RiskMarkerQueryWhereSort
    on QueryBuilder<RiskMarker, RiskMarker, QWhere> {
  QueryBuilder<RiskMarker, RiskMarker, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterWhere> anySeverity() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'severity'),
      );
    });
  }
}

extension RiskMarkerQueryWhere
    on QueryBuilder<RiskMarker, RiskMarker, QWhereClause> {
  QueryBuilder<RiskMarker, RiskMarker, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<RiskMarker, RiskMarker, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterWhereClause> codeEqualTo(
      String code) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'code',
        value: [code],
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterWhereClause> codeNotEqualTo(
      String code) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [],
              upper: [code],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [code],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [code],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [],
              upper: [code],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterWhereClause> severityEqualTo(
      RiskSeverity severity) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'severity',
        value: [severity],
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterWhereClause> severityNotEqualTo(
      RiskSeverity severity) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'severity',
              lower: [],
              upper: [severity],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'severity',
              lower: [severity],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'severity',
              lower: [severity],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'severity',
              lower: [],
              upper: [severity],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterWhereClause> severityGreaterThan(
    RiskSeverity severity, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'severity',
        lower: [severity],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterWhereClause> severityLessThan(
    RiskSeverity severity, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'severity',
        lower: [],
        upper: [severity],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterWhereClause> severityBetween(
    RiskSeverity lowerSeverity,
    RiskSeverity upperSeverity, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'severity',
        lower: [lowerSeverity],
        includeLower: includeLower,
        upper: [upperSeverity],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RiskMarkerQueryFilter
    on QueryBuilder<RiskMarker, RiskMarker, QFilterCondition> {
  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> codeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> codeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> codeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> codeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'code',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> codeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> codeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> codeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> codeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'code',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> codeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> codeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> exampleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'example',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      exampleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'example',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> exampleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'example',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> exampleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'example',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> exampleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'example',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> exampleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'example',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> exampleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'example',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> exampleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'example',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> exampleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'example',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      exampleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'example',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> patternEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      patternGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> patternLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> patternBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pattern',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> patternStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> patternEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> patternContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> patternMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pattern',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> patternIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pattern',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      patternIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pattern',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> severityEqualTo(
      RiskSeverity value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'severity',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      severityGreaterThan(
    RiskSeverity value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'severity',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> severityLessThan(
    RiskSeverity value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'severity',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> severityBetween(
    RiskSeverity lower,
    RiskSeverity upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'severity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> suggestionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'suggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      suggestionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'suggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      suggestionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'suggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> suggestionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'suggestion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      suggestionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'suggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      suggestionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'suggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      suggestionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'suggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition> suggestionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'suggestion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      suggestionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'suggestion',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterFilterCondition>
      suggestionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'suggestion',
        value: '',
      ));
    });
  }
}

extension RiskMarkerQueryObject
    on QueryBuilder<RiskMarker, RiskMarker, QFilterCondition> {}

extension RiskMarkerQueryLinks
    on QueryBuilder<RiskMarker, RiskMarker, QFilterCondition> {}

extension RiskMarkerQuerySortBy
    on QueryBuilder<RiskMarker, RiskMarker, QSortBy> {
  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> sortByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> sortByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> sortByExample() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'example', Sort.asc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> sortByExampleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'example', Sort.desc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> sortByPattern() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pattern', Sort.asc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> sortByPatternDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pattern', Sort.desc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> sortBySeverity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'severity', Sort.asc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> sortBySeverityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'severity', Sort.desc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> sortBySuggestion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestion', Sort.asc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> sortBySuggestionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestion', Sort.desc);
    });
  }
}

extension RiskMarkerQuerySortThenBy
    on QueryBuilder<RiskMarker, RiskMarker, QSortThenBy> {
  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> thenByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> thenByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> thenByExample() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'example', Sort.asc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> thenByExampleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'example', Sort.desc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> thenByPattern() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pattern', Sort.asc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> thenByPatternDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pattern', Sort.desc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> thenBySeverity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'severity', Sort.asc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> thenBySeverityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'severity', Sort.desc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> thenBySuggestion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestion', Sort.asc);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QAfterSortBy> thenBySuggestionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestion', Sort.desc);
    });
  }
}

extension RiskMarkerQueryWhereDistinct
    on QueryBuilder<RiskMarker, RiskMarker, QDistinct> {
  QueryBuilder<RiskMarker, RiskMarker, QDistinct> distinctByCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'code', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QDistinct> distinctByExample(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'example', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QDistinct> distinctByPattern(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pattern', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QDistinct> distinctBySeverity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'severity');
    });
  }

  QueryBuilder<RiskMarker, RiskMarker, QDistinct> distinctBySuggestion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'suggestion', caseSensitive: caseSensitive);
    });
  }
}

extension RiskMarkerQueryProperty
    on QueryBuilder<RiskMarker, RiskMarker, QQueryProperty> {
  QueryBuilder<RiskMarker, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RiskMarker, String, QQueryOperations> codeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'code');
    });
  }

  QueryBuilder<RiskMarker, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<RiskMarker, String, QQueryOperations> exampleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'example');
    });
  }

  QueryBuilder<RiskMarker, String, QQueryOperations> patternProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pattern');
    });
  }

  QueryBuilder<RiskMarker, RiskSeverity, QQueryOperations> severityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'severity');
    });
  }

  QueryBuilder<RiskMarker, String, QQueryOperations> suggestionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'suggestion');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRiskReportCollection on Isar {
  IsarCollection<RiskReport> get riskReports => this.collection();
}

const RiskReportSchema = CollectionSchema(
  name: r'RiskReport',
  id: 4102838522778973529,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'risks': PropertySchema(
      id: 1,
      name: r'risks',
      type: IsarType.objectList,
      target: r'RiskMatch',
    ),
    r'safetyIndex': PropertySchema(
      id: 2,
      name: r'safetyIndex',
      type: IsarType.double,
    ),
    r'sourceName': PropertySchema(
      id: 3,
      name: r'sourceName',
      type: IsarType.string,
    ),
    r'textLength': PropertySchema(
      id: 4,
      name: r'textLength',
      type: IsarType.long,
    )
  },
  estimateSize: _riskReportEstimateSize,
  serialize: _riskReportSerialize,
  deserialize: _riskReportDeserialize,
  deserializeProp: _riskReportDeserializeProp,
  idName: r'id',
  indexes: {
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'RiskMatch': RiskMatchSchema},
  getId: _riskReportGetId,
  getLinks: _riskReportGetLinks,
  attach: _riskReportAttach,
  version: '3.1.0+1',
);

int _riskReportEstimateSize(
  RiskReport object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.risks.length * 3;
  {
    final offsets = allOffsets[RiskMatch]!;
    for (var i = 0; i < object.risks.length; i++) {
      final value = object.risks[i];
      bytesCount += RiskMatchSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.sourceName.length * 3;
  return bytesCount;
}

void _riskReportSerialize(
  RiskReport object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeObjectList<RiskMatch>(
    offsets[1],
    allOffsets,
    RiskMatchSchema.serialize,
    object.risks,
  );
  writer.writeDouble(offsets[2], object.safetyIndex);
  writer.writeString(offsets[3], object.sourceName);
  writer.writeLong(offsets[4], object.textLength);
}

RiskReport _riskReportDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RiskReport(
    risks: reader.readObjectList<RiskMatch>(
          offsets[1],
          RiskMatchSchema.deserialize,
          allOffsets,
          RiskMatch(),
        ) ??
        const [],
    safetyIndex: reader.readDoubleOrNull(offsets[2]) ?? 0,
    sourceName: reader.readString(offsets[3]),
    textLength: reader.readLong(offsets[4]),
  );
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  return object;
}

P _riskReportDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readObjectList<RiskMatch>(
            offset,
            RiskMatchSchema.deserialize,
            allOffsets,
            RiskMatch(),
          ) ??
          const []) as P;
    case 2:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _riskReportGetId(RiskReport object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _riskReportGetLinks(RiskReport object) {
  return [];
}

void _riskReportAttach(IsarCollection<dynamic> col, Id id, RiskReport object) {
  object.id = id;
}

extension RiskReportQueryWhereSort
    on QueryBuilder<RiskReport, RiskReport, QWhere> {
  QueryBuilder<RiskReport, RiskReport, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension RiskReportQueryWhere
    on QueryBuilder<RiskReport, RiskReport, QWhereClause> {
  QueryBuilder<RiskReport, RiskReport, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<RiskReport, RiskReport, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterWhereClause> createdAtEqualTo(
      DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterWhereClause> createdAtNotEqualTo(
      DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterWhereClause> createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [createdAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterWhereClause> createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [],
        upper: [createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterWhereClause> createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [lowerCreatedAt],
        includeLower: includeLower,
        upper: [upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RiskReportQueryFilter
    on QueryBuilder<RiskReport, RiskReport, QFilterCondition> {
  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      createdAtGreaterThan(
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

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      risksLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'risks',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition> risksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'risks',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      risksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'risks',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      risksLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'risks',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      risksLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'risks',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      risksLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'risks',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      safetyIndexEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'safetyIndex',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      safetyIndexGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'safetyIndex',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      safetyIndexLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'safetyIndex',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      safetyIndexBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'safetyIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition> sourceNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      sourceNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      sourceNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition> sourceNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      sourceNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      sourceNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      sourceNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition> sourceNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      sourceNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceName',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      sourceNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceName',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition> textLengthEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textLength',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      textLengthGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'textLength',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition>
      textLengthLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'textLength',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition> textLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'textLength',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RiskReportQueryObject
    on QueryBuilder<RiskReport, RiskReport, QFilterCondition> {
  QueryBuilder<RiskReport, RiskReport, QAfterFilterCondition> risksElement(
      FilterQuery<RiskMatch> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'risks');
    });
  }
}

extension RiskReportQueryLinks
    on QueryBuilder<RiskReport, RiskReport, QFilterCondition> {}

extension RiskReportQuerySortBy
    on QueryBuilder<RiskReport, RiskReport, QSortBy> {
  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> sortBySafetyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'safetyIndex', Sort.asc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> sortBySafetyIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'safetyIndex', Sort.desc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> sortBySourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.asc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> sortBySourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.desc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> sortByTextLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textLength', Sort.asc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> sortByTextLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textLength', Sort.desc);
    });
  }
}

extension RiskReportQuerySortThenBy
    on QueryBuilder<RiskReport, RiskReport, QSortThenBy> {
  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> thenBySafetyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'safetyIndex', Sort.asc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> thenBySafetyIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'safetyIndex', Sort.desc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> thenBySourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.asc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> thenBySourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.desc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> thenByTextLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textLength', Sort.asc);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QAfterSortBy> thenByTextLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textLength', Sort.desc);
    });
  }
}

extension RiskReportQueryWhereDistinct
    on QueryBuilder<RiskReport, RiskReport, QDistinct> {
  QueryBuilder<RiskReport, RiskReport, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<RiskReport, RiskReport, QDistinct> distinctBySafetyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'safetyIndex');
    });
  }

  QueryBuilder<RiskReport, RiskReport, QDistinct> distinctBySourceName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RiskReport, RiskReport, QDistinct> distinctByTextLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textLength');
    });
  }
}

extension RiskReportQueryProperty
    on QueryBuilder<RiskReport, RiskReport, QQueryProperty> {
  QueryBuilder<RiskReport, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RiskReport, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<RiskReport, List<RiskMatch>, QQueryOperations> risksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'risks');
    });
  }

  QueryBuilder<RiskReport, double, QQueryOperations> safetyIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'safetyIndex');
    });
  }

  QueryBuilder<RiskReport, String, QQueryOperations> sourceNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceName');
    });
  }

  QueryBuilder<RiskReport, int, QQueryOperations> textLengthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textLength');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const RiskMatchSchema = Schema(
  name: r'RiskMatch',
  id: 4875028246976243688,
  properties: {
    r'description': PropertySchema(
      id: 0,
      name: r'description',
      type: IsarType.string,
    ),
    r'end': PropertySchema(
      id: 1,
      name: r'end',
      type: IsarType.long,
    ),
    r'example': PropertySchema(
      id: 2,
      name: r'example',
      type: IsarType.string,
    ),
    r'markerCode': PropertySchema(
      id: 3,
      name: r'markerCode',
      type: IsarType.string,
    ),
    r'matchedText': PropertySchema(
      id: 4,
      name: r'matchedText',
      type: IsarType.string,
    ),
    r'severity': PropertySchema(
      id: 5,
      name: r'severity',
      type: IsarType.byte,
      enumMap: _RiskMatchseverityEnumValueMap,
    ),
    r'start': PropertySchema(
      id: 6,
      name: r'start',
      type: IsarType.long,
    ),
    r'suggestion': PropertySchema(
      id: 7,
      name: r'suggestion',
      type: IsarType.string,
    )
  },
  estimateSize: _riskMatchEstimateSize,
  serialize: _riskMatchSerialize,
  deserialize: _riskMatchDeserialize,
  deserializeProp: _riskMatchDeserializeProp,
);

int _riskMatchEstimateSize(
  RiskMatch object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.example.length * 3;
  bytesCount += 3 + object.markerCode.length * 3;
  bytesCount += 3 + object.matchedText.length * 3;
  bytesCount += 3 + object.suggestion.length * 3;
  return bytesCount;
}

void _riskMatchSerialize(
  RiskMatch object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.description);
  writer.writeLong(offsets[1], object.end);
  writer.writeString(offsets[2], object.example);
  writer.writeString(offsets[3], object.markerCode);
  writer.writeString(offsets[4], object.matchedText);
  writer.writeByte(offsets[5], object.severity.index);
  writer.writeLong(offsets[6], object.start);
  writer.writeString(offsets[7], object.suggestion);
}

RiskMatch _riskMatchDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RiskMatch(
    description: reader.readStringOrNull(offsets[0]) ?? '',
    end: reader.readLongOrNull(offsets[1]) ?? 0,
    example: reader.readStringOrNull(offsets[2]) ?? '',
    markerCode: reader.readStringOrNull(offsets[3]) ?? '',
    matchedText: reader.readStringOrNull(offsets[4]) ?? '',
    severity:
        _RiskMatchseverityValueEnumMap[reader.readByteOrNull(offsets[5])] ??
            RiskSeverity.low,
    start: reader.readLongOrNull(offsets[6]) ?? 0,
    suggestion: reader.readStringOrNull(offsets[7]) ?? '',
  );
  return object;
}

P _riskMatchDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 1:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 2:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 3:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 4:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 5:
      return (_RiskMatchseverityValueEnumMap[reader.readByteOrNull(offset)] ??
          RiskSeverity.low) as P;
    case 6:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 7:
      return (reader.readStringOrNull(offset) ?? '') as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _RiskMatchseverityEnumValueMap = {
  'critical': 0,
  'medium': 1,
  'low': 2,
};
const _RiskMatchseverityValueEnumMap = {
  0: RiskSeverity.critical,
  1: RiskSeverity.medium,
  2: RiskSeverity.low,
};

extension RiskMatchQueryFilter
    on QueryBuilder<RiskMatch, RiskMatch, QFilterCondition> {
  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> descriptionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> descriptionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> endEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> endGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> endLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> endBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'end',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> exampleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'example',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> exampleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'example',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> exampleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'example',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> exampleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'example',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> exampleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'example',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> exampleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'example',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> exampleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'example',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> exampleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'example',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> exampleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'example',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      exampleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'example',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> markerCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'markerCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      markerCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'markerCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> markerCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'markerCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> markerCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'markerCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      markerCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'markerCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> markerCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'markerCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> markerCodeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'markerCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> markerCodeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'markerCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      markerCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'markerCode',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      markerCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'markerCode',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> matchedTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'matchedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      matchedTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'matchedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> matchedTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'matchedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> matchedTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'matchedText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      matchedTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'matchedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> matchedTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'matchedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> matchedTextContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'matchedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> matchedTextMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'matchedText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      matchedTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'matchedText',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      matchedTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'matchedText',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> severityEqualTo(
      RiskSeverity value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'severity',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> severityGreaterThan(
    RiskSeverity value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'severity',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> severityLessThan(
    RiskSeverity value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'severity',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> severityBetween(
    RiskSeverity lower,
    RiskSeverity upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'severity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> startEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'start',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> startGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'start',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> startLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'start',
        value: value,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> startBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'start',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> suggestionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'suggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      suggestionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'suggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> suggestionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'suggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> suggestionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'suggestion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      suggestionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'suggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> suggestionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'suggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> suggestionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'suggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition> suggestionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'suggestion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      suggestionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'suggestion',
        value: '',
      ));
    });
  }

  QueryBuilder<RiskMatch, RiskMatch, QAfterFilterCondition>
      suggestionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'suggestion',
        value: '',
      ));
    });
  }
}

extension RiskMatchQueryObject
    on QueryBuilder<RiskMatch, RiskMatch, QFilterCondition> {}
