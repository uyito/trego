import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:trego/providers/feed_provider.dart';
import 'package:trego/providers/plan_provider.dart';
import 'package:trego/screens/home_screen.dart';
import 'package:trego/shared/theme/trego_theme.dart';

Widget _wrap(Widget child) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => PlanProvider()),
    ChangeNotifierProvider(create: (_) => FeedProvider()),
  ],
  child: MaterialApp(
    theme: TregoTheme.light(),
    darkTheme: TregoTheme.dark(),
    themeMode: ThemeMode.dark,
    home: child,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('renders empty hero and empty friends state', (tester) async {
    await tester.pumpWidget(_wrap(const HomeScreen()));
    expect(find.text('No plan yet'), findsOneWidget);
    expect(find.text('Invite friends to see their runs'), findsOneWidget);
  });

  testWidgets('shows stat tiles section header', (tester) async {
    await tester.pumpWidget(_wrap(const HomeScreen()));
    expect(find.text('THIS WEEK'), findsOneWidget);
  });
}
