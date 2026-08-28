import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/notifications/widgets/notification_badge.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  Widget wrap(int count) =>
      testApp(Scaffold(body: Center(child: NotificationBadge(count: count))));

  testWidgets('hidden at zero', (tester) async {
    await tester.pumpWidget(wrap(0));
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('shows the count', (tester) async {
    await tester.pumpWidget(wrap(3));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('caps at 9+', (tester) async {
    await tester.pumpWidget(wrap(42));
    expect(find.text('9+'), findsOneWidget);
  });
}
