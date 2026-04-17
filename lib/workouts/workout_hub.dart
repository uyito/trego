import 'package:flutter/material.dart';
import 'simple_workout_tracker.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.timer),
              text: 'Quick Workout',
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
          SimpleWorkoutTracker(),
          WorkoutPlanScreen(),
        ],
      ),
    );
  }
}