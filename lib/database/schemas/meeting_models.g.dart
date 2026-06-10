// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserModelCollection on Isar {
  IsarCollection<UserModel> get userModels => this.collection();
}

const UserModelSchema = CollectionSchema(
  name: r'UserModel',
  id: 7195426469378571114,
  properties: {
    r'displayName': PropertySchema(
      id: 0,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'email': PropertySchema(
      id: 1,
      name: r'email',
      type: IsarType.string,
    ),
    r'lastSynced': PropertySchema(
      id: 2,
      name: r'lastSynced',
      type: IsarType.dateTime,
    ),
    r'photoUrl': PropertySchema(
      id: 3,
      name: r'photoUrl',
      type: IsarType.string,
    ),
    r'uid': PropertySchema(
      id: 4,
      name: r'uid',
      type: IsarType.string,
    )
  },
  estimateSize: _userModelEstimateSize,
  serialize: _userModelSerialize,
  deserialize: _userModelDeserialize,
  deserializeProp: _userModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'uid': IndexSchema(
      id: 8193695471701937315,
      name: r'uid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _userModelGetId,
  getLinks: _userModelGetLinks,
  attach: _userModelAttach,
  version: '3.1.0+1',
);

int _userModelEstimateSize(
  UserModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.displayName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.email;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.photoUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.uid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _userModelSerialize(
  UserModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.displayName);
  writer.writeString(offsets[1], object.email);
  writer.writeDateTime(offsets[2], object.lastSynced);
  writer.writeString(offsets[3], object.photoUrl);
  writer.writeString(offsets[4], object.uid);
}

UserModel _userModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserModel();
  object.displayName = reader.readStringOrNull(offsets[0]);
  object.email = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.lastSynced = reader.readDateTimeOrNull(offsets[2]);
  object.photoUrl = reader.readStringOrNull(offsets[3]);
  object.uid = reader.readStringOrNull(offsets[4]);
  return object;
}

P _userModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userModelGetId(UserModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userModelGetLinks(UserModel object) {
  return [];
}

void _userModelAttach(IsarCollection<dynamic> col, Id id, UserModel object) {
  object.id = id;
}

extension UserModelByIndex on IsarCollection<UserModel> {
  Future<UserModel?> getByUid(String? uid) {
    return getByIndex(r'uid', [uid]);
  }

  UserModel? getByUidSync(String? uid) {
    return getByIndexSync(r'uid', [uid]);
  }

  Future<bool> deleteByUid(String? uid) {
    return deleteByIndex(r'uid', [uid]);
  }

  bool deleteByUidSync(String? uid) {
    return deleteByIndexSync(r'uid', [uid]);
  }

  Future<List<UserModel?>> getAllByUid(List<String?> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uid', values);
  }

  List<UserModel?> getAllByUidSync(List<String?> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uid', values);
  }

  Future<int> deleteAllByUid(List<String?> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uid', values);
  }

  int deleteAllByUidSync(List<String?> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uid', values);
  }

  Future<Id> putByUid(UserModel object) {
    return putByIndex(r'uid', object);
  }

  Id putByUidSync(UserModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUid(List<UserModel> objects) {
    return putAllByIndex(r'uid', objects);
  }

  List<Id> putAllByUidSync(List<UserModel> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uid', objects, saveLinks: saveLinks);
  }
}

extension UserModelQueryWhereSort
    on QueryBuilder<UserModel, UserModel, QWhere> {
  QueryBuilder<UserModel, UserModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserModelQueryWhere
    on QueryBuilder<UserModel, UserModel, QWhereClause> {
  QueryBuilder<UserModel, UserModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<UserModel, UserModel, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<UserModel, UserModel, QAfterWhereClause> uidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid',
        value: [null],
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterWhereClause> uidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'uid',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterWhereClause> uidEqualTo(
      String? uid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid',
        value: [uid],
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterWhereClause> uidNotEqualTo(
      String? uid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [uid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [uid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension UserModelQueryFilter
    on QueryBuilder<UserModel, UserModel, QFilterCondition> {
  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      displayNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'displayName',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      displayNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'displayName',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> displayNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      displayNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> displayNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> displayNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'displayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      displayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> displayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> displayNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> displayNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'displayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'email',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'email',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'email',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'email',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> lastSyncedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSynced',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      lastSyncedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSynced',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> lastSyncedEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      lastSyncedGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> lastSyncedLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> lastSyncedBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSynced',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> photoUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photoUrl',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      photoUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photoUrl',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> photoUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> photoUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> photoUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> photoUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photoUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> photoUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> photoUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> photoUrlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> photoUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photoUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> photoUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      photoUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photoUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> uidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uid',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> uidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uid',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> uidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> uidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> uidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> uidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> uidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> uidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> uidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> uidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uid',
        value: '',
      ));
    });
  }
}

extension UserModelQueryObject
    on QueryBuilder<UserModel, UserModel, QFilterCondition> {}

extension UserModelQueryLinks
    on QueryBuilder<UserModel, UserModel, QFilterCondition> {}

extension UserModelQuerySortBy on QueryBuilder<UserModel, UserModel, QSortBy> {
  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByLastSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSynced', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByLastSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSynced', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByPhotoUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoUrl', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByPhotoUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoUrl', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension UserModelQuerySortThenBy
    on QueryBuilder<UserModel, UserModel, QSortThenBy> {
  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByLastSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSynced', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByLastSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSynced', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByPhotoUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoUrl', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByPhotoUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoUrl', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension UserModelQueryWhereDistinct
    on QueryBuilder<UserModel, UserModel, QDistinct> {
  QueryBuilder<UserModel, UserModel, QDistinct> distinctByDisplayName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QDistinct> distinctByEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'email', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QDistinct> distinctByLastSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSynced');
    });
  }

  QueryBuilder<UserModel, UserModel, QDistinct> distinctByPhotoUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'photoUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QDistinct> distinctByUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }
}

extension UserModelQueryProperty
    on QueryBuilder<UserModel, UserModel, QQueryProperty> {
  QueryBuilder<UserModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserModel, String?, QQueryOperations> displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<UserModel, String?, QQueryOperations> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'email');
    });
  }

  QueryBuilder<UserModel, DateTime?, QQueryOperations> lastSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSynced');
    });
  }

  QueryBuilder<UserModel, String?, QQueryOperations> photoUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'photoUrl');
    });
  }

  QueryBuilder<UserModel, String?, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMeetingModelCollection on Isar {
  IsarCollection<MeetingModel> get meetingModels => this.collection();
}

