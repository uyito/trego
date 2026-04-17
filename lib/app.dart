import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/loading_provider.dart';
import 'widgets/error_handler_widget.dart';
import 'shared/connectivity_status_widget.dart';
import 'shared/alert_service.dart';
import 'shared/realtime_notification_manager.dart';
import 'shared/notification_settings_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'workouts/workout_hub.dart';
import 'tracker/tracker_hub.dart';
import 'recipes/recipe_screen.dart';
import 'personalization/for_you_hub.dart';
import 'social/social_hub.dart';

class TregoApp extends StatelessWidget {
  const TregoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
      ],
      child: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          if (appState.isInitializing) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fitness_center, size: 100, color: Colors.blue),
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Initializing Trego...'),
                    ],
                  ),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'Trego',
            theme: _buildTheme(),
            home: ErrorHandlerWidget(
              child: _buildHome(context, appState),
            ),
            routes: _buildRoutes(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildHome(BuildContext context, AppStateProvider appState) {
    if (!appState.isAuthenticated) {
      return _buildAuthScreen(context);
    }
    
    return _buildMainScreen(context);
  }

  Widget _buildAuthScreen(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 120, color: Colors.blue),
              const SizedBox(height: 32),
              Text(
                'Welcome to Trego',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI-powered fitness companion',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen(BuildContext context) {
    return InAppAlertWidget(
      child: ConnectivityStatusWidget(
        child: _MainScreenContent(),
      ),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/auth': (context) => _buildAuthScreen(context),
      '/login': (context) => const LoginScreen(),
      '/register': (context) => const RegisterScreen(),
      '/dashboard': (context) => const _PlaceholderTab(title: 'Dashboard', icon: Icons.dashboard),
      '/workouts': (context) => const _PlaceholderTab(title: 'Workouts', icon: Icons.fitness_center),
      '/nutrition': (context) => const _PlaceholderTab(title: 'Nutrition', icon: Icons.restaurant),
      '/social': (context) => const _PlaceholderTab(title: 'Social', icon: Icons.people),
      '/recommendations': (context) => const _PlaceholderTab(title: 'Recommendations', icon: Icons.auto_awesome),
      '/profile': (context) => const _PlaceholderTab(title: 'Profile', icon: Icons.person),
      '/settings': (context) => const _PlaceholderTab(title: 'Settings', icon: Icons.settings),
    };
  }
}

class _MainScreenContent extends StatefulWidget {
  @override
  State<_MainScreenContent> createState() => _MainScreenContentState();
}

class _MainScreenContentState extends State<_MainScreenContent> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Initialize real-time notifications for authenticated user
    // In a real app, you'd get the user ID from your auth service
    const mockUserId = 'current_user_id';
    await RealtimeNotificationManager.instance.initialize(mockUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Trego'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  // Navigate to profile
                },
              ),
            ],
          ),
          body: const TabBarView(
            children: [
              TrackerHub(),
              WorkoutHub(),
              RecipeScreen(),
              SocialHub(),
              ForYouHub(),
            ],
          ),
          bottomNavigationBar: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.fitness_center), text: 'Workouts'),
              Tab(icon: Icon(Icons.restaurant), text: 'Nutrition'),
              Tab(icon: Icon(Icons.people), text: 'Social'),
              Tab(icon: Icon(Icons.auto_awesome), text: 'For You'),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Coming soon with real-time notifications!'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title feature in development')),
              );
            },
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }
}