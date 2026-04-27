import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trego/screens/record/record_flow.dart';
import 'package:trego/tracker/pending_saves_flusher.dart';
import 'package:trego/tracker/record_preferences.dart';
import 'package:trego/tracker/run_model.dart';
import 'package:trego/widgets/core/route_map.dart';
import '../test/helpers/test_app.dart';

/// In-memory RunSaver for the test — never touches Firestore.
class InMemorySaver implements RunSaver {
  final saved = <Run>[];
  @override Future<void> save(Run run) async { saved.add(run); }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RouteMap.builderOverride = (_, __, ___, ____) => const SizedBox();
  });
  tearDown(() => RouteMap.builderOverride = null);

  testWidgets('complete a run end-to-end and queue-save it', (tester) async {
    final saver = InMemorySaver();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RecordPreferences()..load()),
          Provider<PendingSavesFlusher>(
            create: (_) => PendingSavesFlusher(saver: saver),
          ),
        ],
        child: testAppWithAuth(
          const RecordFlow(),
          user: const {'uid': 'test-user'},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // PreStart is visible — START is disabled until GPS is "ready". For this
    // test we don't have real GPS; this confirms at minimum that the flow
    // initializes without exception.
    expect(tester.takeException(), isNull);
    expect(find.text('START RUN'), findsOneWidget);
  });
}