const MeetingModelSchema = CollectionSchema(
  name: r'MeetingModel',
  id: -5864818718325559696,
  properties: {
    r'audioFilePath': PropertySchema(
      id: 0,
      name: r'audioFilePath',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'detectedEmotion': PropertySchema(
      id: 2,
      name: r'detectedEmotion',
      type: IsarType.string,
    ),
    r'durationSeconds': PropertySchema(
      id: 3,
      name: r'durationSeconds',
      type: IsarType.double,
    ),
    r'emotionConfidence': PropertySchema(
      id: 4,
      name: r'emotionConfidence',
      type: IsarType.double,
    ),
    r'isRecording': PropertySchema(
      id: 5,
      name: r'isRecording',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 6,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'title': PropertySchema(
      id: 7,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _meetingModelEstimateSize,
  serialize: _meetingModelSerialize,
  deserialize: _meetingModelDeserialize,
  deserializeProp: _meetingModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'transcript': LinkSchema(
      id: -8935713039996698965,
      name: r'transcript',
      target: r'TranscriptModel',
      single: true,
    ),
    r'summary': LinkSchema(
      id: 9042345668856172469,
      name: r'summary',
      target: r'SummaryModel',
      single: true,
    ),
    r'actionItems': LinkSchema(
      id: 1770863706214170248,
      name: r'actionItems',
      target: r'ActionItemModel',
      single: false,
      linkName: r'meeting',
    ),
    r'decisions': LinkSchema(
      id: -698465359112622735,
      name: r'decisions',
      target: r'DecisionModel',
      single: false,
      linkName: r'meeting',
    ),
    r'chatMessages': LinkSchema(
      id: 1145137151318508684,
      name: r'chatMessages',
      target: r'ChatMessageModel',
      single: false,
      linkName: r'meeting',
    )
  },
  embeddedSchemas: {},
  getId: _meetingModelGetId,
  getLinks: _meetingModelGetLinks,
  attach: _meetingModelAttach,
  version: '3.1.0+1',
);

int _meetingModelEstimateSize(
  MeetingModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.audioFilePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.detectedEmotion;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.title;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _meetingModelSerialize(
  MeetingModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.audioFilePath);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.detectedEmotion);
  writer.writeDouble(offsets[3], object.durationSeconds);
  writer.writeDouble(offsets[4], object.emotionConfidence);
  writer.writeBool(offsets[5], object.isRecording);
  writer.writeBool(offsets[6], object.isSynced);
  writer.writeString(offsets[7], object.title);
}

MeetingModel _meetingModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MeetingModel();
  object.audioFilePath = reader.readStringOrNull(offsets[0]);
  object.createdAt = reader.readDateTimeOrNull(offsets[1]);
  object.detectedEmotion = reader.readStringOrNull(offsets[2]);
  object.durationSeconds = reader.readDouble(offsets[3]);
  object.emotionConfidence = reader.readDoubleOrNull(offsets[4]);
  object.id = id;
  object.isRecording = reader.readBool(offsets[5]);
  object.isSynced = reader.readBool(offsets[6]);
  object.title = reader.readStringOrNull(offsets[7]);
  return object;
}

P _meetingModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _meetingModelGetId(MeetingModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _meetingModelGetLinks(MeetingModel object) {
  return [
    object.transcript,
    object.summary,
    object.actionItems,
    object.decisions,
    object.chatMessages
  ];
}

void _meetingModelAttach(
    IsarCollection<dynamic> col, Id id, MeetingModel object) {
  object.id = id;
  object.transcript
      .attach(col, col.isar.collection<TranscriptModel>(), r'transcript', id);
  object.summary
      .attach(col, col.isar.collection<SummaryModel>(), r'summary', id);
  object.actionItems
      .attach(col, col.isar.collection<ActionItemModel>(), r'actionItems', id);
  object.decisions
      .attach(col, col.isar.collection<DecisionModel>(), r'decisions', id);
  object.chatMessages.attach(
      col, col.isar.collection<ChatMessageModel>(), r'chatMessages', id);
}

extension MeetingModelQueryWhereSort
    on QueryBuilder<MeetingModel, MeetingModel, QWhere> {
  QueryBuilder<MeetingModel, MeetingModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MeetingModelQueryWhere
    on QueryBuilder<MeetingModel, MeetingModel, QWhereClause> {
  QueryBuilder<MeetingModel, MeetingModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<MeetingModel, MeetingModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterWhereClause> idBetween(
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
}

extension MeetingModelQueryFilter
    on QueryBuilder<MeetingModel, MeetingModel, QFilterCondition> {
  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      audioFilePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'audioFilePath',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      audioFilePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'audioFilePath',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      audioFilePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      audioFilePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'audioFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      audioFilePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'audioFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      audioFilePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'audioFilePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      audioFilePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'audioFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      audioFilePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'audioFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      audioFilePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'audioFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      audioFilePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'audioFilePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      audioFilePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioFilePath',
        value: '',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      audioFilePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'audioFilePath',
        value: '',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime? value, {
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

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      createdAtLessThan(
    DateTime? value, {
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

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
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

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      detectedEmotionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'detectedEmotion',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      detectedEmotionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'detectedEmotion',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      detectedEmotionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'detectedEmotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      detectedEmotionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'detectedEmotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      detectedEmotionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'detectedEmotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      detectedEmotionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'detectedEmotion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      detectedEmotionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'detectedEmotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      detectedEmotionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'detectedEmotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      detectedEmotionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'detectedEmotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      detectedEmotionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'detectedEmotion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      detectedEmotionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'detectedEmotion',
        value: '',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      detectedEmotionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'detectedEmotion',
        value: '',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      durationSecondsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationSeconds',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      durationSecondsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationSeconds',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      durationSecondsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationSeconds',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      durationSecondsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      emotionConfidenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'emotionConfidence',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      emotionConfidenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'emotionConfidence',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      emotionConfidenceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emotionConfidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      emotionConfidenceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'emotionConfidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      emotionConfidenceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'emotionConfidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      emotionConfidenceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'emotionConfidence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      isRecordingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isRecording',
        value: value,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> titleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      titleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> titleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> titleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension MeetingModelQueryObject
    on QueryBuilder<MeetingModel, MeetingModel, QFilterCondition> {}

extension MeetingModelQueryLinks
    on QueryBuilder<MeetingModel, MeetingModel, QFilterCondition> {
  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> transcript(
      FilterQuery<TranscriptModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'transcript');
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      transcriptIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'transcript', 0, true, 0, true);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> summary(
      FilterQuery<SummaryModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'summary');
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      summaryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'summary', 0, true, 0, true);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> actionItems(
      FilterQuery<ActionItemModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'actionItems');
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      actionItemsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'actionItems', length, true, length, true);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      actionItemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'actionItems', 0, true, 0, true);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      actionItemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'actionItems', 0, false, 999999, true);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      actionItemsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'actionItems', 0, true, length, include);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      actionItemsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'actionItems', length, include, 999999, true);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      actionItemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'actionItems', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> decisions(
      FilterQuery<DecisionModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'decisions');
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      decisionsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'decisions', length, true, length, true);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      decisionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'decisions', 0, true, 0, true);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      decisionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'decisions', 0, false, 999999, true);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      decisionsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'decisions', 0, true, length, include);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      decisionsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'decisions', length, include, 999999, true);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      decisionsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'decisions', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition> chatMessages(
      FilterQuery<ChatMessageModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'chatMessages');
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      chatMessagesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'chatMessages', length, true, length, true);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      chatMessagesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'chatMessages', 0, true, 0, true);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      chatMessagesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'chatMessages', 0, false, 999999, true);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      chatMessagesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'chatMessages', 0, true, length, include);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      chatMessagesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'chatMessages', length, include, 999999, true);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterFilterCondition>
      chatMessagesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'chatMessages', lower, includeLower, upper, includeUpper);
    });
  }
}

extension MeetingModelQuerySortBy
    on QueryBuilder<MeetingModel, MeetingModel, QSortBy> {
  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> sortByAudioFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioFilePath', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      sortByAudioFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioFilePath', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      sortByDetectedEmotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedEmotion', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      sortByDetectedEmotionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedEmotion', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      sortByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      sortByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      sortByEmotionConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emotionConfidence', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      sortByEmotionConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emotionConfidence', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> sortByIsRecording() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRecording', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      sortByIsRecordingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRecording', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension MeetingModelQuerySortThenBy
    on QueryBuilder<MeetingModel, MeetingModel, QSortThenBy> {
  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> thenByAudioFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioFilePath', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      thenByAudioFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioFilePath', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      thenByDetectedEmotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedEmotion', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      thenByDetectedEmotionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedEmotion', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      thenByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      thenByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      thenByEmotionConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emotionConfidence', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      thenByEmotionConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emotionConfidence', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> thenByIsRecording() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRecording', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy>
      thenByIsRecordingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRecording', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension MeetingModelQueryWhereDistinct
    on QueryBuilder<MeetingModel, MeetingModel, QDistinct> {
  QueryBuilder<MeetingModel, MeetingModel, QDistinct> distinctByAudioFilePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioFilePath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QDistinct> distinctByDetectedEmotion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'detectedEmotion',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QDistinct>
      distinctByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationSeconds');
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QDistinct>
      distinctByEmotionConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'emotionConfidence');
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QDistinct> distinctByIsRecording() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isRecording');
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<MeetingModel, MeetingModel, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension MeetingModelQueryProperty
    on QueryBuilder<MeetingModel, MeetingModel, QQueryProperty> {
  QueryBuilder<MeetingModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MeetingModel, String?, QQueryOperations>
      audioFilePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioFilePath');
    });
  }

  QueryBuilder<MeetingModel, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<MeetingModel, String?, QQueryOperations>
      detectedEmotionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'detectedEmotion');
    });
  }

  QueryBuilder<MeetingModel, double, QQueryOperations>
      durationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationSeconds');
    });
  }

  QueryBuilder<MeetingModel, double?, QQueryOperations>
      emotionConfidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'emotionConfidence');
    });
  }

  QueryBuilder<MeetingModel, bool, QQueryOperations> isRecordingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isRecording');
    });
  }

  QueryBuilder<MeetingModel, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<MeetingModel, String?, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTranscriptSegmentModelCollection on Isar {
  IsarCollection<TranscriptSegmentModel> get transcriptSegmentModels =>
      this.collection();
}

const TranscriptSegmentModelSchema = CollectionSchema(
  name: r'TranscriptSegmentModel',
  id: -6749498707122810600,
  properties: {
    r'endTime': PropertySchema(
      id: 0,
      name: r'endTime',
      type: IsarType.double,
    ),
    r'speaker': PropertySchema(
      id: 1,
      name: r'speaker',
      type: IsarType.long,
    ),
    r'startTime': PropertySchema(
      id: 2,
      name: r'startTime',
      type: IsarType.double,
    ),
    r'text': PropertySchema(
      id: 3,
      name: r'text',
      type: IsarType.string,
    )
  },
  estimateSize: _transcriptSegmentModelEstimateSize,
  serialize: _transcriptSegmentModelSerialize,
  deserialize: _transcriptSegmentModelDeserialize,
  deserializeProp: _transcriptSegmentModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'transcript': LinkSchema(
      id: -8814670377196562421,
      name: r'transcript',
      target: r'TranscriptModel',
      single: true,
    ),
    r'speakerProfile': LinkSchema(
      id: 1250613912516618270,
      name: r'speakerProfile',
      target: r'SpeakerProfileModel',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _transcriptSegmentModelGetId,
  getLinks: _transcriptSegmentModelGetLinks,
  attach: _transcriptSegmentModelAttach,
  version: '3.1.0+1',
);

int _transcriptSegmentModelEstimateSize(
  TranscriptSegmentModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.text;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _transcriptSegmentModelSerialize(
  TranscriptSegmentModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.endTime);
  writer.writeLong(offsets[1], object.speaker);
  writer.writeDouble(offsets[2], object.startTime);
  writer.writeString(offsets[3], object.text);
}

TranscriptSegmentModel _transcriptSegmentModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TranscriptSegmentModel();
  object.endTime = reader.readDouble(offsets[0]);
  object.id = id;
  object.speaker = reader.readLongOrNull(offsets[1]);
  object.startTime = reader.readDouble(offsets[2]);
  object.text = reader.readStringOrNull(offsets[3]);
  return object;
}

