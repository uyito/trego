import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trego/screens/recording_settings_screen.dart';
import 'package:trego/tracker/record_preferences.dart';
import '../helpers/test_app.dart';

Widget _wrap(Widget child, RecordPreferences prefs) =>
    ChangeNotifierProvider<RecordPreferences>.value(
      value: prefs,
      child: testApp(child),
    );

void main() {
  initTestEnv();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows auto-pause row with checkmark when enabled', (tester) async {
    final prefs = RecordPreferences();
    await prefs.load();
    await tester.pumpWidget(_wrap(const RecordingSettingsScreen(), prefs));
    expect(find.text('Auto-pause'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('toggle flips preference', (tester) async {
    final prefs = RecordPreferences();
    await prefs.load();
    await tester.pumpWidget(_wrap(const RecordingSettingsScreen(), prefs));

    await tester.tap(find.text('Auto-pause'));
    await tester.pumpAndSettle();

    expect(prefs.autoPauseEnabled, isFalse);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });
}
