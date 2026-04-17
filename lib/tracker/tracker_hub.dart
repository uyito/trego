import 'package:flutter/material.dart';
import 'tracker_dashboard_screen.dart';
import 'live_run_tracker_screen.dart';
import 'weekly_summary_screen.dart';

class TrackerHub extends StatefulWidget {
  const TrackerHub({super.key});

  @override
  State<TrackerHub> createState() => _TrackerHubState();
}

class _TrackerHubState extends State<TrackerHub> with TickerProviderStateMixin {
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
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard),
              text: 'Overview',
            ),
            Tab(
              icon: Icon(Icons.directions_run),
              text: 'Run Tracker',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Weekly Stats',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TrackerDashboardScreen(),
          LiveRunTrackerScreen(),
          WeeklySummaryScreen(),
        ],
      ),
    );
  }
}