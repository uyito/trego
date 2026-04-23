import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:trego/providers/app_state_provider.dart';
import 'package:trego/shared/theme/trego_theme.dart';

/// Ensures test-environment binding + offline google_fonts.
/// Call once from `main()` of every widget/golden test file.
void initTestEnv() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// Standard wrapper for widget tests that need tokens + typography.
/// Does NOT provide AppStateProvider — use [testAppWithAuth] for that.
Widget testApp(Widget child, {ThemeMode mode = ThemeMode.dark}) => MaterialApp(
      theme: TregoTheme.light(),
      darkTheme: TregoTheme.dark(),
      themeMode: mode,
      home: child,
    );

/// Wrapper for tests that render a screen reading context.watch<AppStateProvider>().
/// Provides a [FakeAppStateProvider] so tests don't touch Firebase.
Widget testAppWithAuth(
  Widget child, {
  ThemeMode mode = ThemeMode.dark,
  Map<String, dynamic>? user,
  bool isAuthenticated = true,
}) =>
    ChangeNotifierProvider<AppStateProvider>.value(
      value: FakeAppStateProvider(user: user, isAuthenticated: isAuthenticated),
      child: testApp(child, mode: mode),
    );

/// Replacement for AppStateProvider that doesn't transitively initialize Firebase.
/// Every getter returns a simple value; no AuthService, no ApiClient.
class FakeAppStateProvider extends ChangeNotifier implements AppStateProvider {
  FakeAppStateProvider({Map<String, dynamic>? user, bool isAuthenticated = true})
      : _user = user,
        _isAuthenticated = isAuthenticated;

  final Map<String, dynamic>? _user;
  final bool _isAuthenticated;

  @override
  bool get isAuthenticated => _isAuthenticated;
  @override
  Map<String, dynamic>? get user => _user;
  @override
  bool get isInitializing => false;
  @override
  bool get isOnline => true;
  @override
  bool get isServerHealthy => true;
  @override
  String? get lastError => null;
  @override
  DateTime? get lastErrorTime => null;

  // Unused by tests; provided as no-ops to satisfy the interface.
  @override
  Future<void> signOut() async {}
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
