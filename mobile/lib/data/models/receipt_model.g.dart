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
  productName: json['productName'] as String?,
  productCategory: json['productCategory'] as String?,
  warrantyPeriodMonths: (json['warrantyPeriodMonths'] as num?)?.toInt(),
  warrantyExpiryDate: json['warrantyExpiryDate'] == null
      ? null
      : DateTime.parse(json['warrantyExpiryDate'] as String),
  returnPeriodDays: (json['returnPeriodDays'] as num?)?.toInt(),
  returnExpiryDate: json['returnExpiryDate'] == null
      ? null
      : DateTime.parse(json['returnExpiryDate'] as String),
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
      'productName': instance.productName,
      'productCategory': instance.productCategory,
      'warrantyPeriodMonths': instance.warrantyPeriodMonths,
      'warrantyExpiryDate': instance.warrantyExpiryDate?.toIso8601String(),
      'returnPeriodDays': instance.returnPeriodDays,
      'returnExpiryDate': instance.returnExpiryDate?.toIso8601String(),
      'status': _$ReceiptStatusEnumMap[instance.status]!,
      'ocrRetryCount': instance.ocrRetryCount,
      'lastOcrAttemptAt': instance.lastOcrAttemptAt?.toIso8601String(),
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'syncedAt': instance.syncedAt?.toIso8601String(),
    };

const _$ReceiptStatusEnumMap = {
  ReceiptStatus.localOnly: 'LOCAL_ONLY',
  ReceiptStatus.uploaded: 'UPLOADED',
  ReceiptStatus.processing: 'PROCESSING',
  ReceiptStatus.completed: 'COMPLETED',
  ReceiptStatus.ocrFailed: 'OCR_FAILED',
  ReceiptStatus.manualEntry: 'MANUAL_ENTRY',
};
