import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/screens/receipt/product_detail_screen.dart';
import 'package:mobile/providers/receipt_provider.dart';
import 'package:mobile/data/database/app_database.dart';
import 'package:mobile/providers/service_providers.dart';
import 'package:mobile/data/models/receipt_model.dart';
import 'package:mobile/data/models/receipt_line_item_model.dart';
import 'package:mobile/core/constants/app_theme.dart';

ReceiptLineItemModel _lineItem() {
  final now = DateTime.now();
  return ReceiptLineItemModel(
    id: 'item-1',
    receiptId: 'receipt-1',
    rowIndex: 0,
    productName: 'Test Camera',
    createdAt: now,
    updatedAt: now,
    status: 'ACTIVE',
  );
}

ReceiptModel _receipt() {
  final now = DateTime.now();
  return ReceiptModel(
    id: 'receipt-1',
    userId: 'user-1',
    storeName: 'Best Buy',
    status: ReceiptStatus.completed,
    ocrRetryCount: 0,
    createdAt: now,
    updatedAt: now,
    lineItems: [_lineItem()],
  );
}

// Base overrides shared by every variant of the screen
List<Override> _baseOverrides() => [
  databaseProvider.overrideWith((ref) => AppDatabase.forTesting()),
];

Widget _wrapLoading() => ProviderScope(
  overrides: [
    ..._baseOverrides(),
    receiptProvider(
      'receipt-1',
    ).overrideWith((ref) => Completer<ReceiptModel>().future),
    receiptImageUrlProvider('receipt-1').overrideWith((ref) async => null),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    home: const ProductDetailScreen(receiptId: 'receipt-1'),
  ),
);

Widget _wrapError() => ProviderScope(
  overrides: [
    ..._baseOverrides(),
    receiptProvider(
      'receipt-1',
    ).overrideWith((ref) async => throw Exception('Not found')),
    receiptImageUrlProvider('receipt-1').overrideWith((ref) async => null),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    home: const ProductDetailScreen(receiptId: 'receipt-1'),
  ),
);

Widget _wrapData({String? lineItemId = 'item-1'}) => ProviderScope(
  overrides: [
    ..._baseOverrides(),
    receiptProvider('receipt-1').overrideWith((ref) async => _receipt()),
    receiptImageUrlProvider('receipt-1').overrideWith((ref) async => null),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    home: ProductDetailScreen(receiptId: 'receipt-1', lineItemId: lineItemId),
  ),
);

void main() {
  group('ProductDetailScreen', () {
    testWidgets('shows loading spinner while receipt is fetching', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapLoading());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error text when receipt fetch fails', (tester) async {
      await tester.pumpWidget(_wrapError());
      await tester.pumpAndSettle();
      expect(find.text('Failed to load product'), findsOneWidget);
    });

    testWidgets('shows Product Details app bar title when loaded', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapData());
      await tester.pumpAndSettle();
      expect(find.text('Product Details'), findsOneWidget);
    });

    testWidgets('shows store name in hero card when loaded', (tester) async {
      await tester.pumpWidget(_wrapData());
      await tester.pumpAndSettle();
      expect(find.text('Best Buy'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows product name from line item when loaded', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapData());
      await tester.pumpAndSettle();
      expect(find.text('Test Camera'), findsOneWidget);
    });
  });
}
