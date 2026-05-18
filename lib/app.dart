import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'metrics/metrics_api_client.dart';
import 'metrics/metrics_provider.dart';
import 'navigation/app_shell.dart';
import 'providers/app_state_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/loading_provider.dart';
import 'providers/plan_provider.dart';
import 'shared/alert_service.dart';
import 'shared/api_client.dart';
import 'shared/connectivity_status_widget.dart';
import 'shared/realtime_notification_manager.dart';
import 'shared/theme/appearance_controller.dart';
import 'shared/theme/trego_theme.dart';
import 'tracker/pending_saves_flusher.dart';
import 'tracker/record_preferences.dart';
import 'widgets/error_handler_widget.dart';

class TregoApp extends StatefulWidget {
  const TregoApp({super.key});

  @override
  State<TregoApp> createState() => _TregoAppState();
}

class _TregoAppState extends State<TregoApp> {
  final _appearance = AppearanceController();

  @override
  void initState() {
    super.initState();
    _appearance.load();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider<AppearanceController>.value(value: _appearance),
        // Record flow providers
        ChangeNotifierProvider(create: (_) => RecordPreferences()..load()),
        Provider<PendingSavesFlusher>(
          create: (_) => PendingSavesFlusher(saver: FirestoreRunSaver())..start(),
          dispose: (_, __) {},
        ),
        Provider<MetricsApiClient>(
          create: (_) => MetricsApiClient(http: ApiClient.instance),
        ),
        ChangeNotifierProvider<MetricsProvider>(
          create: (ctx) => MetricsProvider(client: ctx.read<MetricsApiClient>()),
        ),
      ],
      child: Consumer2<AppStateProvider, AppearanceController>(
        builder: (context, appState, appearance, _) {
          // Drop cached metrics on sign-out.
          if (!appState.isAuthenticated &&
              context.read<MetricsProvider>().hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.read<MetricsProvider>().clear();
            });
          }
          if (appState.isInitializing) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.fitness_center, size: 100),
                      SizedBox(height: 24),
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Initializing Trego...'),
                    ],
                  ),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'Trego',
            theme: TregoTheme.light(),
            darkTheme: TregoTheme.dark(),
            themeMode: appearance.mode,
            home: ErrorHandlerWidget(child: _buildHome(context, appState)),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
            },
          );
        },
      ),
    );
  }

  Widget _buildHome(BuildContext context, AppStateProvider appState) {
    if (!appState.isAuthenticated) return _buildAuthScreen(context);
    return _MainShell();
  }

  Widget _buildAuthScreen(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 120),
              const SizedBox(height: 32),
              Text(
                'Welcome to Trego',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI-powered fitness companion',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainShell extends StatefulWidget {
  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  @override
  void initState() {
    super.initState();
    const mockUserId = 'current_user_id';
    RealtimeNotificationManager.instance.initialize(mockUserId);
  }

  @override
  Widget build(BuildContext context) {
    return InAppAlertWidget(
      child: ConnectivityStatusWidget(
        child: const AppShell(),
      ),
    );
  }
}
