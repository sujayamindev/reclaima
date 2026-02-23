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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    s3ObjectKey,
    storeName,
    purchaseDate,
    totalAmount,
    currency,
    productName,
    productCategory,
    warrantyPeriodMonths,
    warrantyExpiryDate,
    returnPeriodDays,
    returnExpiryDate,
    status,
    ocrRetryCount,
    lastOcrAttemptAt,
    notes,
    createdAt,
    updatedAt,
    syncedAt,
    localImagePath,
    invoiceNumber,
    vendorAddress,
    vendorPhone,
    vendorEmail,
    vendorUrl,
    remarks,
    warrantyNotes,
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
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
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
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      ),
      productCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_category'],
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
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      warrantyNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warranty_notes'],
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
  final String? productName;
  final String? productCategory;
  final int? warrantyPeriodMonths;
  final DateTime? warrantyExpiryDate;
  final int? returnPeriodDays;
  final DateTime? returnExpiryDate;
  final String status;
  final int ocrRetryCount;
  final DateTime? lastOcrAttemptAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final String? localImagePath;
  final String? invoiceNumber;
  final String? vendorAddress;
  final String? vendorPhone;
  final String? vendorEmail;
  final String? vendorUrl;
  final String? remarks;
  final String? warrantyNotes;
  const Receipt({
    required this.id,
    required this.userId,
    this.s3ObjectKey,
    this.storeName,
    this.purchaseDate,
    this.totalAmount,
    this.currency,
    this.productName,
    this.productCategory,
    this.warrantyPeriodMonths,
    this.warrantyExpiryDate,
    this.returnPeriodDays,
    this.returnExpiryDate,
    required this.status,
    required this.ocrRetryCount,
    this.lastOcrAttemptAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
    this.localImagePath,
    this.invoiceNumber,
    this.vendorAddress,
    this.vendorPhone,
    this.vendorEmail,
    this.vendorUrl,
    this.remarks,
    this.warrantyNotes,
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
    if (!nullToAbsent || productName != null) {
      map['product_name'] = Variable<String>(productName);
    }
    if (!nullToAbsent || productCategory != null) {
      map['product_category'] = Variable<String>(productCategory);
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
    map['status'] = Variable<String>(status);
    map['ocr_retry_count'] = Variable<int>(ocrRetryCount);
    if (!nullToAbsent || lastOcrAttemptAt != null) {
      map['last_ocr_attempt_at'] = Variable<DateTime>(lastOcrAttemptAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || localImagePath != null) {
      map['local_image_path'] = Variable<String>(localImagePath);
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
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    if (!nullToAbsent || warrantyNotes != null) {
      map['warranty_notes'] = Variable<String>(warrantyNotes);
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
      productName: productName == null && nullToAbsent
          ? const Value.absent()
          : Value(productName),
      productCategory: productCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(productCategory),
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
      status: Value(status),
      ocrRetryCount: Value(ocrRetryCount),
      lastOcrAttemptAt: lastOcrAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOcrAttemptAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      localImagePath: localImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localImagePath),
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
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      warrantyNotes: warrantyNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyNotes),
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
      productName: serializer.fromJson<String?>(json['productName']),
      productCategory: serializer.fromJson<String?>(json['productCategory']),
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
      status: serializer.fromJson<String>(json['status']),
      ocrRetryCount: serializer.fromJson<int>(json['ocrRetryCount']),
      lastOcrAttemptAt: serializer.fromJson<DateTime?>(
        json['lastOcrAttemptAt'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      localImagePath: serializer.fromJson<String?>(json['localImagePath']),
      invoiceNumber: serializer.fromJson<String?>(json['invoiceNumber']),
      vendorAddress: serializer.fromJson<String?>(json['vendorAddress']),
      vendorPhone: serializer.fromJson<String?>(json['vendorPhone']),
      vendorEmail: serializer.fromJson<String?>(json['vendorEmail']),
      vendorUrl: serializer.fromJson<String?>(json['vendorUrl']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      warrantyNotes: serializer.fromJson<String?>(json['warrantyNotes']),
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
      'productName': serializer.toJson<String?>(productName),
      'productCategory': serializer.toJson<String?>(productCategory),
      'warrantyPeriodMonths': serializer.toJson<int?>(warrantyPeriodMonths),
      'warrantyExpiryDate': serializer.toJson<DateTime?>(warrantyExpiryDate),
      'returnPeriodDays': serializer.toJson<int?>(returnPeriodDays),
      'returnExpiryDate': serializer.toJson<DateTime?>(returnExpiryDate),
      'status': serializer.toJson<String>(status),
      'ocrRetryCount': serializer.toJson<int>(ocrRetryCount),
      'lastOcrAttemptAt': serializer.toJson<DateTime?>(lastOcrAttemptAt),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'localImagePath': serializer.toJson<String?>(localImagePath),
      'invoiceNumber': serializer.toJson<String?>(invoiceNumber),
      'vendorAddress': serializer.toJson<String?>(vendorAddress),
      'vendorPhone': serializer.toJson<String?>(vendorPhone),
      'vendorEmail': serializer.toJson<String?>(vendorEmail),
      'vendorUrl': serializer.toJson<String?>(vendorUrl),
      'remarks': serializer.toJson<String?>(remarks),
      'warrantyNotes': serializer.toJson<String?>(warrantyNotes),
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
    Value<String?> productName = const Value.absent(),
    Value<String?> productCategory = const Value.absent(),
    Value<int?> warrantyPeriodMonths = const Value.absent(),
    Value<DateTime?> warrantyExpiryDate = const Value.absent(),
    Value<int?> returnPeriodDays = const Value.absent(),
    Value<DateTime?> returnExpiryDate = const Value.absent(),
    String? status,
    int? ocrRetryCount,
    Value<DateTime?> lastOcrAttemptAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<String?> localImagePath = const Value.absent(),
    Value<String?> invoiceNumber = const Value.absent(),
    Value<String?> vendorAddress = const Value.absent(),
    Value<String?> vendorPhone = const Value.absent(),
    Value<String?> vendorEmail = const Value.absent(),
    Value<String?> vendorUrl = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
    Value<String?> warrantyNotes = const Value.absent(),
  }) => Receipt(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    s3ObjectKey: s3ObjectKey.present ? s3ObjectKey.value : this.s3ObjectKey,
    storeName: storeName.present ? storeName.value : this.storeName,
    purchaseDate: purchaseDate.present ? purchaseDate.value : this.purchaseDate,
    totalAmount: totalAmount.present ? totalAmount.value : this.totalAmount,
    currency: currency.present ? currency.value : this.currency,
    productName: productName.present ? productName.value : this.productName,
    productCategory: productCategory.present
        ? productCategory.value
        : this.productCategory,
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
    status: status ?? this.status,
    ocrRetryCount: ocrRetryCount ?? this.ocrRetryCount,
    lastOcrAttemptAt: lastOcrAttemptAt.present
        ? lastOcrAttemptAt.value
        : this.lastOcrAttemptAt,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    localImagePath: localImagePath.present
        ? localImagePath.value
        : this.localImagePath,
    invoiceNumber: invoiceNumber.present
        ? invoiceNumber.value
        : this.invoiceNumber,
    vendorAddress: vendorAddress.present
        ? vendorAddress.value
        : this.vendorAddress,
    vendorPhone: vendorPhone.present ? vendorPhone.value : this.vendorPhone,
    vendorEmail: vendorEmail.present ? vendorEmail.value : this.vendorEmail,
    vendorUrl: vendorUrl.present ? vendorUrl.value : this.vendorUrl,
    remarks: remarks.present ? remarks.value : this.remarks,
    warrantyNotes: warrantyNotes.present
        ? warrantyNotes.value
        : this.warrantyNotes,
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
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      productCategory: data.productCategory.present
          ? data.productCategory.value
          : this.productCategory,
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
      status: data.status.present ? data.status.value : this.status,
      ocrRetryCount: data.ocrRetryCount.present
          ? data.ocrRetryCount.value
          : this.ocrRetryCount,
      lastOcrAttemptAt: data.lastOcrAttemptAt.present
          ? data.lastOcrAttemptAt.value
          : this.lastOcrAttemptAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      localImagePath: data.localImagePath.present
          ? data.localImagePath.value
          : this.localImagePath,
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
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      warrantyNotes: data.warrantyNotes.present
          ? data.warrantyNotes.value
          : this.warrantyNotes,
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
          ..write('productName: $productName, ')
          ..write('productCategory: $productCategory, ')
          ..write('warrantyPeriodMonths: $warrantyPeriodMonths, ')
          ..write('warrantyExpiryDate: $warrantyExpiryDate, ')
          ..write('returnPeriodDays: $returnPeriodDays, ')
          ..write('returnExpiryDate: $returnExpiryDate, ')
          ..write('status: $status, ')
          ..write('ocrRetryCount: $ocrRetryCount, ')
          ..write('lastOcrAttemptAt: $lastOcrAttemptAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('vendorAddress: $vendorAddress, ')
          ..write('vendorPhone: $vendorPhone, ')
          ..write('vendorEmail: $vendorEmail, ')
          ..write('vendorUrl: $vendorUrl, ')
          ..write('remarks: $remarks, ')
          ..write('warrantyNotes: $warrantyNotes')
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
    productName,
    productCategory,
    warrantyPeriodMonths,
    warrantyExpiryDate,
    returnPeriodDays,
    returnExpiryDate,
    status,
    ocrRetryCount,
    lastOcrAttemptAt,
    notes,
    createdAt,
    updatedAt,
    syncedAt,
    localImagePath,
    invoiceNumber,
    vendorAddress,
    vendorPhone,
    vendorEmail,
    vendorUrl,
    remarks,
    warrantyNotes,
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
          other.productName == this.productName &&
          other.productCategory == this.productCategory &&
          other.warrantyPeriodMonths == this.warrantyPeriodMonths &&
          other.warrantyExpiryDate == this.warrantyExpiryDate &&
          other.returnPeriodDays == this.returnPeriodDays &&
          other.returnExpiryDate == this.returnExpiryDate &&
          other.status == this.status &&
          other.ocrRetryCount == this.ocrRetryCount &&
          other.lastOcrAttemptAt == this.lastOcrAttemptAt &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.localImagePath == this.localImagePath &&
          other.invoiceNumber == this.invoiceNumber &&
          other.vendorAddress == this.vendorAddress &&
          other.vendorPhone == this.vendorPhone &&
          other.vendorEmail == this.vendorEmail &&
          other.vendorUrl == this.vendorUrl &&
          other.remarks == this.remarks &&
          other.warrantyNotes == this.warrantyNotes);
}

class ReceiptsCompanion extends UpdateCompanion<Receipt> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> s3ObjectKey;
  final Value<String?> storeName;
  final Value<DateTime?> purchaseDate;
  final Value<double?> totalAmount;
  final Value<String?> currency;
  final Value<String?> productName;
  final Value<String?> productCategory;
  final Value<int?> warrantyPeriodMonths;
  final Value<DateTime?> warrantyExpiryDate;
  final Value<int?> returnPeriodDays;
  final Value<DateTime?> returnExpiryDate;
  final Value<String> status;
  final Value<int> ocrRetryCount;
  final Value<DateTime?> lastOcrAttemptAt;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<String?> localImagePath;
  final Value<String?> invoiceNumber;
  final Value<String?> vendorAddress;
  final Value<String?> vendorPhone;
  final Value<String?> vendorEmail;
  final Value<String?> vendorUrl;
  final Value<String?> remarks;
  final Value<String?> warrantyNotes;
  final Value<int> rowid;
  const ReceiptsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.s3ObjectKey = const Value.absent(),
    this.storeName = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.productName = const Value.absent(),
    this.productCategory = const Value.absent(),
    this.warrantyPeriodMonths = const Value.absent(),
    this.warrantyExpiryDate = const Value.absent(),
    this.returnPeriodDays = const Value.absent(),
    this.returnExpiryDate = const Value.absent(),
    this.status = const Value.absent(),
    this.ocrRetryCount = const Value.absent(),
    this.lastOcrAttemptAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.localImagePath = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.vendorAddress = const Value.absent(),
    this.vendorPhone = const Value.absent(),
    this.vendorEmail = const Value.absent(),
    this.vendorUrl = const Value.absent(),
    this.remarks = const Value.absent(),
    this.warrantyNotes = const Value.absent(),
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
    this.productName = const Value.absent(),
    this.productCategory = const Value.absent(),
    this.warrantyPeriodMonths = const Value.absent(),
    this.warrantyExpiryDate = const Value.absent(),
    this.returnPeriodDays = const Value.absent(),
    this.returnExpiryDate = const Value.absent(),
    required String status,
    this.ocrRetryCount = const Value.absent(),
    this.lastOcrAttemptAt = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.localImagePath = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.vendorAddress = const Value.absent(),
    this.vendorPhone = const Value.absent(),
    this.vendorEmail = const Value.absent(),
    this.vendorUrl = const Value.absent(),
    this.remarks = const Value.absent(),
    this.warrantyNotes = const Value.absent(),
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
    Expression<String>? productName,
    Expression<String>? productCategory,
    Expression<int>? warrantyPeriodMonths,
    Expression<DateTime>? warrantyExpiryDate,
    Expression<int>? returnPeriodDays,
    Expression<DateTime>? returnExpiryDate,
    Expression<String>? status,
    Expression<int>? ocrRetryCount,
    Expression<DateTime>? lastOcrAttemptAt,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<String>? localImagePath,
    Expression<String>? invoiceNumber,
    Expression<String>? vendorAddress,
    Expression<String>? vendorPhone,
    Expression<String>? vendorEmail,
    Expression<String>? vendorUrl,
    Expression<String>? remarks,
    Expression<String>? warrantyNotes,
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
      if (productName != null) 'product_name': productName,
      if (productCategory != null) 'product_category': productCategory,
      if (warrantyPeriodMonths != null)
        'warranty_period_months': warrantyPeriodMonths,
      if (warrantyExpiryDate != null)
        'warranty_expiry_date': warrantyExpiryDate,
      if (returnPeriodDays != null) 'return_period_days': returnPeriodDays,
      if (returnExpiryDate != null) 'return_expiry_date': returnExpiryDate,
      if (status != null) 'status': status,
      if (ocrRetryCount != null) 'ocr_retry_count': ocrRetryCount,
      if (lastOcrAttemptAt != null) 'last_ocr_attempt_at': lastOcrAttemptAt,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (localImagePath != null) 'local_image_path': localImagePath,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (vendorAddress != null) 'vendor_address': vendorAddress,
      if (vendorPhone != null) 'vendor_phone': vendorPhone,
      if (vendorEmail != null) 'vendor_email': vendorEmail,
      if (vendorUrl != null) 'vendor_url': vendorUrl,
      if (remarks != null) 'remarks': remarks,
      if (warrantyNotes != null) 'warranty_notes': warrantyNotes,
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
    Value<String?>? productName,
    Value<String?>? productCategory,
    Value<int?>? warrantyPeriodMonths,
    Value<DateTime?>? warrantyExpiryDate,
    Value<int?>? returnPeriodDays,
    Value<DateTime?>? returnExpiryDate,
    Value<String>? status,
    Value<int>? ocrRetryCount,
    Value<DateTime?>? lastOcrAttemptAt,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<String?>? localImagePath,
    Value<String?>? invoiceNumber,
    Value<String?>? vendorAddress,
    Value<String?>? vendorPhone,
    Value<String?>? vendorEmail,
    Value<String?>? vendorUrl,
    Value<String?>? remarks,
    Value<String?>? warrantyNotes,
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
      productName: productName ?? this.productName,
      productCategory: productCategory ?? this.productCategory,
      warrantyPeriodMonths: warrantyPeriodMonths ?? this.warrantyPeriodMonths,
      warrantyExpiryDate: warrantyExpiryDate ?? this.warrantyExpiryDate,
      returnPeriodDays: returnPeriodDays ?? this.returnPeriodDays,
      returnExpiryDate: returnExpiryDate ?? this.returnExpiryDate,
      status: status ?? this.status,
      ocrRetryCount: ocrRetryCount ?? this.ocrRetryCount,
      lastOcrAttemptAt: lastOcrAttemptAt ?? this.lastOcrAttemptAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      localImagePath: localImagePath ?? this.localImagePath,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      vendorAddress: vendorAddress ?? this.vendorAddress,
      vendorPhone: vendorPhone ?? this.vendorPhone,
      vendorEmail: vendorEmail ?? this.vendorEmail,
      vendorUrl: vendorUrl ?? this.vendorUrl,
      remarks: remarks ?? this.remarks,
      warrantyNotes: warrantyNotes ?? this.warrantyNotes,
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
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (productCategory.present) {
      map['product_category'] = Variable<String>(productCategory.value);
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
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (warrantyNotes.present) {
      map['warranty_notes'] = Variable<String>(warrantyNotes.value);
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
          ..write('productName: $productName, ')
          ..write('productCategory: $productCategory, ')
          ..write('warrantyPeriodMonths: $warrantyPeriodMonths, ')
          ..write('warrantyExpiryDate: $warrantyExpiryDate, ')
          ..write('returnPeriodDays: $returnPeriodDays, ')
          ..write('returnExpiryDate: $returnExpiryDate, ')
          ..write('status: $status, ')
          ..write('ocrRetryCount: $ocrRetryCount, ')
          ..write('lastOcrAttemptAt: $lastOcrAttemptAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('vendorAddress: $vendorAddress, ')
          ..write('vendorPhone: $vendorPhone, ')
          ..write('vendorEmail: $vendorEmail, ')
          ..write('vendorUrl: $vendorUrl, ')
          ..write('remarks: $remarks, ')
          ..write('warrantyNotes: $warrantyNotes, ')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  late final $UploadQueueTable uploadQueue = $UploadQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [receipts, uploadQueue];
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
      Value<String?> productName,
      Value<String?> productCategory,
      Value<int?> warrantyPeriodMonths,
      Value<DateTime?> warrantyExpiryDate,
      Value<int?> returnPeriodDays,
      Value<DateTime?> returnExpiryDate,
      required String status,
      Value<int> ocrRetryCount,
      Value<DateTime?> lastOcrAttemptAt,
      Value<String?> notes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> syncedAt,
      Value<String?> localImagePath,
      Value<String?> invoiceNumber,
      Value<String?> vendorAddress,
      Value<String?> vendorPhone,
      Value<String?> vendorEmail,
      Value<String?> vendorUrl,
      Value<String?> remarks,
      Value<String?> warrantyNotes,
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
      Value<String?> productName,
      Value<String?> productCategory,
      Value<int?> warrantyPeriodMonths,
      Value<DateTime?> warrantyExpiryDate,
      Value<int?> returnPeriodDays,
      Value<DateTime?> returnExpiryDate,
      Value<String> status,
      Value<int> ocrRetryCount,
      Value<DateTime?> lastOcrAttemptAt,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
      Value<String?> localImagePath,
      Value<String?> invoiceNumber,
      Value<String?> vendorAddress,
      Value<String?> vendorPhone,
      Value<String?> vendorEmail,
      Value<String?> vendorUrl,
      Value<String?> remarks,
      Value<String?> warrantyNotes,
      Value<int> rowid,
    });

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

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
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

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warrantyNotes => $composableBuilder(
    column: $table.warrantyNotes,
    builder: (column) => ColumnFilters(column),
  );
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

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
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

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warrantyNotes => $composableBuilder(
    column: $table.warrantyNotes,
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

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
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

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<String> get warrantyNotes => $composableBuilder(
    column: $table.warrantyNotes,
    builder: (column) => column,
  );
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
          (Receipt, BaseReferences<_$AppDatabase, $ReceiptsTable, Receipt>),
          Receipt,
          PrefetchHooks Function()
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
                Value<String?> productName = const Value.absent(),
                Value<String?> productCategory = const Value.absent(),
                Value<int?> warrantyPeriodMonths = const Value.absent(),
                Value<DateTime?> warrantyExpiryDate = const Value.absent(),
                Value<int?> returnPeriodDays = const Value.absent(),
                Value<DateTime?> returnExpiryDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> ocrRetryCount = const Value.absent(),
                Value<DateTime?> lastOcrAttemptAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> localImagePath = const Value.absent(),
                Value<String?> invoiceNumber = const Value.absent(),
                Value<String?> vendorAddress = const Value.absent(),
                Value<String?> vendorPhone = const Value.absent(),
                Value<String?> vendorEmail = const Value.absent(),
                Value<String?> vendorUrl = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> warrantyNotes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsCompanion(
                id: id,
                userId: userId,
                s3ObjectKey: s3ObjectKey,
                storeName: storeName,
                purchaseDate: purchaseDate,
                totalAmount: totalAmount,
                currency: currency,
                productName: productName,
                productCategory: productCategory,
                warrantyPeriodMonths: warrantyPeriodMonths,
                warrantyExpiryDate: warrantyExpiryDate,
                returnPeriodDays: returnPeriodDays,
                returnExpiryDate: returnExpiryDate,
                status: status,
                ocrRetryCount: ocrRetryCount,
                lastOcrAttemptAt: lastOcrAttemptAt,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                localImagePath: localImagePath,
                invoiceNumber: invoiceNumber,
                vendorAddress: vendorAddress,
                vendorPhone: vendorPhone,
                vendorEmail: vendorEmail,
                vendorUrl: vendorUrl,
                remarks: remarks,
                warrantyNotes: warrantyNotes,
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
                Value<String?> productName = const Value.absent(),
                Value<String?> productCategory = const Value.absent(),
                Value<int?> warrantyPeriodMonths = const Value.absent(),
                Value<DateTime?> warrantyExpiryDate = const Value.absent(),
                Value<int?> returnPeriodDays = const Value.absent(),
                Value<DateTime?> returnExpiryDate = const Value.absent(),
                required String status,
                Value<int> ocrRetryCount = const Value.absent(),
                Value<DateTime?> lastOcrAttemptAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> localImagePath = const Value.absent(),
                Value<String?> invoiceNumber = const Value.absent(),
                Value<String?> vendorAddress = const Value.absent(),
                Value<String?> vendorPhone = const Value.absent(),
                Value<String?> vendorEmail = const Value.absent(),
                Value<String?> vendorUrl = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> warrantyNotes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsCompanion.insert(
                id: id,
                userId: userId,
                s3ObjectKey: s3ObjectKey,
                storeName: storeName,
                purchaseDate: purchaseDate,
                totalAmount: totalAmount,
                currency: currency,
                productName: productName,
                productCategory: productCategory,
                warrantyPeriodMonths: warrantyPeriodMonths,
                warrantyExpiryDate: warrantyExpiryDate,
                returnPeriodDays: returnPeriodDays,
                returnExpiryDate: returnExpiryDate,
                status: status,
                ocrRetryCount: ocrRetryCount,
                lastOcrAttemptAt: lastOcrAttemptAt,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                localImagePath: localImagePath,
                invoiceNumber: invoiceNumber,
                vendorAddress: vendorAddress,
                vendorPhone: vendorPhone,
                vendorEmail: vendorEmail,
                vendorUrl: vendorUrl,
                remarks: remarks,
                warrantyNotes: warrantyNotes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (Receipt, BaseReferences<_$AppDatabase, $ReceiptsTable, Receipt>),
      Receipt,
      PrefetchHooks Function()
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$UploadQueueTableTableManager get uploadQueue =>
      $$UploadQueueTableTableManager(_db, _db.uploadQueue);
}
