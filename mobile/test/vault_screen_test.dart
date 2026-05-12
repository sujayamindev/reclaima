import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_theme.dart';
import 'package:mobile/data/models/receipt_line_item_model.dart';
import 'package:mobile/data/models/receipt_model.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/receipt_provider.dart';
import 'package:mobile/screens/main_shell.dart';
import 'package:mobile/screens/vault/vault_screen.dart';

ReceiptLineItemModel _lineItem({
  String id = 'item-1',
  String receiptId = 'r-1',
  String? productName = 'Laptop Pro',
  String status = 'ACTIVE',
  DateTime? warrantyExpiry,
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
    warrantyExpiryDate: warrantyExpiry ?? now.add(const Duration(days: 365)),
  );
}

ReceiptModel _receipt({
  String id = 'r-1',
  String? storeName = 'TechMart',
  List<ReceiptLineItemModel>? items,
}) {
  final now = DateTime.now();
  return ReceiptModel(
    id: id,
    userId: 'user-1',
    storeName: storeName,
    status: ReceiptStatus.completed,
    ocrRetryCount: 0,
    createdAt: now,
    updatedAt: now,
    lineItems: items ?? [_lineItem(receiptId: id)],
  );
}

Widget _wrap({required Future<List<ReceiptModel>> Function() receipts}) =>
    ProviderScope(
      overrides: [
        receiptsProvider.overrideWith((ref) => receipts()),
        vaultSearchFocusTriggerProvider.overrideWith((ref) => false),
        // authStateProvider needed by any provider that transitively reads it
        authStateProvider.overrideWith((ref) => const Stream.empty()),
        currentUserProvider.overrideWith((ref) => null),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: const VaultScreen()),
    );

void main() {
  group('VaultScreen', () {
    testWidgets('shows loading spinner while data is fetching', (tester) async {
      await tester.pumpWidget(
        _wrap(receipts: () => Completer<List<ReceiptModel>>().future),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when receipts fail to load', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(receipts: () async => throw Exception('Network error')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Error loading products'), findsOneWidget);
    });

    testWidgets('shows Vault heading when receipts are loaded', (tester) async {
      await tester.pumpWidget(_wrap(receipts: () async => []));
      await tester.pumpAndSettle();
      expect(find.text('Vault'), findsOneWidget);
    });

    testWidgets('shows product name when a receipt with line items is loaded', (
      tester,
    ) async {
      final data = [_receipt()];
      await tester.pumpWidget(_wrap(receipts: () async => data));
      await tester.pumpAndSettle();
      expect(find.text('Laptop Pro'), findsOneWidget);
    });

    testWidgets('shows product count when receipts are loaded', (tester) async {
      await tester.pumpWidget(_wrap(receipts: () async => [_receipt()]));
      await tester.pumpAndSettle();
      // Header shows "N product(s)" below the search bar
      expect(find.text('1 product'), findsOneWidget);
    });
  });
}
