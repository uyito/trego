import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trego/navigation/app_shell.dart';
import 'package:trego/providers/app_state_provider.dart';
import 'package:trego/providers/feed_provider.dart';
import 'package:trego/providers/plan_provider.dart';

import '../helpers/test_app.dart';

Widget _wrap(Widget child) => ChangeNotifierProvider<AppStateProvider>.value(
      value: FakeAppStateProvider(),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PlanProvider()),
          ChangeNotifierProvider(create: (_) => FeedProvider()),
        ],
        child: testApp(child),
      ),
    );

void main() {
  initTestEnv();

  testWidgets('shell starts on Home tab', (tester) async {
    await tester.pumpWidget(_wrap(const AppShell()));
    expect(find.text('THIS WEEK'), findsOneWidget);
  });

  testWidgets('tapping Plan tab shows Plan placeholder', (tester) async {
    await tester.pumpWidget(_wrap(const AppShell()));
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Training plans coming soon'), findsOneWidget);
  });

  testWidgets('tapping You tab shows Tools row', (tester) async {
    await tester.pumpWidget(_wrap(const AppShell()));
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();
    expect(find.text('TOOLS'), findsOneWidget);
  });

  testWidgets('tapping center Record button opens modal', (tester) async {
    await tester.pumpWidget(_wrap(const AppShell()));
    await tester.tap(find.byKey(const Key('shell-record-button')));
    await tester.pumpAndSettle();
    expect(find.text('Record flow coming soon'), findsOneWidget);
  });
}
