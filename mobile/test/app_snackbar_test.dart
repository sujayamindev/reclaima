import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/app_snackbar.dart';
import 'package:mobile/core/constants/app_theme.dart';

Widget _scaffold(void Function(BuildContext) onTap, String label) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: Builder(
        builder: (ctx) =>
            ElevatedButton(onPressed: () => onTap(ctx), child: Text(label)),
      ),
    ),
  );
}

void main() {
  group('AppSnackBar', () {
    testWidgets('showError displays snackbar with message', (tester) async {
      await tester.pumpWidget(
        _scaffold(
          (ctx) => AppSnackBar.showError(ctx, message: 'Something went wrong'),
          'tap',
        ),
      );
      await tester.tap(find.text('tap'));
      await tester.pump();
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('showSuccess displays snackbar with message', (tester) async {
      await tester.pumpWidget(
        _scaffold(
          (ctx) => AppSnackBar.showSuccess(ctx, message: 'Saved successfully'),
          'tap',
        ),
      );
      await tester.tap(find.text('tap'));
      await tester.pump();
      expect(find.text('Saved successfully'), findsOneWidget);
    });

    testWidgets('showInfo displays snackbar with message', (tester) async {
      await tester.pumpWidget(
        _scaffold(
          (ctx) => AppSnackBar.showInfo(ctx, message: 'Please wait'),
          'tap',
        ),
      );
      await tester.tap(find.text('tap'));
      await tester.pump();
      expect(find.text('Please wait'), findsOneWidget);
    });

    testWidgets('snackbar uses floating behavior', (tester) async {
      await tester.pumpWidget(
        _scaffold((ctx) => AppSnackBar.showError(ctx, message: 'Error'), 'tap'),
      );
      await tester.tap(find.text('tap'));
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
    });
  });
}
