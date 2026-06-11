// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ReceiptsTable extends Receipts with TableInfo<$ReceiptsTable, Receipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _s3ObjectKeyMeta = const VerificationMeta(
    's3ObjectKey',
  );
  @override
  late final GeneratedColumn<String> s3ObjectKey = GeneratedColumn<String>(
    's3_object_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeNameMeta = const VerificationMeta(
    'storeName',
  );
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
    'store_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
    'purchase_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _ocrRetryCountMeta = const VerificationMeta(
    'ocrRetryCount',
  );
  @override
  late final GeneratedColumn<int> ocrRetryCount = GeneratedColumn<int>(
    'ocr_retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastOcrAttemptAtMeta = const VerificationMeta(
    'lastOcrAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOcrAttemptAt =
      GeneratedColumn<DateTime>(
        'last_ocr_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoiceNumberMeta = const VerificationMeta(
    'invoiceNumber',
  );
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
    'invoice_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vendorAddressMeta = const VerificationMeta(
    'vendorAddress',
  );
  @override
  late final GeneratedColumn<String> vendorAddress = GeneratedColumn<String>(
    'vendor_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vendorPhoneMeta = const VerificationMeta(
    'vendorPhone',
  );
  @override
  late final GeneratedColumn<String> vendorPhone = GeneratedColumn<String>(
    'vendor_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vendorEmailMeta = const VerificationMeta(
    'vendorEmail',
  );
  @override
  late final GeneratedColumn<String> vendorEmail = GeneratedColumn<String>(
    'vendor_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vendorUrlMeta = const VerificationMeta(
    'vendorUrl',
  );
  @override
  late final GeneratedColumn<String> vendorUrl = GeneratedColumn<String>(
    'vendor_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warrantyNotesMeta = const VerificationMeta(
    'warrantyNotes',
  );
  @override
  late final GeneratedColumn<String> warrantyNotes = GeneratedColumn<String>(
    'warranty_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localImagePathMeta = const VerificationMeta(
    'localImagePath',
  );
  @override
  late final GeneratedColumn<String> localImagePath = GeneratedColumn<String>(
    'local_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    s3ObjectKey,
    storeName,
    purchaseDate,
    totalAmount,
    currency,
    status,
    ocrRetryCount,
    lastOcrAttemptAt,
    notes,
    invoiceNumber,
    vendorAddress,
    vendorPhone,
    vendorEmail,
    vendorUrl,
    warrantyNotes,
    remarks,
    createdAt,
    updatedAt,
    syncedAt,
    localImagePath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Receipt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('s3_object_key')) {
      context.handle(
        _s3ObjectKeyMeta,
        s3ObjectKey.isAcceptableOrUnknown(
          data['s3_object_key']!,
          _s3ObjectKeyMeta,
        ),
      );
    }
    if (data.containsKey('store_name')) {
      context.handle(
        _storeNameMeta,
        storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta),
      );
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('ocr_retry_count')) {
      context.handle(
        _ocrRetryCountMeta,
        ocrRetryCount.isAcceptableOrUnknown(
          data['ocr_retry_count']!,
          _ocrRetryCountMeta,
        ),
      );
    }
    if (data.containsKey('last_ocr_attempt_at')) {
      context.handle(
        _lastOcrAttemptAtMeta,
        lastOcrAttemptAt.isAcceptableOrUnknown(
          data['last_ocr_attempt_at']!,
          _lastOcrAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
        _invoiceNumberMeta,
        invoiceNumber.isAcceptableOrUnknown(
          data['invoice_number']!,
          _invoiceNumberMeta,
        ),
      );
    }
    if (data.containsKey('vendor_address')) {
      context.handle(
        _vendorAddressMeta,
        vendorAddress.isAcceptableOrUnknown(
          data['vendor_address']!,
          _vendorAddressMeta,
        ),
      );
    }
    if (data.containsKey('vendor_phone')) {
      context.handle(
        _vendorPhoneMeta,
        vendorPhone.isAcceptableOrUnknown(
          data['vendor_phone']!,
          _vendorPhoneMeta,
        ),
      );
    }
    if (data.containsKey('vendor_email')) {
      context.handle(
        _vendorEmailMeta,
        vendorEmail.isAcceptableOrUnknown(
          data['vendor_email']!,
          _vendorEmailMeta,
        ),
      );
    }
    if (data.containsKey('vendor_url')) {
      context.handle(
        _vendorUrlMeta,
        vendorUrl.isAcceptableOrUnknown(data['vendor_url']!, _vendorUrlMeta),
      );
    }
    if (data.containsKey('warranty_notes')) {
      context.handle(
        _warrantyNotesMeta,
        warrantyNotes.isAcceptableOrUnknown(
          data['warranty_notes']!,
          _warrantyNotesMeta,
        ),
      );
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
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
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('local_image_path')) {
      context.handle(
        _localImagePathMeta,
        localImagePath.isAcceptableOrUnknown(
          data['local_image_path']!,
          _localImagePathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Receipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Receipt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      s3ObjectKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}s3_object_key'],
      ),
      storeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_name'],
      ),
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchase_date'],
      ),
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      ocrRetryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ocr_retry_count'],
      )!,
      lastOcrAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_ocr_attempt_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      invoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_number'],
      ),
      vendorAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_address'],
      ),
      vendorPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_phone'],
      ),
      vendorEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_email'],
      ),
      vendorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_url'],
      ),
      warrantyNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warranty_notes'],
      ),
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      localImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_image_path'],
      ),
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }
}

