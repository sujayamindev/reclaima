// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_line_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiptLineItemModel _$ReceiptLineItemModelFromJson(
  Map<String, dynamic> json,
) => ReceiptLineItemModel(
  id: json['id'] as String,
  receiptId: json['receiptId'] as String,
  rowIndex: (json['rowIndex'] as num).toInt(),
  productCode: json['productCode'] as String?,
  itemDescription: json['itemDescription'] as String?,
  unitPrice: (json['unitPrice'] as num?)?.toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  productName: json['productName'] as String?,
  productCategory: json['productCategory'] as String?,
  productImageUrl: json['productImageUrl'] as String?,
  warrantyPeriodMonths: (json['warrantyPeriodMonths'] as num?)?.toInt(),
  warrantyExpiryDate: json['warrantyExpiryDate'] == null
      ? null
      : DateTime.parse(json['warrantyExpiryDate'] as String),
  returnPeriodDays: (json['returnPeriodDays'] as num?)?.toInt(),
  returnExpiryDate: json['returnExpiryDate'] == null
      ? null
      : DateTime.parse(json['returnExpiryDate'] as String),
  warrantyLeadDaysOverride: (json['warrantyLeadDaysOverride'] as num?)?.toInt(),
  returnLeadDaysOverride: (json['returnLeadDaysOverride'] as num?)?.toInt(),
  warrantyReminderEnabled: json['warrantyReminderEnabled'] as bool?,
  returnReminderEnabled: json['returnReminderEnabled'] as bool?,
  status: json['status'] as String? ?? 'ACTIVE',
  replacementForId: json['replacementForId'] as String?,
  replacedById: json['replacedById'] as String?,
);

Map<String, dynamic> _$ReceiptLineItemModelToJson(
  ReceiptLineItemModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'receiptId': instance.receiptId,
  'rowIndex': instance.rowIndex,
  'productCode': instance.productCode,
  'itemDescription': instance.itemDescription,
  'unitPrice': instance.unitPrice,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'productName': instance.productName,
  'productCategory': instance.productCategory,
  'productImageUrl': instance.productImageUrl,
  'warrantyPeriodMonths': instance.warrantyPeriodMonths,
  'warrantyExpiryDate': instance.warrantyExpiryDate?.toIso8601String(),
  'returnPeriodDays': instance.returnPeriodDays,
  'returnExpiryDate': instance.returnExpiryDate?.toIso8601String(),
  'warrantyLeadDaysOverride': instance.warrantyLeadDaysOverride,
  'returnLeadDaysOverride': instance.returnLeadDaysOverride,
  'warrantyReminderEnabled': instance.warrantyReminderEnabled,
  'returnReminderEnabled': instance.returnReminderEnabled,
  'status': instance.status,
  'replacementForId': instance.replacementForId,
  'replacedById': instance.replacedById,
};