P _transcriptSegmentModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _transcriptSegmentModelGetId(TranscriptSegmentModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _transcriptSegmentModelGetLinks(
    TranscriptSegmentModel object) {
  return [object.transcript, object.speakerProfile];
}

void _transcriptSegmentModelAttach(
    IsarCollection<dynamic> col, Id id, TranscriptSegmentModel object) {
  object.id = id;
  object.transcript
      .attach(col, col.isar.collection<TranscriptModel>(), r'transcript', id);
  object.speakerProfile.attach(
      col, col.isar.collection<SpeakerProfileModel>(), r'speakerProfile', id);
}

extension TranscriptSegmentModelQueryWhereSort
    on QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QWhere> {
  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TranscriptSegmentModelQueryWhere on QueryBuilder<
    TranscriptSegmentModel, TranscriptSegmentModel, QWhereClause> {
  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterWhereClause> idBetween(
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
}

extension TranscriptSegmentModelQueryFilter on QueryBuilder<
    TranscriptSegmentModel, TranscriptSegmentModel, QFilterCondition> {
  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> endTimeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> endTimeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> endTimeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> endTimeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> speakerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'speaker',
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> speakerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'speaker',
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> speakerEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'speaker',
        value: value,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> speakerGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'speaker',
        value: value,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> speakerLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'speaker',
        value: value,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> speakerBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'speaker',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> startTimeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> startTimeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> startTimeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> startTimeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> textIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'text',
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> textIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'text',
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> textEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> textGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> textLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> textBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'text',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
          QAfterFilterCondition>
      textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
          QAfterFilterCondition>
      textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'text',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'text',
        value: '',
      ));
    });
  }
}

extension TranscriptSegmentModelQueryObject on QueryBuilder<
    TranscriptSegmentModel, TranscriptSegmentModel, QFilterCondition> {}

extension TranscriptSegmentModelQueryLinks on QueryBuilder<
    TranscriptSegmentModel, TranscriptSegmentModel, QFilterCondition> {
  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> transcript(FilterQuery<TranscriptModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'transcript');
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> transcriptIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'transcript', 0, true, 0, true);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
          QAfterFilterCondition>
      speakerProfile(FilterQuery<SpeakerProfileModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'speakerProfile');
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel,
      QAfterFilterCondition> speakerProfileIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'speakerProfile', 0, true, 0, true);
    });
  }
}

extension TranscriptSegmentModelQuerySortBy
    on QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QSortBy> {
  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      sortByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      sortByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      sortBySpeaker() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speaker', Sort.asc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      sortBySpeakerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speaker', Sort.desc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      sortByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      sortByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }
}

extension TranscriptSegmentModelQuerySortThenBy on QueryBuilder<
    TranscriptSegmentModel, TranscriptSegmentModel, QSortThenBy> {
  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      thenByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      thenByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      thenBySpeaker() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speaker', Sort.asc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      thenBySpeakerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speaker', Sort.desc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      thenByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      thenByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QAfterSortBy>
      thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }
}

extension TranscriptSegmentModelQueryWhereDistinct
    on QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QDistinct> {
  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QDistinct>
      distinctByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endTime');
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QDistinct>
      distinctBySpeaker() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'speaker');
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QDistinct>
      distinctByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startTime');
    });
  }

  QueryBuilder<TranscriptSegmentModel, TranscriptSegmentModel, QDistinct>
      distinctByText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }
}

extension TranscriptSegmentModelQueryProperty on QueryBuilder<
    TranscriptSegmentModel, TranscriptSegmentModel, QQueryProperty> {
  QueryBuilder<TranscriptSegmentModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TranscriptSegmentModel, double, QQueryOperations>
      endTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endTime');
    });
  }

  QueryBuilder<TranscriptSegmentModel, int?, QQueryOperations>
      speakerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'speaker');
    });
  }

  QueryBuilder<TranscriptSegmentModel, double, QQueryOperations>
      startTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startTime');
    });
  }

  QueryBuilder<TranscriptSegmentModel, String?, QQueryOperations>
      textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'text');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTranscriptModelCollection on Isar {
  IsarCollection<TranscriptModel> get transcriptModels => this.collection();
}

const TranscriptModelSchema = CollectionSchema(
  name: r'TranscriptModel',
  id: 7090158952041241541,
  properties: {},
  estimateSize: _transcriptModelEstimateSize,
  serialize: _transcriptModelSerialize,
  deserialize: _transcriptModelDeserialize,
  deserializeProp: _transcriptModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'segments': LinkSchema(
      id: -8545644094639554701,
      name: r'segments',
      target: r'TranscriptSegmentModel',
      single: false,
      linkName: r'transcript',
    )
  },
  embeddedSchemas: {},
  getId: _transcriptModelGetId,
  getLinks: _transcriptModelGetLinks,
  attach: _transcriptModelAttach,
  version: '3.1.0+1',
);

int _transcriptModelEstimateSize(
  TranscriptModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _transcriptModelSerialize(
  TranscriptModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {}
TranscriptModel _transcriptModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TranscriptModel();
  object.id = id;
  return object;
}

P _transcriptModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _transcriptModelGetId(TranscriptModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _transcriptModelGetLinks(TranscriptModel object) {
  return [object.segments];
}

void _transcriptModelAttach(
    IsarCollection<dynamic> col, Id id, TranscriptModel object) {
  object.id = id;
  object.segments.attach(
      col, col.isar.collection<TranscriptSegmentModel>(), r'segments', id);
}

extension TranscriptModelQueryWhereSort
    on QueryBuilder<TranscriptModel, TranscriptModel, QWhere> {
  QueryBuilder<TranscriptModel, TranscriptModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TranscriptModelQueryWhere
    on QueryBuilder<TranscriptModel, TranscriptModel, QWhereClause> {
  QueryBuilder<TranscriptModel, TranscriptModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TranscriptModel, TranscriptModel, QAfterWhereClause>
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

  QueryBuilder<TranscriptModel, TranscriptModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TranscriptModel, TranscriptModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TranscriptModel, TranscriptModel, QAfterWhereClause> idBetween(
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
}

extension TranscriptModelQueryFilter
    on QueryBuilder<TranscriptModel, TranscriptModel, QFilterCondition> {
  QueryBuilder<TranscriptModel, TranscriptModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TranscriptModel, TranscriptModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<TranscriptModel, TranscriptModel, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<TranscriptModel, TranscriptModel, QAfterFilterCondition>
      idBetween(
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
}

extension TranscriptModelQueryObject
    on QueryBuilder<TranscriptModel, TranscriptModel, QFilterCondition> {}

extension TranscriptModelQueryLinks
    on QueryBuilder<TranscriptModel, TranscriptModel, QFilterCondition> {
  QueryBuilder<TranscriptModel, TranscriptModel, QAfterFilterCondition>
      segments(FilterQuery<TranscriptSegmentModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'segments');
    });
  }

  QueryBuilder<TranscriptModel, TranscriptModel, QAfterFilterCondition>
      segmentsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'segments', length, true, length, true);
    });
  }

  QueryBuilder<TranscriptModel, TranscriptModel, QAfterFilterCondition>
      segmentsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'segments', 0, true, 0, true);
    });
  }

  QueryBuilder<TranscriptModel, TranscriptModel, QAfterFilterCondition>
      segmentsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'segments', 0, false, 999999, true);
    });
  }

  QueryBuilder<TranscriptModel, TranscriptModel, QAfterFilterCondition>
      segmentsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'segments', 0, true, length, include);
    });
  }

  QueryBuilder<TranscriptModel, TranscriptModel, QAfterFilterCondition>
      segmentsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'segments', length, include, 999999, true);
    });
  }

  QueryBuilder<TranscriptModel, TranscriptModel, QAfterFilterCondition>
      segmentsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'segments', lower, includeLower, upper, includeUpper);
    });
  }
}

extension TranscriptModelQuerySortBy
    on QueryBuilder<TranscriptModel, TranscriptModel, QSortBy> {}

