import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/loading_provider.dart';
import 'widgets/error_handler_widget.dart';

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
                    // Navigate to auth screen
                    // For now, just show a placeholder
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Auth screen coming soon!')),
                    );
                  },
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sign in screen coming soon!')),
                  );
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
    return Scaffold(
      body: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Trego'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  // Navigate to notifications
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
              _PlaceholderTab(title: 'Dashboard', icon: Icons.dashboard),
              _PlaceholderTab(title: 'Workouts', icon: Icons.fitness_center),
              _PlaceholderTab(title: 'Nutrition', icon: Icons.restaurant),
              _PlaceholderTab(title: 'Social', icon: Icons.people),
              _PlaceholderTab(title: 'For You', icon: Icons.auto_awesome),
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

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/auth': (context) => _buildAuthScreen(context),
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
          const Text('Coming soon with backend integration!'),
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