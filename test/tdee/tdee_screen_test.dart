import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/tdee/tdee_screen.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('TdeeScreen builds and shows the calculator form',
      (tester) async {
    await tester.pumpWidget(testApp(const TdeeScreen()));
    await tester.pump();

    // Title
    expect(find.text('TDEE Calculator'), findsOneWidget);
    // An input field (Age)
    expect(find.text('Age'), findsOneWidget);
    // The calculate action
    expect(find.text('Calculate TDEE'), findsOneWidget);
  });
}
