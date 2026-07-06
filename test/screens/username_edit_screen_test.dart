import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/auth/username_api.dart';
import 'package:trego/screens/username_edit_screen.dart';
import 'package:trego/shared/theme/trego_theme.dart';

/// Fake UsernameApi: records the call, returns a preset result (null = success).
class _FakeUsernameApi extends UsernameApi {
  String? nextError;
  String? lastSubmitted;
  int calls = 0;

  @override
  Future<String?> setUsername(String username) async {
    calls++;
    lastSubmitted = username;
    return nextError;
  }
}

void main() {
  Widget wrap(Widget child) => MaterialApp(theme: TregoTheme.light(), home: child);

  testWidgets('valid submit calls api and pops with the username', (tester) async {
    final api = _FakeUsernameApi();
    String? popped;
    await tester.pumpWidget(wrap(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            popped = await Navigator.of(context).push<String>(
              MaterialPageRoute(builder: (_) => UsernameEditScreen(api: api)),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'runner');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(api.calls, 1);
    expect(api.lastSubmitted, 'runner');
    expect(popped, 'runner');
  });

  testWidgets('client-side invalid blocks the api call and shows error', (tester) async {
    final api = _FakeUsernameApi();
    await tester.pumpWidget(wrap(UsernameEditScreen(api: api)));

    await tester.enterText(find.byType(TextField), 'ab'); // too short
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(api.calls, 0);
    expect(find.textContaining('3–20 characters'), findsOneWidget);
  });

  testWidgets('server error (taken) is shown inline, no pop', (tester) async {
    final api = _FakeUsernameApi()..nextError = 'That username is already taken';
    await tester.pumpWidget(wrap(UsernameEditScreen(api: api)));

    await tester.enterText(find.byType(TextField), 'taken');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(api.calls, 1);
    expect(find.text('That username is already taken'), findsOneWidget);
  });
}
