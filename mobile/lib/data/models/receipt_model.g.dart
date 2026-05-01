// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiptModel _$ReceiptModelFromJson(Map<String, dynamic> json) => ReceiptModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  s3ObjectKey: json['s3ObjectKey'] as String?,
  storeName: json['storeName'] as String?,
  purchaseDate: json['purchaseDate'] == null
      ? null
      : DateTime.parse(json['purchaseDate'] as String),
  totalAmount: (json['totalAmount'] as num?)?.toDouble(),
  currency: json['currency'] as String?,
  status: $enumDecode(_$ReceiptStatusEnumMap, json['status']),
  ocrRetryCount: (json['ocrRetryCount'] as num).toInt(),
  lastOcrAttemptAt: json['lastOcrAttemptAt'] == null
      ? null
      : DateTime.parse(json['lastOcrAttemptAt'] as String),
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  syncedAt: json['syncedAt'] == null
      ? null
      : DateTime.parse(json['syncedAt'] as String),
  invoiceNumber: json['invoiceNumber'] as String?,
  vendorAddress: json['vendorAddress'] as String?,
  vendorPhone: json['vendorPhone'] as String?,
  vendorEmail: json['vendorEmail'] as String?,
  vendorUrl: json['vendorUrl'] as String?,
  remarks: json['remarks'] as String?,
  warrantyNotes: json['warrantyNotes'] as String?,
  lineItems:
      (json['lineItems'] as List<dynamic>?)
          ?.map((e) => ReceiptLineItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ReceiptModelToJson(ReceiptModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      's3ObjectKey': instance.s3ObjectKey,
      'storeName': instance.storeName,
      'purchaseDate': instance.purchaseDate?.toIso8601String(),
      'totalAmount': instance.totalAmount,
      'currency': instance.currency,
      'status': _$ReceiptStatusEnumMap[instance.status]!,
      'ocrRetryCount': instance.ocrRetryCount,
      'lastOcrAttemptAt': instance.lastOcrAttemptAt?.toIso8601String(),
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'syncedAt': instance.syncedAt?.toIso8601String(),
      'invoiceNumber': instance.invoiceNumber,
      'vendorAddress': instance.vendorAddress,
      'vendorPhone': instance.vendorPhone,
      'vendorEmail': instance.vendorEmail,
      'vendorUrl': instance.vendorUrl,
      'remarks': instance.remarks,
      'warrantyNotes': instance.warrantyNotes,
      'lineItems': instance.lineItems,
    };

const _$ReceiptStatusEnumMap = {
  ReceiptStatus.localOnly: 'LOCAL_ONLY',
  ReceiptStatus.uploaded: 'UPLOADED',
  ReceiptStatus.processing: 'PROCESSING',
  ReceiptStatus.completed: 'COMPLETED',
  ReceiptStatus.ocrFailed: 'OCR_FAILED',
  ReceiptStatus.manualEntry: 'MANUAL_ENTRY',
};
