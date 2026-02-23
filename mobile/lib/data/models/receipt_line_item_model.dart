import 'package:json_annotation/json_annotation.dart';

part 'receipt_line_item_model.g.dart';

/// A single product / service line item on a receipt or invoice.
@JsonSerializable()
class ReceiptLineItemModel {
  final String id;
  final String receiptId;
  final int rowIndex;
  final String? productCode;
  final String? itemDescription;
  final String? quantity;
  final double? unitPrice;
  final double? amount;
  final DateTime createdAt;

  const ReceiptLineItemModel({
    required this.id,
    required this.receiptId,
    required this.rowIndex,
    this.productCode,
    this.itemDescription,
    this.quantity,
    this.unitPrice,
    this.amount,
    required this.createdAt,
  });

  factory ReceiptLineItemModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptLineItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReceiptLineItemModelToJson(this);
}
