import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/product_selector_sheet.dart';
import 'package:mobile/data/models/receipt_model.dart';
import 'package:mobile/data/models/receipt_line_item_model.dart';
import 'package:mobile/core/constants/app_theme.dart';

ReceiptLineItemModel _item({
  String id = 'item-1',
  String receiptId = 'receipt-1',
  String? productName,
  String status = 'ACTIVE',
  DateTime? warrantyExpiry,
  DateTime? returnExpiry,
}) {
  final now = DateTime.now();
  return ReceiptLineItemModel(
    id: id,
    receiptId: receiptId,
    rowIndex: 0,
    productName: productName,
    createdAt: now,
    updatedAt: now,
    status: status,
    warrantyExpiryDate: warrantyExpiry,
    returnExpiryDate: returnExpiry,
  );
}

ReceiptModel _receipt({
  String id = 'receipt-1',
  String? storeName,
  List<ReceiptLineItemModel> lineItems = const [],
}) {
  final now = DateTime.now();
  return ReceiptModel(
    id: id,
    userId: 'user-1',
    status: ReceiptStatus.completed,
    ocrRetryCount: 0,
    createdAt: now,
    updatedAt: now,
    storeName: storeName,
    lineItems: lineItems,
  );
}

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );

void main() {
  group('ProductSelectorSheet', () {
    testWidgets('shows title', (tester) async {
      await tester.pumpWidget(_wrap(ProductSelectorSheet(receipts: const [])));
      await tester.pumpAndSettle();
      expect(find.text('Select Product to Claim'), findsOneWidget);
    });

    testWidgets('shows empty state when receipts list is empty', (tester) async {
      await tester.pumpWidget(_wrap(ProductSelectorSheet(receipts: const [])));
      await tester.pumpAndSettle();
      expect(find.text('No products found'), findsOneWidget);
    });

    testWidgets('shows empty state when receipts have no line items',
        (tester) async {
      await tester.pumpWidget(
        _wrap(ProductSelectorSheet(receipts: [_receipt(storeName: 'Best Buy')])),
      );
      await tester.pumpAndSettle();
      expect(find.text('No products found'), findsOneWidget);
    });

    testWidgets('renders product name and store name for active items',
        (tester) async {
      final item = _item(productName: 'Laptop', receiptId: 'r1');
      final receipt = _receipt(id: 'r1', storeName: 'Best Buy', lineItems: [item]);
      await tester.pumpWidget(_wrap(ProductSelectorSheet(receipts: [receipt])));
      await tester.pumpAndSettle();
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Best Buy'), findsOneWidget);
    });

    testWidgets('filters out ARCHIVED items', (tester) async {
      final archived = _item(
        id: 'i1',
        productName: 'OldPhone',
        status: 'ARCHIVED',
      );
      final active = _item(id: 'i2', productName: 'NewPhone');
      final receipt = _receipt(lineItems: [archived, active]);
      await tester.pumpWidget(_wrap(ProductSelectorSheet(receipts: [receipt])));
      await tester.pumpAndSettle();
      expect(find.text('OldPhone'), findsNothing);
      expect(find.text('NewPhone'), findsOneWidget);
    });

    testWidgets('search filters products by product name', (tester) async {
      final item1 = _item(id: 'i1', productName: 'Laptop');
      final item2 = _item(id: 'i2', productName: 'Phone');
      final receipt = _receipt(lineItems: [item1, item2]);
      await tester.pumpWidget(_wrap(ProductSelectorSheet(receipts: [receipt])));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'lap');
      await tester.pumpAndSettle();
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Phone'), findsNothing);
    });

    testWidgets('search filters products by store name', (tester) async {
      final item1 = _item(id: 'i1', receiptId: 'r1', productName: 'Headphones');
      final item2 = _item(id: 'i2', receiptId: 'r2', productName: 'Keyboard');
      final receipt1 = _receipt(id: 'r1', storeName: 'Apple Store', lineItems: [item1]);
      final receipt2 = _receipt(id: 'r2', storeName: 'Amazon', lineItems: [item2]);
      await tester.pumpWidget(
        _wrap(ProductSelectorSheet(receipts: [receipt1, receipt2])),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'apple');
      await tester.pumpAndSettle();
      expect(find.text('Headphones'), findsOneWidget);
      expect(find.text('Keyboard'), findsNothing);
    });

    testWidgets('search with no matches shows empty state', (tester) async {
      final item = _item(productName: 'Monitor');
      final receipt = _receipt(storeName: 'Dell', lineItems: [item]);
      await tester.pumpWidget(_wrap(ProductSelectorSheet(receipts: [receipt])));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pumpAndSettle();
      expect(find.text('No products found'), findsOneWidget);
    });

    testWidgets('uses itemDescription as fallback when productName is null',
        (tester) async {
      final now = DateTime.now();
      final item = ReceiptLineItemModel(
        id: 'i1',
        receiptId: 'r1',
        rowIndex: 0,
        itemDescription: 'USB Cable',
        createdAt: now,
        updatedAt: now,
        status: 'ACTIVE',
      );
      final receipt = _receipt(id: 'r1', lineItems: [item]);
      await tester.pumpWidget(_wrap(ProductSelectorSheet(receipts: [receipt])));
      await tester.pumpAndSettle();
      expect(find.text('USB Cable'), findsOneWidget);
    });

    testWidgets('items with active warranty are included', (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 365));
      final item = _item(
        productName: 'TV',
        warrantyExpiry: futureDate,
      );
      final receipt = _receipt(lineItems: [item]);
      await tester.pumpWidget(_wrap(ProductSelectorSheet(receipts: [receipt])));
      await tester.pumpAndSettle();
      expect(find.text('TV'), findsOneWidget);
    });
  });
}