extension TranscriptModelQuerySortThenBy
    on QueryBuilder<TranscriptModel, TranscriptModel, QSortThenBy> {
  QueryBuilder<TranscriptModel, TranscriptModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TranscriptModel, TranscriptModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension TranscriptModelQueryWhereDistinct
    on QueryBuilder<TranscriptModel, TranscriptModel, QDistinct> {}

extension TranscriptModelQueryProperty
    on QueryBuilder<TranscriptModel, TranscriptModel, QQueryProperty> {
  QueryBuilder<TranscriptModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSummaryModelCollection on Isar {
  IsarCollection<SummaryModel> get summaryModels => this.collection();
}

const SummaryModelSchema = CollectionSchema(
  name: r'SummaryModel',
  id: 8375551073867302625,
  properties: {
    r'deadlines': PropertySchema(
      id: 0,
      name: r'deadlines',
      type: IsarType.string,
    ),
    r'executiveSummary': PropertySchema(
      id: 1,
      name: r'executiveSummary',
      type: IsarType.string,
    ),
    r'followUps': PropertySchema(
      id: 2,
      name: r'followUps',
      type: IsarType.string,
    ),
    r'keyTakeaways': PropertySchema(
      id: 3,
      name: r'keyTakeaways',
      type: IsarType.string,
    ),
    r'meetingNotes': PropertySchema(
      id: 4,
      name: r'meetingNotes',
      type: IsarType.string,
    ),
    r'risks': PropertySchema(
      id: 5,
      name: r'risks',
      type: IsarType.string,
    )
  },
  estimateSize: _summaryModelEstimateSize,
  serialize: _summaryModelSerialize,
  deserialize: _summaryModelDeserialize,
  deserializeProp: _summaryModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _summaryModelGetId,
  getLinks: _summaryModelGetLinks,
  attach: _summaryModelAttach,
  version: '3.1.0+1',
);

int _summaryModelEstimateSize(
  SummaryModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.deadlines;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.executiveSummary;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.followUps;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.keyTakeaways;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.meetingNotes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.risks;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _summaryModelSerialize(
  SummaryModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.deadlines);
  writer.writeString(offsets[1], object.executiveSummary);
  writer.writeString(offsets[2], object.followUps);
  writer.writeString(offsets[3], object.keyTakeaways);
  writer.writeString(offsets[4], object.meetingNotes);
  writer.writeString(offsets[5], object.risks);
}

SummaryModel _summaryModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SummaryModel();
  object.deadlines = reader.readStringOrNull(offsets[0]);
  object.executiveSummary = reader.readStringOrNull(offsets[1]);
  object.followUps = reader.readStringOrNull(offsets[2]);
  object.id = id;
  object.keyTakeaways = reader.readStringOrNull(offsets[3]);
  object.meetingNotes = reader.readStringOrNull(offsets[4]);
  object.risks = reader.readStringOrNull(offsets[5]);
  return object;
}

P _summaryModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _summaryModelGetId(SummaryModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _summaryModelGetLinks(SummaryModel object) {
  return [];
}

void _summaryModelAttach(
    IsarCollection<dynamic> col, Id id, SummaryModel object) {
  object.id = id;
}

extension SummaryModelQueryWhereSort
    on QueryBuilder<SummaryModel, SummaryModel, QWhere> {
  QueryBuilder<SummaryModel, SummaryModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SummaryModelQueryWhere
    on QueryBuilder<SummaryModel, SummaryModel, QWhereClause> {
  QueryBuilder<SummaryModel, SummaryModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<SummaryModel, SummaryModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterWhereClause> idBetween(
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
}

extension SummaryModelQueryFilter
    on QueryBuilder<SummaryModel, SummaryModel, QFilterCondition> {
  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      deadlinesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deadlines',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      deadlinesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deadlines',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      deadlinesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deadlines',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      deadlinesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deadlines',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      deadlinesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deadlines',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      deadlinesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deadlines',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      deadlinesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deadlines',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      deadlinesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deadlines',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      deadlinesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deadlines',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      deadlinesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deadlines',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      deadlinesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deadlines',
        value: '',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      deadlinesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deadlines',
        value: '',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      executiveSummaryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'executiveSummary',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      executiveSummaryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'executiveSummary',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      executiveSummaryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'executiveSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      executiveSummaryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'executiveSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      executiveSummaryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'executiveSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      executiveSummaryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'executiveSummary',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      executiveSummaryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'executiveSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      executiveSummaryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'executiveSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      executiveSummaryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'executiveSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      executiveSummaryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'executiveSummary',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      executiveSummaryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'executiveSummary',
        value: '',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      executiveSummaryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'executiveSummary',
        value: '',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      followUpsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'followUps',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      followUpsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'followUps',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      followUpsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followUps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      followUpsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'followUps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      followUpsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'followUps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      followUpsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'followUps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      followUpsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'followUps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      followUpsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'followUps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      followUpsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'followUps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      followUpsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'followUps',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      followUpsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followUps',
        value: '',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      followUpsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'followUps',
        value: '',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      keyTakeawaysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'keyTakeaways',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      keyTakeawaysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'keyTakeaways',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      keyTakeawaysEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keyTakeaways',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      keyTakeawaysGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'keyTakeaways',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      keyTakeawaysLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'keyTakeaways',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      keyTakeawaysBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'keyTakeaways',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      keyTakeawaysStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'keyTakeaways',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      keyTakeawaysEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'keyTakeaways',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      keyTakeawaysContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'keyTakeaways',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      keyTakeawaysMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'keyTakeaways',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      keyTakeawaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keyTakeaways',
        value: '',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      keyTakeawaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'keyTakeaways',
        value: '',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      meetingNotesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'meetingNotes',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      meetingNotesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'meetingNotes',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      meetingNotesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'meetingNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      meetingNotesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'meetingNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      meetingNotesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'meetingNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      meetingNotesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'meetingNotes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      meetingNotesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'meetingNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      meetingNotesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'meetingNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      meetingNotesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'meetingNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      meetingNotesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'meetingNotes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      meetingNotesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'meetingNotes',
        value: '',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      meetingNotesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'meetingNotes',
        value: '',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      risksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'risks',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      risksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'risks',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition> risksEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'risks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      risksGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'risks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition> risksLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'risks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition> risksBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'risks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      risksStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'risks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition> risksEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'risks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition> risksContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'risks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition> risksMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'risks',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      risksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'risks',
        value: '',
      ));
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterFilterCondition>
      risksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'risks',
        value: '',
      ));
    });
  }
}

extension SummaryModelQueryObject
    on QueryBuilder<SummaryModel, SummaryModel, QFilterCondition> {}

extension SummaryModelQueryLinks
    on QueryBuilder<SummaryModel, SummaryModel, QFilterCondition> {}

extension SummaryModelQuerySortBy
    on QueryBuilder<SummaryModel, SummaryModel, QSortBy> {
  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> sortByDeadlines() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadlines', Sort.asc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> sortByDeadlinesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadlines', Sort.desc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy>
      sortByExecutiveSummary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executiveSummary', Sort.asc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy>
      sortByExecutiveSummaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executiveSummary', Sort.desc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> sortByFollowUps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUps', Sort.asc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> sortByFollowUpsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUps', Sort.desc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> sortByKeyTakeaways() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyTakeaways', Sort.asc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy>
      sortByKeyTakeawaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyTakeaways', Sort.desc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> sortByMeetingNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'meetingNotes', Sort.asc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy>
      sortByMeetingNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'meetingNotes', Sort.desc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> sortByRisks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'risks', Sort.asc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> sortByRisksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'risks', Sort.desc);
    });
  }
}

extension SummaryModelQuerySortThenBy
    on QueryBuilder<SummaryModel, SummaryModel, QSortThenBy> {
  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> thenByDeadlines() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadlines', Sort.asc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> thenByDeadlinesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadlines', Sort.desc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy>
      thenByExecutiveSummary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executiveSummary', Sort.asc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy>
      thenByExecutiveSummaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executiveSummary', Sort.desc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> thenByFollowUps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUps', Sort.asc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> thenByFollowUpsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUps', Sort.desc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> thenByKeyTakeaways() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyTakeaways', Sort.asc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy>
      thenByKeyTakeawaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyTakeaways', Sort.desc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> thenByMeetingNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'meetingNotes', Sort.asc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy>
      thenByMeetingNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'meetingNotes', Sort.desc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> thenByRisks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'risks', Sort.asc);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QAfterSortBy> thenByRisksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'risks', Sort.desc);
    });
  }
}

extension SummaryModelQueryWhereDistinct
    on QueryBuilder<SummaryModel, SummaryModel, QDistinct> {
  QueryBuilder<SummaryModel, SummaryModel, QDistinct> distinctByDeadlines(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deadlines', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QDistinct>
      distinctByExecutiveSummary({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'executiveSummary',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QDistinct> distinctByFollowUps(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followUps', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QDistinct> distinctByKeyTakeaways(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'keyTakeaways', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QDistinct> distinctByMeetingNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'meetingNotes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SummaryModel, SummaryModel, QDistinct> distinctByRisks(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'risks', caseSensitive: caseSensitive);
    });
  }
}

extension SummaryModelQueryProperty
    on QueryBuilder<SummaryModel, SummaryModel, QQueryProperty> {
  QueryBuilder<SummaryModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SummaryModel, String?, QQueryOperations> deadlinesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deadlines');
    });
  }

  QueryBuilder<SummaryModel, String?, QQueryOperations>
      executiveSummaryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'executiveSummary');
    });
  }

  QueryBuilder<SummaryModel, String?, QQueryOperations> followUpsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followUps');
    });
  }

  QueryBuilder<SummaryModel, String?, QQueryOperations> keyTakeawaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keyTakeaways');
    });
  }

  QueryBuilder<SummaryModel, String?, QQueryOperations> meetingNotesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'meetingNotes');
    });
  }

  QueryBuilder<SummaryModel, String?, QQueryOperations> risksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'risks');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetActionItemModelCollection on Isar {
  IsarCollection<ActionItemModel> get actionItemModels => this.collection();
}

