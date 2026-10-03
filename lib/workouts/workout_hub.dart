import 'package:flutter/material.dart';
import '../shared/theme/context_tokens.dart';
import 'activity/activity_picker_screen.dart';
import 'activity/history_screen.dart';
import 'activity/prs_screen.dart';
import 'workout_plan_screen.dart';

class WorkoutHub extends StatefulWidget {
  const WorkoutHub({super.key});

  @override
  State<WorkoutHub> createState() => _WorkoutHubState();
}

class _WorkoutHubState extends State<WorkoutHub> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    return Scaffold(
      appBar: AppBar(
        title: Text('Workouts', style: typo.title.copyWith(color: tokens.onBrand)),
        backgroundColor: tokens.brand,
        foregroundColor: tokens.onBrand,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WorkoutHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Personal records',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PRsScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: tokens.onBrand,
          labelColor: tokens.onBrand,
          unselectedLabelColor: tokens.onBrand.withValues(alpha: 0.7),
          labelStyle: typo.button,
          unselectedLabelStyle: typo.button,
          tabs: const [
            Tab(
              icon: Icon(Icons.add),
              text: 'Log Activity',
            ),
            Tab(
              icon: Icon(Icons.fitness_center),
              text: 'Workout Plans',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ActivityPickerScreen(embedded: true),
          WorkoutPlanScreen(),
        ],
      ),
    );
  }
}
