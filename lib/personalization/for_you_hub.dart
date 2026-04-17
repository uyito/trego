import 'package:flutter/material.dart';
import '../achievements/achievements_screen.dart';
import 'screens/enhanced_recommendations_screen.dart';
import '../analytics/advanced_analytics_dashboard.dart';

class ForYouHub extends StatefulWidget {
  const ForYouHub({super.key});

  @override
  State<ForYouHub> createState() => _ForYouHubState();
}

class _ForYouHubState extends State<ForYouHub> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('For You'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.auto_awesome),
              text: 'Recommendations',
            ),
            Tab(
              icon: Icon(Icons.military_tech),
              text: 'Achievements',
            ),
            Tab(
              icon: Icon(Icons.insights),
              text: 'Insights',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          EnhancedRecommendationsScreen(),
          AchievementsScreen(),
          AdvancedAnalyticsDashboard(),
        ],
      ),
    );
  }
}