const ActionItemModelSchema = CollectionSchema(
  name: r'ActionItemModel',
  id: -3858631047937319045,
  properties: {
    r'assignedTo': PropertySchema(
      id: 0,
      name: r'assignedTo',
      type: IsarType.string,
    ),
    r'deadline': PropertySchema(
      id: 1,
      name: r'deadline',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 2,
      name: r'description',
      type: IsarType.string,
    ),
    r'isCompleted': PropertySchema(
      id: 3,
      name: r'isCompleted',
      type: IsarType.bool,
    ),
    r'priority': PropertySchema(
      id: 4,
      name: r'priority',
      type: IsarType.string,
    )
  },
  estimateSize: _actionItemModelEstimateSize,
  serialize: _actionItemModelSerialize,
  deserialize: _actionItemModelDeserialize,
  deserializeProp: _actionItemModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'meeting': LinkSchema(
      id: 1913148891436163322,
      name: r'meeting',
      target: r'MeetingModel',
      single: true,
    ),
    r'speakerProfile': LinkSchema(
      id: -1339938147823182246,
      name: r'speakerProfile',
      target: r'SpeakerProfileModel',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _actionItemModelGetId,
  getLinks: _actionItemModelGetLinks,
  attach: _actionItemModelAttach,
  version: '3.1.0+1',
);

int _actionItemModelEstimateSize(
  ActionItemModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.assignedTo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.priority;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _actionItemModelSerialize(
  ActionItemModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.assignedTo);
  writer.writeDateTime(offsets[1], object.deadline);
  writer.writeString(offsets[2], object.description);
  writer.writeBool(offsets[3], object.isCompleted);
  writer.writeString(offsets[4], object.priority);
}

ActionItemModel _actionItemModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ActionItemModel();
  object.assignedTo = reader.readStringOrNull(offsets[0]);
  object.deadline = reader.readDateTimeOrNull(offsets[1]);
  object.description = reader.readStringOrNull(offsets[2]);
  object.id = id;
  object.isCompleted = reader.readBool(offsets[3]);
  object.priority = reader.readStringOrNull(offsets[4]);
  return object;
}

P _actionItemModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _actionItemModelGetId(ActionItemModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _actionItemModelGetLinks(ActionItemModel object) {
  return [object.meeting, object.speakerProfile];
}

void _actionItemModelAttach(
    IsarCollection<dynamic> col, Id id, ActionItemModel object) {
  object.id = id;
  object.meeting
      .attach(col, col.isar.collection<MeetingModel>(), r'meeting', id);
  object.speakerProfile.attach(
      col, col.isar.collection<SpeakerProfileModel>(), r'speakerProfile', id);
}

extension ActionItemModelQueryWhereSort
    on QueryBuilder<ActionItemModel, ActionItemModel, QWhere> {
  QueryBuilder<ActionItemModel, ActionItemModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ActionItemModelQueryWhere
    on QueryBuilder<ActionItemModel, ActionItemModel, QWhereClause> {
  QueryBuilder<ActionItemModel, ActionItemModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterWhereClause>
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

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterWhereClause> idBetween(
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
}

extension ActionItemModelQueryFilter
    on QueryBuilder<ActionItemModel, ActionItemModel, QFilterCondition> {
  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      assignedToIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'assignedTo',
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      assignedToIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'assignedTo',
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      assignedToEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      assignedToGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      assignedToLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      assignedToBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assignedTo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      assignedToStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      assignedToEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      assignedToContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      assignedToMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'assignedTo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      assignedToIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assignedTo',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      assignedToIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assignedTo',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      deadlineIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deadline',
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      deadlineIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deadline',
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      deadlineEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deadline',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      deadlineGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deadline',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      deadlineLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deadline',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      deadlineBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deadline',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      descriptionEqualTo(
    String? value, {
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

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
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

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      descriptionLessThan(
    String? value, {
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

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      descriptionBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
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

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
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

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      isCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      priorityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'priority',
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      priorityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'priority',
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      priorityEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      priorityGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      priorityLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      priorityBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priority',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      priorityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      priorityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      priorityContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      priorityMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'priority',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      priorityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priority',
        value: '',
      ));
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      priorityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'priority',
        value: '',
      ));
    });
  }
}

extension ActionItemModelQueryObject
    on QueryBuilder<ActionItemModel, ActionItemModel, QFilterCondition> {}

extension ActionItemModelQueryLinks
    on QueryBuilder<ActionItemModel, ActionItemModel, QFilterCondition> {
  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition> meeting(
      FilterQuery<MeetingModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'meeting');
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      meetingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meeting', 0, true, 0, true);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      speakerProfile(FilterQuery<SpeakerProfileModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'speakerProfile');
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterFilterCondition>
      speakerProfileIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'speakerProfile', 0, true, 0, true);
    });
  }
}

extension ActionItemModelQuerySortBy
    on QueryBuilder<ActionItemModel, ActionItemModel, QSortBy> {
  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      sortByAssignedTo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedTo', Sort.asc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      sortByAssignedToDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedTo', Sort.desc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      sortByDeadline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadline', Sort.asc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      sortByDeadlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadline', Sort.desc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      sortByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      sortByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      sortByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      sortByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }
}

extension ActionItemModelQuerySortThenBy
    on QueryBuilder<ActionItemModel, ActionItemModel, QSortThenBy> {
  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      thenByAssignedTo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedTo', Sort.asc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      thenByAssignedToDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedTo', Sort.desc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      thenByDeadline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadline', Sort.asc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      thenByDeadlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadline', Sort.desc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      thenByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      thenByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      thenByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QAfterSortBy>
      thenByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }
}

extension ActionItemModelQueryWhereDistinct
    on QueryBuilder<ActionItemModel, ActionItemModel, QDistinct> {
  QueryBuilder<ActionItemModel, ActionItemModel, QDistinct>
      distinctByAssignedTo({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assignedTo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QDistinct>
      distinctByDeadline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deadline');
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QDistinct>
      distinctByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCompleted');
    });
  }

  QueryBuilder<ActionItemModel, ActionItemModel, QDistinct> distinctByPriority(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priority', caseSensitive: caseSensitive);
    });
  }
}

extension ActionItemModelQueryProperty
    on QueryBuilder<ActionItemModel, ActionItemModel, QQueryProperty> {
  QueryBuilder<ActionItemModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ActionItemModel, String?, QQueryOperations>
      assignedToProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assignedTo');
    });
  }

  QueryBuilder<ActionItemModel, DateTime?, QQueryOperations>
      deadlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deadline');
    });
  }

  QueryBuilder<ActionItemModel, String?, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<ActionItemModel, bool, QQueryOperations> isCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCompleted');
    });
  }

  QueryBuilder<ActionItemModel, String?, QQueryOperations> priorityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priority');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDecisionModelCollection on Isar {
  IsarCollection<DecisionModel> get decisionModels => this.collection();
}

const DecisionModelSchema = CollectionSchema(
  name: r'DecisionModel',
  id: -4947921481997564279,
  properties: {
    r'description': PropertySchema(
      id: 0,
      name: r'description',
      type: IsarType.string,
    )
  },
  estimateSize: _decisionModelEstimateSize,
  serialize: _decisionModelSerialize,
  deserialize: _decisionModelDeserialize,
  deserializeProp: _decisionModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'meeting': LinkSchema(
      id: 6079470343039997437,
      name: r'meeting',
      target: r'MeetingModel',
      single: true,
    ),
    r'speakerProfile': LinkSchema(
      id: 5518663375349142032,
      name: r'speakerProfile',
      target: r'SpeakerProfileModel',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _decisionModelGetId,
  getLinks: _decisionModelGetLinks,
  attach: _decisionModelAttach,
  version: '3.1.0+1',
);

int _decisionModelEstimateSize(
  DecisionModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _decisionModelSerialize(
  DecisionModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.description);
}

DecisionModel _decisionModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DecisionModel();
  object.description = reader.readStringOrNull(offsets[0]);
  object.id = id;
  return object;
}

