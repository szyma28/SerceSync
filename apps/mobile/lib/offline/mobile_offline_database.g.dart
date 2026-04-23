// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mobile_offline_database.dart';

// ignore_for_file: type=lint
class $CacheEntriesTable extends CacheEntries
    with TableInfo<$CacheEntriesTable, CacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheKey,
    userId,
    json,
    fetchedAt,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey, userId};
  @override
  CacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheEntry(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $CacheEntriesTable createAlias(String alias) {
    return $CacheEntriesTable(attachedDatabase, alias);
  }
}

class CacheEntry extends DataClass implements Insertable<CacheEntry> {
  final String cacheKey;
  final String userId;
  final String json;
  final DateTime fetchedAt;
  final int schemaVersion;
  const CacheEntry({
    required this.cacheKey,
    required this.userId,
    required this.json,
    required this.fetchedAt,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['user_id'] = Variable<String>(userId);
    map['json'] = Variable<String>(json);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  CacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return CacheEntriesCompanion(
      cacheKey: Value(cacheKey),
      userId: Value(userId),
      json: Value(json),
      fetchedAt: Value(fetchedAt),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory CacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheEntry(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      userId: serializer.fromJson<String>(json['userId']),
      json: serializer.fromJson<String>(json['json']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'userId': serializer.toJson<String>(userId),
      'json': serializer.toJson<String>(json),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  CacheEntry copyWith({
    String? cacheKey,
    String? userId,
    String? json,
    DateTime? fetchedAt,
    int? schemaVersion,
  }) => CacheEntry(
    cacheKey: cacheKey ?? this.cacheKey,
    userId: userId ?? this.userId,
    json: json ?? this.json,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  CacheEntry copyWithCompanion(CacheEntriesCompanion data) {
    return CacheEntry(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      userId: data.userId.present ? data.userId.value : this.userId,
      json: data.json.present ? data.json.value : this.json,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntry(')
          ..write('cacheKey: $cacheKey, ')
          ..write('userId: $userId, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(cacheKey, userId, json, fetchedAt, schemaVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheEntry &&
          other.cacheKey == this.cacheKey &&
          other.userId == this.userId &&
          other.json == this.json &&
          other.fetchedAt == this.fetchedAt &&
          other.schemaVersion == this.schemaVersion);
}

class CacheEntriesCompanion extends UpdateCompanion<CacheEntry> {
  final Value<String> cacheKey;
  final Value<String> userId;
  final Value<String> json;
  final Value<DateTime> fetchedAt;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const CacheEntriesCompanion({
    this.cacheKey = const Value.absent(),
    this.userId = const Value.absent(),
    this.json = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheEntriesCompanion.insert({
    required String cacheKey,
    required String userId,
    required String json,
    required DateTime fetchedAt,
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       userId = Value(userId),
       json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<CacheEntry> custom({
    Expression<String>? cacheKey,
    Expression<String>? userId,
    Expression<String>? json,
    Expression<DateTime>? fetchedAt,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (userId != null) 'user_id': userId,
      if (json != null) 'json': json,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheEntriesCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? userId,
    Value<String>? json,
    Value<DateTime>? fetchedAt,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return CacheEntriesCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      userId: userId ?? this.userId,
      json: json ?? this.json,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntriesCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('userId: $userId, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueuedMutationsTable extends QueuedMutations
    with TableInfo<$QueuedMutationsTable, QueuedMutation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueuedMutationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRequestIdMeta = const VerificationMeta(
    'clientRequestId',
  );
  @override
  late final GeneratedColumn<String> clientRequestId = GeneratedColumn<String>(
    'client_request_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _residentIdMeta = const VerificationMeta(
    'residentId',
  );
  @override
  late final GeneratedColumn<String> residentId = GeneratedColumn<String>(
    'resident_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventAtMeta = const VerificationMeta(
    'eventAt',
  );
  @override
  late final GeneratedColumn<DateTime> eventAt = GeneratedColumn<DateTime>(
    'event_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMessageMeta = const VerificationMeta(
    'lastErrorMessage',
  );
  @override
  late final GeneratedColumn<String> lastErrorMessage = GeneratedColumn<String>(
    'last_error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    userId,
    clientRequestId,
    kind,
    residentId,
    shiftId,
    payloadJson,
    eventAt,
    status,
    retryCount,
    lastErrorCode,
    lastErrorMessage,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queued_mutations';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueuedMutation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('client_request_id')) {
      context.handle(
        _clientRequestIdMeta,
        clientRequestId.isAcceptableOrUnknown(
          data['client_request_id']!,
          _clientRequestIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientRequestIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('resident_id')) {
      context.handle(
        _residentIdMeta,
        residentId.isAcceptableOrUnknown(data['resident_id']!, _residentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_residentIdMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('event_at')) {
      context.handle(
        _eventAtMeta,
        eventAt.isAcceptableOrUnknown(data['event_at']!, _eventAtMeta),
      );
    } else if (isInserting) {
      context.missing(_eventAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('last_error_message')) {
      context.handle(
        _lastErrorMessageMeta,
        lastErrorMessage.isAcceptableOrUnknown(
          data['last_error_message']!,
          _lastErrorMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  QueuedMutation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueuedMutation(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      clientRequestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_request_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      residentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resident_id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      eventAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}event_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      lastErrorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QueuedMutationsTable createAlias(String alias) {
    return $QueuedMutationsTable(attachedDatabase, alias);
  }
}

class QueuedMutation extends DataClass implements Insertable<QueuedMutation> {
  final String localId;
  final String userId;
  final String clientRequestId;
  final String kind;
  final String residentId;
  final String shiftId;
  final String payloadJson;
  final DateTime eventAt;
  final String status;
  final int retryCount;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  const QueuedMutation({
    required this.localId,
    required this.userId,
    required this.clientRequestId,
    required this.kind,
    required this.residentId,
    required this.shiftId,
    required this.payloadJson,
    required this.eventAt,
    required this.status,
    required this.retryCount,
    this.lastErrorCode,
    this.lastErrorMessage,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['user_id'] = Variable<String>(userId);
    map['client_request_id'] = Variable<String>(clientRequestId);
    map['kind'] = Variable<String>(kind);
    map['resident_id'] = Variable<String>(residentId);
    map['shift_id'] = Variable<String>(shiftId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['event_at'] = Variable<DateTime>(eventAt);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    if (!nullToAbsent || lastErrorMessage != null) {
      map['last_error_message'] = Variable<String>(lastErrorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QueuedMutationsCompanion toCompanion(bool nullToAbsent) {
    return QueuedMutationsCompanion(
      localId: Value(localId),
      userId: Value(userId),
      clientRequestId: Value(clientRequestId),
      kind: Value(kind),
      residentId: Value(residentId),
      shiftId: Value(shiftId),
      payloadJson: Value(payloadJson),
      eventAt: Value(eventAt),
      status: Value(status),
      retryCount: Value(retryCount),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      lastErrorMessage: lastErrorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory QueuedMutation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueuedMutation(
      localId: serializer.fromJson<String>(json['localId']),
      userId: serializer.fromJson<String>(json['userId']),
      clientRequestId: serializer.fromJson<String>(json['clientRequestId']),
      kind: serializer.fromJson<String>(json['kind']),
      residentId: serializer.fromJson<String>(json['residentId']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      eventAt: serializer.fromJson<DateTime>(json['eventAt']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      lastErrorMessage: serializer.fromJson<String?>(json['lastErrorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'userId': serializer.toJson<String>(userId),
      'clientRequestId': serializer.toJson<String>(clientRequestId),
      'kind': serializer.toJson<String>(kind),
      'residentId': serializer.toJson<String>(residentId),
      'shiftId': serializer.toJson<String>(shiftId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'eventAt': serializer.toJson<DateTime>(eventAt),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'lastErrorMessage': serializer.toJson<String?>(lastErrorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QueuedMutation copyWith({
    String? localId,
    String? userId,
    String? clientRequestId,
    String? kind,
    String? residentId,
    String? shiftId,
    String? payloadJson,
    DateTime? eventAt,
    String? status,
    int? retryCount,
    Value<String?> lastErrorCode = const Value.absent(),
    Value<String?> lastErrorMessage = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => QueuedMutation(
    localId: localId ?? this.localId,
    userId: userId ?? this.userId,
    clientRequestId: clientRequestId ?? this.clientRequestId,
    kind: kind ?? this.kind,
    residentId: residentId ?? this.residentId,
    shiftId: shiftId ?? this.shiftId,
    payloadJson: payloadJson ?? this.payloadJson,
    eventAt: eventAt ?? this.eventAt,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    lastErrorMessage: lastErrorMessage.present
        ? lastErrorMessage.value
        : this.lastErrorMessage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  QueuedMutation copyWithCompanion(QueuedMutationsCompanion data) {
    return QueuedMutation(
      localId: data.localId.present ? data.localId.value : this.localId,
      userId: data.userId.present ? data.userId.value : this.userId,
      clientRequestId: data.clientRequestId.present
          ? data.clientRequestId.value
          : this.clientRequestId,
      kind: data.kind.present ? data.kind.value : this.kind,
      residentId: data.residentId.present
          ? data.residentId.value
          : this.residentId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      eventAt: data.eventAt.present ? data.eventAt.value : this.eventAt,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      lastErrorMessage: data.lastErrorMessage.present
          ? data.lastErrorMessage.value
          : this.lastErrorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueuedMutation(')
          ..write('localId: $localId, ')
          ..write('userId: $userId, ')
          ..write('clientRequestId: $clientRequestId, ')
          ..write('kind: $kind, ')
          ..write('residentId: $residentId, ')
          ..write('shiftId: $shiftId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('eventAt: $eventAt, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    userId,
    clientRequestId,
    kind,
    residentId,
    shiftId,
    payloadJson,
    eventAt,
    status,
    retryCount,
    lastErrorCode,
    lastErrorMessage,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueuedMutation &&
          other.localId == this.localId &&
          other.userId == this.userId &&
          other.clientRequestId == this.clientRequestId &&
          other.kind == this.kind &&
          other.residentId == this.residentId &&
          other.shiftId == this.shiftId &&
          other.payloadJson == this.payloadJson &&
          other.eventAt == this.eventAt &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.lastErrorCode == this.lastErrorCode &&
          other.lastErrorMessage == this.lastErrorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class QueuedMutationsCompanion extends UpdateCompanion<QueuedMutation> {
  final Value<String> localId;
  final Value<String> userId;
  final Value<String> clientRequestId;
  final Value<String> kind;
  final Value<String> residentId;
  final Value<String> shiftId;
  final Value<String> payloadJson;
  final Value<DateTime> eventAt;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> lastErrorCode;
  final Value<String?> lastErrorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const QueuedMutationsCompanion({
    this.localId = const Value.absent(),
    this.userId = const Value.absent(),
    this.clientRequestId = const Value.absent(),
    this.kind = const Value.absent(),
    this.residentId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.eventAt = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueuedMutationsCompanion.insert({
    required String localId,
    required String userId,
    required String clientRequestId,
    required String kind,
    required String residentId,
    required String shiftId,
    required String payloadJson,
    required DateTime eventAt,
    required String status,
    this.retryCount = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       userId = Value(userId),
       clientRequestId = Value(clientRequestId),
       kind = Value(kind),
       residentId = Value(residentId),
       shiftId = Value(shiftId),
       payloadJson = Value(payloadJson),
       eventAt = Value(eventAt),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<QueuedMutation> custom({
    Expression<String>? localId,
    Expression<String>? userId,
    Expression<String>? clientRequestId,
    Expression<String>? kind,
    Expression<String>? residentId,
    Expression<String>? shiftId,
    Expression<String>? payloadJson,
    Expression<DateTime>? eventAt,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? lastErrorCode,
    Expression<String>? lastErrorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (userId != null) 'user_id': userId,
      if (clientRequestId != null) 'client_request_id': clientRequestId,
      if (kind != null) 'kind': kind,
      if (residentId != null) 'resident_id': residentId,
      if (shiftId != null) 'shift_id': shiftId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (eventAt != null) 'event_at': eventAt,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (lastErrorMessage != null) 'last_error_message': lastErrorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueuedMutationsCompanion copyWith({
    Value<String>? localId,
    Value<String>? userId,
    Value<String>? clientRequestId,
    Value<String>? kind,
    Value<String>? residentId,
    Value<String>? shiftId,
    Value<String>? payloadJson,
    Value<DateTime>? eventAt,
    Value<String>? status,
    Value<int>? retryCount,
    Value<String?>? lastErrorCode,
    Value<String?>? lastErrorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return QueuedMutationsCompanion(
      localId: localId ?? this.localId,
      userId: userId ?? this.userId,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      kind: kind ?? this.kind,
      residentId: residentId ?? this.residentId,
      shiftId: shiftId ?? this.shiftId,
      payloadJson: payloadJson ?? this.payloadJson,
      eventAt: eventAt ?? this.eventAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (clientRequestId.present) {
      map['client_request_id'] = Variable<String>(clientRequestId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (residentId.present) {
      map['resident_id'] = Variable<String>(residentId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (eventAt.present) {
      map['event_at'] = Variable<DateTime>(eventAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (lastErrorMessage.present) {
      map['last_error_message'] = Variable<String>(lastErrorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueuedMutationsCompanion(')
          ..write('localId: $localId, ')
          ..write('userId: $userId, ')
          ..write('clientRequestId: $clientRequestId, ')
          ..write('kind: $kind, ')
          ..write('residentId: $residentId, ')
          ..write('shiftId: $shiftId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('eventAt: $eventAt, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MobileOfflineDatabase extends GeneratedDatabase {
  _$MobileOfflineDatabase(QueryExecutor e) : super(e);
  $MobileOfflineDatabaseManager get managers =>
      $MobileOfflineDatabaseManager(this);
  late final $CacheEntriesTable cacheEntries = $CacheEntriesTable(this);
  late final $QueuedMutationsTable queuedMutations = $QueuedMutationsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cacheEntries,
    queuedMutations,
  ];
}

typedef $$CacheEntriesTableCreateCompanionBuilder =
    CacheEntriesCompanion Function({
      required String cacheKey,
      required String userId,
      required String json,
      required DateTime fetchedAt,
      Value<int> schemaVersion,
      Value<int> rowid,
    });
typedef $$CacheEntriesTableUpdateCompanionBuilder =
    CacheEntriesCompanion Function({
      Value<String> cacheKey,
      Value<String> userId,
      Value<String> json,
      Value<DateTime> fetchedAt,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

class $$CacheEntriesTableFilterComposer
    extends Composer<_$MobileOfflineDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheEntriesTableOrderingComposer
    extends Composer<_$MobileOfflineDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheEntriesTableAnnotationComposer
    extends Composer<_$MobileOfflineDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );
}

class $$CacheEntriesTableTableManager
    extends
        RootTableManager<
          _$MobileOfflineDatabase,
          $CacheEntriesTable,
          CacheEntry,
          $$CacheEntriesTableFilterComposer,
          $$CacheEntriesTableOrderingComposer,
          $$CacheEntriesTableAnnotationComposer,
          $$CacheEntriesTableCreateCompanionBuilder,
          $$CacheEntriesTableUpdateCompanionBuilder,
          (
            CacheEntry,
            BaseReferences<
              _$MobileOfflineDatabase,
              $CacheEntriesTable,
              CacheEntry
            >,
          ),
          CacheEntry,
          PrefetchHooks Function()
        > {
  $$CacheEntriesTableTableManager(
    _$MobileOfflineDatabase db,
    $CacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheEntriesCompanion(
                cacheKey: cacheKey,
                userId: userId,
                json: json,
                fetchedAt: fetchedAt,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String userId,
                required String json,
                required DateTime fetchedAt,
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheEntriesCompanion.insert(
                cacheKey: cacheKey,
                userId: userId,
                json: json,
                fetchedAt: fetchedAt,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$MobileOfflineDatabase,
      $CacheEntriesTable,
      CacheEntry,
      $$CacheEntriesTableFilterComposer,
      $$CacheEntriesTableOrderingComposer,
      $$CacheEntriesTableAnnotationComposer,
      $$CacheEntriesTableCreateCompanionBuilder,
      $$CacheEntriesTableUpdateCompanionBuilder,
      (
        CacheEntry,
        BaseReferences<_$MobileOfflineDatabase, $CacheEntriesTable, CacheEntry>,
      ),
      CacheEntry,
      PrefetchHooks Function()
    >;
typedef $$QueuedMutationsTableCreateCompanionBuilder =
    QueuedMutationsCompanion Function({
      required String localId,
      required String userId,
      required String clientRequestId,
      required String kind,
      required String residentId,
      required String shiftId,
      required String payloadJson,
      required DateTime eventAt,
      required String status,
      Value<int> retryCount,
      Value<String?> lastErrorCode,
      Value<String?> lastErrorMessage,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$QueuedMutationsTableUpdateCompanionBuilder =
    QueuedMutationsCompanion Function({
      Value<String> localId,
      Value<String> userId,
      Value<String> clientRequestId,
      Value<String> kind,
      Value<String> residentId,
      Value<String> shiftId,
      Value<String> payloadJson,
      Value<DateTime> eventAt,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastErrorCode,
      Value<String?> lastErrorMessage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$QueuedMutationsTableFilterComposer
    extends Composer<_$MobileOfflineDatabase, $QueuedMutationsTable> {
  $$QueuedMutationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get residentId => $composableBuilder(
    column: $table.residentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get eventAt => $composableBuilder(
    column: $table.eventAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueuedMutationsTableOrderingComposer
    extends Composer<_$MobileOfflineDatabase, $QueuedMutationsTable> {
  $$QueuedMutationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get residentId => $composableBuilder(
    column: $table.residentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get eventAt => $composableBuilder(
    column: $table.eventAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueuedMutationsTableAnnotationComposer
    extends Composer<_$MobileOfflineDatabase, $QueuedMutationsTable> {
  $$QueuedMutationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get residentId => $composableBuilder(
    column: $table.residentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get eventAt =>
      $composableBuilder(column: $table.eventAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QueuedMutationsTableTableManager
    extends
        RootTableManager<
          _$MobileOfflineDatabase,
          $QueuedMutationsTable,
          QueuedMutation,
          $$QueuedMutationsTableFilterComposer,
          $$QueuedMutationsTableOrderingComposer,
          $$QueuedMutationsTableAnnotationComposer,
          $$QueuedMutationsTableCreateCompanionBuilder,
          $$QueuedMutationsTableUpdateCompanionBuilder,
          (
            QueuedMutation,
            BaseReferences<
              _$MobileOfflineDatabase,
              $QueuedMutationsTable,
              QueuedMutation
            >,
          ),
          QueuedMutation,
          PrefetchHooks Function()
        > {
  $$QueuedMutationsTableTableManager(
    _$MobileOfflineDatabase db,
    $QueuedMutationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueuedMutationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueuedMutationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueuedMutationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> clientRequestId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> residentId = const Value.absent(),
                Value<String> shiftId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> eventAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueuedMutationsCompanion(
                localId: localId,
                userId: userId,
                clientRequestId: clientRequestId,
                kind: kind,
                residentId: residentId,
                shiftId: shiftId,
                payloadJson: payloadJson,
                eventAt: eventAt,
                status: status,
                retryCount: retryCount,
                lastErrorCode: lastErrorCode,
                lastErrorMessage: lastErrorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                required String userId,
                required String clientRequestId,
                required String kind,
                required String residentId,
                required String shiftId,
                required String payloadJson,
                required DateTime eventAt,
                required String status,
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => QueuedMutationsCompanion.insert(
                localId: localId,
                userId: userId,
                clientRequestId: clientRequestId,
                kind: kind,
                residentId: residentId,
                shiftId: shiftId,
                payloadJson: payloadJson,
                eventAt: eventAt,
                status: status,
                retryCount: retryCount,
                lastErrorCode: lastErrorCode,
                lastErrorMessage: lastErrorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueuedMutationsTableProcessedTableManager =
    ProcessedTableManager<
      _$MobileOfflineDatabase,
      $QueuedMutationsTable,
      QueuedMutation,
      $$QueuedMutationsTableFilterComposer,
      $$QueuedMutationsTableOrderingComposer,
      $$QueuedMutationsTableAnnotationComposer,
      $$QueuedMutationsTableCreateCompanionBuilder,
      $$QueuedMutationsTableUpdateCompanionBuilder,
      (
        QueuedMutation,
        BaseReferences<
          _$MobileOfflineDatabase,
          $QueuedMutationsTable,
          QueuedMutation
        >,
      ),
      QueuedMutation,
      PrefetchHooks Function()
    >;

class $MobileOfflineDatabaseManager {
  final _$MobileOfflineDatabase _db;
  $MobileOfflineDatabaseManager(this._db);
  $$CacheEntriesTableTableManager get cacheEntries =>
      $$CacheEntriesTableTableManager(_db, _db.cacheEntries);
  $$QueuedMutationsTableTableManager get queuedMutations =>
      $$QueuedMutationsTableTableManager(_db, _db.queuedMutations);
}
