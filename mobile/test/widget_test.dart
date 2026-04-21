import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/navigation.dart';

void main() {
  testWidgets('navigator key is available for global routing', (tester) async {
    expect(navigatorKey, isA<GlobalKey<NavigatorState>>());
    expect(navigatorKey.currentState, isNull);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    expect(find.byType(SizedBox), findsOneWidget);
  });
}