P _decisionModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _decisionModelGetId(DecisionModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _decisionModelGetLinks(DecisionModel object) {
  return [object.meeting, object.speakerProfile];
}

void _decisionModelAttach(
    IsarCollection<dynamic> col, Id id, DecisionModel object) {
  object.id = id;
  object.meeting
      .attach(col, col.isar.collection<MeetingModel>(), r'meeting', id);
  object.speakerProfile.attach(
      col, col.isar.collection<SpeakerProfileModel>(), r'speakerProfile', id);
}

extension DecisionModelQueryWhereSort
    on QueryBuilder<DecisionModel, DecisionModel, QWhere> {
  QueryBuilder<DecisionModel, DecisionModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DecisionModelQueryWhere
    on QueryBuilder<DecisionModel, DecisionModel, QWhereClause> {
  QueryBuilder<DecisionModel, DecisionModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<DecisionModel, DecisionModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterWhereClause> idBetween(
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
}

extension DecisionModelQueryFilter
    on QueryBuilder<DecisionModel, DecisionModel, QFilterCondition> {
  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
      descriptionEqualTo(
    String? value, {
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

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
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

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
      descriptionLessThan(
    String? value, {
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

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
      descriptionBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
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

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
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

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition> idBetween(
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
}

extension DecisionModelQueryObject
    on QueryBuilder<DecisionModel, DecisionModel, QFilterCondition> {}

extension DecisionModelQueryLinks
    on QueryBuilder<DecisionModel, DecisionModel, QFilterCondition> {
  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition> meeting(
      FilterQuery<MeetingModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'meeting');
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
      meetingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meeting', 0, true, 0, true);
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
      speakerProfile(FilterQuery<SpeakerProfileModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'speakerProfile');
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterFilterCondition>
      speakerProfileIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'speakerProfile', 0, true, 0, true);
    });
  }
}

extension DecisionModelQuerySortBy
    on QueryBuilder<DecisionModel, DecisionModel, QSortBy> {
  QueryBuilder<DecisionModel, DecisionModel, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }
}

extension DecisionModelQuerySortThenBy
    on QueryBuilder<DecisionModel, DecisionModel, QSortThenBy> {
  QueryBuilder<DecisionModel, DecisionModel, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DecisionModel, DecisionModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension DecisionModelQueryWhereDistinct
    on QueryBuilder<DecisionModel, DecisionModel, QDistinct> {
  QueryBuilder<DecisionModel, DecisionModel, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }
}

extension DecisionModelQueryProperty
    on QueryBuilder<DecisionModel, DecisionModel, QQueryProperty> {
  QueryBuilder<DecisionModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DecisionModel, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetChatMessageModelCollection on Isar {
  IsarCollection<ChatMessageModel> get chatMessageModels => this.collection();
}

const ChatMessageModelSchema = CollectionSchema(
  name: r'ChatMessageModel',
  id: 3821037901158827866,
  properties: {
    r'isUser': PropertySchema(
      id: 0,
      name: r'isUser',
      type: IsarType.bool,
    ),
    r'message': PropertySchema(
      id: 1,
      name: r'message',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 2,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _chatMessageModelEstimateSize,
  serialize: _chatMessageModelSerialize,
  deserialize: _chatMessageModelDeserialize,
  deserializeProp: _chatMessageModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'meeting': LinkSchema(
      id: -7561981913650265424,
      name: r'meeting',
      target: r'MeetingModel',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _chatMessageModelGetId,
  getLinks: _chatMessageModelGetLinks,
  attach: _chatMessageModelAttach,
  version: '3.1.0+1',
);

int _chatMessageModelEstimateSize(
  ChatMessageModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.message;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _chatMessageModelSerialize(
  ChatMessageModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isUser);
  writer.writeString(offsets[1], object.message);
  writer.writeDateTime(offsets[2], object.timestamp);
}

ChatMessageModel _chatMessageModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ChatMessageModel();
  object.id = id;
  object.isUser = reader.readBool(offsets[0]);
  object.message = reader.readStringOrNull(offsets[1]);
  object.timestamp = reader.readDateTimeOrNull(offsets[2]);
  return object;
}

P _chatMessageModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _chatMessageModelGetId(ChatMessageModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _chatMessageModelGetLinks(ChatMessageModel object) {
  return [object.meeting];
}

void _chatMessageModelAttach(
    IsarCollection<dynamic> col, Id id, ChatMessageModel object) {
  object.id = id;
  object.meeting
      .attach(col, col.isar.collection<MeetingModel>(), r'meeting', id);
}

extension ChatMessageModelQueryWhereSort
    on QueryBuilder<ChatMessageModel, ChatMessageModel, QWhere> {
  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ChatMessageModelQueryWhere
    on QueryBuilder<ChatMessageModel, ChatMessageModel, QWhereClause> {
  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterWhereClause>
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

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterWhereClause> idBetween(
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
}

extension ChatMessageModelQueryFilter
    on QueryBuilder<ChatMessageModel, ChatMessageModel, QFilterCondition> {
  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      isUserEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isUser',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      messageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'message',
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      messageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'message',
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      messageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      messageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      messageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      messageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'message',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      messageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      messageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      messageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      messageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'message',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      messageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      messageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      timestampIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'timestamp',
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      timestampIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'timestamp',
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      timestampEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      timestampLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      timestampBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ChatMessageModelQueryObject
    on QueryBuilder<ChatMessageModel, ChatMessageModel, QFilterCondition> {}

extension ChatMessageModelQueryLinks
    on QueryBuilder<ChatMessageModel, ChatMessageModel, QFilterCondition> {
  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      meeting(FilterQuery<MeetingModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'meeting');
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterFilterCondition>
      meetingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meeting', 0, true, 0, true);
    });
  }
}

extension ChatMessageModelQuerySortBy
    on QueryBuilder<ChatMessageModel, ChatMessageModel, QSortBy> {
  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterSortBy>
      sortByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterSortBy>
      sortByIsUserDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterSortBy>
      sortByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterSortBy>
      sortByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension ChatMessageModelQuerySortThenBy
    on QueryBuilder<ChatMessageModel, ChatMessageModel, QSortThenBy> {
  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterSortBy>
      thenByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterSortBy>
      thenByIsUserDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterSortBy>
      thenByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterSortBy>
      thenByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension ChatMessageModelQueryWhereDistinct
    on QueryBuilder<ChatMessageModel, ChatMessageModel, QDistinct> {
  QueryBuilder<ChatMessageModel, ChatMessageModel, QDistinct>
      distinctByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUser');
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QDistinct> distinctByMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'message', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatMessageModel, ChatMessageModel, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension ChatMessageModelQueryProperty
    on QueryBuilder<ChatMessageModel, ChatMessageModel, QQueryProperty> {
  QueryBuilder<ChatMessageModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ChatMessageModel, bool, QQueryOperations> isUserProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUser');
    });
  }

  QueryBuilder<ChatMessageModel, String?, QQueryOperations> messageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'message');
    });
  }

  QueryBuilder<ChatMessageModel, DateTime?, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSpeakerProfileModelCollection on Isar {
  IsarCollection<SpeakerProfileModel> get speakerProfileModels =>
      this.collection();
}

const SpeakerProfileModelSchema = CollectionSchema(
  name: r'SpeakerProfileModel',
  id: 997621389169002064,
  properties: {
    r'avatarEmoji': PropertySchema(
      id: 0,
      name: r'avatarEmoji',
      type: IsarType.string,
    ),
    r'colorValue': PropertySchema(
      id: 1,
      name: r'colorValue',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'meetingCount': PropertySchema(
      id: 3,
      name: r'meetingCount',
      type: IsarType.long,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'voiceEmbedding': PropertySchema(
      id: 5,
      name: r'voiceEmbedding',
      type: IsarType.doubleList,
    )
  },
  estimateSize: _speakerProfileModelEstimateSize,
  serialize: _speakerProfileModelSerialize,
  deserialize: _speakerProfileModelDeserialize,
  deserializeProp: _speakerProfileModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _speakerProfileModelGetId,
  getLinks: _speakerProfileModelGetLinks,
  attach: _speakerProfileModelAttach,
  version: '3.1.0+1',
);

int _speakerProfileModelEstimateSize(
  SpeakerProfileModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.avatarEmoji;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.voiceEmbedding;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  return bytesCount;
}

void _speakerProfileModelSerialize(
  SpeakerProfileModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.avatarEmoji);
  writer.writeLong(offsets[1], object.colorValue);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeLong(offsets[3], object.meetingCount);
  writer.writeString(offsets[4], object.name);
  writer.writeDoubleList(offsets[5], object.voiceEmbedding);
}

SpeakerProfileModel _speakerProfileModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SpeakerProfileModel();
  object.avatarEmoji = reader.readStringOrNull(offsets[0]);
  object.colorValue = reader.readLongOrNull(offsets[1]);
  object.createdAt = reader.readDateTimeOrNull(offsets[2]);
  object.id = id;
  object.meetingCount = reader.readLong(offsets[3]);
  object.name = reader.readStringOrNull(offsets[4]);
  object.voiceEmbedding = reader.readDoubleList(offsets[5]);
  return object;
}

P _speakerProfileModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleList(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _speakerProfileModelGetId(SpeakerProfileModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _speakerProfileModelGetLinks(
    SpeakerProfileModel object) {
  return [];
}

void _speakerProfileModelAttach(
    IsarCollection<dynamic> col, Id id, SpeakerProfileModel object) {
  object.id = id;
}

extension SpeakerProfileModelByIndex on IsarCollection<SpeakerProfileModel> {
  Future<SpeakerProfileModel?> getByName(String? name) {
    return getByIndex(r'name', [name]);
  }

  SpeakerProfileModel? getByNameSync(String? name) {
    return getByIndexSync(r'name', [name]);
  }

  Future<bool> deleteByName(String? name) {
    return deleteByIndex(r'name', [name]);
  }

  bool deleteByNameSync(String? name) {
    return deleteByIndexSync(r'name', [name]);
  }

  Future<List<SpeakerProfileModel?>> getAllByName(List<String?> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndex(r'name', values);
  }

  List<SpeakerProfileModel?> getAllByNameSync(List<String?> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'name', values);
  }

  Future<int> deleteAllByName(List<String?> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'name', values);
  }

  int deleteAllByNameSync(List<String?> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'name', values);
  }

  Future<Id> putByName(SpeakerProfileModel object) {
    return putByIndex(r'name', object);
  }

  Id putByNameSync(SpeakerProfileModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'name', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByName(List<SpeakerProfileModel> objects) {
    return putAllByIndex(r'name', objects);
  }

  List<Id> putAllByNameSync(List<SpeakerProfileModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'name', objects, saveLinks: saveLinks);
  }
}

extension SpeakerProfileModelQueryWhereSort
    on QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QWhere> {
  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SpeakerProfileModelQueryWhere
    on QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QWhereClause> {
  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterWhereClause>
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

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterWhereClause>
      nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [null],
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterWhereClause>
      nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'name',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterWhereClause>
      nameEqualTo(String? name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterWhereClause>
      nameNotEqualTo(String? name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ));
      }
    });
  }
}

