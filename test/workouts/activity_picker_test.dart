import 'package:flutter_test/flutter_test.dart';
import 'package:trego/widgets/core/trego_app_bar.dart';
import 'package:trego/workouts/activity/activity_picker_screen.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('picker lists categories and activities', (tester) async {
    await tester.pumpWidget(testApp(const ActivityPickerScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Soccer'), findsOneWidget);
    expect(find.text('Weight Training'), findsOneWidget);
  });

  testWidgets('standalone picker shows its own app bar', (tester) async {
    await tester.pumpWidget(testApp(const ActivityPickerScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(TregoAppBar), findsOneWidget);
    expect(find.text('Log Activity'), findsOneWidget);
  });
}