class Receipt extends DataClass implements Insertable<Receipt> {
  final String id;
  final String userId;
  final String? s3ObjectKey;
  final String? storeName;
  final DateTime? purchaseDate;
  final double? totalAmount;
  final String? currency;
  final String status;
  final int ocrRetryCount;
  final DateTime? lastOcrAttemptAt;
  final String? notes;
  final String? invoiceNumber;
  final String? vendorAddress;
  final String? vendorPhone;
  final String? vendorEmail;
  final String? vendorUrl;
  final String? warrantyNotes;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final String? localImagePath;
  const Receipt({
    required this.id,
    required this.userId,
    this.s3ObjectKey,
    this.storeName,
    this.purchaseDate,
    this.totalAmount,
    this.currency,
    required this.status,
    required this.ocrRetryCount,
    this.lastOcrAttemptAt,
    this.notes,
    this.invoiceNumber,
    this.vendorAddress,
    this.vendorPhone,
    this.vendorEmail,
    this.vendorUrl,
    this.warrantyNotes,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
    this.localImagePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || s3ObjectKey != null) {
      map['s3_object_key'] = Variable<String>(s3ObjectKey);
    }
    if (!nullToAbsent || storeName != null) {
      map['store_name'] = Variable<String>(storeName);
    }
    if (!nullToAbsent || purchaseDate != null) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate);
    }
    if (!nullToAbsent || totalAmount != null) {
      map['total_amount'] = Variable<double>(totalAmount);
    }
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    map['status'] = Variable<String>(status);
    map['ocr_retry_count'] = Variable<int>(ocrRetryCount);
    if (!nullToAbsent || lastOcrAttemptAt != null) {
      map['last_ocr_attempt_at'] = Variable<DateTime>(lastOcrAttemptAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || invoiceNumber != null) {
      map['invoice_number'] = Variable<String>(invoiceNumber);
    }
    if (!nullToAbsent || vendorAddress != null) {
      map['vendor_address'] = Variable<String>(vendorAddress);
    }
    if (!nullToAbsent || vendorPhone != null) {
      map['vendor_phone'] = Variable<String>(vendorPhone);
    }
    if (!nullToAbsent || vendorEmail != null) {
      map['vendor_email'] = Variable<String>(vendorEmail);
    }
    if (!nullToAbsent || vendorUrl != null) {
      map['vendor_url'] = Variable<String>(vendorUrl);
    }
    if (!nullToAbsent || warrantyNotes != null) {
      map['warranty_notes'] = Variable<String>(warrantyNotes);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || localImagePath != null) {
      map['local_image_path'] = Variable<String>(localImagePath);
    }
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      id: Value(id),
      userId: Value(userId),
      s3ObjectKey: s3ObjectKey == null && nullToAbsent
          ? const Value.absent()
          : Value(s3ObjectKey),
      storeName: storeName == null && nullToAbsent
          ? const Value.absent()
          : Value(storeName),
      purchaseDate: purchaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseDate),
      totalAmount: totalAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(totalAmount),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      status: Value(status),
      ocrRetryCount: Value(ocrRetryCount),
      lastOcrAttemptAt: lastOcrAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOcrAttemptAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      invoiceNumber: invoiceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceNumber),
      vendorAddress: vendorAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(vendorAddress),
      vendorPhone: vendorPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(vendorPhone),
      vendorEmail: vendorEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(vendorEmail),
      vendorUrl: vendorUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(vendorUrl),
      warrantyNotes: warrantyNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyNotes),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      localImagePath: localImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localImagePath),
    );
  }

  factory Receipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Receipt(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      s3ObjectKey: serializer.fromJson<String?>(json['s3ObjectKey']),
      storeName: serializer.fromJson<String?>(json['storeName']),
      purchaseDate: serializer.fromJson<DateTime?>(json['purchaseDate']),
      totalAmount: serializer.fromJson<double?>(json['totalAmount']),
      currency: serializer.fromJson<String?>(json['currency']),
      status: serializer.fromJson<String>(json['status']),
      ocrRetryCount: serializer.fromJson<int>(json['ocrRetryCount']),
      lastOcrAttemptAt: serializer.fromJson<DateTime?>(
        json['lastOcrAttemptAt'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      invoiceNumber: serializer.fromJson<String?>(json['invoiceNumber']),
      vendorAddress: serializer.fromJson<String?>(json['vendorAddress']),
      vendorPhone: serializer.fromJson<String?>(json['vendorPhone']),
      vendorEmail: serializer.fromJson<String?>(json['vendorEmail']),
      vendorUrl: serializer.fromJson<String?>(json['vendorUrl']),
      warrantyNotes: serializer.fromJson<String?>(json['warrantyNotes']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      localImagePath: serializer.fromJson<String?>(json['localImagePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      's3ObjectKey': serializer.toJson<String?>(s3ObjectKey),
      'storeName': serializer.toJson<String?>(storeName),
      'purchaseDate': serializer.toJson<DateTime?>(purchaseDate),
      'totalAmount': serializer.toJson<double?>(totalAmount),
      'currency': serializer.toJson<String?>(currency),
      'status': serializer.toJson<String>(status),
      'ocrRetryCount': serializer.toJson<int>(ocrRetryCount),
      'lastOcrAttemptAt': serializer.toJson<DateTime?>(lastOcrAttemptAt),
      'notes': serializer.toJson<String?>(notes),
      'invoiceNumber': serializer.toJson<String?>(invoiceNumber),
      'vendorAddress': serializer.toJson<String?>(vendorAddress),
      'vendorPhone': serializer.toJson<String?>(vendorPhone),
      'vendorEmail': serializer.toJson<String?>(vendorEmail),
      'vendorUrl': serializer.toJson<String?>(vendorUrl),
      'warrantyNotes': serializer.toJson<String?>(warrantyNotes),
      'remarks': serializer.toJson<String?>(remarks),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'localImagePath': serializer.toJson<String?>(localImagePath),
    };
  }

  Receipt copyWith({
    String? id,
    String? userId,
    Value<String?> s3ObjectKey = const Value.absent(),
    Value<String?> storeName = const Value.absent(),
    Value<DateTime?> purchaseDate = const Value.absent(),
    Value<double?> totalAmount = const Value.absent(),
    Value<String?> currency = const Value.absent(),
    String? status,
    int? ocrRetryCount,
    Value<DateTime?> lastOcrAttemptAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> invoiceNumber = const Value.absent(),
    Value<String?> vendorAddress = const Value.absent(),
    Value<String?> vendorPhone = const Value.absent(),
    Value<String?> vendorEmail = const Value.absent(),
    Value<String?> vendorUrl = const Value.absent(),
    Value<String?> warrantyNotes = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<String?> localImagePath = const Value.absent(),
  }) => Receipt(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    s3ObjectKey: s3ObjectKey.present ? s3ObjectKey.value : this.s3ObjectKey,
    storeName: storeName.present ? storeName.value : this.storeName,
    purchaseDate: purchaseDate.present ? purchaseDate.value : this.purchaseDate,
    totalAmount: totalAmount.present ? totalAmount.value : this.totalAmount,
    currency: currency.present ? currency.value : this.currency,
    status: status ?? this.status,
    ocrRetryCount: ocrRetryCount ?? this.ocrRetryCount,
    lastOcrAttemptAt: lastOcrAttemptAt.present
        ? lastOcrAttemptAt.value
        : this.lastOcrAttemptAt,
    notes: notes.present ? notes.value : this.notes,
    invoiceNumber: invoiceNumber.present
        ? invoiceNumber.value
        : this.invoiceNumber,
    vendorAddress: vendorAddress.present
        ? vendorAddress.value
        : this.vendorAddress,
    vendorPhone: vendorPhone.present ? vendorPhone.value : this.vendorPhone,
    vendorEmail: vendorEmail.present ? vendorEmail.value : this.vendorEmail,
    vendorUrl: vendorUrl.present ? vendorUrl.value : this.vendorUrl,
    warrantyNotes: warrantyNotes.present
        ? warrantyNotes.value
        : this.warrantyNotes,
    remarks: remarks.present ? remarks.value : this.remarks,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    localImagePath: localImagePath.present
        ? localImagePath.value
        : this.localImagePath,
  );
  Receipt copyWithCompanion(ReceiptsCompanion data) {
    return Receipt(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      s3ObjectKey: data.s3ObjectKey.present
          ? data.s3ObjectKey.value
          : this.s3ObjectKey,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      currency: data.currency.present ? data.currency.value : this.currency,
      status: data.status.present ? data.status.value : this.status,
      ocrRetryCount: data.ocrRetryCount.present
          ? data.ocrRetryCount.value
          : this.ocrRetryCount,
      lastOcrAttemptAt: data.lastOcrAttemptAt.present
          ? data.lastOcrAttemptAt.value
          : this.lastOcrAttemptAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      vendorAddress: data.vendorAddress.present
          ? data.vendorAddress.value
          : this.vendorAddress,
      vendorPhone: data.vendorPhone.present
          ? data.vendorPhone.value
          : this.vendorPhone,
      vendorEmail: data.vendorEmail.present
          ? data.vendorEmail.value
          : this.vendorEmail,
      vendorUrl: data.vendorUrl.present ? data.vendorUrl.value : this.vendorUrl,
      warrantyNotes: data.warrantyNotes.present
          ? data.warrantyNotes.value
          : this.warrantyNotes,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      localImagePath: data.localImagePath.present
          ? data.localImagePath.value
          : this.localImagePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Receipt(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('s3ObjectKey: $s3ObjectKey, ')
          ..write('storeName: $storeName, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('currency: $currency, ')
          ..write('status: $status, ')
          ..write('ocrRetryCount: $ocrRetryCount, ')
          ..write('lastOcrAttemptAt: $lastOcrAttemptAt, ')
          ..write('notes: $notes, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('vendorAddress: $vendorAddress, ')
          ..write('vendorPhone: $vendorPhone, ')
          ..write('vendorEmail: $vendorEmail, ')
          ..write('vendorUrl: $vendorUrl, ')
          ..write('warrantyNotes: $warrantyNotes, ')
          ..write('remarks: $remarks, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('localImagePath: $localImagePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    s3ObjectKey,
    storeName,
    purchaseDate,
    totalAmount,
    currency,
    status,
    ocrRetryCount,
    lastOcrAttemptAt,
    notes,
    invoiceNumber,
    vendorAddress,
    vendorPhone,
    vendorEmail,
    vendorUrl,
    warrantyNotes,
    remarks,
    createdAt,
    updatedAt,
    syncedAt,
    localImagePath,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Receipt &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.s3ObjectKey == this.s3ObjectKey &&
          other.storeName == this.storeName &&
          other.purchaseDate == this.purchaseDate &&
          other.totalAmount == this.totalAmount &&
          other.currency == this.currency &&
          other.status == this.status &&
          other.ocrRetryCount == this.ocrRetryCount &&
          other.lastOcrAttemptAt == this.lastOcrAttemptAt &&
          other.notes == this.notes &&
          other.invoiceNumber == this.invoiceNumber &&
          other.vendorAddress == this.vendorAddress &&
          other.vendorPhone == this.vendorPhone &&
          other.vendorEmail == this.vendorEmail &&
          other.vendorUrl == this.vendorUrl &&
          other.warrantyNotes == this.warrantyNotes &&
          other.remarks == this.remarks &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.localImagePath == this.localImagePath);
}

class ReceiptsCompanion extends UpdateCompanion<Receipt> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> s3ObjectKey;
  final Value<String?> storeName;
  final Value<DateTime?> purchaseDate;
  final Value<double?> totalAmount;
  final Value<String?> currency;
  final Value<String> status;
  final Value<int> ocrRetryCount;
  final Value<DateTime?> lastOcrAttemptAt;
  final Value<String?> notes;
  final Value<String?> invoiceNumber;
  final Value<String?> vendorAddress;
  final Value<String?> vendorPhone;
  final Value<String?> vendorEmail;
  final Value<String?> vendorUrl;
  final Value<String?> warrantyNotes;
  final Value<String?> remarks;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<String?> localImagePath;
  final Value<int> rowid;
  const ReceiptsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.s3ObjectKey = const Value.absent(),
    this.storeName = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.status = const Value.absent(),
    this.ocrRetryCount = const Value.absent(),
    this.lastOcrAttemptAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.vendorAddress = const Value.absent(),
    this.vendorPhone = const Value.absent(),
    this.vendorEmail = const Value.absent(),
    this.vendorUrl = const Value.absent(),
    this.warrantyNotes = const Value.absent(),
    this.remarks = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.localImagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    required String id,
    required String userId,
    this.s3ObjectKey = const Value.absent(),
    this.storeName = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.currency = const Value.absent(),
    required String status,
    this.ocrRetryCount = const Value.absent(),
    this.lastOcrAttemptAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.vendorAddress = const Value.absent(),
    this.vendorPhone = const Value.absent(),
    this.vendorEmail = const Value.absent(),
    this.vendorUrl = const Value.absent(),
    this.warrantyNotes = const Value.absent(),
    this.remarks = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.localImagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Receipt> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? s3ObjectKey,
    Expression<String>? storeName,
    Expression<DateTime>? purchaseDate,
    Expression<double>? totalAmount,
    Expression<String>? currency,
    Expression<String>? status,
    Expression<int>? ocrRetryCount,
    Expression<DateTime>? lastOcrAttemptAt,
    Expression<String>? notes,
    Expression<String>? invoiceNumber,
    Expression<String>? vendorAddress,
    Expression<String>? vendorPhone,
    Expression<String>? vendorEmail,
    Expression<String>? vendorUrl,
    Expression<String>? warrantyNotes,
    Expression<String>? remarks,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<String>? localImagePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (s3ObjectKey != null) 's3_object_key': s3ObjectKey,
      if (storeName != null) 'store_name': storeName,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (currency != null) 'currency': currency,
      if (status != null) 'status': status,
      if (ocrRetryCount != null) 'ocr_retry_count': ocrRetryCount,
      if (lastOcrAttemptAt != null) 'last_ocr_attempt_at': lastOcrAttemptAt,
      if (notes != null) 'notes': notes,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (vendorAddress != null) 'vendor_address': vendorAddress,
      if (vendorPhone != null) 'vendor_phone': vendorPhone,
      if (vendorEmail != null) 'vendor_email': vendorEmail,
      if (vendorUrl != null) 'vendor_url': vendorUrl,
      if (warrantyNotes != null) 'warranty_notes': warrantyNotes,
      if (remarks != null) 'remarks': remarks,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (localImagePath != null) 'local_image_path': localImagePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? s3ObjectKey,
    Value<String?>? storeName,
    Value<DateTime?>? purchaseDate,
    Value<double?>? totalAmount,
    Value<String?>? currency,
    Value<String>? status,
    Value<int>? ocrRetryCount,
    Value<DateTime?>? lastOcrAttemptAt,
    Value<String?>? notes,
    Value<String?>? invoiceNumber,
    Value<String?>? vendorAddress,
    Value<String?>? vendorPhone,
    Value<String?>? vendorEmail,
    Value<String?>? vendorUrl,
    Value<String?>? warrantyNotes,
    Value<String?>? remarks,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<String?>? localImagePath,
    Value<int>? rowid,
  }) {
    return ReceiptsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      s3ObjectKey: s3ObjectKey ?? this.s3ObjectKey,
      storeName: storeName ?? this.storeName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      ocrRetryCount: ocrRetryCount ?? this.ocrRetryCount,
      lastOcrAttemptAt: lastOcrAttemptAt ?? this.lastOcrAttemptAt,
      notes: notes ?? this.notes,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      vendorAddress: vendorAddress ?? this.vendorAddress,
      vendorPhone: vendorPhone ?? this.vendorPhone,
      vendorEmail: vendorEmail ?? this.vendorEmail,
      vendorUrl: vendorUrl ?? this.vendorUrl,
      warrantyNotes: warrantyNotes ?? this.warrantyNotes,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      localImagePath: localImagePath ?? this.localImagePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (s3ObjectKey.present) {
      map['s3_object_key'] = Variable<String>(s3ObjectKey.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (ocrRetryCount.present) {
      map['ocr_retry_count'] = Variable<int>(ocrRetryCount.value);
    }
    if (lastOcrAttemptAt.present) {
      map['last_ocr_attempt_at'] = Variable<DateTime>(lastOcrAttemptAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (vendorAddress.present) {
      map['vendor_address'] = Variable<String>(vendorAddress.value);
    }
    if (vendorPhone.present) {
      map['vendor_phone'] = Variable<String>(vendorPhone.value);
    }
    if (vendorEmail.present) {
      map['vendor_email'] = Variable<String>(vendorEmail.value);
    }
    if (vendorUrl.present) {
      map['vendor_url'] = Variable<String>(vendorUrl.value);
    }
    if (warrantyNotes.present) {
      map['warranty_notes'] = Variable<String>(warrantyNotes.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (localImagePath.present) {
      map['local_image_path'] = Variable<String>(localImagePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('s3ObjectKey: $s3ObjectKey, ')
          ..write('storeName: $storeName, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('currency: $currency, ')
          ..write('status: $status, ')
          ..write('ocrRetryCount: $ocrRetryCount, ')
          ..write('lastOcrAttemptAt: $lastOcrAttemptAt, ')
          ..write('notes: $notes, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('vendorAddress: $vendorAddress, ')
          ..write('vendorPhone: $vendorPhone, ')
          ..write('vendorEmail: $vendorEmail, ')
          ..write('vendorUrl: $vendorUrl, ')
          ..write('warrantyNotes: $warrantyNotes, ')
          ..write('remarks: $remarks, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptLineItemsTable extends ReceiptLineItems
    with TableInfo<$ReceiptLineItemsTable, ReceiptLineItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptLineItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES receipts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _rowIndexMeta = const VerificationMeta(
    'rowIndex',
  );
  @override
  late final GeneratedColumn<int> rowIndex = GeneratedColumn<int>(
    'row_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _productCodeMeta = const VerificationMeta(
    'productCode',
  );
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
    'product_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemDescriptionMeta = const VerificationMeta(
    'itemDescription',
  );
  @override
  late final GeneratedColumn<String> itemDescription = GeneratedColumn<String>(
    'item_description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productCategoryMeta = const VerificationMeta(
    'productCategory',
  );
  @override
  late final GeneratedColumn<String> productCategory = GeneratedColumn<String>(
    'product_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productImageUrlMeta = const VerificationMeta(
    'productImageUrl',
  );
  @override
  late final GeneratedColumn<String> productImageUrl = GeneratedColumn<String>(
    'product_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warrantyPeriodMonthsMeta =
      const VerificationMeta('warrantyPeriodMonths');
  @override
  late final GeneratedColumn<int> warrantyPeriodMonths = GeneratedColumn<int>(
    'warranty_period_months',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warrantyExpiryDateMeta =
      const VerificationMeta('warrantyExpiryDate');
  @override
  late final GeneratedColumn<DateTime> warrantyExpiryDate =
      GeneratedColumn<DateTime>(
        'warranty_expiry_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _returnPeriodDaysMeta = const VerificationMeta(
    'returnPeriodDays',
  );
  @override
  late final GeneratedColumn<int> returnPeriodDays = GeneratedColumn<int>(
    'return_period_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _returnExpiryDateMeta = const VerificationMeta(
    'returnExpiryDate',
  );
  @override
  late final GeneratedColumn<DateTime> returnExpiryDate =
      GeneratedColumn<DateTime>(
        'return_expiry_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _warrantyLeadDaysOverrideMeta =
      const VerificationMeta('warrantyLeadDaysOverride');
  @override
  late final GeneratedColumn<int> warrantyLeadDaysOverride =
      GeneratedColumn<int>(
        'warranty_lead_days_override',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _returnLeadDaysOverrideMeta =
      const VerificationMeta('returnLeadDaysOverride');
  @override
  late final GeneratedColumn<int> returnLeadDaysOverride = GeneratedColumn<int>(
    'return_lead_days_override',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warrantyReminderEnabledMeta =
      const VerificationMeta('warrantyReminderEnabled');
  @override
  late final GeneratedColumn<bool> warrantyReminderEnabled =
      GeneratedColumn<bool>(
        'warranty_reminder_enabled',
        aliasedName,
        true,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("warranty_reminder_enabled" IN (0, 1))',
        ),
      );
  static const VerificationMeta _returnReminderEnabledMeta =
      const VerificationMeta('returnReminderEnabled');
  @override
  late final GeneratedColumn<bool> returnReminderEnabled =
      GeneratedColumn<bool>(
        'return_reminder_enabled',
        aliasedName,
        true,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("return_reminder_enabled" IN (0, 1))',
        ),
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACTIVE'),
  );
  static const VerificationMeta _replacementForIdMeta = const VerificationMeta(
    'replacementForId',
  );
  @override
  late final GeneratedColumn<String> replacementForId = GeneratedColumn<String>(
    'replacement_for_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replacedByIdMeta = const VerificationMeta(
    'replacedById',
  );
  @override
  late final GeneratedColumn<String> replacedById = GeneratedColumn<String>(
    'replaced_by_id',
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
    id,
    receiptId,
    rowIndex,
    productCode,
    itemDescription,
    unitPrice,
    productName,
    productCategory,
    productImageUrl,
    warrantyPeriodMonths,
    warrantyExpiryDate,
    returnPeriodDays,
    returnExpiryDate,
    warrantyLeadDaysOverride,
    returnLeadDaysOverride,
    warrantyReminderEnabled,
    returnReminderEnabled,
    status,
    replacementForId,
    replacedById,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipt_line_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceiptLineItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('row_index')) {
      context.handle(
        _rowIndexMeta,
        rowIndex.isAcceptableOrUnknown(data['row_index']!, _rowIndexMeta),
      );
    }
    if (data.containsKey('product_code')) {
      context.handle(
        _productCodeMeta,
        productCode.isAcceptableOrUnknown(
          data['product_code']!,
          _productCodeMeta,
        ),
      );
    }
    if (data.containsKey('item_description')) {
      context.handle(
        _itemDescriptionMeta,
        itemDescription.isAcceptableOrUnknown(
          data['item_description']!,
          _itemDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    }
    if (data.containsKey('product_category')) {
      context.handle(
        _productCategoryMeta,
        productCategory.isAcceptableOrUnknown(
          data['product_category']!,
          _productCategoryMeta,
        ),
      );
    }
    if (data.containsKey('product_image_url')) {
      context.handle(
        _productImageUrlMeta,
        productImageUrl.isAcceptableOrUnknown(
          data['product_image_url']!,
          _productImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('warranty_period_months')) {
      context.handle(
        _warrantyPeriodMonthsMeta,
        warrantyPeriodMonths.isAcceptableOrUnknown(
          data['warranty_period_months']!,
          _warrantyPeriodMonthsMeta,
        ),
      );
    }
    if (data.containsKey('warranty_expiry_date')) {
      context.handle(
        _warrantyExpiryDateMeta,
        warrantyExpiryDate.isAcceptableOrUnknown(
          data['warranty_expiry_date']!,
          _warrantyExpiryDateMeta,
        ),
      );
    }
    if (data.containsKey('return_period_days')) {
      context.handle(
        _returnPeriodDaysMeta,
        returnPeriodDays.isAcceptableOrUnknown(
          data['return_period_days']!,
          _returnPeriodDaysMeta,
        ),
      );
    }
    if (data.containsKey('return_expiry_date')) {
      context.handle(
        _returnExpiryDateMeta,
        returnExpiryDate.isAcceptableOrUnknown(
          data['return_expiry_date']!,
          _returnExpiryDateMeta,
        ),
      );
    }
    if (data.containsKey('warranty_lead_days_override')) {
      context.handle(
        _warrantyLeadDaysOverrideMeta,
        warrantyLeadDaysOverride.isAcceptableOrUnknown(
          data['warranty_lead_days_override']!,
          _warrantyLeadDaysOverrideMeta,
        ),
      );
    }
    if (data.containsKey('return_lead_days_override')) {
      context.handle(
        _returnLeadDaysOverrideMeta,
        returnLeadDaysOverride.isAcceptableOrUnknown(
          data['return_lead_days_override']!,
          _returnLeadDaysOverrideMeta,
        ),
      );
    }
    if (data.containsKey('warranty_reminder_enabled')) {
      context.handle(
        _warrantyReminderEnabledMeta,
        warrantyReminderEnabled.isAcceptableOrUnknown(
          data['warranty_reminder_enabled']!,
          _warrantyReminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('return_reminder_enabled')) {
      context.handle(
        _returnReminderEnabledMeta,
        returnReminderEnabled.isAcceptableOrUnknown(
          data['return_reminder_enabled']!,
          _returnReminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('replacement_for_id')) {
      context.handle(
        _replacementForIdMeta,
        replacementForId.isAcceptableOrUnknown(
          data['replacement_for_id']!,
          _replacementForIdMeta,
        ),
      );
    }
    if (data.containsKey('replaced_by_id')) {
      context.handle(
        _replacedByIdMeta,
        replacedById.isAcceptableOrUnknown(
          data['replaced_by_id']!,
          _replacedByIdMeta,
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReceiptLineItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptLineItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      )!,
      rowIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_index'],
      )!,
      productCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_code'],
      ),
      itemDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_description'],
      ),
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      ),
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      ),
      productCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_category'],
      ),
      productImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_image_url'],
      ),
      warrantyPeriodMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warranty_period_months'],
      ),
      warrantyExpiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}warranty_expiry_date'],
      ),
      returnPeriodDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}return_period_days'],
      ),
      returnExpiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}return_expiry_date'],
      ),
      warrantyLeadDaysOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warranty_lead_days_override'],
      ),
      returnLeadDaysOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}return_lead_days_override'],
      ),
      warrantyReminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}warranty_reminder_enabled'],
      ),
      returnReminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}return_reminder_enabled'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      replacementForId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}replacement_for_id'],
      ),
      replacedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}replaced_by_id'],
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
  $ReceiptLineItemsTable createAlias(String alias) {
    return $ReceiptLineItemsTable(attachedDatabase, alias);
  }
}

class ReceiptLineItem extends DataClass implements Insertable<ReceiptLineItem> {
  final String id;
  final String receiptId;
  final int rowIndex;
  final String? productCode;
  final String? itemDescription;
  final double? unitPrice;
  final String? productName;
  final String? productCategory;
  final String? productImageUrl;
  final int? warrantyPeriodMonths;
  final DateTime? warrantyExpiryDate;
  final int? returnPeriodDays;
  final DateTime? returnExpiryDate;
  final int? warrantyLeadDaysOverride;
  final int? returnLeadDaysOverride;
  final bool? warrantyReminderEnabled;
  final bool? returnReminderEnabled;
  final String status;
  final String? replacementForId;
  final String? replacedById;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ReceiptLineItem({
    required this.id,
    required this.receiptId,
    required this.rowIndex,
    this.productCode,
    this.itemDescription,
    this.unitPrice,
    this.productName,
    this.productCategory,
    this.productImageUrl,
    this.warrantyPeriodMonths,
    this.warrantyExpiryDate,
    this.returnPeriodDays,
    this.returnExpiryDate,
    this.warrantyLeadDaysOverride,
    this.returnLeadDaysOverride,
    this.warrantyReminderEnabled,
    this.returnReminderEnabled,
    required this.status,
    this.replacementForId,
    this.replacedById,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['receipt_id'] = Variable<String>(receiptId);
    map['row_index'] = Variable<int>(rowIndex);
    if (!nullToAbsent || productCode != null) {
      map['product_code'] = Variable<String>(productCode);
    }
    if (!nullToAbsent || itemDescription != null) {
      map['item_description'] = Variable<String>(itemDescription);
    }
    if (!nullToAbsent || unitPrice != null) {
      map['unit_price'] = Variable<double>(unitPrice);
    }
    if (!nullToAbsent || productName != null) {
      map['product_name'] = Variable<String>(productName);
    }
    if (!nullToAbsent || productCategory != null) {
      map['product_category'] = Variable<String>(productCategory);
    }
    if (!nullToAbsent || productImageUrl != null) {
      map['product_image_url'] = Variable<String>(productImageUrl);
    }
    if (!nullToAbsent || warrantyPeriodMonths != null) {
      map['warranty_period_months'] = Variable<int>(warrantyPeriodMonths);
    }
    if (!nullToAbsent || warrantyExpiryDate != null) {
      map['warranty_expiry_date'] = Variable<DateTime>(warrantyExpiryDate);
    }
    if (!nullToAbsent || returnPeriodDays != null) {
      map['return_period_days'] = Variable<int>(returnPeriodDays);
    }
    if (!nullToAbsent || returnExpiryDate != null) {
      map['return_expiry_date'] = Variable<DateTime>(returnExpiryDate);
    }
    if (!nullToAbsent || warrantyLeadDaysOverride != null) {
      map['warranty_lead_days_override'] = Variable<int>(
        warrantyLeadDaysOverride,
      );
    }
    if (!nullToAbsent || returnLeadDaysOverride != null) {
      map['return_lead_days_override'] = Variable<int>(returnLeadDaysOverride);
    }
    if (!nullToAbsent || warrantyReminderEnabled != null) {
      map['warranty_reminder_enabled'] = Variable<bool>(
        warrantyReminderEnabled,
      );
    }
    if (!nullToAbsent || returnReminderEnabled != null) {
      map['return_reminder_enabled'] = Variable<bool>(returnReminderEnabled);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || replacementForId != null) {
      map['replacement_for_id'] = Variable<String>(replacementForId);
    }
    if (!nullToAbsent || replacedById != null) {
      map['replaced_by_id'] = Variable<String>(replacedById);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReceiptLineItemsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptLineItemsCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      rowIndex: Value(rowIndex),
      productCode: productCode == null && nullToAbsent
          ? const Value.absent()
          : Value(productCode),
      itemDescription: itemDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(itemDescription),
      unitPrice: unitPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPrice),
      productName: productName == null && nullToAbsent
          ? const Value.absent()
          : Value(productName),
      productCategory: productCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(productCategory),
      productImageUrl: productImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(productImageUrl),
      warrantyPeriodMonths: warrantyPeriodMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyPeriodMonths),
      warrantyExpiryDate: warrantyExpiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyExpiryDate),
      returnPeriodDays: returnPeriodDays == null && nullToAbsent
          ? const Value.absent()
          : Value(returnPeriodDays),
      returnExpiryDate: returnExpiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(returnExpiryDate),
      warrantyLeadDaysOverride: warrantyLeadDaysOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyLeadDaysOverride),
      returnLeadDaysOverride: returnLeadDaysOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(returnLeadDaysOverride),
      warrantyReminderEnabled: warrantyReminderEnabled == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyReminderEnabled),
      returnReminderEnabled: returnReminderEnabled == null && nullToAbsent
          ? const Value.absent()
          : Value(returnReminderEnabled),
      status: Value(status),
      replacementForId: replacementForId == null && nullToAbsent
          ? const Value.absent()
          : Value(replacementForId),
      replacedById: replacedById == null && nullToAbsent
          ? const Value.absent()
          : Value(replacedById),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReceiptLineItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptLineItem(
      id: serializer.fromJson<String>(json['id']),
      receiptId: serializer.fromJson<String>(json['receiptId']),
      rowIndex: serializer.fromJson<int>(json['rowIndex']),
      productCode: serializer.fromJson<String?>(json['productCode']),
      itemDescription: serializer.fromJson<String?>(json['itemDescription']),
      unitPrice: serializer.fromJson<double?>(json['unitPrice']),
      productName: serializer.fromJson<String?>(json['productName']),
      productCategory: serializer.fromJson<String?>(json['productCategory']),
      productImageUrl: serializer.fromJson<String?>(json['productImageUrl']),
      warrantyPeriodMonths: serializer.fromJson<int?>(
        json['warrantyPeriodMonths'],
      ),
      warrantyExpiryDate: serializer.fromJson<DateTime?>(
        json['warrantyExpiryDate'],
      ),
      returnPeriodDays: serializer.fromJson<int?>(json['returnPeriodDays']),
      returnExpiryDate: serializer.fromJson<DateTime?>(
        json['returnExpiryDate'],
      ),
      warrantyLeadDaysOverride: serializer.fromJson<int?>(
        json['warrantyLeadDaysOverride'],
      ),
      returnLeadDaysOverride: serializer.fromJson<int?>(
        json['returnLeadDaysOverride'],
      ),
      warrantyReminderEnabled: serializer.fromJson<bool?>(
        json['warrantyReminderEnabled'],
      ),
      returnReminderEnabled: serializer.fromJson<bool?>(
        json['returnReminderEnabled'],
      ),
      status: serializer.fromJson<String>(json['status']),
      replacementForId: serializer.fromJson<String?>(json['replacementForId']),
      replacedById: serializer.fromJson<String?>(json['replacedById']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'receiptId': serializer.toJson<String>(receiptId),
      'rowIndex': serializer.toJson<int>(rowIndex),
      'productCode': serializer.toJson<String?>(productCode),
      'itemDescription': serializer.toJson<String?>(itemDescription),
      'unitPrice': serializer.toJson<double?>(unitPrice),
      'productName': serializer.toJson<String?>(productName),
      'productCategory': serializer.toJson<String?>(productCategory),
      'productImageUrl': serializer.toJson<String?>(productImageUrl),
      'warrantyPeriodMonths': serializer.toJson<int?>(warrantyPeriodMonths),
      'warrantyExpiryDate': serializer.toJson<DateTime?>(warrantyExpiryDate),
      'returnPeriodDays': serializer.toJson<int?>(returnPeriodDays),
      'returnExpiryDate': serializer.toJson<DateTime?>(returnExpiryDate),
      'warrantyLeadDaysOverride': serializer.toJson<int?>(
        warrantyLeadDaysOverride,
      ),
      'returnLeadDaysOverride': serializer.toJson<int?>(returnLeadDaysOverride),
      'warrantyReminderEnabled': serializer.toJson<bool?>(
        warrantyReminderEnabled,
      ),
      'returnReminderEnabled': serializer.toJson<bool?>(returnReminderEnabled),
      'status': serializer.toJson<String>(status),
      'replacementForId': serializer.toJson<String?>(replacementForId),
      'replacedById': serializer.toJson<String?>(replacedById),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReceiptLineItem copyWith({
    String? id,
    String? receiptId,
    int? rowIndex,
    Value<String?> productCode = const Value.absent(),
    Value<String?> itemDescription = const Value.absent(),
    Value<double?> unitPrice = const Value.absent(),
    Value<String?> productName = const Value.absent(),
    Value<String?> productCategory = const Value.absent(),
    Value<String?> productImageUrl = const Value.absent(),
    Value<int?> warrantyPeriodMonths = const Value.absent(),
    Value<DateTime?> warrantyExpiryDate = const Value.absent(),
    Value<int?> returnPeriodDays = const Value.absent(),
    Value<DateTime?> returnExpiryDate = const Value.absent(),
    Value<int?> warrantyLeadDaysOverride = const Value.absent(),
    Value<int?> returnLeadDaysOverride = const Value.absent(),
    Value<bool?> warrantyReminderEnabled = const Value.absent(),
    Value<bool?> returnReminderEnabled = const Value.absent(),
    String? status,
    Value<String?> replacementForId = const Value.absent(),
    Value<String?> replacedById = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ReceiptLineItem(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    rowIndex: rowIndex ?? this.rowIndex,
    productCode: productCode.present ? productCode.value : this.productCode,
    itemDescription: itemDescription.present
        ? itemDescription.value
        : this.itemDescription,
    unitPrice: unitPrice.present ? unitPrice.value : this.unitPrice,
    productName: productName.present ? productName.value : this.productName,
    productCategory: productCategory.present
        ? productCategory.value
        : this.productCategory,
    productImageUrl: productImageUrl.present
        ? productImageUrl.value
        : this.productImageUrl,
    warrantyPeriodMonths: warrantyPeriodMonths.present
        ? warrantyPeriodMonths.value
        : this.warrantyPeriodMonths,
    warrantyExpiryDate: warrantyExpiryDate.present
        ? warrantyExpiryDate.value
        : this.warrantyExpiryDate,
    returnPeriodDays: returnPeriodDays.present
        ? returnPeriodDays.value
        : this.returnPeriodDays,
    returnExpiryDate: returnExpiryDate.present
        ? returnExpiryDate.value
        : this.returnExpiryDate,
    warrantyLeadDaysOverride: warrantyLeadDaysOverride.present
        ? warrantyLeadDaysOverride.value
        : this.warrantyLeadDaysOverride,
    returnLeadDaysOverride: returnLeadDaysOverride.present
        ? returnLeadDaysOverride.value
        : this.returnLeadDaysOverride,
    warrantyReminderEnabled: warrantyReminderEnabled.present
        ? warrantyReminderEnabled.value
        : this.warrantyReminderEnabled,
    returnReminderEnabled: returnReminderEnabled.present
        ? returnReminderEnabled.value
        : this.returnReminderEnabled,
    status: status ?? this.status,
    replacementForId: replacementForId.present
        ? replacementForId.value
        : this.replacementForId,
    replacedById: replacedById.present ? replacedById.value : this.replacedById,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReceiptLineItem copyWithCompanion(ReceiptLineItemsCompanion data) {
    return ReceiptLineItem(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      rowIndex: data.rowIndex.present ? data.rowIndex.value : this.rowIndex,
      productCode: data.productCode.present
          ? data.productCode.value
          : this.productCode,
      itemDescription: data.itemDescription.present
          ? data.itemDescription.value
          : this.itemDescription,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      productCategory: data.productCategory.present
          ? data.productCategory.value
          : this.productCategory,
      productImageUrl: data.productImageUrl.present
          ? data.productImageUrl.value
          : this.productImageUrl,
      warrantyPeriodMonths: data.warrantyPeriodMonths.present
          ? data.warrantyPeriodMonths.value
          : this.warrantyPeriodMonths,
      warrantyExpiryDate: data.warrantyExpiryDate.present
          ? data.warrantyExpiryDate.value
          : this.warrantyExpiryDate,
      returnPeriodDays: data.returnPeriodDays.present
          ? data.returnPeriodDays.value
          : this.returnPeriodDays,
      returnExpiryDate: data.returnExpiryDate.present
          ? data.returnExpiryDate.value
          : this.returnExpiryDate,
      warrantyLeadDaysOverride: data.warrantyLeadDaysOverride.present
          ? data.warrantyLeadDaysOverride.value
          : this.warrantyLeadDaysOverride,
      returnLeadDaysOverride: data.returnLeadDaysOverride.present
          ? data.returnLeadDaysOverride.value
          : this.returnLeadDaysOverride,
      warrantyReminderEnabled: data.warrantyReminderEnabled.present
          ? data.warrantyReminderEnabled.value
          : this.warrantyReminderEnabled,
      returnReminderEnabled: data.returnReminderEnabled.present
          ? data.returnReminderEnabled.value
          : this.returnReminderEnabled,
      status: data.status.present ? data.status.value : this.status,
      replacementForId: data.replacementForId.present
          ? data.replacementForId.value
          : this.replacementForId,
      replacedById: data.replacedById.present
          ? data.replacedById.value
          : this.replacedById,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptLineItem(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('rowIndex: $rowIndex, ')
          ..write('productCode: $productCode, ')
          ..write('itemDescription: $itemDescription, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('productName: $productName, ')
          ..write('productCategory: $productCategory, ')
          ..write('productImageUrl: $productImageUrl, ')
          ..write('warrantyPeriodMonths: $warrantyPeriodMonths, ')
          ..write('warrantyExpiryDate: $warrantyExpiryDate, ')
          ..write('returnPeriodDays: $returnPeriodDays, ')
          ..write('returnExpiryDate: $returnExpiryDate, ')
          ..write('warrantyLeadDaysOverride: $warrantyLeadDaysOverride, ')
          ..write('returnLeadDaysOverride: $returnLeadDaysOverride, ')
          ..write('warrantyReminderEnabled: $warrantyReminderEnabled, ')
          ..write('returnReminderEnabled: $returnReminderEnabled, ')
          ..write('status: $status, ')
          ..write('replacementForId: $replacementForId, ')
          ..write('replacedById: $replacedById, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    receiptId,
    rowIndex,
    productCode,
    itemDescription,
    unitPrice,
    productName,
    productCategory,
    productImageUrl,
    warrantyPeriodMonths,
    warrantyExpiryDate,
    returnPeriodDays,
    returnExpiryDate,
    warrantyLeadDaysOverride,
    returnLeadDaysOverride,
    warrantyReminderEnabled,
    returnReminderEnabled,
    status,
    replacementForId,
    replacedById,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptLineItem &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          other.rowIndex == this.rowIndex &&
          other.productCode == this.productCode &&
          other.itemDescription == this.itemDescription &&
          other.unitPrice == this.unitPrice &&
          other.productName == this.productName &&
          other.productCategory == this.productCategory &&
          other.productImageUrl == this.productImageUrl &&
          other.warrantyPeriodMonths == this.warrantyPeriodMonths &&
          other.warrantyExpiryDate == this.warrantyExpiryDate &&
          other.returnPeriodDays == this.returnPeriodDays &&
          other.returnExpiryDate == this.returnExpiryDate &&
          other.warrantyLeadDaysOverride == this.warrantyLeadDaysOverride &&
          other.returnLeadDaysOverride == this.returnLeadDaysOverride &&
          other.warrantyReminderEnabled == this.warrantyReminderEnabled &&
          other.returnReminderEnabled == this.returnReminderEnabled &&
          other.status == this.status &&
          other.replacementForId == this.replacementForId &&
          other.replacedById == this.replacedById &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReceiptLineItemsCompanion extends UpdateCompanion<ReceiptLineItem> {
  final Value<String> id;
  final Value<String> receiptId;
  final Value<int> rowIndex;
  final Value<String?> productCode;
  final Value<String?> itemDescription;
  final Value<double?> unitPrice;
  final Value<String?> productName;
  final Value<String?> productCategory;
  final Value<String?> productImageUrl;
  final Value<int?> warrantyPeriodMonths;
  final Value<DateTime?> warrantyExpiryDate;
  final Value<int?> returnPeriodDays;
  final Value<DateTime?> returnExpiryDate;
  final Value<int?> warrantyLeadDaysOverride;
  final Value<int?> returnLeadDaysOverride;
  final Value<bool?> warrantyReminderEnabled;
  final Value<bool?> returnReminderEnabled;
  final Value<String> status;
  final Value<String?> replacementForId;
  final Value<String?> replacedById;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReceiptLineItemsCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.rowIndex = const Value.absent(),
    this.productCode = const Value.absent(),
    this.itemDescription = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.productName = const Value.absent(),
    this.productCategory = const Value.absent(),
    this.productImageUrl = const Value.absent(),
    this.warrantyPeriodMonths = const Value.absent(),
    this.warrantyExpiryDate = const Value.absent(),
    this.returnPeriodDays = const Value.absent(),
    this.returnExpiryDate = const Value.absent(),
    this.warrantyLeadDaysOverride = const Value.absent(),
    this.returnLeadDaysOverride = const Value.absent(),
    this.warrantyReminderEnabled = const Value.absent(),
    this.returnReminderEnabled = const Value.absent(),
    this.status = const Value.absent(),
    this.replacementForId = const Value.absent(),
    this.replacedById = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptLineItemsCompanion.insert({
    required String id,
    required String receiptId,
    this.rowIndex = const Value.absent(),
    this.productCode = const Value.absent(),
    this.itemDescription = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.productName = const Value.absent(),
    this.productCategory = const Value.absent(),
    this.productImageUrl = const Value.absent(),
    this.warrantyPeriodMonths = const Value.absent(),
    this.warrantyExpiryDate = const Value.absent(),
    this.returnPeriodDays = const Value.absent(),
    this.returnExpiryDate = const Value.absent(),
    this.warrantyLeadDaysOverride = const Value.absent(),
    this.returnLeadDaysOverride = const Value.absent(),
    this.warrantyReminderEnabled = const Value.absent(),
    this.returnReminderEnabled = const Value.absent(),
    this.status = const Value.absent(),
    this.replacementForId = const Value.absent(),
    this.replacedById = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       receiptId = Value(receiptId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ReceiptLineItem> custom({
    Expression<String>? id,
    Expression<String>? receiptId,
    Expression<int>? rowIndex,
    Expression<String>? productCode,
    Expression<String>? itemDescription,
    Expression<double>? unitPrice,
    Expression<String>? productName,
    Expression<String>? productCategory,
    Expression<String>? productImageUrl,
    Expression<int>? warrantyPeriodMonths,
    Expression<DateTime>? warrantyExpiryDate,
    Expression<int>? returnPeriodDays,
    Expression<DateTime>? returnExpiryDate,
    Expression<int>? warrantyLeadDaysOverride,
    Expression<int>? returnLeadDaysOverride,
    Expression<bool>? warrantyReminderEnabled,
    Expression<bool>? returnReminderEnabled,
    Expression<String>? status,
    Expression<String>? replacementForId,
    Expression<String>? replacedById,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (rowIndex != null) 'row_index': rowIndex,
      if (productCode != null) 'product_code': productCode,
      if (itemDescription != null) 'item_description': itemDescription,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (productName != null) 'product_name': productName,
      if (productCategory != null) 'product_category': productCategory,
      if (productImageUrl != null) 'product_image_url': productImageUrl,
      if (warrantyPeriodMonths != null)
        'warranty_period_months': warrantyPeriodMonths,
      if (warrantyExpiryDate != null)
        'warranty_expiry_date': warrantyExpiryDate,
      if (returnPeriodDays != null) 'return_period_days': returnPeriodDays,
      if (returnExpiryDate != null) 'return_expiry_date': returnExpiryDate,
      if (warrantyLeadDaysOverride != null)
        'warranty_lead_days_override': warrantyLeadDaysOverride,
      if (returnLeadDaysOverride != null)
        'return_lead_days_override': returnLeadDaysOverride,
      if (warrantyReminderEnabled != null)
        'warranty_reminder_enabled': warrantyReminderEnabled,
      if (returnReminderEnabled != null)
        'return_reminder_enabled': returnReminderEnabled,
      if (status != null) 'status': status,
      if (replacementForId != null) 'replacement_for_id': replacementForId,
      if (replacedById != null) 'replaced_by_id': replacedById,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptLineItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? receiptId,
    Value<int>? rowIndex,
    Value<String?>? productCode,
    Value<String?>? itemDescription,
    Value<double?>? unitPrice,
    Value<String?>? productName,
    Value<String?>? productCategory,
    Value<String?>? productImageUrl,
    Value<int?>? warrantyPeriodMonths,
    Value<DateTime?>? warrantyExpiryDate,
    Value<int?>? returnPeriodDays,
    Value<DateTime?>? returnExpiryDate,
    Value<int?>? warrantyLeadDaysOverride,
    Value<int?>? returnLeadDaysOverride,
    Value<bool?>? warrantyReminderEnabled,
    Value<bool?>? returnReminderEnabled,
    Value<String>? status,
    Value<String?>? replacementForId,
    Value<String?>? replacedById,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReceiptLineItemsCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      rowIndex: rowIndex ?? this.rowIndex,
      productCode: productCode ?? this.productCode,
      itemDescription: itemDescription ?? this.itemDescription,
      unitPrice: unitPrice ?? this.unitPrice,
      productName: productName ?? this.productName,
      productCategory: productCategory ?? this.productCategory,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      warrantyPeriodMonths: warrantyPeriodMonths ?? this.warrantyPeriodMonths,
      warrantyExpiryDate: warrantyExpiryDate ?? this.warrantyExpiryDate,
      returnPeriodDays: returnPeriodDays ?? this.returnPeriodDays,
      returnExpiryDate: returnExpiryDate ?? this.returnExpiryDate,
      warrantyLeadDaysOverride:
          warrantyLeadDaysOverride ?? this.warrantyLeadDaysOverride,
      returnLeadDaysOverride:
          returnLeadDaysOverride ?? this.returnLeadDaysOverride,
      warrantyReminderEnabled:
          warrantyReminderEnabled ?? this.warrantyReminderEnabled,
      returnReminderEnabled:
          returnReminderEnabled ?? this.returnReminderEnabled,
      status: status ?? this.status,
      replacementForId: replacementForId ?? this.replacementForId,
      replacedById: replacedById ?? this.replacedById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (rowIndex.present) {
      map['row_index'] = Variable<int>(rowIndex.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (itemDescription.present) {
      map['item_description'] = Variable<String>(itemDescription.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (productCategory.present) {
      map['product_category'] = Variable<String>(productCategory.value);
    }
    if (productImageUrl.present) {
      map['product_image_url'] = Variable<String>(productImageUrl.value);
    }
    if (warrantyPeriodMonths.present) {
      map['warranty_period_months'] = Variable<int>(warrantyPeriodMonths.value);
    }
    if (warrantyExpiryDate.present) {
      map['warranty_expiry_date'] = Variable<DateTime>(
        warrantyExpiryDate.value,
      );
    }
    if (returnPeriodDays.present) {
      map['return_period_days'] = Variable<int>(returnPeriodDays.value);
    }
    if (returnExpiryDate.present) {
      map['return_expiry_date'] = Variable<DateTime>(returnExpiryDate.value);
    }
    if (warrantyLeadDaysOverride.present) {
      map['warranty_lead_days_override'] = Variable<int>(
        warrantyLeadDaysOverride.value,
      );
    }
    if (returnLeadDaysOverride.present) {
      map['return_lead_days_override'] = Variable<int>(
        returnLeadDaysOverride.value,
      );
    }
    if (warrantyReminderEnabled.present) {
      map['warranty_reminder_enabled'] = Variable<bool>(
        warrantyReminderEnabled.value,
      );
    }
    if (returnReminderEnabled.present) {
      map['return_reminder_enabled'] = Variable<bool>(
        returnReminderEnabled.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (replacementForId.present) {
      map['replacement_for_id'] = Variable<String>(replacementForId.value);
    }
    if (replacedById.present) {
      map['replaced_by_id'] = Variable<String>(replacedById.value);
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
    return (StringBuffer('ReceiptLineItemsCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('rowIndex: $rowIndex, ')
          ..write('productCode: $productCode, ')
          ..write('itemDescription: $itemDescription, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('productName: $productName, ')
          ..write('productCategory: $productCategory, ')
          ..write('productImageUrl: $productImageUrl, ')
          ..write('warrantyPeriodMonths: $warrantyPeriodMonths, ')
          ..write('warrantyExpiryDate: $warrantyExpiryDate, ')
          ..write('returnPeriodDays: $returnPeriodDays, ')
          ..write('returnExpiryDate: $returnExpiryDate, ')
          ..write('warrantyLeadDaysOverride: $warrantyLeadDaysOverride, ')
          ..write('returnLeadDaysOverride: $returnLeadDaysOverride, ')
          ..write('warrantyReminderEnabled: $warrantyReminderEnabled, ')
          ..write('returnReminderEnabled: $returnReminderEnabled, ')
          ..write('status: $status, ')
          ..write('replacementForId: $replacementForId, ')
          ..write('replacedById: $replacedById, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UploadQueueTable extends UploadQueue
    with TableInfo<$UploadQueueTable, UploadQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UploadQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localImagePathMeta = const VerificationMeta(
    'localImagePath',
  );
  @override
  late final GeneratedColumn<String> localImagePath = GeneratedColumn<String>(
    'local_image_path',
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
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    receiptId,
    localImagePath,
    retryCount,
    createdAt,
    lastAttemptAt,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'upload_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<UploadQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('local_image_path')) {
      context.handle(
        _localImagePathMeta,
        localImagePath.isAcceptableOrUnknown(
          data['local_image_path']!,
          _localImagePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localImagePathMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
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
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UploadQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UploadQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      )!,
      localImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_image_path'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $UploadQueueTable createAlias(String alias) {
    return $UploadQueueTable(attachedDatabase, alias);
  }
}

class UploadQueueData extends DataClass implements Insertable<UploadQueueData> {
  final String id;
  final String receiptId;
  final String localImagePath;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final String? errorMessage;
  const UploadQueueData({
    required this.id,
    required this.receiptId,
    required this.localImagePath,
    required this.retryCount,
    required this.createdAt,
    this.lastAttemptAt,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['receipt_id'] = Variable<String>(receiptId);
    map['local_image_path'] = Variable<String>(localImagePath);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  UploadQueueCompanion toCompanion(bool nullToAbsent) {
    return UploadQueueCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      localImagePath: Value(localImagePath),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory UploadQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UploadQueueData(
      id: serializer.fromJson<String>(json['id']),
      receiptId: serializer.fromJson<String>(json['receiptId']),
      localImagePath: serializer.fromJson<String>(json['localImagePath']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'receiptId': serializer.toJson<String>(receiptId),
      'localImagePath': serializer.toJson<String>(localImagePath),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  UploadQueueData copyWith({
    String? id,
    String? receiptId,
    String? localImagePath,
    int? retryCount,
    DateTime? createdAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
  }) => UploadQueueData(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    localImagePath: localImagePath ?? this.localImagePath,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  UploadQueueData copyWithCompanion(UploadQueueCompanion data) {
    return UploadQueueData(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      localImagePath: data.localImagePath.present
          ? data.localImagePath.value
          : this.localImagePath,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UploadQueueData(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    receiptId,
    localImagePath,
    retryCount,
    createdAt,
    lastAttemptAt,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UploadQueueData &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          other.localImagePath == this.localImagePath &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.errorMessage == this.errorMessage);
}

class UploadQueueCompanion extends UpdateCompanion<UploadQueueData> {
  final Value<String> id;
  final Value<String> receiptId;
  final Value<String> localImagePath;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const UploadQueueCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.localImagePath = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UploadQueueCompanion.insert({
    required String id,
    required String receiptId,
    required String localImagePath,
    this.retryCount = const Value.absent(),
    required DateTime createdAt,
    this.lastAttemptAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       receiptId = Value(receiptId),
       localImagePath = Value(localImagePath),
       createdAt = Value(createdAt);
  static Insertable<UploadQueueData> custom({
    Expression<String>? id,
    Expression<String>? receiptId,
    Expression<String>? localImagePath,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (localImagePath != null) 'local_image_path': localImagePath,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UploadQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? receiptId,
    Value<String>? localImagePath,
    Value<int>? retryCount,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return UploadQueueCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      localImagePath: localImagePath ?? this.localImagePath,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (localImagePath.present) {
      map['local_image_path'] = Variable<String>(localImagePath.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UploadQueueCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClaimDocumentsTable extends ClaimDocuments
    with TableInfo<$ClaimDocumentsTable, ClaimDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClaimDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineItemIdMeta = const VerificationMeta(
    'lineItemId',
  );
  @override
  late final GeneratedColumn<String> lineItemId = GeneratedColumn<String>(
    'line_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issueDescriptionMeta = const VerificationMeta(
    'issueDescription',
  );
  @override
  late final GeneratedColumn<String> issueDescription = GeneratedColumn<String>(
    'issue_description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _claimTypeMeta = const VerificationMeta(
    'claimType',
  );
  @override
  late final GeneratedColumn<String> claimType = GeneratedColumn<String>(
    'claim_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('SUBMITTED'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _generatedPdfS3KeyMeta = const VerificationMeta(
    'generatedPdfS3Key',
  );
  @override
  late final GeneratedColumn<String> generatedPdfS3Key =
      GeneratedColumn<String>(
        'generated_pdf_s3_key',
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    receiptId,
    lineItemId,
    issueDescription,
    claimType,
    status,
    notes,
    generatedPdfS3Key,
    createdAt,
    updatedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'claim_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClaimDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('line_item_id')) {
      context.handle(
        _lineItemIdMeta,
        lineItemId.isAcceptableOrUnknown(
          data['line_item_id']!,
          _lineItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lineItemIdMeta);
    }
    if (data.containsKey('issue_description')) {
      context.handle(
        _issueDescriptionMeta,
        issueDescription.isAcceptableOrUnknown(
          data['issue_description']!,
          _issueDescriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_issueDescriptionMeta);
    }
    if (data.containsKey('claim_type')) {
      context.handle(
        _claimTypeMeta,
        claimType.isAcceptableOrUnknown(data['claim_type']!, _claimTypeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('generated_pdf_s3_key')) {
      context.handle(
        _generatedPdfS3KeyMeta,
        generatedPdfS3Key.isAcceptableOrUnknown(
          data['generated_pdf_s3_key']!,
          _generatedPdfS3KeyMeta,
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
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClaimDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClaimDocument(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      )!,
      lineItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_item_id'],
      )!,
      issueDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_description'],
      )!,
      claimType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claim_type'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      generatedPdfS3Key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}generated_pdf_s3_key'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $ClaimDocumentsTable createAlias(String alias) {
    return $ClaimDocumentsTable(attachedDatabase, alias);
  }
}

class ClaimDocument extends DataClass implements Insertable<ClaimDocument> {
  final String id;
  final String receiptId;
  final String lineItemId;
  final String issueDescription;
  final String? claimType;
  final String status;
  final String? notes;
  final String? generatedPdfS3Key;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  const ClaimDocument({
    required this.id,
    required this.receiptId,
    required this.lineItemId,
    required this.issueDescription,
    this.claimType,
    required this.status,
    this.notes,
    this.generatedPdfS3Key,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['receipt_id'] = Variable<String>(receiptId);
    map['line_item_id'] = Variable<String>(lineItemId);
    map['issue_description'] = Variable<String>(issueDescription);
    if (!nullToAbsent || claimType != null) {
      map['claim_type'] = Variable<String>(claimType);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || generatedPdfS3Key != null) {
      map['generated_pdf_s3_key'] = Variable<String>(generatedPdfS3Key);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  ClaimDocumentsCompanion toCompanion(bool nullToAbsent) {
    return ClaimDocumentsCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      lineItemId: Value(lineItemId),
      issueDescription: Value(issueDescription),
      claimType: claimType == null && nullToAbsent
          ? const Value.absent()
          : Value(claimType),
      status: Value(status),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      generatedPdfS3Key: generatedPdfS3Key == null && nullToAbsent
          ? const Value.absent()
          : Value(generatedPdfS3Key),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory ClaimDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClaimDocument(
      id: serializer.fromJson<String>(json['id']),
      receiptId: serializer.fromJson<String>(json['receiptId']),
      lineItemId: serializer.fromJson<String>(json['lineItemId']),
      issueDescription: serializer.fromJson<String>(json['issueDescription']),
      claimType: serializer.fromJson<String?>(json['claimType']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      generatedPdfS3Key: serializer.fromJson<String?>(
        json['generatedPdfS3Key'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'receiptId': serializer.toJson<String>(receiptId),
      'lineItemId': serializer.toJson<String>(lineItemId),
      'issueDescription': serializer.toJson<String>(issueDescription),
      'claimType': serializer.toJson<String?>(claimType),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'generatedPdfS3Key': serializer.toJson<String?>(generatedPdfS3Key),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  ClaimDocument copyWith({
    String? id,
    String? receiptId,
    String? lineItemId,
    String? issueDescription,
    Value<String?> claimType = const Value.absent(),
    String? status,
    Value<String?> notes = const Value.absent(),
    Value<String?> generatedPdfS3Key = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => ClaimDocument(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    lineItemId: lineItemId ?? this.lineItemId,
    issueDescription: issueDescription ?? this.issueDescription,
    claimType: claimType.present ? claimType.value : this.claimType,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
    generatedPdfS3Key: generatedPdfS3Key.present
        ? generatedPdfS3Key.value
        : this.generatedPdfS3Key,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  ClaimDocument copyWithCompanion(ClaimDocumentsCompanion data) {
    return ClaimDocument(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      lineItemId: data.lineItemId.present
          ? data.lineItemId.value
          : this.lineItemId,
      issueDescription: data.issueDescription.present
          ? data.issueDescription.value
          : this.issueDescription,
      claimType: data.claimType.present ? data.claimType.value : this.claimType,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      generatedPdfS3Key: data.generatedPdfS3Key.present
          ? data.generatedPdfS3Key.value
          : this.generatedPdfS3Key,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClaimDocument(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('lineItemId: $lineItemId, ')
          ..write('issueDescription: $issueDescription, ')
          ..write('claimType: $claimType, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('generatedPdfS3Key: $generatedPdfS3Key, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    receiptId,
    lineItemId,
    issueDescription,
    claimType,
    status,
    notes,
    generatedPdfS3Key,
    createdAt,
    updatedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClaimDocument &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          other.lineItemId == this.lineItemId &&
          other.issueDescription == this.issueDescription &&
          other.claimType == this.claimType &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.generatedPdfS3Key == this.generatedPdfS3Key &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class ClaimDocumentsCompanion extends UpdateCompanion<ClaimDocument> {
  final Value<String> id;
  final Value<String> receiptId;
  final Value<String> lineItemId;
  final Value<String> issueDescription;
  final Value<String?> claimType;
  final Value<String> status;
  final Value<String?> notes;
  final Value<String?> generatedPdfS3Key;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const ClaimDocumentsCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.lineItemId = const Value.absent(),
    this.issueDescription = const Value.absent(),
    this.claimType = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.generatedPdfS3Key = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClaimDocumentsCompanion.insert({
    required String id,
    required String receiptId,
    required String lineItemId,
    required String issueDescription,
    this.claimType = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.generatedPdfS3Key = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       receiptId = Value(receiptId),
       lineItemId = Value(lineItemId),
       issueDescription = Value(issueDescription),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ClaimDocument> custom({
    Expression<String>? id,
    Expression<String>? receiptId,
    Expression<String>? lineItemId,
    Expression<String>? issueDescription,
    Expression<String>? claimType,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<String>? generatedPdfS3Key,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (lineItemId != null) 'line_item_id': lineItemId,
      if (issueDescription != null) 'issue_description': issueDescription,
      if (claimType != null) 'claim_type': claimType,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (generatedPdfS3Key != null) 'generated_pdf_s3_key': generatedPdfS3Key,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClaimDocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? receiptId,
    Value<String>? lineItemId,
    Value<String>? issueDescription,
    Value<String?>? claimType,
    Value<String>? status,
    Value<String?>? notes,
    Value<String?>? generatedPdfS3Key,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return ClaimDocumentsCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      lineItemId: lineItemId ?? this.lineItemId,
      issueDescription: issueDescription ?? this.issueDescription,
      claimType: claimType ?? this.claimType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      generatedPdfS3Key: generatedPdfS3Key ?? this.generatedPdfS3Key,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (lineItemId.present) {
      map['line_item_id'] = Variable<String>(lineItemId.value);
    }
    if (issueDescription.present) {
      map['issue_description'] = Variable<String>(issueDescription.value);
    }
    if (claimType.present) {
      map['claim_type'] = Variable<String>(claimType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (generatedPdfS3Key.present) {
      map['generated_pdf_s3_key'] = Variable<String>(generatedPdfS3Key.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClaimDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('lineItemId: $lineItemId, ')
          ..write('issueDescription: $issueDescription, ')
          ..write('claimType: $claimType, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('generatedPdfS3Key: $generatedPdfS3Key, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClaimDefectImagesTable extends ClaimDefectImages
    with TableInfo<$ClaimDefectImagesTable, ClaimDefectImage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClaimDefectImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _claimIdMeta = const VerificationMeta(
    'claimId',
  );
  @override
  late final GeneratedColumn<String> claimId = GeneratedColumn<String>(
    'claim_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES claim_documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _s3ObjectKeyMeta = const VerificationMeta(
    's3ObjectKey',
  );
  @override
  late final GeneratedColumn<String> s3ObjectKey = GeneratedColumn<String>(
    's3_object_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    claimId,
    s3ObjectKey,
    displayOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'claim_defect_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClaimDefectImage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('claim_id')) {
      context.handle(
        _claimIdMeta,
        claimId.isAcceptableOrUnknown(data['claim_id']!, _claimIdMeta),
      );
    } else if (isInserting) {
      context.missing(_claimIdMeta);
    }
    if (data.containsKey('s3_object_key')) {
      context.handle(
        _s3ObjectKeyMeta,
        s3ObjectKey.isAcceptableOrUnknown(
          data['s3_object_key']!,
          _s3ObjectKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_s3ObjectKeyMeta);
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClaimDefectImage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClaimDefectImage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      claimId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claim_id'],
      )!,
      s3ObjectKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}s3_object_key'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ClaimDefectImagesTable createAlias(String alias) {
    return $ClaimDefectImagesTable(attachedDatabase, alias);
  }
}

class ClaimDefectImage extends DataClass
    implements Insertable<ClaimDefectImage> {
  final String id;
  final String claimId;
  final String s3ObjectKey;
  final int displayOrder;
  final DateTime createdAt;
  const ClaimDefectImage({
    required this.id,
    required this.claimId,
    required this.s3ObjectKey,
    required this.displayOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['claim_id'] = Variable<String>(claimId);
    map['s3_object_key'] = Variable<String>(s3ObjectKey);
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ClaimDefectImagesCompanion toCompanion(bool nullToAbsent) {
    return ClaimDefectImagesCompanion(
      id: Value(id),
      claimId: Value(claimId),
      s3ObjectKey: Value(s3ObjectKey),
      displayOrder: Value(displayOrder),
      createdAt: Value(createdAt),
    );
  }

  factory ClaimDefectImage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClaimDefectImage(
      id: serializer.fromJson<String>(json['id']),
      claimId: serializer.fromJson<String>(json['claimId']),
      s3ObjectKey: serializer.fromJson<String>(json['s3ObjectKey']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'claimId': serializer.toJson<String>(claimId),
      's3ObjectKey': serializer.toJson<String>(s3ObjectKey),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ClaimDefectImage copyWith({
    String? id,
    String? claimId,
    String? s3ObjectKey,
    int? displayOrder,
    DateTime? createdAt,
  }) => ClaimDefectImage(
    id: id ?? this.id,
    claimId: claimId ?? this.claimId,
    s3ObjectKey: s3ObjectKey ?? this.s3ObjectKey,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  ClaimDefectImage copyWithCompanion(ClaimDefectImagesCompanion data) {
    return ClaimDefectImage(
      id: data.id.present ? data.id.value : this.id,
      claimId: data.claimId.present ? data.claimId.value : this.claimId,
      s3ObjectKey: data.s3ObjectKey.present
          ? data.s3ObjectKey.value
          : this.s3ObjectKey,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClaimDefectImage(')
          ..write('id: $id, ')
          ..write('claimId: $claimId, ')
          ..write('s3ObjectKey: $s3ObjectKey, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, claimId, s3ObjectKey, displayOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClaimDefectImage &&
          other.id == this.id &&
          other.claimId == this.claimId &&
          other.s3ObjectKey == this.s3ObjectKey &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt);
}

class ClaimDefectImagesCompanion extends UpdateCompanion<ClaimDefectImage> {
  final Value<String> id;
  final Value<String> claimId;
  final Value<String> s3ObjectKey;
  final Value<int> displayOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ClaimDefectImagesCompanion({
    this.id = const Value.absent(),
    this.claimId = const Value.absent(),
    this.s3ObjectKey = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClaimDefectImagesCompanion.insert({
    required String id,
    required String claimId,
    required String s3ObjectKey,
    this.displayOrder = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       claimId = Value(claimId),
       s3ObjectKey = Value(s3ObjectKey),
       createdAt = Value(createdAt);
  static Insertable<ClaimDefectImage> custom({
    Expression<String>? id,
    Expression<String>? claimId,
    Expression<String>? s3ObjectKey,
    Expression<int>? displayOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (claimId != null) 'claim_id': claimId,
      if (s3ObjectKey != null) 's3_object_key': s3ObjectKey,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClaimDefectImagesCompanion copyWith({
    Value<String>? id,
    Value<String>? claimId,
    Value<String>? s3ObjectKey,
    Value<int>? displayOrder,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ClaimDefectImagesCompanion(
      id: id ?? this.id,
      claimId: claimId ?? this.claimId,
      s3ObjectKey: s3ObjectKey ?? this.s3ObjectKey,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (claimId.present) {
      map['claim_id'] = Variable<String>(claimId.value);
    }
    if (s3ObjectKey.present) {
      map['s3_object_key'] = Variable<String>(s3ObjectKey.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClaimDefectImagesCompanion(')
          ..write('id: $id, ')
          ..write('claimId: $claimId, ')
          ..write('s3ObjectKey: $s3ObjectKey, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  late final $ReceiptLineItemsTable receiptLineItems = $ReceiptLineItemsTable(
    this,
  );
  late final $UploadQueueTable uploadQueue = $UploadQueueTable(this);
  late final $ClaimDocumentsTable claimDocuments = $ClaimDocumentsTable(this);
  late final $ClaimDefectImagesTable claimDefectImages =
      $ClaimDefectImagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    receipts,
    receiptLineItems,
    uploadQueue,
    claimDocuments,
    claimDefectImages,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'receipts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('receipt_line_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'claim_documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('claim_defect_images', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ReceiptsTableCreateCompanionBuilder =
    ReceiptsCompanion Function({
      required String id,
      required String userId,
      Value<String?> s3ObjectKey,
      Value<String?> storeName,
      Value<DateTime?> purchaseDate,
      Value<double?> totalAmount,
      Value<String?> currency,
      required String status,
      Value<int> ocrRetryCount,
      Value<DateTime?> lastOcrAttemptAt,
      Value<String?> notes,
      Value<String?> invoiceNumber,
      Value<String?> vendorAddress,
      Value<String?> vendorPhone,
      Value<String?> vendorEmail,
      Value<String?> vendorUrl,
      Value<String?> warrantyNotes,
      Value<String?> remarks,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> syncedAt,
      Value<String?> localImagePath,
      Value<int> rowid,
    });
typedef $$ReceiptsTableUpdateCompanionBuilder =
    ReceiptsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String?> s3ObjectKey,
      Value<String?> storeName,
      Value<DateTime?> purchaseDate,
      Value<double?> totalAmount,
      Value<String?> currency,
      Value<String> status,
      Value<int> ocrRetryCount,
      Value<DateTime?> lastOcrAttemptAt,
      Value<String?> notes,
      Value<String?> invoiceNumber,
      Value<String?> vendorAddress,
      Value<String?> vendorPhone,
      Value<String?> vendorEmail,
      Value<String?> vendorUrl,
      Value<String?> warrantyNotes,
      Value<String?> remarks,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
      Value<String?> localImagePath,
      Value<int> rowid,
    });

final class $$ReceiptsTableReferences
    extends BaseReferences<_$AppDatabase, $ReceiptsTable, Receipt> {
  $$ReceiptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReceiptLineItemsTable, List<ReceiptLineItem>>
  _receiptLineItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.receiptLineItems,
    aliasName: 'receipts__id__receipt_line_items__receipt_id',
  );

  $$ReceiptLineItemsTableProcessedTableManager get receiptLineItemsRefs {
    final manager = $$ReceiptLineItemsTableTableManager(
      $_db,
      $_db.receiptLineItems,
    ).filter((f) => f.receiptId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _receiptLineItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReceiptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get s3ObjectKey => $composableBuilder(
    column: $table.s3ObjectKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ocrRetryCount => $composableBuilder(
    column: $table.ocrRetryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOcrAttemptAt => $composableBuilder(
    column: $table.lastOcrAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendorAddress => $composableBuilder(
    column: $table.vendorAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendorPhone => $composableBuilder(
    column: $table.vendorPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendorEmail => $composableBuilder(
    column: $table.vendorEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendorUrl => $composableBuilder(
    column: $table.vendorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warrantyNotes => $composableBuilder(
    column: $table.warrantyNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
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

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> receiptLineItemsRefs(
    Expression<bool> Function($$ReceiptLineItemsTableFilterComposer f) f,
  ) {
    final $$ReceiptLineItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptLineItems,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptLineItemsTableFilterComposer(
            $db: $db,
            $table: $db.receiptLineItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get s3ObjectKey => $composableBuilder(
    column: $table.s3ObjectKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ocrRetryCount => $composableBuilder(
    column: $table.ocrRetryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOcrAttemptAt => $composableBuilder(
    column: $table.lastOcrAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendorAddress => $composableBuilder(
    column: $table.vendorAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendorPhone => $composableBuilder(
    column: $table.vendorPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendorEmail => $composableBuilder(
    column: $table.vendorEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendorUrl => $composableBuilder(
    column: $table.vendorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warrantyNotes => $composableBuilder(
    column: $table.warrantyNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
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

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get s3ObjectKey => $composableBuilder(
    column: $table.s3ObjectKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get ocrRetryCount => $composableBuilder(
    column: $table.ocrRetryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastOcrAttemptAt => $composableBuilder(
    column: $table.lastOcrAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vendorAddress => $composableBuilder(
    column: $table.vendorAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vendorPhone => $composableBuilder(
    column: $table.vendorPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vendorEmail => $composableBuilder(
    column: $table.vendorEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vendorUrl =>
      $composableBuilder(column: $table.vendorUrl, builder: (column) => column);

  GeneratedColumn<String> get warrantyNotes => $composableBuilder(
    column: $table.warrantyNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => column,
  );

  Expression<T> receiptLineItemsRefs<T extends Object>(
    Expression<T> Function($$ReceiptLineItemsTableAnnotationComposer a) f,
  ) {
    final $$ReceiptLineItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptLineItems,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptLineItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.receiptLineItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReceiptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptsTable,
          Receipt,
          $$ReceiptsTableFilterComposer,
          $$ReceiptsTableOrderingComposer,
          $$ReceiptsTableAnnotationComposer,
          $$ReceiptsTableCreateCompanionBuilder,
          $$ReceiptsTableUpdateCompanionBuilder,
          (Receipt, $$ReceiptsTableReferences),
          Receipt,
          PrefetchHooks Function({bool receiptLineItemsRefs})
        > {
  $$ReceiptsTableTableManager(_$AppDatabase db, $ReceiptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> s3ObjectKey = const Value.absent(),
                Value<String?> storeName = const Value.absent(),
                Value<DateTime?> purchaseDate = const Value.absent(),
                Value<double?> totalAmount = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> ocrRetryCount = const Value.absent(),
                Value<DateTime?> lastOcrAttemptAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> invoiceNumber = const Value.absent(),
                Value<String?> vendorAddress = const Value.absent(),
                Value<String?> vendorPhone = const Value.absent(),
                Value<String?> vendorEmail = const Value.absent(),
                Value<String?> vendorUrl = const Value.absent(),
                Value<String?> warrantyNotes = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> localImagePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsCompanion(
                id: id,
                userId: userId,
                s3ObjectKey: s3ObjectKey,
                storeName: storeName,
                purchaseDate: purchaseDate,
                totalAmount: totalAmount,
                currency: currency,
                status: status,
                ocrRetryCount: ocrRetryCount,
                lastOcrAttemptAt: lastOcrAttemptAt,
                notes: notes,
                invoiceNumber: invoiceNumber,
                vendorAddress: vendorAddress,
                vendorPhone: vendorPhone,
                vendorEmail: vendorEmail,
                vendorUrl: vendorUrl,
                warrantyNotes: warrantyNotes,
                remarks: remarks,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                localImagePath: localImagePath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String?> s3ObjectKey = const Value.absent(),
                Value<String?> storeName = const Value.absent(),
                Value<DateTime?> purchaseDate = const Value.absent(),
                Value<double?> totalAmount = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                required String status,
                Value<int> ocrRetryCount = const Value.absent(),
                Value<DateTime?> lastOcrAttemptAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> invoiceNumber = const Value.absent(),
                Value<String?> vendorAddress = const Value.absent(),
                Value<String?> vendorPhone = const Value.absent(),
                Value<String?> vendorEmail = const Value.absent(),
                Value<String?> vendorUrl = const Value.absent(),
                Value<String?> warrantyNotes = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> localImagePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsCompanion.insert(
                id: id,
                userId: userId,
                s3ObjectKey: s3ObjectKey,
                storeName: storeName,
                purchaseDate: purchaseDate,
                totalAmount: totalAmount,
                currency: currency,
                status: status,
                ocrRetryCount: ocrRetryCount,
                lastOcrAttemptAt: lastOcrAttemptAt,
                notes: notes,
                invoiceNumber: invoiceNumber,
                vendorAddress: vendorAddress,
                vendorPhone: vendorPhone,
                vendorEmail: vendorEmail,
                vendorUrl: vendorUrl,
                warrantyNotes: warrantyNotes,
                remarks: remarks,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                localImagePath: localImagePath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReceiptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptLineItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (receiptLineItemsRefs) db.receiptLineItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (receiptLineItemsRefs)
                    await $_getPrefetchedData<
                      Receipt,
                      $ReceiptsTable,
                      ReceiptLineItem
                    >(
                      currentTable: table,
                      referencedTable: $$ReceiptsTableReferences
                          ._receiptLineItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ReceiptsTableReferences(
                        db,
                        table,
                        p0,
                      ).receiptLineItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.receiptId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptsTable,
      Receipt,
      $$ReceiptsTableFilterComposer,
      $$ReceiptsTableOrderingComposer,
      $$ReceiptsTableAnnotationComposer,
      $$ReceiptsTableCreateCompanionBuilder,
      $$ReceiptsTableUpdateCompanionBuilder,
      (Receipt, $$ReceiptsTableReferences),
      Receipt,
      PrefetchHooks Function({bool receiptLineItemsRefs})
    >;
typedef $$ReceiptLineItemsTableCreateCompanionBuilder =
    ReceiptLineItemsCompanion Function({
      required String id,
      required String receiptId,
      Value<int> rowIndex,
      Value<String?> productCode,
      Value<String?> itemDescription,
      Value<double?> unitPrice,
      Value<String?> productName,
      Value<String?> productCategory,
      Value<String?> productImageUrl,
      Value<int?> warrantyPeriodMonths,
      Value<DateTime?> warrantyExpiryDate,
      Value<int?> returnPeriodDays,
      Value<DateTime?> returnExpiryDate,
      Value<int?> warrantyLeadDaysOverride,
      Value<int?> returnLeadDaysOverride,
      Value<bool?> warrantyReminderEnabled,
      Value<bool?> returnReminderEnabled,
      Value<String> status,
      Value<String?> replacementForId,
      Value<String?> replacedById,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReceiptLineItemsTableUpdateCompanionBuilder =
    ReceiptLineItemsCompanion Function({
      Value<String> id,
      Value<String> receiptId,
      Value<int> rowIndex,
      Value<String?> productCode,
      Value<String?> itemDescription,
      Value<double?> unitPrice,
      Value<String?> productName,
      Value<String?> productCategory,
      Value<String?> productImageUrl,
      Value<int?> warrantyPeriodMonths,
      Value<DateTime?> warrantyExpiryDate,
      Value<int?> returnPeriodDays,
      Value<DateTime?> returnExpiryDate,
      Value<int?> warrantyLeadDaysOverride,
      Value<int?> returnLeadDaysOverride,
      Value<bool?> warrantyReminderEnabled,
      Value<bool?> returnReminderEnabled,
      Value<String> status,
      Value<String?> replacementForId,
      Value<String?> replacedById,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ReceiptLineItemsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ReceiptLineItemsTable, ReceiptLineItem> {
  $$ReceiptLineItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ReceiptsTable _receiptIdTable(_$AppDatabase db) =>
      db.receipts.createAlias('receipt_line_items__receipt_id__receipts__id');

  $$ReceiptsTableProcessedTableManager get receiptId {
    final $_column = $_itemColumn<String>('receipt_id')!;

    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receiptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReceiptLineItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptLineItemsTable> {
  $$ReceiptLineItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowIndex => $composableBuilder(
    column: $table.rowIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemDescription => $composableBuilder(
    column: $table.itemDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productImageUrl => $composableBuilder(
    column: $table.productImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warrantyPeriodMonths => $composableBuilder(
    column: $table.warrantyPeriodMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get warrantyExpiryDate => $composableBuilder(
    column: $table.warrantyExpiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get returnPeriodDays => $composableBuilder(
    column: $table.returnPeriodDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get returnExpiryDate => $composableBuilder(
    column: $table.returnExpiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warrantyLeadDaysOverride => $composableBuilder(
    column: $table.warrantyLeadDaysOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get returnLeadDaysOverride => $composableBuilder(
    column: $table.returnLeadDaysOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get warrantyReminderEnabled => $composableBuilder(
    column: $table.warrantyReminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get returnReminderEnabled => $composableBuilder(
    column: $table.returnReminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replacementForId => $composableBuilder(
    column: $table.replacementForId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replacedById => $composableBuilder(
    column: $table.replacedById,
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

  $$ReceiptsTableFilterComposer get receiptId {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptLineItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptLineItemsTable> {
  $$ReceiptLineItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowIndex => $composableBuilder(
    column: $table.rowIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemDescription => $composableBuilder(
    column: $table.itemDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productImageUrl => $composableBuilder(
    column: $table.productImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warrantyPeriodMonths => $composableBuilder(
    column: $table.warrantyPeriodMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get warrantyExpiryDate => $composableBuilder(
    column: $table.warrantyExpiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get returnPeriodDays => $composableBuilder(
    column: $table.returnPeriodDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get returnExpiryDate => $composableBuilder(
    column: $table.returnExpiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warrantyLeadDaysOverride => $composableBuilder(
    column: $table.warrantyLeadDaysOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get returnLeadDaysOverride => $composableBuilder(
    column: $table.returnLeadDaysOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get warrantyReminderEnabled => $composableBuilder(
    column: $table.warrantyReminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get returnReminderEnabled => $composableBuilder(
    column: $table.returnReminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replacementForId => $composableBuilder(
    column: $table.replacementForId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replacedById => $composableBuilder(
    column: $table.replacedById,
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

  $$ReceiptsTableOrderingComposer get receiptId {
    final $$ReceiptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableOrderingComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptLineItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptLineItemsTable> {
  $$ReceiptLineItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get rowIndex =>
      $composableBuilder(column: $table.rowIndex, builder: (column) => column);

  GeneratedColumn<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemDescription => $composableBuilder(
    column: $table.itemDescription,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productImageUrl => $composableBuilder(
    column: $table.productImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get warrantyPeriodMonths => $composableBuilder(
    column: $table.warrantyPeriodMonths,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get warrantyExpiryDate => $composableBuilder(
    column: $table.warrantyExpiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get returnPeriodDays => $composableBuilder(
    column: $table.returnPeriodDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get returnExpiryDate => $composableBuilder(
    column: $table.returnExpiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get warrantyLeadDaysOverride => $composableBuilder(
    column: $table.warrantyLeadDaysOverride,
    builder: (column) => column,
  );

  GeneratedColumn<int> get returnLeadDaysOverride => $composableBuilder(
    column: $table.returnLeadDaysOverride,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get warrantyReminderEnabled => $composableBuilder(
    column: $table.warrantyReminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get returnReminderEnabled => $composableBuilder(
    column: $table.returnReminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get replacementForId => $composableBuilder(
    column: $table.replacementForId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replacedById => $composableBuilder(
    column: $table.replacedById,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ReceiptsTableAnnotationComposer get receiptId {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptLineItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptLineItemsTable,
          ReceiptLineItem,
          $$ReceiptLineItemsTableFilterComposer,
          $$ReceiptLineItemsTableOrderingComposer,
          $$ReceiptLineItemsTableAnnotationComposer,
          $$ReceiptLineItemsTableCreateCompanionBuilder,
          $$ReceiptLineItemsTableUpdateCompanionBuilder,
          (ReceiptLineItem, $$ReceiptLineItemsTableReferences),
          ReceiptLineItem,
          PrefetchHooks Function({bool receiptId})
        > {
  $$ReceiptLineItemsTableTableManager(
    _$AppDatabase db,
    $ReceiptLineItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptLineItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptLineItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptLineItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> receiptId = const Value.absent(),
                Value<int> rowIndex = const Value.absent(),
                Value<String?> productCode = const Value.absent(),
                Value<String?> itemDescription = const Value.absent(),
                Value<double?> unitPrice = const Value.absent(),
                Value<String?> productName = const Value.absent(),
                Value<String?> productCategory = const Value.absent(),
                Value<String?> productImageUrl = const Value.absent(),
                Value<int?> warrantyPeriodMonths = const Value.absent(),
                Value<DateTime?> warrantyExpiryDate = const Value.absent(),
                Value<int?> returnPeriodDays = const Value.absent(),
                Value<DateTime?> returnExpiryDate = const Value.absent(),
                Value<int?> warrantyLeadDaysOverride = const Value.absent(),
                Value<int?> returnLeadDaysOverride = const Value.absent(),
                Value<bool?> warrantyReminderEnabled = const Value.absent(),
                Value<bool?> returnReminderEnabled = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> replacementForId = const Value.absent(),
                Value<String?> replacedById = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptLineItemsCompanion(
                id: id,
                receiptId: receiptId,
                rowIndex: rowIndex,
                productCode: productCode,
                itemDescription: itemDescription,
                unitPrice: unitPrice,
                productName: productName,
                productCategory: productCategory,
                productImageUrl: productImageUrl,
                warrantyPeriodMonths: warrantyPeriodMonths,
                warrantyExpiryDate: warrantyExpiryDate,
                returnPeriodDays: returnPeriodDays,
                returnExpiryDate: returnExpiryDate,
                warrantyLeadDaysOverride: warrantyLeadDaysOverride,
                returnLeadDaysOverride: returnLeadDaysOverride,
                warrantyReminderEnabled: warrantyReminderEnabled,
                returnReminderEnabled: returnReminderEnabled,
                status: status,
                replacementForId: replacementForId,
                replacedById: replacedById,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String receiptId,
                Value<int> rowIndex = const Value.absent(),
                Value<String?> productCode = const Value.absent(),
                Value<String?> itemDescription = const Value.absent(),
                Value<double?> unitPrice = const Value.absent(),
                Value<String?> productName = const Value.absent(),
                Value<String?> productCategory = const Value.absent(),
                Value<String?> productImageUrl = const Value.absent(),
                Value<int?> warrantyPeriodMonths = const Value.absent(),
                Value<DateTime?> warrantyExpiryDate = const Value.absent(),
                Value<int?> returnPeriodDays = const Value.absent(),
                Value<DateTime?> returnExpiryDate = const Value.absent(),
                Value<int?> warrantyLeadDaysOverride = const Value.absent(),
                Value<int?> returnLeadDaysOverride = const Value.absent(),
                Value<bool?> warrantyReminderEnabled = const Value.absent(),
                Value<bool?> returnReminderEnabled = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> replacementForId = const Value.absent(),
                Value<String?> replacedById = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReceiptLineItemsCompanion.insert(
                id: id,
                receiptId: receiptId,
                rowIndex: rowIndex,
                productCode: productCode,
                itemDescription: itemDescription,
                unitPrice: unitPrice,
                productName: productName,
                productCategory: productCategory,
                productImageUrl: productImageUrl,
                warrantyPeriodMonths: warrantyPeriodMonths,
                warrantyExpiryDate: warrantyExpiryDate,
                returnPeriodDays: returnPeriodDays,
                returnExpiryDate: returnExpiryDate,
                warrantyLeadDaysOverride: warrantyLeadDaysOverride,
                returnLeadDaysOverride: returnLeadDaysOverride,
                warrantyReminderEnabled: warrantyReminderEnabled,
                returnReminderEnabled: returnReminderEnabled,
                status: status,
                replacementForId: replacementForId,
                replacedById: replacedById,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReceiptLineItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (receiptId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.receiptId,
                                referencedTable:
                                    $$ReceiptLineItemsTableReferences
                                        ._receiptIdTable(db),
                                referencedColumn:
                                    $$ReceiptLineItemsTableReferences
                                        ._receiptIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReceiptLineItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptLineItemsTable,
      ReceiptLineItem,
      $$ReceiptLineItemsTableFilterComposer,
      $$ReceiptLineItemsTableOrderingComposer,
      $$ReceiptLineItemsTableAnnotationComposer,
      $$ReceiptLineItemsTableCreateCompanionBuilder,
      $$ReceiptLineItemsTableUpdateCompanionBuilder,
      (ReceiptLineItem, $$ReceiptLineItemsTableReferences),
      ReceiptLineItem,
      PrefetchHooks Function({bool receiptId})
    >;
typedef $$UploadQueueTableCreateCompanionBuilder =
    UploadQueueCompanion Function({
      required String id,
      required String receiptId,
      required String localImagePath,
      Value<int> retryCount,
      required DateTime createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$UploadQueueTableUpdateCompanionBuilder =
    UploadQueueCompanion Function({
      Value<String> id,
      Value<String> receiptId,
      Value<String> localImagePath,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

class $$UploadQueueTableFilterComposer
    extends Composer<_$AppDatabase, $UploadQueueTable> {
  $$UploadQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UploadQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $UploadQueueTable> {
  $$UploadQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UploadQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $UploadQueueTable> {
  $$UploadQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$UploadQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UploadQueueTable,
          UploadQueueData,
          $$UploadQueueTableFilterComposer,
          $$UploadQueueTableOrderingComposer,
          $$UploadQueueTableAnnotationComposer,
          $$UploadQueueTableCreateCompanionBuilder,
          $$UploadQueueTableUpdateCompanionBuilder,
          (
            UploadQueueData,
            BaseReferences<_$AppDatabase, $UploadQueueTable, UploadQueueData>,
          ),
          UploadQueueData,
          PrefetchHooks Function()
        > {
  $$UploadQueueTableTableManager(_$AppDatabase db, $UploadQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UploadQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UploadQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UploadQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> receiptId = const Value.absent(),
                Value<String> localImagePath = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UploadQueueCompanion(
                id: id,
                receiptId: receiptId,
                localImagePath: localImagePath,
                retryCount: retryCount,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String receiptId,
                required String localImagePath,
                Value<int> retryCount = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UploadQueueCompanion.insert(
                id: id,
                receiptId: receiptId,
                localImagePath: localImagePath,
                retryCount: retryCount,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UploadQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UploadQueueTable,
      UploadQueueData,
      $$UploadQueueTableFilterComposer,
      $$UploadQueueTableOrderingComposer,
      $$UploadQueueTableAnnotationComposer,
      $$UploadQueueTableCreateCompanionBuilder,
      $$UploadQueueTableUpdateCompanionBuilder,
      (
        UploadQueueData,
        BaseReferences<_$AppDatabase, $UploadQueueTable, UploadQueueData>,
      ),
      UploadQueueData,
      PrefetchHooks Function()
    >;
typedef $$ClaimDocumentsTableCreateCompanionBuilder =
    ClaimDocumentsCompanion Function({
      required String id,
      required String receiptId,
      required String lineItemId,
      required String issueDescription,
      Value<String?> claimType,
      Value<String> status,
      Value<String?> notes,
      Value<String?> generatedPdfS3Key,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$ClaimDocumentsTableUpdateCompanionBuilder =
    ClaimDocumentsCompanion Function({
      Value<String> id,
      Value<String> receiptId,
      Value<String> lineItemId,
      Value<String> issueDescription,
      Value<String?> claimType,
      Value<String> status,
      Value<String?> notes,
      Value<String?> generatedPdfS3Key,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

final class $$ClaimDocumentsTableReferences
    extends BaseReferences<_$AppDatabase, $ClaimDocumentsTable, ClaimDocument> {
  $$ClaimDocumentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ClaimDefectImagesTable, List<ClaimDefectImage>>
  _claimDefectImagesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.claimDefectImages,
        aliasName: 'claim_documents__id__claim_defect_images__claim_id',
      );

  $$ClaimDefectImagesTableProcessedTableManager get claimDefectImagesRefs {
    final manager = $$ClaimDefectImagesTableTableManager(
      $_db,
      $_db.claimDefectImages,
    ).filter((f) => f.claimId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _claimDefectImagesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClaimDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $ClaimDocumentsTable> {
  $$ClaimDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineItemId => $composableBuilder(
    column: $table.lineItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueDescription => $composableBuilder(
    column: $table.issueDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get claimType => $composableBuilder(
    column: $table.claimType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get generatedPdfS3Key => $composableBuilder(
    column: $table.generatedPdfS3Key,
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

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> claimDefectImagesRefs(
    Expression<bool> Function($$ClaimDefectImagesTableFilterComposer f) f,
  ) {
    final $$ClaimDefectImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.claimDefectImages,
      getReferencedColumn: (t) => t.claimId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClaimDefectImagesTableFilterComposer(
            $db: $db,
            $table: $db.claimDefectImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClaimDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClaimDocumentsTable> {
  $$ClaimDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineItemId => $composableBuilder(
    column: $table.lineItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueDescription => $composableBuilder(
    column: $table.issueDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claimType => $composableBuilder(
    column: $table.claimType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get generatedPdfS3Key => $composableBuilder(
    column: $table.generatedPdfS3Key,
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

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClaimDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClaimDocumentsTable> {
  $$ClaimDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<String> get lineItemId => $composableBuilder(
    column: $table.lineItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issueDescription => $composableBuilder(
    column: $table.issueDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get claimType =>
      $composableBuilder(column: $table.claimType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get generatedPdfS3Key => $composableBuilder(
    column: $table.generatedPdfS3Key,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  Expression<T> claimDefectImagesRefs<T extends Object>(
    Expression<T> Function($$ClaimDefectImagesTableAnnotationComposer a) f,
  ) {
    final $$ClaimDefectImagesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.claimDefectImages,
          getReferencedColumn: (t) => t.claimId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClaimDefectImagesTableAnnotationComposer(
                $db: $db,
                $table: $db.claimDefectImages,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ClaimDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClaimDocumentsTable,
          ClaimDocument,
          $$ClaimDocumentsTableFilterComposer,
          $$ClaimDocumentsTableOrderingComposer,
          $$ClaimDocumentsTableAnnotationComposer,
          $$ClaimDocumentsTableCreateCompanionBuilder,
          $$ClaimDocumentsTableUpdateCompanionBuilder,
          (ClaimDocument, $$ClaimDocumentsTableReferences),
          ClaimDocument,
          PrefetchHooks Function({bool claimDefectImagesRefs})
        > {
  $$ClaimDocumentsTableTableManager(
    _$AppDatabase db,
    $ClaimDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClaimDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClaimDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClaimDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> receiptId = const Value.absent(),
                Value<String> lineItemId = const Value.absent(),
                Value<String> issueDescription = const Value.absent(),
                Value<String?> claimType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> generatedPdfS3Key = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClaimDocumentsCompanion(
                id: id,
                receiptId: receiptId,
                lineItemId: lineItemId,
                issueDescription: issueDescription,
                claimType: claimType,
                status: status,
                notes: notes,
                generatedPdfS3Key: generatedPdfS3Key,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String receiptId,
                required String lineItemId,
                required String issueDescription,
                Value<String?> claimType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> generatedPdfS3Key = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClaimDocumentsCompanion.insert(
                id: id,
                receiptId: receiptId,
                lineItemId: lineItemId,
                issueDescription: issueDescription,
                claimType: claimType,
                status: status,
                notes: notes,
                generatedPdfS3Key: generatedPdfS3Key,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ClaimDocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({claimDefectImagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (claimDefectImagesRefs) db.claimDefectImages,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (claimDefectImagesRefs)
                    await $_getPrefetchedData<
                      ClaimDocument,
                      $ClaimDocumentsTable,
                      ClaimDefectImage
                    >(
                      currentTable: table,
                      referencedTable: $$ClaimDocumentsTableReferences
                          ._claimDefectImagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ClaimDocumentsTableReferences(
                            db,
                            table,
                            p0,
                          ).claimDefectImagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.claimId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ClaimDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClaimDocumentsTable,
      ClaimDocument,
      $$ClaimDocumentsTableFilterComposer,
      $$ClaimDocumentsTableOrderingComposer,
      $$ClaimDocumentsTableAnnotationComposer,
      $$ClaimDocumentsTableCreateCompanionBuilder,
      $$ClaimDocumentsTableUpdateCompanionBuilder,
      (ClaimDocument, $$ClaimDocumentsTableReferences),
      ClaimDocument,
      PrefetchHooks Function({bool claimDefectImagesRefs})
    >;
typedef $$ClaimDefectImagesTableCreateCompanionBuilder =
    ClaimDefectImagesCompanion Function({
      required String id,
      required String claimId,
      required String s3ObjectKey,
      Value<int> displayOrder,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ClaimDefectImagesTableUpdateCompanionBuilder =
    ClaimDefectImagesCompanion Function({
      Value<String> id,
      Value<String> claimId,
      Value<String> s3ObjectKey,
      Value<int> displayOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ClaimDefectImagesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ClaimDefectImagesTable,
          ClaimDefectImage
        > {
  $$ClaimDefectImagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClaimDocumentsTable _claimIdTable(_$AppDatabase db) => db
      .claimDocuments
      .createAlias('claim_defect_images__claim_id__claim_documents__id');

  $$ClaimDocumentsTableProcessedTableManager get claimId {
    final $_column = $_itemColumn<String>('claim_id')!;

    final manager = $$ClaimDocumentsTableTableManager(
      $_db,
      $_db.claimDocuments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_claimIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ClaimDefectImagesTableFilterComposer
    extends Composer<_$AppDatabase, $ClaimDefectImagesTable> {
  $$ClaimDefectImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get s3ObjectKey => $composableBuilder(
    column: $table.s3ObjectKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ClaimDocumentsTableFilterComposer get claimId {
    final $$ClaimDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.claimId,
      referencedTable: $db.claimDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClaimDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.claimDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClaimDefectImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClaimDefectImagesTable> {
  $$ClaimDefectImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get s3ObjectKey => $composableBuilder(
    column: $table.s3ObjectKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClaimDocumentsTableOrderingComposer get claimId {
    final $$ClaimDocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.claimId,
      referencedTable: $db.claimDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClaimDocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.claimDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClaimDefectImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClaimDefectImagesTable> {
  $$ClaimDefectImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get s3ObjectKey => $composableBuilder(
    column: $table.s3ObjectKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ClaimDocumentsTableAnnotationComposer get claimId {
    final $$ClaimDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.claimId,
      referencedTable: $db.claimDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClaimDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.claimDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClaimDefectImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClaimDefectImagesTable,
          ClaimDefectImage,
          $$ClaimDefectImagesTableFilterComposer,
          $$ClaimDefectImagesTableOrderingComposer,
          $$ClaimDefectImagesTableAnnotationComposer,
          $$ClaimDefectImagesTableCreateCompanionBuilder,
          $$ClaimDefectImagesTableUpdateCompanionBuilder,
          (ClaimDefectImage, $$ClaimDefectImagesTableReferences),
          ClaimDefectImage,
          PrefetchHooks Function({bool claimId})
        > {
  $$ClaimDefectImagesTableTableManager(
    _$AppDatabase db,
    $ClaimDefectImagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClaimDefectImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClaimDefectImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClaimDefectImagesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> claimId = const Value.absent(),
                Value<String> s3ObjectKey = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClaimDefectImagesCompanion(
                id: id,
                claimId: claimId,
                s3ObjectKey: s3ObjectKey,
                displayOrder: displayOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String claimId,
                required String s3ObjectKey,
                Value<int> displayOrder = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ClaimDefectImagesCompanion.insert(
                id: id,
                claimId: claimId,
                s3ObjectKey: s3ObjectKey,
                displayOrder: displayOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ClaimDefectImagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({claimId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (claimId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.claimId,
                                referencedTable:
                                    $$ClaimDefectImagesTableReferences
                                        ._claimIdTable(db),
                                referencedColumn:
                                    $$ClaimDefectImagesTableReferences
                                        ._claimIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ClaimDefectImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClaimDefectImagesTable,
      ClaimDefectImage,
      $$ClaimDefectImagesTableFilterComposer,
      $$ClaimDefectImagesTableOrderingComposer,
      $$ClaimDefectImagesTableAnnotationComposer,
      $$ClaimDefectImagesTableCreateCompanionBuilder,
      $$ClaimDefectImagesTableUpdateCompanionBuilder,
      (ClaimDefectImage, $$ClaimDefectImagesTableReferences),
      ClaimDefectImage,
      PrefetchHooks Function({bool claimId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$ReceiptLineItemsTableTableManager get receiptLineItems =>
      $$ReceiptLineItemsTableTableManager(_db, _db.receiptLineItems);
  $$UploadQueueTableTableManager get uploadQueue =>
      $$UploadQueueTableTableManager(_db, _db.uploadQueue);
  $$ClaimDocumentsTableTableManager get claimDocuments =>
      $$ClaimDocumentsTableTableManager(_db, _db.claimDocuments);
  $$ClaimDefectImagesTableTableManager get claimDefectImages =>
      $$ClaimDefectImagesTableTableManager(_db, _db.claimDefectImages);
}