extension SpeakerProfileModelQueryFilter on QueryBuilder<SpeakerProfileModel,
    SpeakerProfileModel, QFilterCondition> {
  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      avatarEmojiIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avatarEmoji',
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      avatarEmojiIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avatarEmoji',
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      avatarEmojiEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      avatarEmojiGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'avatarEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      avatarEmojiLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'avatarEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      avatarEmojiBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'avatarEmoji',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      avatarEmojiStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'avatarEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      avatarEmojiEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'avatarEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      avatarEmojiContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'avatarEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      avatarEmojiMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'avatarEmoji',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      avatarEmojiIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarEmoji',
        value: '',
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      avatarEmojiIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'avatarEmoji',
        value: '',
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      colorValueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'colorValue',
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      colorValueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'colorValue',
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      colorValueEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      colorValueGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      colorValueLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      colorValueBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime? value, {
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

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      createdAtLessThan(
    DateTime? value, {
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

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
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

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      meetingCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'meetingCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      meetingCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'meetingCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      meetingCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'meetingCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      meetingCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'meetingCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      voiceEmbeddingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'voiceEmbedding',
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      voiceEmbeddingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'voiceEmbedding',
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      voiceEmbeddingElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'voiceEmbedding',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      voiceEmbeddingElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'voiceEmbedding',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      voiceEmbeddingElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'voiceEmbedding',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      voiceEmbeddingElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'voiceEmbedding',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      voiceEmbeddingLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'voiceEmbedding',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      voiceEmbeddingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'voiceEmbedding',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      voiceEmbeddingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'voiceEmbedding',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      voiceEmbeddingLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'voiceEmbedding',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      voiceEmbeddingLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'voiceEmbedding',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterFilterCondition>
      voiceEmbeddingLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'voiceEmbedding',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension SpeakerProfileModelQueryObject on QueryBuilder<SpeakerProfileModel,
    SpeakerProfileModel, QFilterCondition> {}

extension SpeakerProfileModelQueryLinks on QueryBuilder<SpeakerProfileModel,
    SpeakerProfileModel, QFilterCondition> {}

extension SpeakerProfileModelQuerySortBy
    on QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QSortBy> {
  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      sortByAvatarEmoji() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarEmoji', Sort.asc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      sortByAvatarEmojiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarEmoji', Sort.desc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      sortByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      sortByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      sortByMeetingCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'meetingCount', Sort.asc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      sortByMeetingCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'meetingCount', Sort.desc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension SpeakerProfileModelQuerySortThenBy
    on QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QSortThenBy> {
  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      thenByAvatarEmoji() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarEmoji', Sort.asc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      thenByAvatarEmojiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarEmoji', Sort.desc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      thenByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      thenByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      thenByMeetingCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'meetingCount', Sort.asc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      thenByMeetingCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'meetingCount', Sort.desc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension SpeakerProfileModelQueryWhereDistinct
    on QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QDistinct> {
  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QDistinct>
      distinctByAvatarEmoji({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avatarEmoji', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QDistinct>
      distinctByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorValue');
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QDistinct>
      distinctByMeetingCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'meetingCount');
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QDistinct>
      distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QDistinct>
      distinctByVoiceEmbedding() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'voiceEmbedding');
    });
  }
}

extension SpeakerProfileModelQueryProperty
    on QueryBuilder<SpeakerProfileModel, SpeakerProfileModel, QQueryProperty> {
  QueryBuilder<SpeakerProfileModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SpeakerProfileModel, String?, QQueryOperations>
      avatarEmojiProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatarEmoji');
    });
  }

  QueryBuilder<SpeakerProfileModel, int?, QQueryOperations>
      colorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorValue');
    });
  }

  QueryBuilder<SpeakerProfileModel, DateTime?, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<SpeakerProfileModel, int, QQueryOperations>
      meetingCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'meetingCount');
    });
  }

  QueryBuilder<SpeakerProfileModel, String?, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<SpeakerProfileModel, List<double>?, QQueryOperations>
      voiceEmbeddingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'voiceEmbedding');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSpeakerEmotionModelCollection on Isar {
  IsarCollection<SpeakerEmotionModel> get speakerEmotionModels =>
      this.collection();
}

const SpeakerEmotionModelSchema = CollectionSchema(
  name: r'SpeakerEmotionModel',
  id: -5406307977917888665,
  properties: {
    r'confidence': PropertySchema(
      id: 0,
      name: r'confidence',
      type: IsarType.double,
    ),
    r'emotion': PropertySchema(
      id: 1,
      name: r'emotion',
      type: IsarType.string,
    ),
    r'endTime': PropertySchema(
      id: 2,
      name: r'endTime',
      type: IsarType.double,
    ),
    r'startTime': PropertySchema(
      id: 3,
      name: r'startTime',
      type: IsarType.double,
    )
  },
  estimateSize: _speakerEmotionModelEstimateSize,
  serialize: _speakerEmotionModelSerialize,
  deserialize: _speakerEmotionModelDeserialize,
  deserializeProp: _speakerEmotionModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'speakerProfile': LinkSchema(
      id: -4404528549079291865,
      name: r'speakerProfile',
      target: r'SpeakerProfileModel',
      single: true,
    ),
    r'meeting': LinkSchema(
      id: 7012586865827417353,
      name: r'meeting',
      target: r'MeetingModel',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _speakerEmotionModelGetId,
  getLinks: _speakerEmotionModelGetLinks,
  attach: _speakerEmotionModelAttach,
  version: '3.1.0+1',
);

int _speakerEmotionModelEstimateSize(
  SpeakerEmotionModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.emotion;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _speakerEmotionModelSerialize(
  SpeakerEmotionModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.confidence);
  writer.writeString(offsets[1], object.emotion);
  writer.writeDouble(offsets[2], object.endTime);
  writer.writeDouble(offsets[3], object.startTime);
}

SpeakerEmotionModel _speakerEmotionModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SpeakerEmotionModel();
  object.confidence = reader.readDouble(offsets[0]);
  object.emotion = reader.readStringOrNull(offsets[1]);
  object.endTime = reader.readDouble(offsets[2]);
  object.id = id;
  object.startTime = reader.readDouble(offsets[3]);
  return object;
}

P _speakerEmotionModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _speakerEmotionModelGetId(SpeakerEmotionModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _speakerEmotionModelGetLinks(
    SpeakerEmotionModel object) {
  return [object.speakerProfile, object.meeting];
}

void _speakerEmotionModelAttach(
    IsarCollection<dynamic> col, Id id, SpeakerEmotionModel object) {
  object.id = id;
  object.speakerProfile.attach(
      col, col.isar.collection<SpeakerProfileModel>(), r'speakerProfile', id);
  object.meeting
      .attach(col, col.isar.collection<MeetingModel>(), r'meeting', id);
}

extension SpeakerEmotionModelQueryWhereSort
    on QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QWhere> {
  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SpeakerEmotionModelQueryWhere
    on QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QWhereClause> {
  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterWhereClause>
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

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterWhereClause>
      idBetween(
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
}

extension SpeakerEmotionModelQueryFilter on QueryBuilder<SpeakerEmotionModel,
    SpeakerEmotionModel, QFilterCondition> {
  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      confidenceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      confidenceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      confidenceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      confidenceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'confidence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      emotionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'emotion',
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      emotionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'emotion',
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      emotionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      emotionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'emotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      emotionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'emotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      emotionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'emotion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      emotionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'emotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      emotionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'emotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      emotionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'emotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      emotionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'emotion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      emotionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emotion',
        value: '',
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      emotionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'emotion',
        value: '',
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      endTimeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      endTimeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      endTimeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      endTimeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      startTimeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      startTimeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      startTimeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      startTimeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension SpeakerEmotionModelQueryObject on QueryBuilder<SpeakerEmotionModel,
    SpeakerEmotionModel, QFilterCondition> {}

extension SpeakerEmotionModelQueryLinks on QueryBuilder<SpeakerEmotionModel,
    SpeakerEmotionModel, QFilterCondition> {
  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      speakerProfile(FilterQuery<SpeakerProfileModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'speakerProfile');
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      speakerProfileIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'speakerProfile', 0, true, 0, true);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      meeting(FilterQuery<MeetingModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'meeting');
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterFilterCondition>
      meetingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meeting', 0, true, 0, true);
    });
  }
}

