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
  quantity: json['quantity'] as String?,
  unitPrice: (json['unitPrice'] as num?)?.toDouble(),
  amount: (json['amount'] as num?)?.toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ReceiptLineItemModelToJson(
  ReceiptLineItemModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'receiptId': instance.receiptId,
  'rowIndex': instance.rowIndex,
  'productCode': instance.productCode,
  'itemDescription': instance.itemDescription,
  'quantity': instance.quantity,
  'unitPrice': instance.unitPrice,
  'amount': instance.amount,
  'createdAt': instance.createdAt.toIso8601String(),
};
