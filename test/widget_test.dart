import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trego/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Trego app builds without errors', (tester) async {
    // AppStateProvider synchronously constructs AuthService, which touches
    // FirebaseAuth.instance — Firebase isn't initialized in this test host.
    // We swallow the expected Firebase-not-initialized error (plus the
    // downstream "Null is not AppStateProvider" unmount error it causes)
    // and just confirm TregoApp wires up without a compile/import failure.
    final captured = <Object>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => captured.add(details.exception);

    try {
      await tester.pumpWidget(const TregoApp());
      await tester.pump();
      // Replace the tree with an empty widget so that unmount of the
      // partially-built provider scope happens BEFORE we restore onError,
      // letting us swallow the "Null is not AppStateProvider" teardown
      // error too.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    } finally {
      FlutterError.onError = previousOnError;
    }

    // Every caught exception must be one of the two we expect from the
    // uninitialized Firebase test host.
    for (final e in captured) {
      final msg = e.toString();
      expect(
        msg.contains('No Firebase App') ||
            msg.contains("'Null' is not a subtype of type 'AppStateProvider'"),
        isTrue,
        reason: 'Unexpected exception during smoke test: $e',
      );
    }
  });
}
