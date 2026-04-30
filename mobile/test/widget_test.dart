import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mobile/screens/main_shell.dart';
import 'package:mobile/core/constants/app_theme.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/receipt_provider.dart';
import 'package:mobile/providers/claim_provider.dart';
import 'package:mobile/data/models/user_model.dart';
import 'package:mobile/screens/home/home_screen.dart';
import 'package:mobile/screens/vault/vault_screen.dart';
import 'package:mobile/screens/claims/claims_hub_screen.dart';
import 'package:mobile/screens/settings/settings_screen.dart';

void main() {
  testWidgets('MainShell renders app shell and allows basic tab navigation', (
    tester,
  ) async {
    // Override backend-dependent providers to return empty/mock data
    final overrides = [
      authStateProvider.overrideWith((ref) => const Stream.empty()),
      currentUserProvider.overrideWith((ref) => null),
      userProfileProvider.overrideWith(
        (ref) async => UserModel(
          id: 'mock-id',
          firebaseUid: 'mock-uid',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      receiptsProvider.overrideWith((ref) async => []),
      userClaimsProvider.overrideWith((ref) async => []),
    ];

    // Build the MainShell wrapped in required Providers and MaterialApp
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(home: const MainShell(), theme: AppTheme.lightTheme),
      ),
    );

    // Wait for Futures to resolve and animations to settle
    await tester.pumpAndSettle();

    // 1. Verify Home screen is the default active tab
    expect(find.byType(HomeScreen), findsOneWidget);
    // Note: IndexedStack keeps off-screen widgets in the tree but they might be hidden or offstage.
    // To strictly test visibility, we ensure the Bottom Nav Bar renders correctly.

    // 2. Navigate to Vault tab
    await tester.tap(find.byIcon(Symbols.view_object_track_rounded));
    await tester.pumpAndSettle();

    // We expect the Vault screen to be built
    expect(find.byType(VaultScreen), findsOneWidget);

    // 3. Navigate to Claims tab
    await tester.tap(find.byIcon(Symbols.fiber_smart_record_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(ClaimsHubScreen), findsOneWidget);

    // 4. Navigate to Settings tab
    await tester.tap(find.byIcon(Symbols.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