extension SpeakerEmotionModelQuerySortBy
    on QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QSortBy> {
  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      sortByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      sortByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      sortByEmotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emotion', Sort.asc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      sortByEmotionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emotion', Sort.desc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      sortByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      sortByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      sortByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      sortByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }
}

extension SpeakerEmotionModelQuerySortThenBy
    on QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QSortThenBy> {
  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      thenByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      thenByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      thenByEmotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emotion', Sort.asc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      thenByEmotionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emotion', Sort.desc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      thenByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      thenByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      thenByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QAfterSortBy>
      thenByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }
}

extension SpeakerEmotionModelQueryWhereDistinct
    on QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QDistinct> {
  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QDistinct>
      distinctByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confidence');
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QDistinct>
      distinctByEmotion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'emotion', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QDistinct>
      distinctByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endTime');
    });
  }

  QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QDistinct>
      distinctByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startTime');
    });
  }
}

extension SpeakerEmotionModelQueryProperty
    on QueryBuilder<SpeakerEmotionModel, SpeakerEmotionModel, QQueryProperty> {
  QueryBuilder<SpeakerEmotionModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SpeakerEmotionModel, double, QQueryOperations>
      confidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confidence');
    });
  }

  QueryBuilder<SpeakerEmotionModel, String?, QQueryOperations>
      emotionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'emotion');
    });
  }

  QueryBuilder<SpeakerEmotionModel, double, QQueryOperations>
      endTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endTime');
    });
  }

  QueryBuilder<SpeakerEmotionModel, double, QQueryOperations>
      startTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startTime');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSpeakerAnalyticsModelCollection on Isar {
  IsarCollection<SpeakerAnalyticsModel> get speakerAnalyticsModels =>
      this.collection();
}

const SpeakerAnalyticsModelSchema = CollectionSchema(
  name: r'SpeakerAnalyticsModel',
  id: -1835362585677868001,
  properties: {
    r'interactionScore': PropertySchema(
      id: 0,
      name: r'interactionScore',
      type: IsarType.double,
    ),
    r'participationPercentage': PropertySchema(
      id: 1,
      name: r'participationPercentage',
      type: IsarType.double,
    ),
    r'speakingTimeSeconds': PropertySchema(
      id: 2,
      name: r'speakingTimeSeconds',
      type: IsarType.double,
    ),
    r'wordCount': PropertySchema(
      id: 3,
      name: r'wordCount',
      type: IsarType.long,
    )
  },
  estimateSize: _speakerAnalyticsModelEstimateSize,
  serialize: _speakerAnalyticsModelSerialize,
  deserialize: _speakerAnalyticsModelDeserialize,
  deserializeProp: _speakerAnalyticsModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'speakerProfile': LinkSchema(
      id: 8767713835934679151,
      name: r'speakerProfile',
      target: r'SpeakerProfileModel',
      single: true,
    ),
    r'meeting': LinkSchema(
      id: -7260711598148575838,
      name: r'meeting',
      target: r'MeetingModel',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _speakerAnalyticsModelGetId,
  getLinks: _speakerAnalyticsModelGetLinks,
  attach: _speakerAnalyticsModelAttach,
  version: '3.1.0+1',
);

int _speakerAnalyticsModelEstimateSize(
  SpeakerAnalyticsModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _speakerAnalyticsModelSerialize(
  SpeakerAnalyticsModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.interactionScore);
  writer.writeDouble(offsets[1], object.participationPercentage);
  writer.writeDouble(offsets[2], object.speakingTimeSeconds);
  writer.writeLong(offsets[3], object.wordCount);
}

SpeakerAnalyticsModel _speakerAnalyticsModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SpeakerAnalyticsModel();
  object.id = id;
  object.interactionScore = reader.readDouble(offsets[0]);
  object.participationPercentage = reader.readDouble(offsets[1]);
  object.speakingTimeSeconds = reader.readDouble(offsets[2]);
  object.wordCount = reader.readLong(offsets[3]);
  return object;
}

P _speakerAnalyticsModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _speakerAnalyticsModelGetId(SpeakerAnalyticsModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _speakerAnalyticsModelGetLinks(
    SpeakerAnalyticsModel object) {
  return [object.speakerProfile, object.meeting];
}

void _speakerAnalyticsModelAttach(
    IsarCollection<dynamic> col, Id id, SpeakerAnalyticsModel object) {
  object.id = id;
  object.speakerProfile.attach(
      col, col.isar.collection<SpeakerProfileModel>(), r'speakerProfile', id);
  object.meeting
      .attach(col, col.isar.collection<MeetingModel>(), r'meeting', id);
}

extension SpeakerAnalyticsModelQueryWhereSort
    on QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QWhere> {
  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SpeakerAnalyticsModelQueryWhere on QueryBuilder<SpeakerAnalyticsModel,
    SpeakerAnalyticsModel, QWhereClause> {
  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterWhereClause>
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

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterWhereClause>
      idBetween(
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
}

extension SpeakerAnalyticsModelQueryFilter on QueryBuilder<
    SpeakerAnalyticsModel, SpeakerAnalyticsModel, QFilterCondition> {
  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> interactionScoreEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'interactionScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> interactionScoreGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'interactionScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> interactionScoreLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'interactionScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> interactionScoreBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'interactionScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> participationPercentageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'participationPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> participationPercentageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'participationPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> participationPercentageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'participationPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> participationPercentageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'participationPercentage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> speakingTimeSecondsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'speakingTimeSeconds',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> speakingTimeSecondsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'speakingTimeSeconds',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> speakingTimeSecondsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'speakingTimeSeconds',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> speakingTimeSecondsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'speakingTimeSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> wordCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wordCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> wordCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'wordCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> wordCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'wordCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> wordCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'wordCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SpeakerAnalyticsModelQueryObject on QueryBuilder<
    SpeakerAnalyticsModel, SpeakerAnalyticsModel, QFilterCondition> {}

extension SpeakerAnalyticsModelQueryLinks on QueryBuilder<SpeakerAnalyticsModel,
    SpeakerAnalyticsModel, QFilterCondition> {
  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
          QAfterFilterCondition>
      speakerProfile(FilterQuery<SpeakerProfileModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'speakerProfile');
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> speakerProfileIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'speakerProfile', 0, true, 0, true);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> meeting(FilterQuery<MeetingModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'meeting');
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel,
      QAfterFilterCondition> meetingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meeting', 0, true, 0, true);
    });
  }
}

extension SpeakerAnalyticsModelQuerySortBy
    on QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QSortBy> {
  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      sortByInteractionScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interactionScore', Sort.asc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      sortByInteractionScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interactionScore', Sort.desc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      sortByParticipationPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participationPercentage', Sort.asc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      sortByParticipationPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participationPercentage', Sort.desc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      sortBySpeakingTimeSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speakingTimeSeconds', Sort.asc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      sortBySpeakingTimeSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speakingTimeSeconds', Sort.desc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      sortByWordCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wordCount', Sort.asc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      sortByWordCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wordCount', Sort.desc);
    });
  }
}

extension SpeakerAnalyticsModelQuerySortThenBy
    on QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QSortThenBy> {
  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      thenByInteractionScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interactionScore', Sort.asc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      thenByInteractionScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interactionScore', Sort.desc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      thenByParticipationPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participationPercentage', Sort.asc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      thenByParticipationPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participationPercentage', Sort.desc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      thenBySpeakingTimeSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speakingTimeSeconds', Sort.asc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      thenBySpeakingTimeSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speakingTimeSeconds', Sort.desc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      thenByWordCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wordCount', Sort.asc);
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QAfterSortBy>
      thenByWordCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wordCount', Sort.desc);
    });
  }
}

extension SpeakerAnalyticsModelQueryWhereDistinct
    on QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QDistinct> {
  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QDistinct>
      distinctByInteractionScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'interactionScore');
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QDistinct>
      distinctByParticipationPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'participationPercentage');
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QDistinct>
      distinctBySpeakingTimeSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'speakingTimeSeconds');
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, SpeakerAnalyticsModel, QDistinct>
      distinctByWordCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wordCount');
    });
  }
}

extension SpeakerAnalyticsModelQueryProperty on QueryBuilder<
    SpeakerAnalyticsModel, SpeakerAnalyticsModel, QQueryProperty> {
  QueryBuilder<SpeakerAnalyticsModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, double, QQueryOperations>
      interactionScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'interactionScore');
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, double, QQueryOperations>
      participationPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'participationPercentage');
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, double, QQueryOperations>
      speakingTimeSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'speakingTimeSeconds');
    });
  }

  QueryBuilder<SpeakerAnalyticsModel, int, QQueryOperations>
      wordCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wordCount');
    });
  }
}
