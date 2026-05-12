import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/screens/home/home_screen.dart';
import 'package:mobile/screens/main_shell.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/receipt_provider.dart';
import 'package:mobile/providers/claim_provider.dart';
import 'package:mobile/data/models/receipt_model.dart';
import 'package:mobile/data/models/receipt_line_item_model.dart';
import 'package:mobile/data/models/user_model.dart';
import 'package:mobile/services/claim_service.dart';
import 'package:mobile/core/constants/app_theme.dart';

Widget _wrap({
  List<ReceiptModel> receipts = const [],
  List<ClaimDocumentResponse> claims = const [],
  String greeting = 'Good morning,',
  String displayName = 'Alex',
}) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith((ref) => const Stream.empty()),
    currentUserProvider.overrideWith((ref) => null),
    userProfileProvider.overrideWith(
      (ref) async => UserModel(
        id: 'mock-id',
        firebaseUid: 'mock-uid',
        email: 'test@example.com',
        displayName: displayName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ),
    greetingProvider.overrideWithValue(greeting),
    displayNameProvider.overrideWithValue(displayName),
    mainNavIndexProvider.overrideWith((ref) => 0),
    vaultSearchFocusTriggerProvider.overrideWith((ref) => false),
    receiptsProvider.overrideWith((ref) async => receipts),
    userClaimsProvider.overrideWith((ref) async => claims),
  ],
  child: MaterialApp(theme: AppTheme.lightTheme, home: const HomeScreen()),
);

ReceiptLineItemModel _lineItem({
  String id = 'item-1',
  String receiptId = 'r-1',
}) {
  final now = DateTime.now();
  return ReceiptLineItemModel(
    id: id,
    receiptId: receiptId,
    rowIndex: 0,
    productName: 'Sample Product',
    createdAt: now,
    updatedAt: now,
    status: 'ACTIVE',
    warrantyExpiryDate: now.add(const Duration(days: 180)),
  );
}

ReceiptModel _receipt({String id = 'r-1', List<ReceiptLineItemModel>? items}) {
  final now = DateTime.now();
  return ReceiptModel(
    id: id,
    userId: 'user-1',
    storeName: 'Demo Store',
    status: ReceiptStatus.completed,
    ocrRetryCount: 0,
    createdAt: now,
    updatedAt: now,
    lineItems: items ?? [_lineItem(receiptId: id)],
  );
}

void main() {
  group('HomeScreen', () {
    testWidgets('renders Receipta. app title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Receipta.'), findsOneWidget);
    });

    testWidgets('renders greeting from provider', (tester) async {
      await tester.pumpWidget(_wrap(greeting: 'Good evening,'));
      await tester.pumpAndSettle();
      expect(find.text('Good evening,'), findsOneWidget);
    });

    testWidgets('renders display name from provider', (tester) async {
      await tester.pumpWidget(_wrap(displayName: 'Jordan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Jordan'), findsOneWidget);
    });

    testWidgets('renders Add New button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Add New'), findsOneWidget);
    });

    testWidgets('shows Nothing Here Yet when no receipts', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Nothing Here Yet!'), findsOneWidget);
    });

    testWidgets('shows Total stat label when receipts are loaded', (
      tester,
    ) async {
      final receipts = [_receipt()];
      await tester.pumpWidget(_wrap(receipts: receipts));
      await tester.pumpAndSettle();
      expect(find.text('Total'), findsOneWidget);
    });
  });
}
